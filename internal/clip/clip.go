// Package clip copies text to the system clipboard, cross-platform,
// with an OSC52 fallback so remote-over-SSH-inside-tmux still works.
//
// Detection order (first success wins):
//
//	1. Q_CLIP=osc52          → force OSC52 (skip local tools)
//	2. Q_CLIP=<tool>         → force a specific local tool
//	3. Local clipboard tool  → wl-copy / xclip / xsel / pbcopy / clip.exe
//	4. OSC52 escape          → written to /dev/tty; tmux / kitty /
//	                           wezterm / iTerm2 / Alacritty forward
//	                           it to the local system clipboard as
//	                           long as the terminal's clipboard-write
//	                           permission is set (tmux: `set -g
//	                           set-clipboard on`).
//
// A hard failure (no local tool AND no /dev/tty for OSC52) returns
// an error naming what was tried so the caller can print an install
// hint and still show the text on stderr for manual copy.
package clip

import (
	"encoding/base64"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

// Copy writes s to the system clipboard. On success returns nil; on
// failure returns an error describing what was tried. Callers should
// print s to stderr as a manual-copy fallback when this returns err.
func Copy(s string) error {
	forced := strings.ToLower(strings.TrimSpace(os.Getenv("Q_CLIP")))

	// Explicit override wins.
	if forced == "osc52" {
		return copyOSC52(s)
	}
	if forced != "" && forced != "auto" {
		return copyLocal(forced, forcedArgs(forced), s)
	}

	// Auto: try local tool first, OSC52 fallback.
	if tool, args := detect(); tool != "" {
		if err := copyLocal(tool, args, s); err == nil {
			return nil
		}
		// Local tool errored (X server down? xclip crashed?) — fall
		// through to OSC52 so the user isn't stuck.
	}
	return copyOSC52(s)
}

// ToolName returns which mechanism Copy would use next, for UX/status.
// Format: local tool name (e.g. "xclip"), "osc52" for the escape-code
// fallback, or "" if forced-off.
func ToolName() string {
	forced := strings.ToLower(strings.TrimSpace(os.Getenv("Q_CLIP")))
	if forced == "osc52" {
		return "osc52"
	}
	if forced != "" && forced != "auto" {
		return forced
	}
	if t, _ := detect(); t != "" {
		return t
	}
	return "osc52"
}

// --- local-tool path ------------------------------------------------

// copyLocal runs an external clipboard binary with args, feeding s
// through its stdin. Small, focused, no goroutines.
func copyLocal(tool string, args []string, s string) error {
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

// forcedArgs returns the default arg list for a tool named via Q_CLIP.
// Falls back to no-args for anything not in the built-in table.
func forcedArgs(tool string) []string {
	switch tool {
	case "xclip":
		return []string{"-selection", "clipboard"}
	case "xsel":
		return []string{"-bi"}
	}
	return nil
}

// --- OSC52 path -----------------------------------------------------

// copyOSC52 writes an OSC52 escape sequence to /dev/tty carrying the
// base64-encoded clipboard content. tmux + modern terminal emulators
// (kitty, wezterm, iTerm2, Alacritty, foot, ghostty, Windows Terminal)
// intercept this and put the payload into the local system clipboard,
// which is what makes copy work over SSH-into-a-remote inside tmux.
//
// tmux passthrough requires `set -g set-clipboard on` in ~/.tmux.conf
// (this has been the default since tmux 3.2, so most users have it).
// Payload size: OSC52 payload is base64, ~4/3 of the source. Terminals
// vary in their max — most accept ≥ 100 KiB base64 (~75 KiB raw),
// which is far more than any assembled q command will ever be.
func copyOSC52(s string) error {
	f, err := os.OpenFile("/dev/tty", os.O_WRONLY, 0)
	if err != nil {
		return fmt.Errorf("osc52: /dev/tty: %w", err)
	}
	defer f.Close()

	enc := base64.StdEncoding.EncodeToString([]byte(s))

	// When running inside tmux, wrap the escape in tmux's DCS
	// passthrough (`\x1bPtmux;\x1b<original>\x1b\\`) so tmux forwards
	// it rather than swallowing it. Detect via TMUX env.
	var seq string
	if os.Getenv("TMUX") != "" {
		// Escape any ESC inside the payload — none in OSC52 body,
		// but the wrapping trailer includes ESC that tmux consumes.
		seq = "\x1bPtmux;\x1b\x1b]52;c;" + enc + "\x07\x1b\\"
	} else {
		seq = "\x1b]52;c;" + enc + "\x07"
	}
	if _, err := f.WriteString(seq); err != nil {
		return fmt.Errorf("osc52: write /dev/tty: %w", err)
	}
	return nil
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

