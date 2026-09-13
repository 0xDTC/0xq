// q — Fast, keyboard-driven command launcher for pentesters.
// Go port. Currently implements: rebuild, lint.
//
// Roadmap subcommands (not yet wired):
//
//	q                    interactive picker (fzf subprocess)
//	q history / session  MRU + session mgmt
//	q build / combos     builder + combos captured on run
//	q config             config knob get/set
//
// The bash tree at repo root is authoritative during the port. When
// this binary reaches feature parity, migration doc goes here.
package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/0xDTC/0xq/internal/combos"
	"github.com/0xDTC/0xq/internal/config"
	"github.com/0xDTC/0xq/internal/executor"
	"github.com/0xDTC/0xq/internal/fill"
	"github.com/0xDTC/0xq/internal/index"
	"github.com/0xDTC/0xq/internal/parser"
	"github.com/0xDTC/0xq/internal/session"
	"github.com/0xDTC/0xq/internal/tui"
)

const version = "0.2.0-wip"

func main() {
	// --inline mode: same picker + fill flow, but the final filled
	// command goes to stdout (for the shell widget's BUFFER) instead
	// of being executed. Everything else prints to stderr / /dev/tty.
	inline := false
	args := os.Args[1:]
	if len(args) > 0 && args[0] == "--inline" {
		inline = true
		args = args[1:]
	}

	if len(args) == 0 {
		if err := interactive("", inline); err != nil {
			fmt.Fprintln(os.Stderr, "[-]", err)
			os.Exit(1)
		}
		return
	}
	switch args[0] {
	case "--version", "-v":
		fmt.Println("q", version, "(go port)")
	case "--help", "-h", "help":
		usage()
	case "rebuild":
		if err := rebuildIndex(); err != nil {
			fmt.Fprintln(os.Stderr, "[-] rebuild:", err)
			os.Exit(1)
		}
	case "lint":
		if err := lint(); err != nil {
			fmt.Fprintln(os.Stderr, "[-] lint:", err)
			os.Exit(1)
		}
	case "combos", "combo":
		runCombos(args[1:])
	case "config":
		runConfig(args[1:])
	case "history":
		runHistory()
	default:
		// Anything else is treated as an initial query. Matches the
		// bash tree — `q nmap` = interactive picker pre-filtered to nmap.
		if err := interactive(strings.Join(args, " "), inline); err != nil {
			fmt.Fprintln(os.Stderr, "[-]", err)
			os.Exit(1)
		}
	}
}

func usage() {
	fmt.Fprintf(os.Stderr, `q — Fast command launcher for pentesters (go port %s)

USAGE
    q [query]                Interactive picker (default; optional initial query)
    q rebuild                Rebuild the cheatsheet index cache
    q lint                   Report cross-file duplicate commands
    q combos [list|forget]   List / forget captured personal combos
    q config get NAME        Read config knob (from ~/.config/q/config.sh)
    q history                Show current session's command history
    q --version | -v
    q --help | -h

Fill / builder / [s] save / Ctrl+B/M/X/D keybinds land in follow-up
commits as their supporting packages come online. Selecting a command
today prints the raw template (with {{placeholders}} intact) so you
can inspect it; execution+fill lands next session.
`, version)
}

