// fuzzy scoring — subsequence-based, case-insensitive. Not fzf-perfect
// but competitive for our use: pentester types "userassist" or "nmap
// vuln" and expects those subsequences to bubble the right rows.
//
// Score composition (higher = better):
//   +100  contiguous match bonus (all query chars adjacent in target)
//   + 50  match at word boundary (space, /, -, _ before match position)
//   + 10  per matched character
//   -  2  per unmatched character between matches
//   -  1  per character of target before the first match
//
// Non-match → score 0, drop from results.
package tui

import "strings"

// Score returns a positive score if query matches target (case-
// insensitive), 0 otherwise. Prefers substring matches over
// subsequence, and matches at word boundaries over mid-word.
func Score(target, query string) int {
	if query == "" {
		return 1 // everything matches an empty query with the same weight
	}
	if target == "" {
		return 0
	}

	t := strings.ToLower(target)
	q := strings.ToLower(query)

	// Substring match wins big. Scan every occurrence — the highest-
	// scoring one (word-boundary + earliest position + short target)
	// beats a mid-word match elsewhere.
	best := 0
	for i := 0; i+len(q) <= len(t); i++ {
		if t[i:i+len(q)] == q {
			s := 200                    // substring base
			s += 10 * len(q)            // per matched char
			s -= i                      // prefer earlier position
			s -= (len(t) - len(q)) / 4  // prefer shorter targets
			if i == 0 {
				s += 100 // full prefix
			} else if isWordBoundary(t[i-1]) {
				s += 50 // starts at a word boundary
			}
			if s > best {
				best = s
			}
		}
	}
	if best > 0 {
		return best
	}

	// Subsequence fallback — greedy left-to-right walk. Score lower
	// than any substring match; captures loose typing like "regr plug"
	// hitting "regripper single plugin".
	var positions []int
	ti := 0
	for qi := 0; qi < len(q); qi++ {
		found := -1
		for ti < len(t) {
			if t[ti] == q[qi] {
				found = ti
				ti++
				break
			}
			ti++
		}
		if found < 0 {
			return 0
		}
		positions = append(positions, found)
	}

	// Base: 5 per matched char (< substring's 10).
	score := 5 * len(positions)
	score -= positions[0] // leading gap penalty
	contiguous := true
	for i := 1; i < len(positions); i++ {
		gap := positions[i] - positions[i-1] - 1
		if gap > 0 {
			contiguous = false
			score -= 2 * gap
		}
	}
	if contiguous {
		score += 20 // contiguous subsequence still < substring
	}
	if positions[0] == 0 {
		score += 30
	} else if isWordBoundary(t[positions[0]-1]) {
		score += 20
	}
	if score < 1 {
		return 1
	}
	return score
}

func isWordBoundary(b byte) bool {
	return b == ' ' || b == '/' || b == '-' || b == '_' || b == '.'
}
