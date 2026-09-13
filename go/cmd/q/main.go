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
	"fmt"
	"os"
	"path/filepath"

	"github.com/0xDTC/0xq/go/internal/index"
	"github.com/0xDTC/0xq/go/internal/parser"
)

const version = "0.1.0-wip"

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}
	switch os.Args[1] {
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
	default:
		fmt.Fprintf(os.Stderr, "[-] unknown subcommand: %s\n", os.Args[1])
		usage()
		os.Exit(2)
	}
}

func usage() {
	fmt.Fprintf(os.Stderr, `q — Fast command launcher for pentesters (go port %s)

USAGE
    q rebuild                Rebuild the cheatsheet index cache
    q lint                   Report cross-file duplicate commands
    q --version | -v
    q --help | -h

The bash tree at repo root is still authoritative for interactive
search, builder, combos, session, etc. This binary handles the
non-interactive maintenance commands only, for now.
`, version)
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
