// Package clip copies text to the system clipboard, cross-platform.
//
// Detection order (first hit wins):
//
//	Linux/BSD Wayland:  wl-copy
//	Linux/BSD X11:      xclip -selection clipboard (or xsel -bi)
//	macOS:              pbcopy
//	WSL:                clip.exe
//
// A missing clipboard tool is a soft failure — the caller gets a
// wrapped error naming what was missing so they can print an install
// hint and still print the text to stderr as a manual-copy fallback.
package clip

import (
	"fmt"
	"os/exec"
	"runtime"
)

// Copy writes s to the system clipboard. Returns an error naming the
// tool it tried when no clipboard mechanism is available.
func Copy(s string) error {
	tool, args := detect()
	if tool == "" {
		return fmt.Errorf("no clipboard tool found — install one of: %s", installHint())
	}
	c := exec.Command(tool, args...)
	stdin, err := c.StdinPipe()
	if err != nil {
		return fmt.Errorf("%s: stdin pipe: %w", tool, err)
	}
	if err := c.Start(); err != nil {
		return fmt.Errorf("%s: start: %w", tool, err)
	}
	if _, err := stdin.Write([]byte(s)); err != nil {
		_ = c.Process.Kill()
		return fmt.Errorf("%s: write: %w", tool, err)
	}
	if err := stdin.Close(); err != nil {
		return fmt.Errorf("%s: close: %w", tool, err)
	}
	if err := c.Wait(); err != nil {
		return fmt.Errorf("%s: wait: %w", tool, err)
	}
	return nil
}

// ToolName returns the clipboard binary that would be used, or ""
// if none is available. Useful for status/UX messages.
func ToolName() string {
	t, _ := detect()
	return t
}

// detect picks the first available clipboard binary + arg list.
func detect() (string, []string) {
	switch runtime.GOOS {
	case "darwin":
		if have("pbcopy") {
			return "pbcopy", nil
		}
	case "linux", "freebsd", "openbsd", "netbsd":
		// Wayland is preferred when running under it.
		if have("wl-copy") {
			return "wl-copy", nil
		}
		if have("xclip") {
			return "xclip", []string{"-selection", "clipboard"}
		}
		if have("xsel") {
			return "xsel", []string{"-bi"}
		}
		// WSL falls back to Windows clip.exe.
		if have("clip.exe") {
			return "clip.exe", nil
		}
	case "windows":
		if have("clip.exe") {
			return "clip.exe", nil
		}
		if have("clip") {
			return "clip", nil
		}
	}
	return "", nil
}

func have(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func installHint() string {
	switch runtime.GOOS {
	case "darwin":
		return "pbcopy (built into macOS — should already be present)"
	case "linux", "freebsd", "openbsd", "netbsd":
		return "wl-copy (wl-clipboard) | xclip | xsel"
	case "windows":
		return "clip.exe (built into Windows)"
	}
	return "wl-copy | xclip | xsel | pbcopy | clip.exe"
}
