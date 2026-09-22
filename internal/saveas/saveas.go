// Package saveas persists a filled command as a new cheatsheet entry
// so today's ad-hoc run becomes tomorrow's picker option.
//
// Every saved command lands in cheatsheets/saved/user-saved.md — one
// file, always the same location, so the user isn't forced to pick a
// category at save time. They can move entries later with `q edit` if
// they want richer organization.
package saveas

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// SavedFile returns the canonical path where new user-saved entries
// live. Path resolves relative to sheetsDir (the cheatsheets/ root).
// The parent directory is created if missing.
func SavedFile(sheetsDir string) string {
	return filepath.Join(sheetsDir, "saved", "user-saved.md")
}

// Append writes a new entry to the saved cheatsheet file.
//
//   - title: short, lowercase words — becomes the ## header.
//   - desc:  one-line description. Optional; falls back to a timestamp.
//   - cmd:   the assembled command to save (already-filled or template).
//
// If the file doesn't exist yet, it's created with the required
// header. Duplicate titles are avoided by appending "  #N" suffix.
// Returns the path written to so the caller can log it.
func Append(sheetsDir, title, desc, cmd string) (string, error) {
	title = strings.TrimSpace(title)
	if title == "" {
		return "", fmt.Errorf("title is required")
	}
	if cmd == "" {
		return "", fmt.Errorf("command is required")
	}
	if desc == "" {
		desc = "Saved via q on " + time.Now().Format("2006-01-02 15:04")
	}

	path := SavedFile(sheetsDir)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return "", err
	}

	// Ensure file exists with header. Create if missing.
	if _, err := os.Stat(path); os.IsNotExist(err) {
		if err := writeHeader(path); err != nil {
			return "", err
		}
	}

	// Dedupe title within the file.
	title, err := uniqueTitle(path, title)
	if err != nil {
		return "", err
	}

	// Append the new entry.
	f, err := os.OpenFile(path, os.O_APPEND|os.O_WRONLY, 0o644)
	if err != nil {
		return "", err
	}
	defer f.Close()

	entry := fmt.Sprintf(
		"\n## %s\n%s\n\n```bash\n%s\n```\n\n<!-- meta: risk=low | phase=custom | tags=saved,user -->\n\n---\n",
		title, desc, cmd,
	)
	if _, err := io.WriteString(f, entry); err != nil {
		return "", err
	}
	return path, nil
}

func writeHeader(path string) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	_, err = io.WriteString(f, `# Saved

> Commands you saved via ` + "`[s] Save-as`" + ` at the confirm prompt. Each entry gets a title you chose plus a stock ` + "`risk=low | phase=custom`" + ` meta line — edit with ` + "`q edit saved`" + ` to reorganize into other categories later.

<!-- tags: saved, custom, user -->

---
`)
	return err
}

// uniqueTitle scans path for existing "## <title>" headers and, if
// title collides, appends "  #2", "  #3" etc. until it's unique.
func uniqueTitle(path, title string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return title, err
	}
	defer f.Close()

	existing := map[string]bool{}
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if strings.HasPrefix(line, "## ") {
			existing[strings.TrimPrefix(line, "## ")] = true
		}
	}
	if err := sc.Err(); err != nil {
		return title, err
	}
	if !existing[title] {
		return title, nil
	}
	for i := 2; i < 100; i++ {
		cand := fmt.Sprintf("%s  #%d", title, i)
		if !existing[cand] {
			return cand, nil
		}
	}
	return title, nil // fallback — hopefully never hit 100 dupes
}
