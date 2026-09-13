// Package tool extracts the primary binary name from a shell command
// line. The canonical port of q_extract_tool_binary from lib/core.sh.
//
// The rules match the bash implementation exactly:
//   - Skip leading env-var assignments (FOO=bar syntax)
//   - Skip `sudo` and its argument-consuming flags (-u USER, -g GROUP,
//     -C LEV, -D DIR)
//   - Skip any remaining short flags
//   - The first surviving token is the tool
//   - Strip its dirname, .exe suffix, .py suffix
package tool

import (
	"strings"
)

// argConsumingSudoFlags is the set of short sudo flags whose next
// token is an argument (not the binary). Kept small and explicit
// rather than parsing the full sudo(8) grammar.
var argConsumingSudoFlags = map[string]bool{
	"-u": true, // -u USER
	"-g": true, // -g GROUP
	"-C": true, // -C LEVEL
	"-D": true, // -D DIR
}

// isEnvAssignment reports whether tok is a shell env assignment
// (VAR=value with a valid identifier on the left of the first =).
func isEnvAssignment(tok string) bool {
	eq := strings.IndexByte(tok, '=')
	if eq <= 0 {
		return false
	}
	name := tok[:eq]
	for i, r := range name {
		if i == 0 {
			if !isIdentStart(r) {
				return false
			}
		} else if !isIdentPart(r) {
			return false
		}
	}
	return true
}

func isIdentStart(r rune) bool {
	return r == '_' || (r >= 'A' && r <= 'Z') || (r >= 'a' && r <= 'z')
}

func isIdentPart(r rune) bool {
	return isIdentStart(r) || (r >= '0' && r <= '9')
}

// Extract returns the primary binary name from cmd, or "" if none can
// be identified (empty input, only env assignments, only sudo, etc.).
func Extract(cmd string) string {
	words := strings.Fields(cmd)
	i := 0

	// Skip env assignments.
	for i < len(words) && isEnvAssignment(words[i]) {
		i++
	}

	// Skip sudo + its arg-consuming flags.
	if i < len(words) && words[i] == "sudo" {
		i++
		for i < len(words) && strings.HasPrefix(words[i], "-") {
			flag := words[i]
			i++
			if argConsumingSudoFlags[flag] && i < len(words) {
				i++
			}
		}
	}

	// Skip any remaining short flags before the tool.
	for i < len(words) && strings.HasPrefix(words[i], "-") {
		i++
	}

	if i >= len(words) {
		return ""
	}

	name := words[i]
	// Strip dirname.
	if idx := strings.LastIndexByte(name, '/'); idx >= 0 {
		name = name[idx+1:]
	}
	// Strip common suffixes.
	name = strings.TrimSuffix(name, ".exe")
	name = strings.TrimSuffix(name, ".py")
	return name
}
