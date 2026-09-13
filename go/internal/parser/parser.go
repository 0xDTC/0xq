// Package parser walks cheatsheets/**/*.md and produces index.Entry
// rows. Ports the awk-based lib/parser.sh 1:1 in behaviour.
//
// Cheatsheet file structure (as authored via `q new`):
//
//	# tool-name                              ← H1 (tool)
//	<!-- tags: file,level,tags -->           ← file-level tags (optional)
//	<!-- platform: windows -->                ← file-level platform (optional)
//
//	## entry-title                            ← H2 (title, one per entry)
//	description prose (single line)
//
//	```bash
//	one or more command lines
//	```
//
//	<!-- meta: risk=safe | phase=recon | tags=... | platform=... -->
//
// Multi-line commands are flattened to one space-joined line. Choice
// placeholder OPTION VALUES ({{X:choice:opt1=desc1,opt2=desc2,...}})
// are extracted and appended to the tags column so `q regripper
// userassist` finds the plugin's parent command.
package parser

import (
	"bufio"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/0xDTC/0xq/go/internal/index"
)

// choicePlaceholderRe matches {{NAME:choice:opts}}. Non-greedy
// content match; opts may contain commas, colons, spaces.
var choicePlaceholderRe = regexp.MustCompile(`\{\{[A-Za-z_][A-Za-z0-9_]*:choice:[^}]+\}\}`)

// choicePrefixRe strips the leading `{{NAME:choice:` off a match.
var choicePrefixRe = regexp.MustCompile(`^\{\{[A-Za-z_][A-Za-z0-9_]*:choice:`)

// ParseFile parses one cheatsheet file into zero or more Entry rows.
// sheetsDir is the root under which category and source paths are
// computed (typically `Q_ROOT/cheatsheets`).
func ParseFile(path, sheetsDir string) ([]index.Entry, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	// Derive category (first path segment under sheetsDir) and source
	// (full path relative to sheetsDir).
	rel, err := filepath.Rel(sheetsDir, path)
	if err != nil {
		rel = path
	}
	source := filepath.ToSlash(rel)
	category := ""
	if i := strings.IndexByte(source, '/'); i >= 0 {
		category = source[:i]
	}

	var (
		out []index.Entry

		currentTool  string
		fileTags     string
		filePlatform string

		// Per-entry state — reset by every new H2.
		inEntry     bool
		inCodeBlock bool
		title       string
		description strings.Builder
		command     strings.Builder
		entryRisk   string
		entryPhase  string
		entryTags   string
		entryPlat   string
	)

	// Flush the current entry (if any) into out, then reset per-entry
	// state. Handles the "no entry started yet" case.
	flush := func() {
		if currentTool == "" || title == "" {
			return
		}
		desc := strings.TrimSpace(description.String())
		cmd := strings.TrimSpace(command.String())
		// Collapse internal tabs/newlines/runs of spaces.
		desc = normaliseWhitespace(desc)
		cmd = normaliseWhitespace(cmd)

		risk := entryRisk
		if risk == "" {
			risk = "low"
		}
		phase := entryPhase
		if phase == "" {
			phase = "misc"
		}
		// Platform precedence: entry > file > "any".
		platform := entryPlat
		if platform == "" {
			platform = filePlatform
		}
		if platform == "" {
			platform = "any"
		}

		// Merge tags: file + entry + extracted choice values.
		merged := mergeTags(fileTags, entryTags, extractChoiceValues(cmd))

		out = append(out, index.Entry{
			Category: category,
			Tool:     currentTool,
			Title:    title,
			Desc:     desc,
			Command:  cmd,
			Risk:     strings.ToLower(risk),
			Phase:    strings.ToLower(phase),
			Tags:     merged,
			Source:   source,
			Platform: strings.ToLower(platform),
		})
	}

	resetEntry := func() {
		title = ""
		description.Reset()
		command.Reset()
		entryRisk = ""
		entryPhase = ""
		entryTags = ""
		entryPlat = ""
		inCodeBlock = false
		inEntry = false
	}

	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 0, 64*1024), 4*1024*1024)
	for sc.Scan() {
		line := sc.Text()

		// File-level tags — before any H2.
		if !inEntry && strings.HasPrefix(strings.TrimSpace(line), "<!-- tags:") {
			fileTags = strings.TrimSpace(stripHTMLComment(line, "tags:"))
			fileTags = stripAllWhitespace(fileTags)
			continue
		}
		// File-level platform — before any H2.
		if !inEntry && strings.HasPrefix(strings.TrimSpace(line), "<!-- platform:") {
			filePlatform = strings.TrimSpace(stripHTMLComment(line, "platform:"))
			filePlatform = stripAllWhitespace(filePlatform)
			continue
		}
		// H1 — tool name (one per file, typically first content line).
		if strings.HasPrefix(line, "# ") && !strings.HasPrefix(line, "## ") {
			currentTool = strings.TrimSpace(strings.TrimPrefix(line, "# "))
			continue
		}
		// H2 — new entry. Flush prior, reset, capture title.
		if strings.HasPrefix(line, "## ") {
			flush()
			resetEntry()
			title = strings.TrimSpace(strings.TrimPrefix(line, "## "))
			inEntry = true
			continue
		}
		// Code fence open — accept ```bash (also naked ``` inside an entry).
		if strings.HasPrefix(line, "```bash") && inEntry {
			inCodeBlock = true
			continue
		}
		if strings.HasPrefix(line, "```") && inCodeBlock {
			inCodeBlock = false
			continue
		}
		// Inside code block — accumulate command.
		if inCodeBlock {
			if command.Len() > 0 {
				command.WriteByte(' ')
			}
			command.WriteString(line)
			continue
		}
		// Entry-level meta comment — parse key=value pairs.
		if inEntry && strings.HasPrefix(strings.TrimSpace(line), "<!-- meta:") {
			body := stripHTMLComment(line, "meta:")
			for _, pair := range strings.Split(body, "|") {
				pair = strings.TrimSpace(pair)
				eq := strings.IndexByte(pair, '=')
				if eq <= 0 {
					continue
				}
				k := strings.TrimSpace(pair[:eq])
				v := strings.TrimSpace(pair[eq+1:])
				switch k {
				case "risk":
					entryRisk = v
				case "phase":
					entryPhase = v
				case "tags":
					entryTags = v
				case "platform":
					entryPlat = v
				}
			}
			continue
		}
		// Description prose — everything else in entry, skip HR / blank / blockquote.
		if inEntry && !inCodeBlock {
			t := strings.TrimSpace(line)
			if t == "" || strings.HasPrefix(t, "---") || strings.HasPrefix(t, ">") {
				continue
			}
			if description.Len() > 0 {
				description.WriteByte(' ')
			}
			description.WriteString(t)
		}
	}
	flush()
	return out, sc.Err()
}

