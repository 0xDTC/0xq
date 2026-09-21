// Package qlog is q's structured action log — every meaningful
// keystroke, flow entry, and error gets a timestamped line so we can
// diagnose "why didn't X work" without asking the user to reproduce.
//
// Enabled by default; disabled by setting Q_LOG=off. Writes to
// $XDG_DATA_HOME/q/debug.log (override with Q_LOG_FILE=/path).
// Rotates at 1MiB — old file becomes debug.log.old (single generation
// kept; older archives dropped) so unattended runs can't fill disk.
//
// Concurrency: an internal *log.Logger + sync.Mutex. Safe for use from
// bubbletea's goroutine and the main goroutine simultaneously.
package qlog

import (
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

const rotateBytes int64 = 1 << 20 // 1 MiB

var (
	mu     sync.Mutex
	lg     *log.Logger
	file   *os.File
	path   string
	active bool
)

// Init opens (or reopens) the log. Called once at process start.
// dataDir is the root under which debug.log lives; a Q_LOG_FILE
// override wins if set. Errors are swallowed (a broken log must
// never break the tool) but printed to stderr once.
func Init(dataDir string) {
	mu.Lock()
	defer mu.Unlock()

	if strings.EqualFold(os.Getenv("Q_LOG"), "off") {
		active = false
		return
	}

	p := os.Getenv("Q_LOG_FILE")
	if p == "" {
		p = filepath.Join(dataDir, "debug.log")
	}
	_ = os.MkdirAll(filepath.Dir(p), 0o755)

	// Rotate if too big.
	if info, err := os.Stat(p); err == nil && info.Size() > rotateBytes {
		_ = os.Rename(p, p+".old")
	}

	f, err := os.OpenFile(p, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		fmt.Fprintln(os.Stderr, "[!] qlog init:", err)
		active = false
		return
	}
	if file != nil {
		_ = file.Close()
	}
	file = f
	path = p
	lg = log.New(f, "", log.LstdFlags|log.Lmicroseconds)
	active = true
	// Write the boot marker inline — calling writeLine here would
	// re-acquire mu and deadlock the process.
	lg.Printf("[=   ] session start pid=%d", os.Getpid())
}

// Path returns the current log file location (empty if disabled).
func Path() string {
	mu.Lock()
	defer mu.Unlock()
	return path
}

// Close flushes + closes the file. Safe to call more than once.
func Close() {
	mu.Lock()
	defer mu.Unlock()
	if file != nil {
		_ = file.Close()
		file = nil
	}
	active = false
}

// Infof / Warnf / Errorf mirror the log package's Printf but tag the
// line with a level so grep works nicely. Each takes format+args.
func Infof(format string, a ...any)  { writeLine("info", format, a...) }
func Warnf(format string, a ...any)  { writeLine("warn", format, a...) }
func Errorf(format string, a ...any) { writeLine("err ", format, a...) }

// Action is the workhorse: log a UI action with structured context.
// Use it for every keypress that changes state so the log becomes a
// full replay of the session's UX.
//
//	qlog.Action("curator", "delete", "tool=%s", name)
func Action(area, action, ctxFormat string, a ...any) {
	if ctxFormat == "" {
		writeLine("ACT", "%s.%s", area, action)
		return
	}
	writeLine("ACT", "%s.%s "+ctxFormat, append([]any{area, action}, a...)...)
}

// Enter / Exit bracket a flow so we can see what stalled. Prefer
// paired calls; a bare Enter without an Exit is a smell.
func Enter(area string, args ...any) { writeLine(">>>", "%s %s", area, joinArgs(args)) }
func Exit(area string, args ...any)  { writeLine("<<<", "%s %s", area, joinArgs(args)) }

func writeLine(level, format string, a ...any) {
	mu.Lock()
	defer mu.Unlock()
	if !active || lg == nil {
		return
	}
	msg := fmt.Sprintf(format, a...)
	lg.Printf("[%s] %s", level, msg)
}

func joinArgs(a []any) string {
	if len(a) == 0 {
		return ""
	}
	parts := make([]string, len(a))
	for i, v := range a {
		parts[i] = fmt.Sprint(v)
	}
	return strings.Join(parts, " ")
}

// Tail streams the log file into w, printing existing content then
// following new appends. Blocks until the file is removed or w
// returns an error. Used by `q log -f`.
func Tail(w io.Writer) error {
	p := Path()
	if p == "" {
		home, _ := os.UserHomeDir()
		p = filepath.Join(home, ".local", "share", "q", "debug.log")
	}
	f, err := os.Open(p)
	if err != nil {
		return err
	}
	defer f.Close()
	// Print existing content, then follow.
	if _, err := io.Copy(w, f); err != nil {
		return err
	}
	buf := make([]byte, 4096)
	for {
		n, err := f.Read(buf)
		if n > 0 {
			if _, werr := w.Write(buf[:n]); werr != nil {
				return werr
			}
		}
		if err == io.EOF {
			// Poll cheaply; anything faster is wasted CPU for a log.
			sleep200ms()
			continue
		}
		if err != nil {
			return err
		}
	}
}

// sleep200ms is factored out so tests can stub timing if we ever
// need to. Kept trivial for now.
func sleep200ms() {
	waitCh := make(chan struct{})
	go func() {
		timerSleep(200)
		close(waitCh)
	}()
	<-waitCh
}
