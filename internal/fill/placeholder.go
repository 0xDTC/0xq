// Package fill handles placeholder parsing, candidate building, and
// interactive substitution. Ports lib/variables.sh — the biggest
// piece of the bash tree (1100 lines) at ~40% the size in Go.
//
// Placeholder syntax accepted (matches the bash tree so cheatsheets
// port over unchanged):
//
//	{{NAME}}                    bare — type str, no default
//	{{NAME:type}}               type only
//	{{NAME:type:default}}       type + default (default may contain :)
//	{{NAME:choice:v1,v2,v3}}    enum
//	{{NAME:choice:v1=hint1,v2=hint2}}
//	                            enum with per-option descriptions
//	{{?TAG}}...{{/TAG}}         optional block (see optional.go)
package fill

import (
	"regexp"
	"strings"
)

// Placeholder is one occurrence of {{NAME:type:default}} in a command.
// A single NAME may appear more than once in the same command —
// callers typically dedupe by Name and prompt once.
type Placeholder struct {
	Name    string
	Type    string // str, choice, file, dir, wordlist, ip, url, domain, port, lport, payload, iface, etc.
	Default string // raw default string; for choice this is the comma-joined option list
	Raw     string // the full {{...}} token as it appeared in the command
}

// ChoiceOption represents one entry in a choice-typed default.
type ChoiceOption struct {
	Value string
	Hint  string
}

// Options parses the Default field of a Placeholder whose Type is
// "choice" or "enum". Returns the ordered option list. Options
// without a hint have Hint == "".
func (p Placeholder) Options() []ChoiceOption {
	if p.Default == "" {
		return nil
	}
	parts := strings.Split(p.Default, ",")
	out := make([]ChoiceOption, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		if eq := strings.IndexByte(part, '='); eq > 0 {
			out = append(out, ChoiceOption{
				Value: strings.TrimSpace(part[:eq]),
				Hint:  strings.TrimSpace(part[eq+1:]),
			})
		} else {
			out = append(out, ChoiceOption{Value: part})
		}
	}
	return out
}

// EffectiveDefault returns the auto-fill default for this placeholder.
// For choice types it's the first option (stripped of any =hint);
// otherwise it's the raw Default string.
func (p Placeholder) EffectiveDefault() string {
	if p.Type == "choice" || p.Type == "enum" {
		opts := p.Options()
		if len(opts) > 0 {
			return opts[0].Value
		}
		return ""
	}
	return p.Default
}

// placeholderRe matches a `{{NAME[:TYPE[:DEFAULT]]}}` token. Does
// NOT match the optional-block markers `{{?NAME}}` or `{{/NAME}}`
// (they don't have identifier-only inners).
var placeholderRe = regexp.MustCompile(`\{\{([^}?/][^}]*)\}\}`)

// Extract returns every placeholder in cmd, preserving order and
// duplicates. Optional-block markers ({{?TAG}}, {{/TAG}}) are
// skipped — they're handled by the optional.go pass.
func Extract(cmd string) []Placeholder {
	matches := placeholderRe.FindAllStringSubmatchIndex(cmd, -1)
	out := make([]Placeholder, 0, len(matches))
	for _, m := range matches {
		full := cmd[m[0]:m[1]]
		inner := cmd[m[2]:m[3]]
		// Split on first two colons; everything after the second is default.
		name, typ, def := parseInner(inner)
		out = append(out, Placeholder{
			Name:    name,
			Type:    typ,
			Default: def,
			Raw:     full,
		})
	}
	return out
}

// parseInner splits `NAME[:TYPE[:DEFAULT]]`. DEFAULT may contain any
// character including additional colons (e.g. Windows paths).
func parseInner(inner string) (name, typ, def string) {
	// First colon → name.
	c1 := strings.IndexByte(inner, ':')
	if c1 < 0 {
		return inner, "str", ""
	}
	name = inner[:c1]
	rest := inner[c1+1:]
	// Second colon → type.
	c2 := strings.IndexByte(rest, ':')
	if c2 < 0 {
		typ = rest
		if typ == "" {
			typ = "str"
		}
		return
	}
	typ = rest[:c2]
	if typ == "" {
		typ = "str"
	}
	def = rest[c2+1:]
	return
}

// UniqueNames returns the placeholders deduped by Name (order
// preserved). The first occurrence's Type/Default win — later
// duplicates are dropped.
func UniqueNames(phs []Placeholder) []Placeholder {
	seen := map[string]bool{}
	out := make([]Placeholder, 0, len(phs))
	for _, p := range phs {
		if seen[p.Name] {
			continue
		}
		seen[p.Name] = true
		out = append(out, p)
	}
	return out
}

// Substitute replaces every `{{NAME[:...]}}` for name in cmd with
// value. Pure string operations (no regex) so backslashes and & in
// the value survive intact.
func Substitute(cmd, name, value string) string {
	open := "{{" + name
	close := "}}"
	var b strings.Builder
	b.Grow(len(cmd))
	rest := cmd
	for {
		idx := strings.Index(rest, open)
		if idx < 0 {
			b.WriteString(rest)
			break
		}
		b.WriteString(rest[:idx])
		after := rest[idx+len(open):]
		// Next char must be `}` or `:` for this to be OUR placeholder
		// (not just a name prefix like NAMESPACE matching NAME).
		if len(after) == 0 || (after[0] != '}' && after[0] != ':') {
			b.WriteString(open)
			rest = after
			continue
		}
		// Skip up to and including the closing }}.
		end := strings.Index(after, close)
		if end < 0 {
			// Malformed — write out and stop.
			b.WriteString(open)
			b.WriteString(after)
			break
		}
		b.WriteString(value)
		rest = after[end+len(close):]
	}
	return b.String()
}
