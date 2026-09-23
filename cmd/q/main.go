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
	"bufio"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/0xDTC/0xq/internal/clip"
	"github.com/0xDTC/0xq/internal/config"
	"github.com/0xDTC/0xq/internal/executor"
	"github.com/0xDTC/0xq/internal/fill"
	"github.com/0xDTC/0xq/internal/index"
	"github.com/0xDTC/0xq/internal/nexthint"
	"github.com/0xDTC/0xq/internal/parser"
	"github.com/0xDTC/0xq/internal/qlog"
	"github.com/0xDTC/0xq/internal/saveas"
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

	// Extract picker filter flags (--phase/--risk/--tag/--platform)
	// from args before subcommand dispatch. Applied only when we fall
	// through to the picker/query path — subcommands ignore them.
	var pickerFilter interactiveFilter
	args, pickerFilter = extractPickerFilters(args)

	if len(args) == 0 {
		qlog.Infof("dispatch: interactive (no args, filter=%+v)", pickerFilter)
		if err := interactive("", inline, pickerFilter); err != nil {
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
	case "session":
		if err := runSession(args[1:]); err != nil {
			fmt.Fprintln(os.Stderr, "[-] session:", err)
			os.Exit(1)
		}
	case "var":
		if err := runVar(args[1:]); err != nil {
			fmt.Fprintln(os.Stderr, "[-] var:", err)
			os.Exit(1)
		}
	case "target":
		if err := runTarget(args[1:]); err != nil {
			fmt.Fprintln(os.Stderr, "[-] target:", err)
			os.Exit(1)
		}
	case "update":
		if err := runUpdate(); err != nil {
			fmt.Fprintln(os.Stderr, "[-] update:", err)
			os.Exit(1)
		}
	default:
		// Anything else is treated as an initial query. Matches the
		// bash tree — `q nmap` = interactive picker pre-filtered to nmap.
		if err := interactive(strings.Join(args, " "), inline, pickerFilter); err != nil {
			fmt.Fprintln(os.Stderr, "[-]", err)
			os.Exit(1)
		}
	}
}

// interactiveFilter is the picker's pre-filter set (metadata narrowing
// applied BEFORE fuzzy search). Empty fields = no restriction.
type interactiveFilter struct {
	Phase    string
	Risk     string
	Tag      string
	Platform string
}

// extractPickerFilters walks args, pulls out any --phase/--risk/--tag/
// --platform flag+value pairs, and returns (remaining, filter). Format
// accepted: `--flag value` or `--flag=value`. Unknown flags pass
// through untouched (so subcommands can define their own).
func extractPickerFilters(args []string) ([]string, interactiveFilter) {
	var (
		out    []string
		filter interactiveFilter
	)
	for i := 0; i < len(args); i++ {
		a := args[i]
		key, val, hasEq := strings.Cut(a, "=")
		takeNext := func() string {
			if hasEq {
				return val
			}
			if i+1 < len(args) {
				i++
				return args[i]
			}
			return ""
		}
		switch key {
		case "--phase":
			filter.Phase = strings.ToLower(takeNext())
		case "--risk":
			filter.Risk = strings.ToLower(takeNext())
		case "--tag":
			filter.Tag = strings.ToLower(takeNext())
		case "--platform":
			filter.Platform = strings.ToLower(takeNext())
		default:
			out = append(out, a)
		}
	}
	return out, filter
}

// matchesFilter reports whether an index entry passes every non-empty
// field of the filter. Case-insensitive contains-match on tags so
// `--tag ad` matches an entry tagged `ad,kerberoast,spn`.
func matchesFilter(e index.Entry, f interactiveFilter) bool {
	if f.Phase != "" && !strings.EqualFold(e.Phase, f.Phase) {
		return false
	}
	if f.Risk != "" && !strings.EqualFold(e.Risk, f.Risk) {
		return false
	}
	if f.Platform != "" && !strings.EqualFold(e.Platform, f.Platform) && e.Platform != "any" && e.Platform != "" {
		return false
	}
	if f.Tag != "" && !strings.Contains(strings.ToLower(e.Tags), f.Tag) {
		return false
	}
	return true
}