// WalkAndParse walks sheetsDir, parses every .md, returns the sorted
// concatenation. Skips nothing — external syncs used to land under
// external/ but that subsystem is retired.
func WalkAndParse(sheetsDir string) ([]index.Entry, error) {
	var files []string
	err := filepath.WalkDir(sheetsDir, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if strings.HasSuffix(path, ".md") {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	sort.Strings(files)
	var out []index.Entry
	for _, p := range files {
		entries, err := ParseFile(p, sheetsDir)
		if err != nil {
			return nil, err
		}
		out = append(out, entries...)
	}
	return out, nil
}

// ---------- helpers ----------

// stripHTMLComment removes the leading `<!-- KEY` and trailing `-->`
// wrappers, returning the inner body (trimmed).
func stripHTMLComment(line, key string) string {
	line = strings.TrimSpace(line)
	line = strings.TrimPrefix(line, "<!--")
	line = strings.TrimSuffix(line, "-->")
	line = strings.TrimSpace(line)
	line = strings.TrimPrefix(line, key)
	return strings.TrimSpace(line)
}

// stripAllWhitespace returns s without any spaces or tabs (used for
// tag lists so `foo, bar` becomes `foo,bar`).
func stripAllWhitespace(s string) string {
	var b strings.Builder
	b.Grow(len(s))
	for _, r := range s {
		if r == ' ' || r == '\t' || r == '\r' || r == '\n' {
			continue
		}
		b.WriteRune(r)
	}
	return b.String()
}

// normaliseWhitespace collapses tabs and newlines to spaces, then
// runs-of-spaces to a single space. Used to flatten multi-line cmds
// and multi-word descriptions into one clean field.
func normaliseWhitespace(s string) string {
	if s == "" {
		return s
	}
	// Replace tabs and newlines with spaces first, then collapse.
	s = strings.ReplaceAll(s, "\t", " ")
	s = strings.ReplaceAll(s, "\n", " ")
	// Collapse runs of spaces.
	for strings.Contains(s, "  ") {
		s = strings.ReplaceAll(s, "  ", " ")
	}
	return s
}

// mergeTags glues comma-separated tag lists (file + entry + choice
// values from command) into one comma-separated string, dropping
// empty pieces.
func mergeTags(parts ...string) string {
	var out []string
	for _, p := range parts {
		if p == "" {
			continue
		}
		out = append(out, p)
	}
	return strings.Join(out, ",")
}

// extractChoiceValues finds every {{NAME:choice:opt1=desc1,opt2=desc2}}
// in cmd and returns the option values (not descriptions) as a
// comma-separated string suitable for merging into tags.
func extractChoiceValues(cmd string) string {
	matches := choicePlaceholderRe.FindAllString(cmd, -1)
	if len(matches) == 0 {
		return ""
	}
	var vals []string
	for _, m := range matches {
		body := choicePrefixRe.ReplaceAllString(m, "")
		body = strings.TrimSuffix(body, "}}")
		for _, opt := range strings.Split(body, ",") {
			opt = strings.TrimSpace(opt)
			// Drop the =description if present; keep only the value.
			if eq := strings.IndexByte(opt, '='); eq >= 0 {
				opt = opt[:eq]
			}
			if opt != "" {
				vals = append(vals, opt)
			}
		}
	}
	return strings.Join(vals, ",")
}