// interactive runs the default picker flow: read index + combos,
// show the NATIVE bubbletea picker. On selection:
//   - if inline is true (Ctrl+Q widget), the FILLED command goes
//     to stdout so the shell can slot it into the buffer;
//   - otherwise the executor confirm-and-runs it.
func interactive(query string, inline bool) error {
	env, err := config.Load()
	if err != nil {
		return err
	}
	entries, err := index.ReadFile(env.IndexPath())
	if err != nil {
		fmt.Fprintln(os.Stderr, "[*] Index missing, building...")
		if err := rebuildIndex(); err != nil {
			return err
		}
		entries, err = index.ReadFile(env.IndexPath())
		if err != nil {
			return err
		}
	}

	combRows := combos.EmitPickerRows(env.DataDir)
	mru := session.MRU(env.DataDir)
	osFilter := env.Get("Q_OS_FILTER", "")

	// Build MRU rank lookup.
	mruRank := map[string]int{}
	for i, t := range mru {
		if _, ok := mruRank[t]; !ok {
			mruRank[t] = i + 1
		}
	}

	// Assemble tui.Row set: combos rank 0 (top), MRU cheatsheets
	// rank 101+, everything else 999999.
	var rows []tui.Row
	for _, e := range combRows {
		if !platformOK(e.Platform, osFilter) {
			continue
		}
		rows = append(rows, entryToRow(e, "⚙", 0))
	}
	for _, e := range entries {
		if !platformOK(e.Platform, osFilter) {
			continue
		}
		mark := "  "
		rk := 999999
		if r, ok := mruRank[e.Title]; ok {
			mark = "★ "
			rk = r + 100
		}
		rows = append(rows, entryToRow(e, mark, rk))
	}

	// Preview callback — shows the highlighted row's template + its
	// session-filled preview + source. Bound to a fresh Session so
	// we can look up vars without allocating one per keystroke.
	previewSess, _ := session.New(env.SessionDir())
	preview := func(r tui.Row) string {
		e, ok := r.Payload.(index.Entry)
		if !ok {
			return ""
		}
		return renderPreview(e, previewSess)
	}

	res, err := tui.Show(tui.Options{
		Prompt:       "q> ",
		Header:       "★ recent  ⚙ combo  Enter=run  Esc=quit  ↑↓ = move",
		Rows:         rows,
		InitialQuery: query,
		Preview:      preview,
		PreviewRatio: 0.4,
	})
	if err != nil {
		return err
	}
	if res == nil || res.Cancelled || res.Selected == nil {
		fmt.Fprintln(os.Stderr, "[*] No command selected.")
		return nil
	}
	sel := res.Selected.Payload.(index.Entry)

	// Capture the template as a combo, bump the MRU by title.
	_ = combos.Bump(env.DataDir, sel.Command)
	_ = session.BumpMRU(env.DataDir, sel.Title)

	// Fill placeholders. Try auto (session vars + defaults) first;
	// fall back to interactive if any placeholder is unresolved or
	// the command has {{?...}} optional blocks.
	sess, err := session.New(env.SessionDir())
	if err != nil {
		return err
	}
	st := fill.NewState(sess, filepath.Join(env.DataDir, "var_history"))
	filled, err := st.Auto(sel.Command)
	if err != nil {
		if !errors.Is(err, fill.ErrUnresolved) && !errors.Is(err, fill.ErrOptional) {
			return err
		}
		filled, err = st.Interactive(sel.Command)
		if err != nil {
			return err
		}
		if filled == "" {
			fmt.Fprintln(os.Stderr, "[*] Fill cancelled.")
			return nil
		}
	}

	// Inline mode — return the filled command on stdout for the
	// Ctrl+Q shell widget. No exec.
	if inline {
		fmt.Print(filled)
		return nil
	}
	// Confirm + execute.
	_, err = executor.ConfirmAndRun(sess, filled, true)
	return err
}

// entryToRow flattens an index.Entry into a tui.Row. Display carries
// visible columns (mark, tool, title, description) with ANSI styling;
// Search is a plain-text concatenation of everything the fuzzy match
// should hit (title, tool, tags, category).
func entryToRow(e index.Entry, mark string, rank int) tui.Row {
	const (
		cyan    = "\x1b[36m"
		bold    = "\x1b[1m"
		dim     = "\x1b[2m"
		magenta = "\x1b[35m"
		reset   = "\x1b[0m"
	)
	sep := dim + "│" + reset
	desc := e.Desc
	if desc == "" {
		desc = "(no description)"
	}
	display := magenta + mark + reset +
		cyan + padCol(e.Tool, 22) + reset + " " + sep + " " +
		bold + padCol(e.Title, 38) + reset + " " + sep + " " +
		dim + desc + reset

	search := strings.Join([]string{
		e.Tool, e.Title, e.Desc, e.Category, e.Phase,
		strings.ReplaceAll(e.Tags, ",", " "),
	}, " ")

	return tui.Row{
		Display: display,
		Search:  search,
		Rank:    rank,
		Payload: e,
	}
}

func padCol(s string, w int) string {
	if len(s) >= w {
		return s[:w]
	}
	return s + strings.Repeat(" ", w-len(s))
}

func platformOK(rowPlatform, filter string) bool {
	if filter == "" || rowPlatform == "" || rowPlatform == "any" {
		return true
	}
	return strings.EqualFold(rowPlatform, filter)
}