func usage() {
	fmt.Fprintf(os.Stderr, `q — Fast command launcher for pentesters (go port %s)

USAGE
    q [query]                Picker over cheatsheets (default)
    q edit [query]           Open a cheatsheet in $EDITOR (fuzzy match)
    q session [sub]          Session mgmt — new|use|list|rm|current
    q var [sub]              Var mgmt      — list|get|set|rm
    q target [sub]           Target mgmt   — list|add|rm|clear
    q update                 Pull latest cheatsheets + rebuild index
    q rebuild                Rebuild the cheatsheet index cache
    q lint                   Static checks — dupes / missing UA / no-timeout / deprecated flags
    q config get NAME        Read config knob (from ~/.config/q/config.sh)
    q history                Show current session's command history
    q log [-f|clear]         Show / tail / clear the debug log
    q --version | -v
    q --help | -h

FILTERS  (prepend to any picker/query invocation)
    --phase X                narrow to phase (recon|enum|attack|post|dfir|...)
    --risk X                 narrow to risk  (low|medium|high|safe)
    --tag X                  narrow to entries whose tags contain X (substring)
    --platform X             narrow to platform (linux|windows|any)
    e.g.  q --phase attack --tag ad   nmap

PICKER KEYS
    Enter                   run — fills placeholders (reuses last values silently)
    Ctrl+F / F4 / Alt+↵     run BUT prompt for every placeholder (change IP/path/...)
    Ctrl+E / F3             open the selected cheatsheet in $EDITOR (auto-rebuild)
    ↑↓ / ^K ^J              move        Esc         quit
    (type)                  fuzzy-filter across title, tool, tags, category

CONFIRM KEYS  (after fill, before execution)
    Enter                   run the command
    v                       Change values — re-prompt every placeholder
    e                       Edit text — open the assembled command in $EDITOR
    c                       Copy assembled command to system clipboard (or OSC52 fallback)
    s                       Save-as new cheatsheet (prompts title + description)
    q                       cancel

PLACEHOLDERS  (in cheatsheet command templates)
    {{NAME}}                       plain string
    {{NAME:type:default}}          typed (str|ip|url|port|file|dir|domain|...)
    {{NAME:choice:a,b=hint,c}}     pick from a list, optional hints
    {{NAME:helpflags:tool}}        pick a flag from ` + "`tool --help`" + ` output
    {{NAME:wordlist:default}}      picker of curated SecLists / wordlists files
    {{NAME:snippet:key}}           expand a named snippet (reverse shells, PTY upgrades)
    {{?TAG}}...{{/TAG}}            optional block (asks yes/no)

FILES
    ~/.local/bin/q                     the binary
    ~/.local/bin/q-ua                  live-UA helper (used by cheatsheets)
    ~/.local/share/q/                  session state, MRU, debug.log, var_history
    ~/.local/share/q/sessions/<name>/  per-session vars, targets, history, hashes.txt
    ~/.config/q/                       config.sh, snippets/*.yaml, enabled tool state

ENV
    Q_SESSION_NAME  active session (default "default"; see q session)
    Q_LOG=off       disable debug log entirely
    Q_PROMOTE=off   disable output auto-promote (parse stdout for IPs/hashes/...)
    Q_CLIP=osc52    force OSC52 escape for clipboard (tmux + SSH-friendly)
    EDITOR          $EDITOR / $VISUAL / nano / vim / vi (in that order)
`, version)
}

