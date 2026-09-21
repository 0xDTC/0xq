// q — Fast, keyboard-driven command launcher for pentesters.
//
// Subcommands:
//
//	q [query]        interactive picker over cheatsheets
//	q edit [query]   open a cheatsheet in $EDITOR (fuzzy-matches title/tool)
//	q config get     read config knobs
//	q history        current session's command log
//	q log [-f|clear] show / tail / clear the debug log
//	q rebuild        rebuild the cheatsheet index cache
//	q lint           report cross-file duplicate commands
package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/0xDTC/0xq/internal/config"
	"github.com/0xDTC/0xq/internal/executor"
	"github.com/0xDTC/0xq/internal/fill"
	"github.com/0xDTC/0xq/internal/index"
	"github.com/0xDTC/0xq/internal/parser"
	"github.com/0xDTC/0xq/internal/qlog"
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

	// Boot the action log early so every subcommand entry shows up
	// even for one-shot invocations. Errors are swallowed inside
	// qlog.Init — the tool must never break because logging can't.
	if env, err := config.Load(); err == nil {
		qlog.Init(env.DataDir)
	}
	defer qlog.Close()
	qlog.Enter("main", "argv="+strings.Join(os.Args, " "), "inline=", inline)
	defer qlog.Exit("main", "done")

	if len(args) == 0 {
		qlog.Infof("dispatch: interactive (no args)")
		if err := interactive("", inline); err != nil {
			qlog.Errorf("interactive: %v", err)
			fmt.Fprintln(os.Stderr, "[-]", err)
			os.Exit(1)
		}
		return
	}
	qlog.Infof("dispatch: %s (args=%v)", args[0], args[1:])
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
	case "config":
		runConfig(args[1:])
	case "history":
		runHistory()
	case "log":
		runLog(args[1:])
	case "edit":
		if err := runEdit(strings.Join(args[1:], " ")); err != nil {
			fmt.Fprintln(os.Stderr, "[-] edit:", err)
			os.Exit(1)
		}
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
    q [query]                Picker over cheatsheets (default)
    q edit [query]           Open a cheatsheet in $EDITOR (fuzzy match)
    q rebuild                Rebuild the cheatsheet index cache
    q lint                   Report cross-file duplicate commands
    q config get NAME        Read config knob (from ~/.config/q/config.sh)
    q history                Show current session's command history
    q log [-f|clear]         Show / tail / clear the debug log
    q --version | -v
    q --help | -h

PICKER KEYS
    Enter                   run — fills placeholders (reuses last values silently)
    Ctrl+F / F4 / Alt+↵     run BUT prompt for every placeholder (change IP/path/…)
    Ctrl+E / F3             open the selected cheatsheet in $EDITOR (auto-rebuild)
    ↑↓ / ^K ^J              move        Esc         quit
    (type)                  fuzzy-filter across title, tool, tags, category

CONFIRM KEYS  (after fill, before execution)
    Enter                   run the command
    v                       Change values — re-prompt every placeholder
    e                       Edit text — open the assembled command in $EDITOR
    q                       cancel

PLACEHOLDERS  (in cheatsheet command templates)
    {{NAME}}                       plain string
    {{NAME:choice:a,b=hint,c}}     pick from a list, optional hints
    {{NAME:helpflags:tool}}        pick a flag from ` + "`tool --help`" + ` output
    {{?TAG}}...{{/TAG}}            optional block (asks yes/no)
