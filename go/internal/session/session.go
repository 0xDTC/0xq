// Package session tracks session state: KEY=VAL vars, targets, MRU,
// and a KEY=VAL history for variable candidates. Ports the on-disk
// layout of lib/session.sh — the Go binary and the (deprecated) bash
// tree both see the same files.
package session

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Session is a handle to the current session dir. Cheap; no state
// held in the struct — everything reads/writes the on-disk files.
type Session struct {
	Dir string
}

// New returns a Session for dir (created if missing).
func New(dir string) (*Session, error) {
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return nil, err
	}
	return &Session{Dir: dir}, nil
}

// --- KEY=VAL vars -----------------------------------------------------

// varsFile is the plaintext KEY=VAL store; one line per entry.
func (s *Session) varsFile() string { return filepath.Join(s.Dir, "vars") }

// GetVar returns the value for k, or "" if unset.
func (s *Session) GetVar(k string) string {
	f, err := os.Open(s.varsFile())
	if err != nil {
		return ""
	}
	defer f.Close()
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, k+"=") {
			return line[len(k)+1:]
		}
	}
	return ""
}

// SetVar writes k=v atomically. Existing rows for k are removed.
func (s *Session) SetVar(k, v string) error {
	if strings.ContainsAny(k, "=\n\t") {
		return fmt.Errorf("invalid var name: %q", k)
	}
	path := s.varsFile()
	existing, _ := os.ReadFile(path)
	var out []string
	for _, line := range strings.Split(strings.TrimRight(string(existing), "\n"), "\n") {
		if line == "" || strings.HasPrefix(line, k+"=") {
			continue
		}
		out = append(out, line)
	}
	out = append(out, k+"="+v)
	return writeLines(path, out)
}

// AllVars returns every KEY=VAL pair. Order: file order (append).
func (s *Session) AllVars() map[string]string {
	m := map[string]string{}
	f, err := os.Open(s.varsFile())
	if err != nil {
		return m
	}
	defer f.Close()
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		line := sc.Text()
		eq := strings.IndexByte(line, '=')
		if eq <= 0 {
			continue
		}
		m[line[:eq]] = line[eq+1:]
	}
	return m
}

// --- targets ----------------------------------------------------------

func (s *Session) targetsFile() string { return filepath.Join(s.Dir, "targets") }

// Target is one entry with a type (url|ip|cidr|domain|file|str) and a
// value. Types are inferred by ClassifyTarget below when adding.
type Target struct {
	Type  string
	Value string
}

// AddTarget prepends v (deduped) with an inferred type. source is
// stored for logging (not persisted).
func (s *Session) AddTarget(v, source string) error {
	t := ClassifyTarget(v)
	entry := t + ":" + v
	path := s.targetsFile()
	existing, _ := os.ReadFile(path)
	var out []string
	out = append(out, entry) // prepend
	for _, line := range strings.Split(strings.TrimRight(string(existing), "\n"), "\n") {
		if line == "" || line == entry {
			continue
		}
		out = append(out, line)
	}
	return writeLines(path, out)
}

// Targets returns every target (MRU order).
func (s *Session) Targets() []Target {
	f, err := os.Open(s.targetsFile())
	if err != nil {
		return nil
	}
	defer f.Close()
	var out []Target
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		line := sc.Text()
		col := strings.IndexByte(line, ':')
		if col <= 0 {
			continue
		}
		out = append(out, Target{Type: line[:col], Value: line[col+1:]})
	}
	return out
}

// ClassifyTarget infers a type from the value's shape. Order matters
// (URL before domain, CIDR before IP, etc.).
func ClassifyTarget(v string) string {
	if strings.HasPrefix(v, "http://") || strings.HasPrefix(v, "https://") {
		return "url"
	}
	if looksLikeCIDR(v) {
		return "cidr"
	}
	if looksLikeIP(v) {
		return "ip"
	}
	if looksLikeDomain(v) {
		return "domain"
	}
	if strings.HasPrefix(v, "/") || strings.HasPrefix(v, "./") || strings.HasPrefix(v, "~/") {
		return "file"
	}
	return "str"
}

// --- MRU (global command-title history) -------------------------------

// mruFile lives at DataDir/mru — one title per line, most-recent first.
// Cap 50.
func mruFile(dataDir string) string { return filepath.Join(dataDir, "mru") }

// BumpMRU moves title to the top of DataDir/mru, dropping duplicates
// and truncating at cap 50.
func BumpMRU(dataDir, title string) error {
	if title == "" {
		return nil
	}
	path := mruFile(dataDir)
	existing, _ := os.ReadFile(path)
	var out []string
	out = append(out, title)
	for _, line := range strings.Split(strings.TrimRight(string(existing), "\n"), "\n") {
		if line == "" || line == title {
			continue
		}
		out = append(out, line)
		if len(out) >= 50 {
			break
		}
	}
	return writeLines(path, out)
}

// MRU returns the current MRU list (newest first).
func MRU(dataDir string) []string {
	b, err := os.ReadFile(mruFile(dataDir))
	if err != nil {
		return nil
	}
	var out []string
	for _, line := range strings.Split(strings.TrimRight(string(b), "\n"), "\n") {
		if line != "" {
			out = append(out, line)
		}
	}
	return out
}

// --- history.log --------------------------------------------------------

// HistoryLog appends one row: ts\trc\tdur\tcmd. Kept text-compatible
// with lib/session.sh so both trees can read the same log.
func (s *Session) HistoryLog(command string, rc, durationSec int) error {
	line := fmt.Sprintf("%s\t%d\t%d\t%s\n",
		nowTS(), rc, durationSec, strings.ReplaceAll(strings.ReplaceAll(command, "\t", " "), "\n", " ; "))
	f, err := os.OpenFile(filepath.Join(s.Dir, "history.log"), os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()
	_, err = f.WriteString(line)
	return err
}

// --- helpers ----------------------------------------------------------

func writeLines(path string, lines []string) error {
	tmp := path + ".tmp"
	f, err := os.Create(tmp)
	if err != nil {
		return err
	}
	bw := bufio.NewWriter(f)
	for _, line := range lines {
		if line == "" {
			continue
		}
		if _, err := bw.WriteString(line); err != nil {
			f.Close()
			os.Remove(tmp)
			return err
		}
		if err := bw.WriteByte('\n'); err != nil {
			f.Close()
			os.Remove(tmp)
			return err
		}
	}
	if err := bw.Flush(); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err := f.Close(); err != nil {
		os.Remove(tmp)
		return err
	}
	return os.Rename(tmp, path)
}
