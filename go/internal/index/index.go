// Package index reads and writes cache/index.tsv — the primary
// searchable command table produced by the parser.
//
// Column layout matches the bash tree (lib/parser.sh):
//
//	1 CATEGORY   subdirectory under cheatsheets/
//	2 TOOL       H1 heading
//	3 TITLE      H2 heading
//	4 DESC       prose between H2 and the ```bash block
//	5 COMMAND    command (multi-line flattened to space-joined)
//	6 RISK       safe|low|med|high|critical
//	7 PHASE      recon|enum|exploit|post|dfir|misc|...
//	8 TAGS       merged file+entry tags, comma-separated
//	9 SOURCE     path relative to cheatsheets/
//	10 PLATFORM  any|windows|linux|macos
package index

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strings"
)

// Entry is one row of index.tsv.
type Entry struct {
	Category string
	Tool     string
	Title    string
	Desc     string
	Command  string
	Risk     string
	Phase    string
	Tags     string // comma-joined
	Source   string // path relative to cheatsheets/
	Platform string
}

// Columns is the number of fields in the on-disk row.
const Columns = 10

// UnmarshalRow parses one TSV line into an Entry.
// Malformed rows (fewer than Columns fields) get default-filled.
func UnmarshalRow(line string) Entry {
	f := strings.SplitN(line, "\t", Columns)
	get := func(i int) string {
		if i < len(f) {
			return f[i]
		}
		return ""
	}
	return Entry{
		Category: get(0),
		Tool:     get(1),
		Title:    get(2),
		Desc:     get(3),
		Command:  get(4),
		Risk:     get(5),
		Phase:    get(6),
		Tags:     get(7),
		Source:   get(8),
		Platform: get(9),
	}
}

// MarshalRow renders an Entry as one TSV line (no trailing newline).
func (e Entry) MarshalRow() string {
	return strings.Join([]string{
		e.Category, e.Tool, e.Title, e.Desc, e.Command,
		e.Risk, e.Phase, e.Tags, e.Source, e.Platform,
	}, "\t")
}

// Read parses every row from r into a slice.
func Read(r io.Reader) ([]Entry, error) {
	var out []Entry
	sc := bufio.NewScanner(r)
	// Long placeholder lists (choice with many options) can exceed the
	// default 64 KB scanner buffer.
	sc.Buffer(make([]byte, 0, 64*1024), 4*1024*1024)
	for sc.Scan() {
		line := sc.Text()
		if line == "" {
			continue
		}
		out = append(out, UnmarshalRow(line))
	}
	return out, sc.Err()
}

// ReadFile reads the entire index from path.
func ReadFile(path string) ([]Entry, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("open %s: %w", path, err)
	}
	defer f.Close()
	return Read(f)
}

// Write emits entries as TSV lines to w, one per line.
func Write(w io.Writer, entries []Entry) error {
	bw := bufio.NewWriter(w)
	for _, e := range entries {
		if _, err := bw.WriteString(e.MarshalRow()); err != nil {
			return err
		}
		if err := bw.WriteByte('\n'); err != nil {
			return err
		}
	}
	return bw.Flush()
}

// WriteFile writes entries atomically to path (write to .tmp, rename).
func WriteFile(path string, entries []Entry) error {
	tmp := path + ".tmp"
	f, err := os.Create(tmp)
	if err != nil {
		return err
	}
	if err := Write(f, entries); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err := f.Close(); err != nil {
		os.Remove(tmp)
		return err
	}
	return os.Rename(tmp, path)
}
