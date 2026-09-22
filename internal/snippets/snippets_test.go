package snippets

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestReverseShellsYAML loads the shipped reverse-shells.yaml and
// asserts one representative row round-trips through the parser.
// Points Q_ROOT at the repo root so snippetDirs finds
// builders/snippets/ regardless of the test binary's cwd (go test
// runs from the package dir).
func TestReverseShellsYAML(t *testing.T) {
	root, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("abs: %v", err)
	}
	t.Setenv("Q_ROOT", root)
	Reload()

	payload, ok := Get("rshell-bash-linux")
	if !ok {
		t.Fatalf("Get(rshell-bash-linux) returned false — check builders/snippets/reverse-shells.yaml")
	}
	if !strings.Contains(payload, "bash -c") {
		t.Fatalf("payload missing 'bash -c': %q", payload)
	}
	if !strings.Contains(payload, "{{LHOST}}") || !strings.Contains(payload, "{{LPORT}}") {
		t.Fatalf("payload missing {{LHOST}} / {{LPORT}} placeholders: %q", payload)
	}

	// Sanity — a couple more rows that exercise the quoting corners.
	if p, ok := Get("rshell-python3"); !ok || !strings.Contains(p, `s.connect(("{{LHOST}}",{{LPORT}}))`) {
		t.Fatalf("python3 payload malformed: %q", p)
	}
	if p, ok := Get("rshell-powershell-tcp"); !ok || !strings.HasPrefix(p, `powershell -nop -c "$c=`) {
		t.Fatalf("powershell payload malformed: %q", p)
	}

	// List should cover every entry from the shipped files.
	names := map[string]bool{}
	for _, s := range List() {
		names[s.Key] = true
		if s.Category == "" {
			t.Errorf("snippet %s has empty category", s.Key)
		}
	}
	for _, want := range []string{"rshell-bash-linux", "rshell-python3", "pty-python3", "pty-script"} {
		if !names[want] {
			t.Errorf("List() missing %s", want)
		}
	}
}

// TestUnknownKey — a missing key returns ("", false), no panic.
func TestUnknownKey(t *testing.T) {
	root, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("abs: %v", err)
	}
	t.Setenv("Q_ROOT", root)
	Reload()

	v, ok := Get("does-not-exist")
	if ok || v != "" {
		t.Fatalf("Get(unknown) = (%q,%v), want (\"\",false)", v, ok)
	}
}

// TestUserOverrideShadowsBuiltin writes a snippet with the same key
// as a shipped one into a temp XDG_CONFIG_HOME and verifies the
// override wins. Guards against a regression where load order got
// flipped.
func TestUserOverrideShadowsBuiltin(t *testing.T) {
	root, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("abs: %v", err)
	}
	tmp := t.TempDir()
	overrideDir := filepath.Join(tmp, ".config", "q", "snippets")
	if err := os.MkdirAll(overrideDir, 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	body := "category: user-test\nsnippets:\n  - {key: rshell-bash-linux, desc: \"user override\", payload: \"OVERRIDE\"}\n"
	if err := os.WriteFile(filepath.Join(overrideDir, "override.yaml"), []byte(body), 0o644); err != nil {
		t.Fatalf("write: %v", err)
	}
	t.Setenv("Q_ROOT", root)
	t.Setenv("HOME", tmp)
	Reload()

	got, ok := Get("rshell-bash-linux")
	if !ok {
		t.Fatalf("Get returned false after override")
	}
	if got != "OVERRIDE" {
		t.Fatalf("override lost — got %q, want OVERRIDE", got)
	}
}
