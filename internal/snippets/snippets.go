// Package snippets loads a library of reusable payload snippets from
// builders/snippets/*.yaml. Cheatsheets reference snippets via
// {{NAME:snippet:<key>}} — the fill flow substitutes the payload
// text at run time, and any placeholders inside the payload (e.g.
// {{LHOST}}, {{LPORT}}) are picked up by the next fill pass.
//
// Two directories are scanned, in order:
//
//  1. <Q_ROOT>/builders/snippets/*.yaml   (shipped defaults)
//  2. ~/.config/q/snippets/*.yaml         (per-user overrides)
//
// User overrides win on key collision so operators can shadow a
// bundled snippet without editing the repo. Loading is lazy and
// cached — the first Get or List triggers a walk of both dirs, and
// subsequent calls hit the in-memory map.
//
// The YAML dialect accepted is a hand-rolled subset:
//
//	category: <bare or quoted string>
//	snippets:
//	  - {key: KEY, desc: "text", payload: "text"}
//	  - {key: KEY, desc: "text", payload: 'text'}
//
// Values can be bare (terminated by ',' or '}'), double-quoted with
// \" and \\ escapes, or single-quoted with '' as the literal-quote
// escape. Payloads containing '}' or ',' MUST be quoted. Block
// scalars (|, >) and nested structures are not supported — flow
// style keeps parsing predictable without a YAML dependency.
package snippets

import (
	"errors"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
)

// Snippet is one entry in the library. Category is inherited from
// the parent file's top-level `category:` key.
type Snippet struct {
	Key         string
	Category    string
	Description string
	Payload     string
}

var (
	loadOnce sync.Once
	byKey    map[string]Snippet
	sorted   []Snippet
)

// Get returns the payload text for the named snippet. Returns
// ("", false) if the key is unknown.
func Get(key string) (string, bool) {
	loadOnce.Do(loadAll)
	s, ok := byKey[key]
	if !ok {
		return "", false
	}
	return s.Payload, true
}

// List returns every loaded snippet, sorted by (category, key). The
// returned slice is a copy — callers cannot mutate the cache.
func List() []Snippet {
	loadOnce.Do(loadAll)
	out := make([]Snippet, len(sorted))
	copy(out, sorted)
	return out
}

// Reload drops the cache so the next Get / List re-reads from disk.
// Useful for tests and for a future `q rebuild` hook.
func Reload() {
	loadOnce = sync.Once{}
}

// ---------- loader ----------

func loadAll() {
	byKey = map[string]Snippet{}
	for _, dir := range snippetDirs() {
		files, _ := filepath.Glob(filepath.Join(dir, "*.yaml"))
		sort.Strings(files)
		for _, p := range files {
			_ = parseFile(p, byKey)
		}
	}
	sorted = make([]Snippet, 0, len(byKey))
	for _, s := range byKey {
		sorted = append(sorted, s)
	}
	sort.Slice(sorted, func(i, j int) bool {
		if sorted[i].Category != sorted[j].Category {
			return sorted[i].Category < sorted[j].Category
		}
		return sorted[i].Key < sorted[j].Key
	})
}

// snippetDirs returns the ordered list of dirs to scan for snippet
// YAML files. Built-ins come first; user overrides second so a later
// definition of the same key shadows the shipped one.
func snippetDirs() []string {
	var out []string
	if root := findRoot(); root != "" {
		out = append(out, filepath.Join(root, "builders", "snippets"))
	}
	if home, err := os.UserHomeDir(); err == nil {
		out = append(out, filepath.Join(home, ".config", "q", "snippets"))
	}
	return out
}

// findRoot mirrors internal/config.findRoot: Q_ROOT env → walk up
// from the running binary → CWD. Anchored on the builders/ directory
// rather than cheatsheets/ so snippet lookups still work when a user
// vendored the repo without cheatsheets.
func findRoot() string {
	if r := os.Getenv("Q_ROOT"); r != "" {
		return r
	}
	if exe, err := os.Executable(); err == nil {
		dir := filepath.Dir(exe)
		for i := 0; i < 5; i++ {
			if _, err := os.Stat(filepath.Join(dir, "builders")); err == nil {
				return dir
			}
			dir = filepath.Dir(dir)
		}
	}
	if cwd, err := os.Getwd(); err == nil {
		if _, err := os.Stat(filepath.Join(cwd, "builders")); err == nil {
			return cwd
		}
	}
	return ""
}