// interactive runs the default picker flow: read the cheatsheet
// index, show the NATIVE bubbletea picker. On selection:
//   - if inline is true (Ctrl+Q widget), the FILLED command goes
//     to stdout so the shell can slot it into the buffer;
//   - otherwise the executor confirm-and-runs it.
//
// filter narrows the row set BEFORE fuzzy search (metadata restrict).
// Empty-fields filter = no restriction (behaviour identical to before).
func interactive(query string, inline bool, filter interactiveFilter) error {
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
	// everything else rank 999999. filter narrows BEFORE row build.
	var rows []tui.Row
	filtered := 0
	for _, e := range entries {
		if !platformOK(e.Platform, osFilter) {
			continue
		}
		if !matchesFilter(e, filter) {
			filtered++
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
	if filtered > 0 {
		qlog.Infof("picker: filter=%+v narrowed %d rows (%d remain)", filter, filtered, len(rows))
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
		return interactive(query, inline, filter)
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
	return runFillAndConfirmWithHint(env, sess, sel, forceInteractiveFill, inline)
}

// runFillAndConfirmWithHint wraps runFillAndConfirm with a post-run
// "what's next?" line pulled from the nexthint rule table. Only fires
// on OutcomeRun (i.e., user actually executed) so hints don't spam
// after cancels/copies/saves.
func runFillAndConfirmWithHint(env *config.Env, sess *session.Session, e index.Entry, forceInteractive, inline bool) error {
	err := runFillAndConfirm(env, sess, e.Command, forceInteractive, inline)
	if err == nil && !inline {
		if hint := nexthint.For(e.Title, e.Tags); hint != "" {
			fmt.Fprintf(os.Stderr, "\x1b[2m[next] %s\x1b[0m\n", hint)
		}
	}
	return err
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
			outcome2, err := executor.ConfirmAndRun(sess, edited, true)
			if err != nil || outcome2 != executor.OutcomeVars {
				return err
			}
			forceInteractive = true
			continue
		case executor.OutcomeCopy:
			qlog.Action("confirm", "copy", "")
			if err := clip.Copy(filled); err != nil {
				fmt.Fprintln(os.Stderr, "[-] copy failed:", err)
				fmt.Fprintln(os.Stderr, "[*] manual copy — command printed above")
			} else {
				fmt.Fprintln(os.Stderr, "[+] copied to clipboard via", clip.ToolName())
			}
			return nil
		case executor.OutcomeSave:
			qlog.Action("confirm", "save-as", "")
			if err := saveFilledAsCheatsheet(env, filled); err != nil {
				fmt.Fprintln(os.Stderr, "[-] save-as failed:", err)
			}
			return nil
		default:
			return nil
		}
	}
}

// saveFilledAsCheatsheet prompts the user for a title + short
// description, then hands the (assembled or template) command to the
// saveas package. On success, rebuilds the index so the new entry
// shows up in the picker immediately.
func saveFilledAsCheatsheet(env *config.Env, command string) error {
	fmt.Fprintln(os.Stderr)
	fmt.Fprint(os.Stderr, "\x1b[1msave-as — title\x1b[0m (short lowercase words, e.g. \"nmap fast htb\"): ")
	title, err := readLine()
	if err != nil {
		return err
	}
	if strings.TrimSpace(title) == "" {
		return fmt.Errorf("title required")
	}
	fmt.Fprint(os.Stderr, "\x1b[1msave-as — description\x1b[0m (Enter to skip): ")
	desc, err := readLine()
	if err != nil {
		return err
	}
	path, err := saveas.Append(env.SheetsDir, title, desc, command)
	if err != nil {
		return err
	}
	fmt.Fprintln(os.Stderr, "[+] saved →", path)
	// Rebuild so the new entry is pickable right away.
	if err := rebuildIndex(); err != nil {
		fmt.Fprintln(os.Stderr, "[!] rebuild after save-as:", err)
	}
	return nil
}

// readOneKey reads one byte from /dev/tty (falling back to stdin).
// Used for y/N confirmation prompts. Non-raw: user must press Enter
// after the letter; that's fine for interactive confirms.
func readOneKey() (byte, error) {
	f, err := os.Open("/dev/tty")
	if err != nil {
		f = os.Stdin
	} else {
		defer f.Close()
	}
	var b [1]byte
	_, err = f.Read(b[:])
	return b[0], err
}

// readLine reads a single line from /dev/tty when available, falling
// back to stdin. Trims trailing newline. Used for the save-as prompts
// where we want unbuffered visible input, not the raw single-byte
// input from readOneKey.
func readLine() (string, error) {
	f, err := os.Open("/dev/tty")
	if err != nil {
		f = os.Stdin
	} else {
		defer f.Close()
	}
	sc := bufio.NewReader(f)
	line, err := sc.ReadString('\n')
	if err != nil {
		return "", err
	}
	return strings.TrimRight(line, "\r\n"), nil
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

// runSession handles `q session {list|current|new NAME|use NAME|rm NAME}`.
// Session state = a subdir of DataDir/sessions/ holding per-session
// vars, targets, MRU, and history.log. Persisted "active" session
// name lives at DataDir/.active_session — env Q_SESSION_NAME wins.
func runSession(args []string) error {
	env, err := config.Load()
	if err != nil {
		return err
	}
	sub := "list"
	if len(args) > 0 {
		sub = args[0]
	}
	sessionsDir := filepath.Join(env.DataDir, "sessions")
	_ = os.MkdirAll(sessionsDir, 0o755)
	activeFile := filepath.Join(env.DataDir, ".active_session")

	switch sub {
	case "list", "ls":
		entries, err := os.ReadDir(sessionsDir)
		if err != nil {
			return err
		}
		active := env.SessionName()
		var names []string
		for _, e := range entries {
			if e.IsDir() {
				names = append(names, e.Name())
			}
		}
		if len(names) == 0 {
			fmt.Fprintln(os.Stderr, "[*] no sessions yet — 'q session new NAME' to create one")
			return nil
		}
		for _, n := range names {
			mark := "  "
			if n == active {
				mark = "▸ "
			}
			// Best-effort metrics per session.
			histCount := 0
			if b, err := os.ReadFile(filepath.Join(sessionsDir, n, "history.log")); err == nil {
				histCount = strings.Count(string(b), "\n")
			}
			varsCount := 0
			if b, err := os.ReadFile(filepath.Join(sessionsDir, n, "vars")); err == nil {
				varsCount = strings.Count(strings.TrimRight(string(b), "\n"), "\n") + 1
				if len(b) == 0 {
					varsCount = 0
				}
			}
			targetsCount := 0
			if b, err := os.ReadFile(filepath.Join(sessionsDir, n, "targets")); err == nil {
				targetsCount = strings.Count(strings.TrimRight(string(b), "\n"), "\n") + 1
				if len(b) == 0 {
					targetsCount = 0
				}
			}
			fmt.Fprintf(os.Stdout, "%s%-24s %3d cmds  %2d vars  %2d targets\n",
				mark, n, histCount, varsCount, targetsCount)
		}
	case "current", "active":
		fmt.Println(env.SessionName())
	case "new":
		if len(args) < 2 {
			return fmt.Errorf("usage: q session new NAME")
		}
		name := args[1]
		if !validSessionName(name) {
			return fmt.Errorf("invalid session name: %q (letters/digits/_-. only)", name)
		}
		d := filepath.Join(sessionsDir, name)
		if _, err := os.Stat(d); err == nil {
			return fmt.Errorf("session already exists: %s", name)
		}
		if err := os.MkdirAll(d, 0o755); err != nil {
			return err
		}
		// Auto-switch to the new session.
		if err := os.WriteFile(activeFile, []byte(name+"\n"), 0o644); err != nil {
			return err
		}
		fmt.Fprintln(os.Stderr, "[+] created + switched →", name)
	case "use", "switch":
		if len(args) < 2 {
			return fmt.Errorf("usage: q session use NAME")
		}
		name := args[1]
		d := filepath.Join(sessionsDir, name)
		if _, err := os.Stat(d); os.IsNotExist(err) {
			return fmt.Errorf("no such session: %s (use 'q session new %s' to create)", name, name)
		}
		if err := os.WriteFile(activeFile, []byte(name+"\n"), 0o644); err != nil {
			return err
		}
		fmt.Fprintln(os.Stderr, "[+] switched →", name)
	case "rm", "delete":
		if len(args) < 2 {
			return fmt.Errorf("usage: q session rm NAME")
		}
		name := args[1]
		if name == "default" {
			return fmt.Errorf("refusing to delete 'default' session — clear its files with 'q session use default && rm ~/.local/share/q/sessions/default/*' if that's really what you want")
		}
		d := filepath.Join(sessionsDir, name)
		if _, err := os.Stat(d); os.IsNotExist(err) {
			return fmt.Errorf("no such session: %s", name)
		}
		fmt.Fprintf(os.Stderr, "\x1b[1;33m[!]\x1b[0m delete session %q and all its data? [y/N] ", name)
		key, _ := readOneKey()
		fmt.Fprintln(os.Stderr)
		if key != 'y' && key != 'Y' {
			fmt.Fprintln(os.Stderr, "[*] cancelled.")
			return nil
		}
		if err := os.RemoveAll(d); err != nil {
			return err
		}
		// If we just deleted the active one, fall back to default.
		if env.SessionName() == name {
			_ = os.WriteFile(activeFile, []byte("default\n"), 0o644)
			fmt.Fprintln(os.Stderr, "[*] fell back to 'default' session")
		}
		fmt.Fprintln(os.Stderr, "[+] deleted", name)
	default:
		return fmt.Errorf("unknown session subcommand: %s (valid: list|current|new|use|rm)", sub)
	}
	return nil
}

func validSessionName(s string) bool {
	if s == "" {
		return false
	}
	for _, r := range s {
		ok := (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') ||
			(r >= '0' && r <= '9') || r == '_' || r == '-' || r == '.'
		if !ok {
			return false
		}
	}
	return true
}

// runVar handles `q var {list|get NAME|set NAME VALUE|rm NAME}` on
// the ACTIVE session. NAMEs are upper-cased for convention.
func runVar(args []string) error {
	env, err := config.Load()
	if err != nil {
		return err
	}
	sess, err := session.New(env.SessionDir())
	if err != nil {
		return err
	}
	sub := "list"
	if len(args) > 0 {
		sub = args[0]
	}
	switch sub {
	case "list", "ls":
		vars := sess.AllVars()
		if len(vars) == 0 {
			fmt.Fprintln(os.Stderr, "[*] no vars set")
			return nil
		}
		for k, v := range vars {
			fmt.Printf("%-16s = %s\n", k, v)
		}
	case "get":
		if len(args) < 2 {
			return fmt.Errorf("usage: q var get NAME")
		}
		name := strings.ToUpper(args[1])
		v := sess.GetVar(name)
		if v == "" {
			return fmt.Errorf("var not set: %s", name)
		}
		fmt.Println(v)
	case "set":
		if len(args) < 3 {
			return fmt.Errorf("usage: q var set NAME VALUE")
		}
		name := strings.ToUpper(args[1])
		val := strings.Join(args[2:], " ")
		if err := sess.SetVar(name, val); err != nil {
			return err
		}
		fmt.Fprintf(os.Stderr, "[+] %s = %s\n", name, val)
	case "rm", "delete", "unset":
		if len(args) < 2 {
			return fmt.Errorf("usage: q var rm NAME")
		}
		name := strings.ToUpper(args[1])
		// SetVar with "" removes; but SetVar rejects empty? Use direct rewrite.
		if err := sess.SetVar(name, ""); err != nil {
			return err
		}
		// Empty value stored — remove by rewriting the file without the row.
		// SetVar's behavior: writes k= line. That's still "set" but empty.
		// Post-process to strip:
		if err := removeVarLine(env.SessionDir(), name); err != nil {
			return err
		}
		fmt.Fprintln(os.Stderr, "[+] removed", name)
	default:
		return fmt.Errorf("unknown var subcommand: %s (valid: list|get|set|rm)", sub)
	}
	return nil
}

// removeVarLine rewrites <sessDir>/vars without the row starting NAME=.
// Complements session.SetVar which only appends; there's no public delete.
func removeVarLine(sessDir, name string) error {
	path := filepath.Join(sessDir, "vars")
	b, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	var kept []string
	for _, line := range strings.Split(strings.TrimRight(string(b), "\n"), "\n") {
		if line == "" {
			continue
		}
		if strings.HasPrefix(line, name+"=") {
			continue
		}
		kept = append(kept, line)
	}
	out := strings.Join(kept, "\n")
	if out != "" {
		out += "\n"
	}
	return os.WriteFile(path, []byte(out), 0o644)
}

// runTarget handles `q target {list|add VALUE|rm VALUE|clear}` on
// the ACTIVE session.
func runTarget(args []string) error {
	env, err := config.Load()
	if err != nil {
		return err
	}
	sess, err := session.New(env.SessionDir())
	if err != nil {
		return err
	}
	sub := "list"
	if len(args) > 0 {
		sub = args[0]
	}
	switch sub {
	case "list", "ls":
		targets := sess.Targets()
		if len(targets) == 0 {
			fmt.Fprintln(os.Stderr, "[*] no targets")
			return nil
		}
		for _, t := range targets {
			fmt.Printf("%-8s %s\n", t.Type, t.Value)
		}
	case "add":
		if len(args) < 2 {
			return fmt.Errorf("usage: q target add VALUE")
		}
		v := args[1]
		if err := sess.AddTarget(v, "cli"); err != nil {
			return err
		}
		fmt.Fprintf(os.Stderr, "[+] added %s (type=%s)\n", v, session.ClassifyTarget(v))
	case "rm", "delete":
		if len(args) < 2 {
			return fmt.Errorf("usage: q target rm VALUE")
		}
		v := args[1]
		if err := removeTargetLine(env.SessionDir(), v); err != nil {
			return err
		}
		fmt.Fprintln(os.Stderr, "[+] removed", v)
	case "clear":
		fmt.Fprint(os.Stderr, "\x1b[1;33m[!]\x1b[0m clear ALL targets for session? [y/N] ")
		key, _ := readOneKey()
		fmt.Fprintln(os.Stderr)
		if key != 'y' && key != 'Y' {
			fmt.Fprintln(os.Stderr, "[*] cancelled.")
			return nil
		}
		_ = os.Remove(filepath.Join(env.SessionDir(), "targets"))
		fmt.Fprintln(os.Stderr, "[+] cleared")
	default:
		return fmt.Errorf("unknown target subcommand: %s (valid: list|add|rm|clear)", sub)
	}
	return nil
}

// removeTargetLine rewrites <sessDir>/targets without any row whose
// VALUE (the part after the first colon) matches v.
func removeTargetLine(sessDir, v string) error {
	path := filepath.Join(sessDir, "targets")
	b, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	var kept []string
	for _, line := range strings.Split(strings.TrimRight(string(b), "\n"), "\n") {
		if line == "" {
			continue
		}
		if col := strings.IndexByte(line, ':'); col >= 0 && line[col+1:] == v {
			continue
		}
		kept = append(kept, line)
	}
	out := strings.Join(kept, "\n")
	if out != "" {
		out += "\n"
	}
	return os.WriteFile(path, []byte(out), 0o644)
}

// runUpdate does `git pull` in the repo root, then `q rebuild`.
// Errors are surfaced but never rebuild-crashing — a failed pull
// still leaves the tree usable.
func runUpdate() error {
	root, err := qRoot()
	if err != nil {
		return err
	}
	if _, err := os.Stat(filepath.Join(root, ".git")); os.IsNotExist(err) {
		return fmt.Errorf("q root %s isn't a git checkout — nothing to update", root)
	}
	fmt.Fprintln(os.Stderr, "[*] git pull in", root)
	c := exec.Command("git", "-C", root, "pull", "--ff-only")
	c.Stdout = os.Stderr
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		fmt.Fprintln(os.Stderr, "[!] git pull failed — rebuilding index against current tree anyway")
	}
	return rebuildIndex()
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

// lint runs a battery of static checks across every cheatsheet:
//
//	1. Cross-file duplicate commands (original behaviour)
//	2. Web-request commands missing a {{UA}} placeholder
//	3. Deprecated flags (--random-agent, --random-user-agent, -json without -jsonl)
//	4. Placeholder name inconsistencies (TARGET vs TARGET_IP for the same tool)
//	5. Scanner commands without a timeout guard
//
// Every finding prints as `<severity> <file>:<title> — <detail>`.
// Exits nonzero on any finding so CI/pre-commit can gate on it.
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

	findings := 0

	// 1. duplicate commands
	groups := map[string][]index.Entry{}
	for _, e := range entries {
		key := normaliseForLint(e.Command)
		groups[key] = append(groups[key], e)
	}
	for _, es := range groups {
		if len(es) < 2 {
			continue
		}
		findings++
		fmt.Fprintf(os.Stderr, "\x1b[33m[dup]\x1b[0m ×%d — same normalised command in:\n", len(es))
		for _, e := range es {
			fmt.Fprintf(os.Stderr, "    %s:%s\n", e.Source, e.Title)
		}
	}

	// 2-5. per-entry checks
	for _, e := range entries {
		for _, f := range lintEntry(e) {
			findings++
			fmt.Fprintf(os.Stderr, "\x1b[33m[%s]\x1b[0m %s:%s — %s\n", f.kind, e.Source, e.Title, f.msg)
		}
	}

	if findings == 0 {
		fmt.Fprintln(os.Stderr, "[+] lint clean.")
		return nil
	}
	fmt.Fprintf(os.Stderr, "\n%d finding(s).\n", findings)
	return nil
}

// lintFinding is one detector output row.
type lintFinding struct{ kind, msg string }

// containsURL reports whether cmd carries a literal http(s):// URL —
// used by the UA-missing check to skip curl/wget invocations that
// don't actually make an outbound HTTP request (local file ops,
// unix-socket calls, etc.).
func containsURL(cmd string) bool {
	return strings.Contains(cmd, "http://") || strings.Contains(cmd, "https://")
}

// containsURLPlaceholder reports whether cmd uses a {{...:url}} or
// {{URL...}} placeholder. Chained commands where curl reads $url from
// an earlier step still need UA spoofing even though the URL isn't
// literal in the template.
func containsURLPlaceholder(cmd string) bool {
	return strings.Contains(cmd, ":url}}") || strings.Contains(cmd, "{{URL") ||
		strings.Contains(cmd, `"$url"`) || strings.Contains(cmd, "$url ")
}

// isBotFriendlyURL reports whether the URL in cmd points to a host
// that returns raw content regardless of User-Agent (GitHub raw,
// GitHub API, release-download endpoints, PyPA install script). Sending
// a spoofed UA to these hosts is pointless — they're built for
// automation.
func isBotFriendlyURL(cmd string) bool {
	for _, h := range []string{
		"raw.githubusercontent.com",
		"api.github.com",
		"gist.githubusercontent.com",
		"github.com/", // covers /releases/latest/download/ + /raw/ redirects
		"bootstrap.pypa.io",
		"sh.rustup.rs",
		"get.docker.com",
	} {
		if strings.Contains(cmd, h) {
			return true
		}
	}
	return false
}

// webToolFlags maps a leading token (the tool name) to the UA-carrying
// flag we expect to see somewhere in the command. Used by lintEntry
// check "ua-missing".
var webToolFlags = map[string]string{
	"nuclei":      `-H "User-Agent`,
	"ffuf":        `-H "User-Agent`,
	"wfuzz":       `-H "User-Agent`,
	"katana":      `-H "User-Agent`,
	"httpx":       `-H "User-Agent`,
	"gobuster":    `-a "`,
	"feroxbuster": `--user-agent`,
	"dirsearch":   `--user-agent`,
	"wpscan":      `--user-agent`,
	"nikto":       `-useragent`,
	"whatweb":     `--user-agent`,
	"sqlmap":      `--user-agent`,
	"curl":        `-A `, // curl -A
}

// deprecatedFlags maps a flag string to a short reason why it's flagged.
var deprecatedFlags = map[string]string{
	"--random-agent":      "sqlmap's --random-agent pulls from a fixed list that WAFs already know",
	"--random-user-agent": "wpscan's --random-user-agent has the same problem — use an explicit UA via q-ua",
	"-irr":                "nuclei -irr is deprecated; -jsonl includes RR unless -omit-raw is set",
}

// scannerNeedsTimeout lists tools whose long default runtime should be
// bounded by a `timeout` prefix or a tool-specific --maxtime flag.
var scannerNeedsTimeout = map[string]bool{
	"nikto":  true,
	"amass":  true,
	"masscan": true,
}

func lintEntry(e index.Entry) []lintFinding {
	var out []lintFinding
	cmd := e.Command

	// (a) UA-missing check: if any known web tool appears anywhere in
	// the command and no UA flag follows, flag it.
	//
	// Skips (false-positive killers):
	//   - commands that don't reference an HTTP URL at all (curl
	//     used for downloading from raw.githubusercontent.com, or
	//     for local operations, doesn't need spoofing)
	//   - commands hitting well-known bot-friendly infra (raw.
	//     githubusercontent.com, api.github.com) — no WAF, UA
	//     doesn't matter
	//   - the `web/curl.md` "show verbose request headers" demo entry
	//     which is teaching curl syntax, not making a real request
	for tool, needle := range webToolFlags {
		if !strings.Contains(cmd, tool) {
			continue
		}
		if strings.Contains(cmd, needle) {
			continue
		}
		// Skip if command doesn't hit an HTTP target at all — but
		// exempt the fuzzers/scanners whose --url or -u flag might
		// carry the target elsewhere.
		if tool == "curl" || tool == "wget" {
			if !containsURL(cmd) && !containsURLPlaceholder(cmd) {
				continue
			}
			if isBotFriendlyURL(cmd) {
				continue
			}
			// The one intentional demo — teaching curl's -v output.
			if strings.Contains(cmd, "-v ") && strings.Contains(cmd, "2>&1") {
				continue
			}
		}
		// gobuster dns mode uses DNS, not HTTP — never carries UA.
		if tool == "gobuster" && strings.Contains(cmd, "gobuster dns") {
			continue
		}
		out = append(out, lintFinding{
			kind: "ua-missing",
			msg:  "uses '" + tool + "' but no UA flag found — add " + needle + `...{{UA:str:$(q-ua)}}"`,
		})
	}

	// (b) Deprecated-flag check.
	for flag, why := range deprecatedFlags {
		if strings.Contains(cmd, flag) {
			out = append(out, lintFinding{
				kind: "deprecated",
				msg:  flag + " — " + why,
			})
		}
	}

	// (c) Placeholder-name consistency: prefer TARGET over TARGET_IP for
	// tools that use the ip type; harmless heuristic, not a hard rule.
	if strings.Contains(cmd, "{{TARGET_IP") && strings.Contains(cmd, "{{TARGET:ip") {
		out = append(out, lintFinding{
			kind: "placeholder-mix",
			msg:  "both {{TARGET}} and {{TARGET_IP}} used — pick one for session-var sharing",
		})
	}

	// (d) Scanner-without-timeout: long-runners should be bounded.
	first := strings.Fields(cmd)
	if len(first) > 0 {
		head := strings.TrimSpace(first[0])
		// strip sudo prefix
		if head == "sudo" && len(first) > 1 {
			head = first[1]
		}
		if scannerNeedsTimeout[head] {
			if !strings.Contains(cmd, "timeout ") && !strings.Contains(cmd, "--maxtime") && !strings.Contains(cmd, "-maxtime") {
				out = append(out, lintFinding{
					kind: "no-timeout",
					msg:  head + " has no timeout / --maxtime — hung scans stall the session",
				})
			}
		}
	}

	return out
}

// normaliseForLint replaces every {{...}} placeholder with a
// [[NAME=default]] sentinel — INCLUDING the default value so two
// commands with the same skeleton but semantically-different defaults
// don't collide. Example: `reg query "HKCU:...\Run"` and
// `reg query "HKLM:...\Putty"` both look like `reg query "[[KEYPATH]]"`
// under the old name-only rule; now they normalise to distinct
// `reg query "[[KEYPATH=HKCU:...\Run]]"` vs `[[KEYPATH=HKLM:...\Putty]]`
// and stay separate.
//
// Placeholders without a default still normalise to `[[NAME]]` so
// `nmap {{TARGET:ip}}` variants collide as before.
//
// The sentinel form still doesn't re-match {{...}}, avoiding the
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
			name, def := lintSplitPlaceholder(inner)
			out = append(out, '[', '[')
			out = append(out, name...)
			if def != "" {
				out = append(out, '=')
				out = append(out, def...)
			}
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

// lintSplitPlaceholder parses `NAME[:TYPE[:DEFAULT]]` (the inner of
// a {{...}} token) into (name, default). Returns default="" when the
// placeholder omits it. Type is discarded — for lint purposes only
// name + default matter (two commands with different types but same
// default resolve to the same filled string).
func lintSplitPlaceholder(inner string) (name, def string) {
	c1 := indexByteAny(inner, ":}")
	if c1 < 0 || inner[c1] == '}' {
		return inner, ""
	}
	name = inner[:c1]
	rest := inner[c1+1:]
	// Second colon splits type from default.
	c2 := indexByteAny(rest, ":")
	if c2 < 0 {
		return name, "" // only type given, no default
	}
	def = rest[c2+1:]
	return name, def
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
