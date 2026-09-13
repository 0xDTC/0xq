// Package config resolves the standard q directories and knobs.
// Ports the Q_* env dance from lib/core.sh.
package config

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Env captures the runtime environment: where q lives, where its
// data and cache go, and which knobs are set.
type Env struct {
	Root      string // holds cheatsheets/, lib/, cache/
	DataDir   string // $XDG_DATA_HOME/q or ~/.local/share/q
	CacheDir  string // $Q_CACHE_DIR or Root/cache
	SheetsDir string // Root/cheatsheets
	Config    map[string]string
}

// Load resolves paths (Q_ROOT auto-detect matches cmd/q/main.go),
// reads ~/.config/q/config.sh into the Config map. Missing config
// file is not an error — every key has a default at read time.
func Load() (*Env, error) {
	root, err := findRoot()
	if err != nil {
		return nil, err
	}
	dataDir := os.Getenv("Q_DATA_DIR")
	if dataDir == "" {
		xdg := os.Getenv("XDG_DATA_HOME")
		if xdg == "" {
			home, _ := os.UserHomeDir()
			xdg = filepath.Join(home, ".local", "share")
		}
		dataDir = filepath.Join(xdg, "q")
	}
	cacheDir := os.Getenv("Q_CACHE_DIR")
	if cacheDir == "" {
		cacheDir = filepath.Join(root, "cache")
	}
	sheetsDir := filepath.Join(root, "cheatsheets")

	env := &Env{
		Root:      root,
		DataDir:   dataDir,
		CacheDir:  cacheDir,
		SheetsDir: sheetsDir,
		Config:    map[string]string{},
	}
	// Ensure dirs.
	for _, d := range []string{dataDir, cacheDir, filepath.Join(dataDir, "sessions"), filepath.Join(dataDir, "combos"), filepath.Join(dataDir, "var_history")} {
		_ = os.MkdirAll(d, 0o755)
	}
	// Load config.sh — very small parser: KEY=value or export KEY=value.
	// Quotes stripped. Comments and blank lines skipped. Bash function
	// bodies etc. are simply ignored.
	home, _ := os.UserHomeDir()
	cfgFile := filepath.Join(home, ".config", "q", "config.sh")
	if f, err := os.Open(cfgFile); err == nil {
		defer f.Close()
		sc := bufio.NewScanner(f)
		for sc.Scan() {
			line := strings.TrimSpace(sc.Text())
			if line == "" || strings.HasPrefix(line, "#") {
				continue
			}
			line = strings.TrimPrefix(line, "export ")
			eq := strings.IndexByte(line, '=')
			if eq <= 0 {
				continue
			}
			k := strings.TrimSpace(line[:eq])
			v := strings.TrimSpace(line[eq+1:])
			v = strings.Trim(v, `"'`)
			env.Config[k] = v
		}
	}
	return env, nil
}

// Get returns the config value for key, falling back to env, then
// def. Order: env var → config.sh entry → default.
func (e *Env) Get(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	if v, ok := e.Config[key]; ok && v != "" {
		return v
	}
	return def
}

// SessionName returns Q_SESSION_NAME (or "default"), resolving from
// env → the persisted .active_session file → default.
func (e *Env) SessionName() string {
	if v := os.Getenv("Q_SESSION_NAME"); v != "" {
		return v
	}
	if v := os.Getenv("OXQ_SESSION"); v != "" {
		return v
	}
	// Persisted marker.
	if b, err := os.ReadFile(filepath.Join(e.DataDir, ".active_session")); err == nil {
		s := strings.TrimSpace(string(b))
		if s != "" {
			return s
		}
	}
	return "default"
}

// SessionDir returns the dir for the current session (created if needed).
func (e *Env) SessionDir() string {
	d := filepath.Join(e.DataDir, "sessions", e.SessionName())
	_ = os.MkdirAll(d, 0o755)
	return d
}

// IndexPath is Q_CACHE_DIR/index.tsv.
func (e *Env) IndexPath() string { return filepath.Join(e.CacheDir, "index.tsv") }

// findRoot mirrors cmd/q/main.go: Q_ROOT env → walk up from binary
// → CWD. Returns the first dir that contains cheatsheets/.
func findRoot() (string, error) {
	if r := os.Getenv("Q_ROOT"); r != "" {
		return r, nil
	}
	if exe, err := os.Executable(); err == nil {
		dir := filepath.Dir(exe)
		for i := 0; i < 5; i++ {
			if _, err := os.Stat(filepath.Join(dir, "cheatsheets")); err == nil {
				return dir, nil
			}
			dir = filepath.Dir(dir)
		}
	}
	if cwd, err := os.Getwd(); err == nil {
		if _, err := os.Stat(filepath.Join(cwd, "cheatsheets")); err == nil {
			return cwd, nil
		}
	}
	return "", fmt.Errorf("could not locate Q_ROOT (set env var to the dir holding cheatsheets/)")
}