// parseFile reads one YAML file and merges every well-formed snippet
// into sink. Malformed entries are skipped silently — one broken row
// must not prevent the rest of the library from loading.
func parseFile(path string, sink map[string]Snippet) error {
	b, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	category := ""
	inSnippets := false
	for _, raw := range strings.Split(string(b), "\n") {
		line := strings.TrimRight(raw, "\r")
		trim := strings.TrimSpace(line)
		if trim == "" || strings.HasPrefix(trim, "#") {
			continue
		}
		// Top-level `category:` scalar.
		if !inSnippets && strings.HasPrefix(trim, "category:") {
			category = strings.TrimSpace(strings.TrimPrefix(trim, "category:"))
			category = strings.Trim(category, `"'`)
			continue
		}
		// Top-level `snippets:` sequence header.
		if !inSnippets && trim == "snippets:" {
			inSnippets = true
			continue
		}
		// List entry — `- {key: ..., desc: ..., payload: ...}`.
		if inSnippets && strings.HasPrefix(trim, "-") {
			body := strings.TrimSpace(trim[1:])
			if !strings.HasPrefix(body, "{") || !strings.HasSuffix(body, "}") {
				continue
			}
			m, err := parseFlowMap(body)
			if err != nil {
				continue
			}
			key := strings.TrimSpace(m["key"])
			if key == "" {
				continue
			}
			sink[key] = Snippet{
				Key:         key,
				Category:    category,
				Description: m["desc"],
				Payload:     m["payload"],
			}
		}
	}
	return nil
}

// parseFlowMap parses a YAML flow-style mapping `{k: v, k: v, ...}`
// into a plain map. Keys are bare identifiers; values can be bare,
// double-quoted (with \" and \\ escapes), or single-quoted (with ''
// as a literal-quote escape). Whitespace around keys and values is
// trimmed.
func parseFlowMap(s string) (map[string]string, error) {
	s = strings.TrimSpace(s)
	if !strings.HasPrefix(s, "{") || !strings.HasSuffix(s, "}") {
		return nil, errors.New("snippets: not a flow map")
	}
	inner := s[1 : len(s)-1]
	out := map[string]string{}
	i := 0
	for i < len(inner) {
		// Skip whitespace and separator commas.
		for i < len(inner) && (inner[i] == ' ' || inner[i] == '\t' || inner[i] == ',') {
			i++
		}
		if i >= len(inner) {
			break
		}
		// Read a bare key up to ':'.
		keyStart := i
		for i < len(inner) && inner[i] != ':' && inner[i] != ',' {
			i++
		}
		if i >= len(inner) || inner[i] != ':' {
			return nil, errors.New("snippets: missing ':' after key")
		}
		key := strings.TrimSpace(inner[keyStart:i])
		i++ // consume ':'
		// Skip whitespace between ':' and value.
		for i < len(inner) && (inner[i] == ' ' || inner[i] == '\t') {
			i++
		}
		if i >= len(inner) {
			out[key] = ""
			break
		}
		var (
			val string
			err error
		)
		switch inner[i] {
		case '"':
			val, i, err = readDoubleQuoted(inner, i)
		case '\'':
			val, i, err = readSingleQuoted(inner, i)
		default:
			val, i = readBare(inner, i)
		}
		if err != nil {
			return nil, err
		}
		out[key] = val
	}
	return out, nil
}

// readDoubleQuoted consumes s[i:] starting at an opening '"',
// returning the un-escaped string content plus the index after the
// closing '"'. Recognised escapes: \" → ", \\ → \, \n → LF, \t → TAB,
// \r → CR. Any other \X pair is dropped to just X (YAML behaviour).
func readDoubleQuoted(s string, i int) (string, int, error) {
	if i >= len(s) || s[i] != '"' {
		return "", i, errors.New("snippets: expected double quote")
	}
	i++
	var b strings.Builder
	for i < len(s) {
		c := s[i]
		if c == '\\' && i+1 < len(s) {
			switch s[i+1] {
			case '"':
				b.WriteByte('"')
			case '\\':
				b.WriteByte('\\')
			case 'n':
				b.WriteByte('\n')
			case 't':
				b.WriteByte('\t')
			case 'r':
				b.WriteByte('\r')
			default:
				b.WriteByte(s[i+1])
			}
			i += 2
			continue
		}
		if c == '"' {
			return b.String(), i + 1, nil
		}
		b.WriteByte(c)
		i++
	}
	return "", i, errors.New("snippets: unterminated double-quoted string")
}

// readSingleQuoted consumes s[i:] starting at an opening '\'',
// returning the string content plus the index after the closing
// '\''. The only escape recognised is '' → literal single quote
// (matches YAML single-quoted scalar rules).
func readSingleQuoted(s string, i int) (string, int, error) {
	if i >= len(s) || s[i] != '\'' {
		return "", i, errors.New("snippets: expected single quote")
	}
	i++
	var b strings.Builder
	for i < len(s) {
		c := s[i]
		if c == '\'' {
			if i+1 < len(s) && s[i+1] == '\'' {
				b.WriteByte('\'')
				i += 2
				continue
			}
			return b.String(), i + 1, nil
		}
		b.WriteByte(c)
		i++
	}
	return "", i, errors.New("snippets: unterminated single-quoted string")
}

// readBare consumes an unquoted value up to the next ',' or '}'
// (which mark end-of-value in a flow map). Trailing whitespace is
// trimmed. Bare values cannot contain ',' or '}' — quote them if
// they need to.
func readBare(s string, i int) (string, int) {
	start := i
	for i < len(s) && s[i] != ',' && s[i] != '}' {
		i++
	}
	return strings.TrimSpace(s[start:i]), i
}