func runCombos(args []string) {
	env, err := config.Load()
	if err != nil {
		fmt.Fprintln(os.Stderr, "[-]", err)
		os.Exit(1)
	}
	sub := "list"
	if len(args) > 0 {
		sub = args[0]
	}
	switch sub {
	case "list":
		filter := ""
		if len(args) > 1 {
			filter = args[1]
		}
		combos.List(env.DataDir, filter, os.Stderr)
	case "forget":
		if len(args) < 2 {
			fmt.Fprintln(os.Stderr, "usage: q combos forget TOOL [TEMPLATE]")
			os.Exit(1)
		}
		template := ""
		if len(args) > 2 {
			template = args[2]
		}
		if err := combos.Forget(env.DataDir, args[1], template); err != nil {
			fmt.Fprintln(os.Stderr, "[-]", err)
			os.Exit(1)
		}
		fmt.Fprintln(os.Stderr, "[+] forgotten.")
	case "path":
		fmt.Println(filepath.Join(env.DataDir, "combos"))
	default:
		fmt.Fprintf(os.Stderr, "unknown combos subcommand: %s\n", sub)
		fmt.Fprintln(os.Stderr, "valid: list [TOOL], forget TOOL [TEMPLATE], path")
		os.Exit(1)
	}
}

func runConfig(args []string) {
	env, err := config.Load()
	if err != nil {
		fmt.Fprintln(os.Stderr, "[-]", err)
		os.Exit(1)
	}
	if len(args) < 2 || args[0] != "get" {
		// Full list.
		for _, k := range []string{
			"Q_OS_FILTER", "Q_PREVIEW_SIZE", "Q_SESSION_NAME",
			"Q_CLIPBOARD_CANDIDATE", "Q_FILE_MAXDEPTH", "Q_FILE_MAXCOUNT",
			"Q_HOME_MAXDEPTH", "Q_HOME_MAXCOUNT",
		} {
			fmt.Printf("  %-24s %s\n", k, env.Get(k, ""))
		}
		return
	}
	key := args[1]
	if !strings.HasPrefix(key, "Q_") {
		key = "Q_" + strings.ToUpper(key)
	}
	fmt.Println(env.Get(key, ""))
}

func runHistory() {
	env, err := config.Load()
	if err != nil {
		fmt.Fprintln(os.Stderr, "[-]", err)
		os.Exit(1)
	}
	s, err := session.New(env.SessionDir())
	if err != nil {
		fmt.Fprintln(os.Stderr, "[-]", err)
		os.Exit(1)
	}
	b, err := os.ReadFile(filepath.Join(s.Dir, "history.log"))
	if err != nil {
		fmt.Fprintln(os.Stderr, "[*] no history yet.")
		return
	}
	os.Stdout.Write(b)
}

// qRoot resolves Q_ROOT — the directory containing lib/ and cheatsheets/.
// Order: Q_ROOT env → the parent of the running binary's directory (if
// that parent has cheatsheets/) → the CWD (if it has cheatsheets/).
func qRoot() (string, error) {
	if r := os.Getenv("Q_ROOT"); r != "" {
		return r, nil
	}
	// Walk up from the executable location looking for cheatsheets/.
	exe, err := os.Executable()
	if err == nil {
		dir := filepath.Dir(exe)
		for i := 0; i < 4; i++ {
			if _, err := os.Stat(filepath.Join(dir, "cheatsheets")); err == nil {
				return dir, nil
			}
			dir = filepath.Dir(dir)
		}
	}
	// Fall back to CWD.
	if cwd, err := os.Getwd(); err == nil {
		if _, err := os.Stat(filepath.Join(cwd, "cheatsheets")); err == nil {
			return cwd, nil
		}
	}
	return "", fmt.Errorf("could not locate Q_ROOT (set the env var to the dir holding cheatsheets/)")
}

func cacheDir(root string) string {
	if d := os.Getenv("Q_CACHE_DIR"); d != "" {
		return d
	}
	return filepath.Join(root, "cache")
}

func rebuildIndex() error {
	root, err := qRoot()
	if err != nil {
		return err
	}
	sheets := filepath.Join(root, "cheatsheets")
	cd := cacheDir(root)
	if err := os.MkdirAll(cd, 0o755); err != nil {
		return err
	}

	fmt.Fprintln(os.Stderr, "[*] Rebuilding cheatsheet index...")
	entries, err := parser.WalkAndParse(sheets)
	if err != nil {
		return err
	}
	out := filepath.Join(cd, "index.tsv")
	if err := index.WriteFile(out, entries); err != nil {
		return err
	}
	// Count unique source files.
	files := map[string]struct{}{}
	for _, e := range entries {
		files[e.Source] = struct{}{}
	}
	fmt.Fprintf(os.Stderr, "[*] Indexed %d commands from %d file(s)\n", len(entries), len(files))
	fmt.Fprintln(os.Stderr, "[+] Index rebuilt.")
	return nil
}

