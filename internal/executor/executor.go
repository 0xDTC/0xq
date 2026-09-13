// Package executor confirms a filled command with the user, runs
// path sanity checks, executes via `bash -c`, and logs to the
// session's history.log. Ports lib/executor.sh.
package executor

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/0xDTC/0xq/internal/session"
)

// Outcome names what the user asked for at the confirm prompt.
type Outcome int

const (
	OutcomeRun    Outcome = iota // execute the filled command
	OutcomeEdit                  // open in $EDITOR (not yet wired)
	OutcomeCopy                  // copy to clipboard (not yet wired)
	OutcomeSave                  // save-as-cheatsheet (not yet wired)
	OutcomeCancel                // do nothing
)

// ConfirmAndRun shows the command in bold+green, runs a path sanity
// check that warns about non-existent input files, then reads one
// key from stdin: Enter = run, e = edit, c = copy, s = save, q = quit.
// Non-run outcomes are returned so the caller can act; run happens
// inline and logs the exit code + duration to session history.
func ConfirmAndRun(sess *session.Session, command string, requireConfirm bool) (Outcome, error) {
	// 1. Show the command.
	fmt.Fprintln(os.Stderr)
	fmt.Fprintf(os.Stderr, "\x1b[1;32m %s \x1b[0m\n", command)

	// 2. Path sanity check.
	warnMissingInputPaths(command)

	// 3. Confirm.
	if requireConfirm {
		fmt.Fprintln(os.Stderr)
		fmt.Fprint(os.Stderr, "\x1b[1m[Enter]\x1b[0m Run  \x1b[1m[e]\x1b[0m Edit  \x1b[1m[c]\x1b[0m Copy  \x1b[1m[s]\x1b[0m Save  \x1b[1m[q]\x1b[0m Cancel  ")
		key, err := readOneKey()
		fmt.Fprintln(os.Stderr)
		if err != nil {
			return OutcomeCancel, err
		}
		switch key {
		case '\r', '\n', 'y', 'Y', 'r', 'R':
			// fallthrough to run
		case 'e', 'E':
			return OutcomeEdit, nil
		case 'c', 'C':
			return OutcomeCopy, nil
		case 's', 'S':
			return OutcomeSave, nil
		default:
			return OutcomeCancel, nil
		}
	}

	// 4. Run.
	fmt.Fprintln(os.Stderr, "\x1b[2m--- Executing ---\x1b[0m")
	start := time.Now()
	cmd := exec.Command("bash", "-c", command)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	dur := int(time.Since(start).Seconds())
	rc := 0
	if err != nil {
		if ee, ok := err.(*exec.ExitError); ok {
			rc = ee.ExitCode()
		} else {
			rc = 1
		}
	}
	fmt.Fprintf(os.Stderr, "\x1b[2m--- Finished (exit %d, %ds) ---\x1b[0m\n", rc, dur)
	if sess != nil {
		_ = sess.HistoryLog(command, rc, dur)
	}
	return OutcomeRun, nil
}

// warnMissingInputPaths mirrors lib/executor.sh — flags path-shaped
// tokens (start with / ./ ~/ ../) that don't exist AND aren't
// clearly output destinations (after > / -o / --output=). Best
// effort; false positives are non-fatal (only prints a warning).
func warnMissingInputPaths(command string) {
	tokens := strings.Fields(command)
	outFlags := map[string]bool{
		"-o": true, "-oN": true, "-oX": true, "-oG": true, "-oA": true,
		"-w": true, "-of": true, "--out": true, "--output": true,
		"--output-file": true, "--outfile": true, "--write": true, "--write-to": true,
	}
	prev := ""
	for _, tok := range tokens {
		// Skip token AFTER a redirect operator or output flag.
		if isRedirect(prev) || outFlags[prev] {
			prev = tok
			continue
		}
		// Skip inline redirects / inline output-flag assignments.
		if strings.HasPrefix(tok, ">") || strings.HasPrefix(tok, "<") ||
			strings.HasPrefix(tok, "2>") || strings.HasPrefix(tok, "&>") ||
			strings.HasPrefix(tok, "--output=") || strings.HasPrefix(tok, "--output-file=") ||
			strings.HasPrefix(tok, "--out=") || strings.HasPrefix(tok, "--outfile=") ||
			strings.HasPrefix(tok, "-o=") {
			prev = tok
			continue
		}
		// Strip surrounding quotes.
		t := strings.Trim(tok, `"'`)
		// Path-shaped only.
		if !(strings.HasPrefix(t, "/") || strings.HasPrefix(t, "./") ||
			strings.HasPrefix(t, "~/") || strings.HasPrefix(t, "../")) {
			prev = tok
			continue
		}
		// Skip URLs.
		if strings.Contains(t, "://") {
			prev = tok
			continue
		}
		expanded := t
		if strings.HasPrefix(t, "~/") {
			home, _ := os.UserHomeDir()
			expanded = home + t[1:]
		}
		info, err := os.Stat(expanded)
		if err != nil {
			fmt.Fprintf(os.Stderr, "\x1b[1;33m[!]\x1b[0m path not found: %s\n", t)
		} else if !info.IsDir() && info.Size() == 0 {
			fmt.Fprintf(os.Stderr, "\x1b[1;33m[!]\x1b[0m empty file: %s\n", t)
		}
		prev = tok
	}
}

func isRedirect(tok string) bool {
	switch tok {
	case ">", ">>", "<", "2>", "2>>", "&>", "1>":
		return true
	}
	return false
}

// readOneKey reads one byte from stdin in raw mode. Returns the key
// or an error. If /dev/tty isn't readable, falls back to line read.
func readOneKey() (byte, error) {
	f, err := os.Open("/dev/tty")
	if err != nil {
		// No tty — read from stdin.
		var b [1]byte
		_, err := os.Stdin.Read(b[:])
		return b[0], err
	}
	defer f.Close()
	if err := setRawMode(int(f.Fd())); err != nil {
		// Best-effort — just read a line and take the first byte.
		var buf [128]byte
		n, _ := f.Read(buf[:])
		if n == 0 {
			return 0, nil
		}
		return buf[0], nil
	}
	defer restoreMode(int(f.Fd()))
	var b [1]byte
	_, err = f.Read(b[:])
	return b[0], err
}
