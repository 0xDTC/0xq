// Package executor confirms a filled command with the user, runs
// path sanity checks, executes via `bash -c`, and logs to the
// session's history.log. Ports lib/executor.sh.
package executor

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/0xDTC/0xq/internal/promote"
	"github.com/0xDTC/0xq/internal/session"
)

// Outcome names what the user asked for at the confirm prompt.
type Outcome int

const (
	OutcomeRun    Outcome = iota // execute the filled command
	OutcomeVars                  // re-prompt placeholders (caller reruns fill Interactive)
	OutcomeEdit                  // open assembled command in $EDITOR
	OutcomeCopy                  // copy assembled command to system clipboard
	OutcomeSave                  // save assembled command as a new cheatsheet entry
	OutcomeCancel                // do nothing
)

// ConfirmAndRun shows the command in bold+green, runs a path sanity
// check that warns about non-existent input files, then reads one
// key from stdin.
//
// Keys:
//
//	Enter / y / r  → run the command as shown
//	v              → change placeholder values (return OutcomeVars)
//	e              → open the assembled command in $EDITOR then re-confirm
//	c              → copy assembled command to system clipboard, don't run
//	s              → save as a new cheatsheet entry (caller prompts for name)
//	q / esc / any  → cancel
//
// Non-run outcomes are returned so the caller can loop back through
// the fill flow; run happens inline and logs the exit code + duration.
func ConfirmAndRun(sess *session.Session, command string, requireConfirm bool) (Outcome, error) {
	// 1. Show the command.
	fmt.Fprintln(os.Stderr)
	fmt.Fprintf(os.Stderr, "\x1b[1;32m %s \x1b[0m\n", command)

	// 2. Path sanity check.
	warnMissingInputPaths(command)

	// 3. Confirm.
	if requireConfirm {
		fmt.Fprintln(os.Stderr)
		fmt.Fprint(os.Stderr, "\x1b[1m[Enter]\x1b[0m Run  \x1b[1m[v]\x1b[0m Vars  \x1b[1m[e]\x1b[0m Edit  \x1b[1m[c]\x1b[0m Copy  \x1b[1m[s]\x1b[0m Save-as  \x1b[1m[q]\x1b[0m Cancel  ")
		key, err := readOneKey()
		fmt.Fprintln(os.Stderr)
		if err != nil {
			return OutcomeCancel, err
		}
		switch key {
		case '\r', '\n', 'y', 'Y', 'r', 'R':
			// fallthrough to run
		case 'v', 'V':
			return OutcomeVars, nil
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

	// 4. Run — tee stdout into a size-capped buffer so we can parse it
	// for artefacts after exit (auto-promote). stderr isn't captured
	// because tool output that matters is almost always on stdout, and
	// many tools print progress noise to stderr that would pollute
	// findings.
	fmt.Fprintln(os.Stderr, "\x1b[2m--- Executing ---\x1b[0m")
	start := time.Now()
	cmd := exec.Command("bash", "-c", command)
	cmd.Stdin = os.Stdin
	capture := &capBuffer{max: 10 << 20} // 10 MiB cap
	cmd.Stdout = io.MultiWriter(os.Stdout, capture)
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
	// Auto-promote — parse captured stdout, offer artefacts to the
	// user. Disabled with Q_PROMOTE=off. Skipped entirely if session
	// or capture is empty.
	if sess != nil && capture.Len() > 0 && !strings.EqualFold(os.Getenv("Q_PROMOTE"), "off") {
		promotePrompt(sess, capture.Bytes())
	}
	return OutcomeRun, nil
}

// promotePrompt runs the promote parser over captured stdout, groups
// findings by kind, prints a summary, and asks the user whether to
// add the URL / IP / domain rows as session targets. Hashes get
// written to a per-session hashes file (never overwritten). UPNs go
// to a separate users file. All acceptance is opt-in per-run.
func promotePrompt(sess *session.Session, out []byte) {
	findings := promote.Parse(string(out))
	if len(findings) == 0 {
		return
	}
	// Deduplicate: strip anything already in session.Targets().
	existing := map[string]bool{}
	for _, t := range sess.Targets() {
		existing[t.Value] = true
	}
	var novel []promote.Finding
	for _, f := range findings {
		if existing[f.Value] {
			continue
		}
		novel = append(novel, f)
	}
	if len(novel) == 0 {
		return
	}

	fmt.Fprintln(os.Stderr)
	fmt.Fprintln(os.Stderr, "\x1b[1;36m[promote] discovered in output:\x1b[0m")
	byKind := map[promote.Kind][]promote.Finding{}
	for _, f := range novel {
		byKind[f.Kind] = append(byKind[f.Kind], f)
	}
	for _, k := range []promote.Kind{promote.KindURL, promote.KindPort, promote.KindIP, promote.KindDomain, promote.KindNTLM, promote.KindUPN} {
		rows := byKind[k]
		if len(rows) == 0 {
			continue
		}
		fmt.Fprintf(os.Stderr, "  \x1b[35m[%s]\x1b[0m %d\n", k, len(rows))
		for i, f := range rows {
			if i >= 5 {
				fmt.Fprintf(os.Stderr, "    … and %d more\n", len(rows)-5)
				break
			}
			fmt.Fprintf(os.Stderr, "    %s\n", f.Value)
		}
	}
	fmt.Fprint(os.Stderr, "\n\x1b[1mAdd URL/IP/domain rows to session targets? [y/N]\x1b[0m ")
	key, _ := readOneKey()
	fmt.Fprintln(os.Stderr)
	if key != 'y' && key != 'Y' {
		fmt.Fprintln(os.Stderr, "\x1b[2m[promote] skipped\x1b[0m")
		return
	}
	added := 0
	for _, f := range novel {
		switch f.Kind {
		case promote.KindURL, promote.KindIP, promote.KindDomain:
			if err := sess.AddTarget(f.Value, "promote"); err == nil {
				added++
			}
		}
	}
	// Hashes + UPNs go to per-session files for later reference.
	if hashes := byKind[promote.KindNTLM]; len(hashes) > 0 {
		writeSessFile(sess, "hashes.txt", hashes)
	}
	if upns := byKind[promote.KindUPN]; len(upns) > 0 {
		writeSessFile(sess, "users.txt", upns)
	}
	fmt.Fprintf(os.Stderr, "\x1b[32m[promote] +%d targets added to session\x1b[0m\n", added)
}

// writeSessFile appends unique values to <sessDir>/<name>. Used for
// hashes.txt + users.txt so promoted secrets aren't quietly lost when
// the user says "no" to target promotion.
func writeSessFile(sess *session.Session, name string, rows []promote.Finding) {
	if sess == nil {
		return
	}
	path := sess.Dir + "/" + name
	existing, _ := os.ReadFile(path)
	seen := map[string]bool{}
	for _, line := range strings.Split(string(existing), "\n") {
		if line != "" {
			seen[line] = true
		}
	}
	f, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return
	}
	defer f.Close()
	for _, r := range rows {
		if seen[r.Value] {
			continue
		}
		fmt.Fprintln(f, r.Value)
		seen[r.Value] = true
	}
}

// capBuffer is a byte buffer that stops accepting writes past a cap.
// Prevents a runaway scan from consuming all our memory when we tee
// its stdout for post-exec parsing.
type capBuffer struct {
	buf bytes.Buffer
	max int
}

func (c *capBuffer) Write(p []byte) (int, error) {
	remain := c.max - c.buf.Len()
	if remain <= 0 {
		return len(p), nil // pretend we wrote it; drop on floor
	}
	if len(p) > remain {
		c.buf.Write(p[:remain])
		return len(p), nil
	}
	return c.buf.Write(p)
}

func (c *capBuffer) Len() int      { return c.buf.Len() }
func (c *capBuffer) Bytes() []byte { return c.buf.Bytes() }

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
