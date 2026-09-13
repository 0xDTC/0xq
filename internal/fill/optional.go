package fill

import (
	"strings"
)

// HasOptionalBlocks reports whether cmd contains any {{?TAG}}...{{/TAG}}.
func HasOptionalBlocks(cmd string) bool {
	return strings.Contains(cmd, "{{?") && strings.Contains(cmd, "{{/")
}

// OptionalBlock is one expandable segment discovered in a template.
type OptionalBlock struct {
	Tag     string // the NAME between {{? and }}
	Content string // what's between {{?TAG}} and {{/TAG}} (may contain placeholders)
	Full    string // the full {{?TAG}}...{{/TAG}} slice as it appeared
}

// FindOptionalBlocks returns every block in cmd in left-to-right
// order. Matching tags must exactly correspond ({{?output}}...{{/output}}).
// Nesting is not supported — an inner {{? ... }} inside another
// optional block is left for the outer expansion to consume.
func FindOptionalBlocks(cmd string) []OptionalBlock {
	var out []OptionalBlock
	i := 0
	for i < len(cmd) {
		start := strings.Index(cmd[i:], "{{?")
		if start < 0 {
			break
		}
		start += i
		// Find the closing }} of the opener.
		nameEnd := strings.Index(cmd[start+3:], "}}")
		if nameEnd < 0 {
			break
		}
		tag := cmd[start+3 : start+3+nameEnd]
		if tag == "" {
			i = start + 3
			continue
		}
		openLen := 3 + nameEnd + 2 // "{{?" + name + "}}"
		close := "{{/" + tag + "}}"
		closeAt := strings.Index(cmd[start+openLen:], close)
		if closeAt < 0 {
			// Malformed — skip past the opener and keep looking.
			i = start + openLen
			continue
		}
		absClose := start + openLen + closeAt
		content := cmd[start+openLen : absClose]
		full := cmd[start : absClose+len(close)]
		out = append(out, OptionalBlock{
			Tag:     tag,
			Content: content,
			Full:    full,
		})
		i = absClose + len(close)
	}
	return out
}

// PromptFunc is asked one yes/no question per block; returns true to
// include the block, false to drop it entirely.
type PromptFunc func(tag string) bool

// ProcessOptionalBlocks expands or drops every optional block in
// cmd according to ask. After expansion, runs of two-or-more spaces
// left by drops get collapsed to one. Whitespace surrounding the
// block that's dropped is trimmed too.
func ProcessOptionalBlocks(cmd string, ask PromptFunc) string {
	// Loop until no blocks remain — nested inner blocks that appear
	// inside a KEPT block get processed on the next iteration.
	for HasOptionalBlocks(cmd) {
		blocks := FindOptionalBlocks(cmd)
		if len(blocks) == 0 {
			break
		}
		// Process the first block only, then re-scan (so answers to
		// later blocks see the mutated cmd — matters when a kept
		// block contained nested blocks that then need prompting).
		b := blocks[0]
		var replacement string
		if ask(b.Tag) {
			replacement = b.Content
		} else {
			replacement = ""
		}
		cmd = strings.Replace(cmd, b.Full, replacement, 1)
	}
	// Collapse runs of spaces left by drops (but preserve newlines).
	for strings.Contains(cmd, "  ") {
		cmd = strings.ReplaceAll(cmd, "  ", " ")
	}
	return strings.TrimSpace(cmd)
}