// lint finds duplicate commands across files. Same normalisation as
// the bash lib/core.sh `q lint`: replace every {{VAR:...}} with a
// [[VAR]] marker (sentinel that doesn't re-match), collapse
// whitespace, group by result.
func lint() error {
	root, err := qRoot()
	if err != nil {
		return err
	}
	idxPath := filepath.Join(cacheDir(root), "index.tsv")
	entries, err := index.ReadFile(idxPath)
	if err != nil {
		return fmt.Errorf("read index (run `q rebuild` first): %w", err)
	}
	groups := map[string][]index.Entry{}
	for _, e := range entries {
		key := normaliseForLint(e.Command)
		groups[key] = append(groups[key], e)
	}
	dupes := 0
	for key, es := range groups {
		if len(es) < 2 {
			continue
		}
		dupes++
		fmt.Fprintf(os.Stderr, "─── x%d ───\n  cmd:  %s\n  seen:", len(es), key)
		for _, e := range es {
			fmt.Fprintf(os.Stderr, "\n    %s:%s", e.Source, e.Title)
		}
		fmt.Fprintln(os.Stderr)
	}
	if dupes == 0 {
		fmt.Fprintln(os.Stderr, "[+] No cross-file duplicate commands found.")
		return nil
	}
	fmt.Fprintf(os.Stderr, "%d duplicate group(s).\n", dupes)
	return nil
}

// normaliseForLint replaces every {{...}} placeholder with a
// [[NAME]] sentinel (extracted from the leading NAME up to the first
// ':' or '}') so commands that differ only in placeholder metadata
// collide. The sentinel form doesn't re-match {{...}}, avoiding the
// infinite-loop bug the bash awk parser once had.
func normaliseForLint(cmd string) string {
	var out []byte
	i := 0
	for i < len(cmd) {
		if i+1 < len(cmd) && cmd[i] == '{' && cmd[i+1] == '{' {
			// Find matching }}
			end := i + 2
			for end+1 < len(cmd) && !(cmd[end] == '}' && cmd[end+1] == '}') {
				end++
			}
			if end+1 >= len(cmd) {
				out = append(out, cmd[i:]...)
				break
			}
			inner := cmd[i+2 : end]
			name := inner
			if c := indexByteAny(inner, ":}"); c >= 0 {
				name = inner[:c]
			}
			out = append(out, '[', '[')
			out = append(out, name...)
			out = append(out, ']', ']')
			i = end + 2
			continue
		}
		out = append(out, cmd[i])
		i++
	}
	// Collapse whitespace runs.
	s := string(out)
	for containsDoubleSpace(s) {
		s = replaceAll(s, "  ", " ")
	}
	// Trim.
	for len(s) > 0 && (s[0] == ' ' || s[0] == '\t') {
		s = s[1:]
	}
	for len(s) > 0 && (s[len(s)-1] == ' ' || s[len(s)-1] == '\t') {
		s = s[:len(s)-1]
	}
	return s
}

// Small helpers that avoid importing strings twice; kept local to
// keep the top of the file focused.
func indexByteAny(s, chars string) int {
	for i := 0; i < len(s); i++ {
		for j := 0; j < len(chars); j++ {
			if s[i] == chars[j] {
				return i
			}
		}
	}
	return -1
}
func containsDoubleSpace(s string) bool {
	for i := 0; i+1 < len(s); i++ {
		if s[i] == ' ' && s[i+1] == ' ' {
			return true
		}
	}
	return false
}
func replaceAll(s, old, new string) string {
	out := ""
	for {
		i := indexOf(s, old)
		if i < 0 {
			out += s
			return out
		}
		out += s[:i] + new
		s = s[i+len(old):]
	}
}
func indexOf(s, sub string) int {
	if len(sub) == 0 {
		return 0
	}
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return i
		}
	}
	return -1
}

// renderPreview builds the bottom-pane content for the highlighted
// row. Shows the raw template with {{VAR}} placeholders highlighted,
// then the session-filled version below (unresolved placeholders
// rendered as <?NAME?> in red), plus the source path. Kept fast
// because it runs on every cursor move.
func renderPreview(e index.Entry, sess *session.Session) string {
	const (
		bold    = "\x1b[1m"
		dim     = "\x1b[2m"
		cyan    = "\x1b[36m"
		yellow  = "\x1b[33m"
		green   = "\x1b[32m"
		red     = "\x1b[31m"
		magenta = "\x1b[35m"
		reset   = "\x1b[0m"
	)

	var b strings.Builder

	// TEMPLATE — the raw command with {{VAR:type:default}} shown in yellow.
	b.WriteString(bold + cyan + "TEMPLATE" + reset + "\n")
	b.WriteString("  " + highlightPlaceholders(e.Command, yellow, dim, reset) + "\n\n")

	// FILLED — walk placeholders, substitute from session vars.
	// Unresolved placeholders render as <?NAME?> in red.
	filled, missing := previewFill(e.Command, sess)
	if missing == 0 {
		b.WriteString(bold + cyan + "FILLED" + reset + " " + green + "[ready — Enter to run]" + reset + "\n")
	} else {
		b.WriteString(bold + cyan + "FILLED" + reset + " " +
			yellow + fmt.Sprintf("[%d unresolved — Enter to prompt]", missing) + reset + "\n")
	}
	b.WriteString("  " + filled + "\n\n")

	// Source path in dim.
	b.WriteString(dim + "source: " + e.Source)
	if e.Category == "combo" {
		b.WriteString("  " + magenta + "⚙ combo" + reset)
	}
	b.WriteString(reset)
	return b.String()
}