`, version)
}

// interactive runs the default picker flow: read the cheatsheet
// index, show the NATIVE bubbletea picker. On selection:
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

	mru := session.MRU(env.DataDir)
	osFilter := env.Get("Q_OS_FILTER", "")

	// Build MRU rank lookup so recent picks sort to the top.
	mruRank := map[string]int{}
	for i, t := range mru {
		if _, ok := mruRank[t]; !ok {
			mruRank[t] = i + 1
		}
	}

	// Assemble tui.Row set: MRU cheatsheets rank 1..N (top),
	// everything else rank 999999.
	var rows []tui.Row
	for _, e := range entries {
		if !platformOK(e.Platform, osFilter) {
			continue
		}
		mark := "  "
		rk := 999999
		if r, ok := mruRank[e.Title]; ok {
			mark = "★ "
			rk = r
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

	// Ctrl+E opens the highlighted cheatsheet's source in $EDITOR.
	// F3 is bound as a tmux-safe alias — Ctrl+E is often free but
	// some terminals bind it to end-of-line.
	editAction := func(_ *tui.Row, _ string) (bool, error) { return true, nil }
	res, err := tui.Show(tui.Options{
		Prompt:       "q> ",
		Header:       "★ recent  Enter=run  Ctrl+F/F4=change vars  Ctrl+E/F3=edit file  Esc=quit",
		Rows:         rows,
		InitialQuery: query,
		Preview:      preview,
		PreviewRatio: 0.4,
		Binds: []tui.Bind{
			{Key: "ctrl+e", Label: "edit", Action: editAction},
			{Key: "f3", Label: "edit", Action: editAction},
			// Ctrl+F / F4 / Alt+Enter → force the Interactive fill
			// flow so the user gets a picker for every placeholder
			// (last-used values pre-selected on top). Ctrl+F matches
			// the bash tree's binding for muscle-memory continuity.
			{Key: "ctrl+f", Label: "vars", Action: func(_ *tui.Row, _ string) (bool, error) { return true, nil }},
			{Key: "f4", Label: "vars", Action: func(_ *tui.Row, _ string) (bool, error) { return true, nil }},
			{Key: "alt+enter", Label: "vars", Action: func(_ *tui.Row, _ string) (bool, error) { return true, nil }},
		},
	})
	if err != nil {
		return err
	}
	if res != nil && res.FiredBind == "edit" {
		if res.Selected == nil {
			fmt.Fprintln(os.Stderr, "[*] Nothing to edit.")
			return nil
		}
		e := res.Selected.Payload.(index.Entry)
		qlog.Action("picker", "edit", "src=%s title=%q", e.Source, e.Title)
		if err := openInEditor(env, e.Source); err != nil {
			return err
		}
		if err := rebuildIndex(); err != nil {
			qlog.Warnf("rebuild after edit: %v", err)
		}
		return interactive(query, inline)
	}
	if res == nil || res.Cancelled || res.Selected == nil {
		fmt.Fprintln(os.Stderr, "[*] No command selected.")
		return nil
	}
	sel := res.Selected.Payload.(index.Entry)
	forceInteractiveFill := res.FiredBind == "vars"
	if forceInteractiveFill {
		qlog.Action("picker", "force-interactive", "title=%q", sel.Title)
	}

	// Bump the MRU by title so this cheatsheet sorts to the top next
	// time. The cheatsheet file IS the source of truth; user edits
	// it directly with Ctrl+E when they want to change the template.
	_ = session.BumpMRU(env.DataDir, sel.Title)

	sess, err := session.New(env.SessionDir())
	if err != nil {
		return err
	}
	return runFillAndConfirm(env, sess, sel.Command, forceInteractiveFill, inline)
}

// runFillAndConfirm handles the fill → confirm → outcome loop for one
// command template. Broken out so the confirm dialog's [v] Change
// values option can loop back through fill.Interactive without
// duplicating the code.
func runFillAndConfirm(env *config.Env, sess *session.Session, template string, forceInteractive, inline bool) error {
	st := fill.NewState(sess, filepath.Join(env.DataDir, "var_history"))

	for {
		var filled string
		var err error
		if forceInteractive {
			filled, err = st.Interactive(template)
		} else {
			filled, err = st.Auto(template)
			if err != nil {
				if !errors.Is(err, fill.ErrUnresolved) && !errors.Is(err, fill.ErrOptional) {
					return err
				}
				filled, err = st.Interactive(template)
			}
		}
		if err != nil {
			return err
		}
		if filled == "" {
			fmt.Fprintln(os.Stderr, "[*] Fill cancelled.")
			return nil
		}

		// Inline mode — hand the assembled command back to the shell
		// widget on stdout. No confirm/exec loop; the shell drives.
		if inline {
			fmt.Print(filled)
			return nil
		}

		outcome, err := executor.ConfirmAndRun(sess, filled, true)
		if err != nil {
			return err
		}
		switch outcome {
		case executor.OutcomeVars:
			// User wants to change placeholder values — re-run fill
			// in Interactive mode, keeping the same template. The
			// session vars from the previous fill are still on top
			// of each picker, so Enter reuses / typing replaces.
			qlog.Action("confirm", "vars", "")
			forceInteractive = true
			continue
		case executor.OutcomeEdit:
			qlog.Action("confirm", "edit-text", "")
			edited, err := editTextInEditor(filled)
			if err != nil {
				return err
			}
			if edited == "" {
				return nil
			}
			// Skip fill on the manually-edited text and go straight
			// to confirm.
			outcome2, err := executor.ConfirmAndRun(sess, edited, true)
			if err != nil || outcome2 != executor.OutcomeVars {
				return err
			}
			// If they hit [v] on the edited text, restart with the
			// ORIGINAL template so placeholders come back.
			forceInteractive = true
			continue
		default:
			return nil
		}
	}
}

// editTextInEditor drops the given command into a temp file, opens
// $EDITOR against it, and returns the (possibly modified) contents.
// Empty return means the user emptied the file or cancelled somehow;
// caller should treat that as "don't run anything".
func editTextInEditor(command string) (string, error) {
	tmp, err := os.CreateTemp("", "q-edit-*.sh")
	if err != nil {
		return "", err
	}
	path := tmp.Name()
	if _, err := tmp.WriteString(command); err != nil {
		tmp.Close()
		os.Remove(path)
		return "", err
	}
	tmp.Close()
	defer os.Remove(path)

	ed := os.Getenv("EDITOR")
	if ed == "" {
		ed = "nano"
	}
	c := exec.Command(ed, path)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		return "", err
	}
	b, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(b)), nil
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

// runEdit opens a cheatsheet in $EDITOR. When query is empty, fires
// the picker restricted to Ctrl+E; when query matches one entry
// unambiguously, opens straight into the editor. On any match count
// > 1, falls back to a picker pre-filtered to the query so the user
// disambiguates. After the editor exits, the index rebuilds.
func runEdit(query string) error {
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

	// Unambiguous exact-file shortcut: `q edit foo.md` or a path.
	if query != "" {
		if _, err := os.Stat(query); err == nil {
			if err := openInEditor(env, query); err != nil {
				return err
			}
			return rebuildIndex()
		}
	}

	// Fuzzy-match query against title, tool, tags. On a single hit
	// open that file; otherwise show a picker restricted to the hits
	// so the user picks.
	scored := make([]index.Entry, 0, len(entries))
	q := strings.ToLower(query)
	for _, e := range entries {
		if q == "" || tui.Score(strings.ToLower(e.Title+" "+e.Tool+" "+e.Tags), q) > 0 {
			scored = append(scored, e)
		}
	}
	if len(scored) == 0 {
		fmt.Fprintln(os.Stderr, "[*] no cheatsheet matched", query)
		return nil
	}
	// Collapse to unique source files — same file often holds many
	// entries and we only need one edit target per file.
	uniq := map[string]index.Entry{}
	for _, e := range scored {
		if _, ok := uniq[e.Source]; !ok {
			uniq[e.Source] = e
		}
	}
	if len(uniq) == 1 {
		var target string
		for src := range uniq {
			target = src
		}
		if err := openInEditor(env, target); err != nil {
			return err
		}
		return rebuildIndex()
	}
	// Multiple candidate files → picker.
	rows := make([]tui.Row, 0, len(uniq))
	for src, e := range uniq {
		rows = append(rows, tui.Row{
			Display: fmt.Sprintf("\x1b[36m%s\x1b[0m  \x1b[2m%s\x1b[0m", e.Tool, src),
			Search:  e.Tool + " " + e.Title + " " + src,
			Payload: src,
		})
	}
	res, err := tui.Show(tui.Options{
		Prompt: "edit> ",
		Header: "Enter=open in $EDITOR  Esc=quit",
		Rows:   rows,
	})
	if err != nil {
		return err
	}
	if res == nil || res.Cancelled || res.Selected == nil {
		return nil
	}
	src := res.Selected.Payload.(string)
	if err := openInEditor(env, src); err != nil {
		return err
	}
	return rebuildIndex()
}

// openInEditor spawns the user's $EDITOR against path. Falls back
// through EDITOR → VISUAL → nano → vim. Inherits stdio so the editor
// gets a full-screen TTY.
//
// Cheatsheet sources are stored as PATHS RELATIVE TO env.SheetsDir
// so they stay portable between machines with different repo roots.
// When called from the Ctrl+Q widget the shell CWD is the user's,
// not the repo — a naked "web/dirsearch.md" would be looked up in
// the wrong place and the editor would open a blank buffer (or fail
// entirely). Resolve to absolute against SheetsDir before spawning.
func openInEditor(env *config.Env, path string) error {
	if !filepath.IsAbs(path) {
		path = filepath.Join(env.SheetsDir, path)
	}
	ed := os.Getenv("EDITOR")
	if ed == "" {
		ed = os.Getenv("VISUAL")
	}
	if ed == "" {
		for _, cand := range []string{"nano", "vim", "vi"} {
			if _, err := exec.LookPath(cand); err == nil {
				ed = cand
				break
			}
		}
	}
	if ed == "" {
		return fmt.Errorf("no editor found — set $EDITOR")
	}
	qlog.Infof("openInEditor: %s %s", ed, path)
	c := exec.Command(ed, path)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	return c.Run()
}

// runLog handles `q log`, `q log -f` (tail), and `q log clear`.
// Path lookup goes through qlog so a Q_LOG_FILE override is honoured.
func runLog(args []string) {
	p := qlog.Path()
	if p == "" {
		// qlog.Init hasn't set a path (Q_LOG=off or init failed).
		home, _ := os.UserHomeDir()
		p = filepath.Join(home, ".local", "share", "q", "debug.log")
	}
	sub := ""
	if len(args) > 0 {
		sub = args[0]
	}
	switch sub {
	case "-f", "follow", "tail":
		fmt.Fprintln(os.Stderr, "[*] following", p, "(Ctrl+C to stop)")
		if err := qlog.Tail(os.Stdout); err != nil {
			fmt.Fprintln(os.Stderr, "[-]", err)
			os.Exit(1)
		}
	case "clear", "reset":
		if err := os.Remove(p); err != nil && !os.IsNotExist(err) {
			fmt.Fprintln(os.Stderr, "[-]", err)
			os.Exit(1)
		}
		fmt.Fprintln(os.Stderr, "[+] cleared", p)
	case "", "cat":
		b, err := os.ReadFile(p)
		if err != nil {
			if os.IsNotExist(err) {
				fmt.Fprintln(os.Stderr, "[*] no log yet at", p)
				return
			}
			fmt.Fprintln(os.Stderr, "[-]", err)
			os.Exit(1)
		}
		os.Stdout.Write(b)
	default:
		fmt.Fprintf(os.Stderr, "unknown log subcommand: %s\n", sub)
		fmt.Fprintln(os.Stderr, "valid: (none|cat) dump; -f follow; clear")
		os.Exit(1)
	}
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