// highlightPlaceholders paints every {{...}} token in yellow-on-dim
// so the template pane visually distinguishes placeholders from
// literal command text.
func highlightPlaceholders(cmd, yellow, dim, reset string) string {
	var b strings.Builder
	b.Grow(len(cmd) + 64)
	b.WriteString(dim)
	rest := cmd
	for {
		i := strings.Index(rest, "{{")
		if i < 0 {
			b.WriteString(rest)
			break
		}
		b.WriteString(rest[:i])
		end := strings.Index(rest[i:], "}}")
		if end < 0 {
			b.WriteString(rest[i:])
			break
		}
		tok := rest[i : i+end+2]
		b.WriteString(reset + yellow + tok + reset + dim)
		rest = rest[i+end+2:]
	}
	b.WriteString(reset)
	return b.String()
}

// previewFill substitutes every {{NAME:type:default}} in cmd with
// (in order):
//   session-var value  →  green
//   declared default    →  green
//   <?NAME?>            →  red   (also counts toward missing)
//
// Returns (rendered, missingCount). Optional blocks are left
// intact — the preview shows the pre-optional shape.
func previewFill(cmd string, sess *session.Session) (string, int) {
	const (
		green = "\x1b[32m"
		red   = "\x1b[31m"
		bold  = "\x1b[1m"
		reset = "\x1b[0m"
	)
	missing := 0
	var b strings.Builder
	b.Grow(len(cmd) + 32)
	rest := cmd
	for {
		i := strings.Index(rest, "{{")
		if i < 0 {
			b.WriteString(rest)
			break
		}
		b.WriteString(rest[:i])
		end := strings.Index(rest[i:], "}}")
		if end < 0 {
			b.WriteString(rest[i:])
			break
		}
		inner := rest[i+2 : i+end]
		// Skip optional-block markers ({{?TAG}} / {{/TAG}}) — leave
		// them raw in the preview so the user can see the shape.
		if strings.HasPrefix(inner, "?") || strings.HasPrefix(inner, "/") {
			b.WriteString("{{" + inner + "}}")
			rest = rest[i+end+2:]
			continue
		}
		// Parse NAME[:TYPE[:DEFAULT]] — first-colon splits name, and
		// for choice types the default is the first comma-split option.
		name, typ, def := parsePlaceholderInner(inner)
		val := sess.GetVar(name)
		if val == "" {
			// For choice, the effective default is the first option
			// (with any =hint stripped).
			if typ == "choice" || typ == "enum" {
				if comma := strings.IndexByte(def, ','); comma > 0 {
					def = def[:comma]
				}
				if eq := strings.IndexByte(def, '='); eq > 0 {
					def = def[:eq]
				}
			}
			val = def
		}
		if val == "" {
			b.WriteString(red + bold + "<?" + name + "?>" + reset)
			missing++
		} else {
			b.WriteString(green + val + reset)
		}
		rest = rest[i+end+2:]
	}
	return b.String(), missing
}

// parsePlaceholderInner splits `NAME[:TYPE[:DEFAULT]]` — lightweight
// copy of internal/fill's parseInner (kept private to cmd/q so the
// preview doesn't reach into internal/fill for one function).
func parsePlaceholderInner(inner string) (name, typ, def string) {
	c1 := strings.IndexByte(inner, ':')
	if c1 < 0 {
		return inner, "str", ""
	}
	name = inner[:c1]
	rest := inner[c1+1:]
	c2 := strings.IndexByte(rest, ':')
	if c2 < 0 {
		typ = rest
		if typ == "" {
			typ = "str"
		}
		return
	}
	typ = rest[:c2]
	if typ == "" {
		typ = "str"
	}
	def = rest[c2+1:]
	return
}
