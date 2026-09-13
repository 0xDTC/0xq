// Package combos captures placeholder-preserving TEMPLATES per tool
// so the picker can surface "your own most-used combos" alongside
// cheatsheet entries. Ports lib/combos.sh.
//
// On-disk: $DataDir/combos/<tool>.tsv — one line per unique template.
//
//	<count>\t<template>
//
// sorted by count desc.
package combos

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/0xDTC/0xq/go/internal/index"
	"github.com/0xDTC/0xq/go/internal/tool"
)

// Bump increments the hit count for template under its tool. Silent
// (nil error) for empty templates or utility commands like `q rebuild`.
func Bump(dataDir, template string) error {
	if template == "" {
		return nil
	}
	tname := tool.Extract(template)
	// Skip q's own utility commands and bare single-word "commands".
	if tname == "" || tname == "q" || !strings.Contains(template, " ") {
		return nil
	}
	template = normaliseWhitespace(template)

	dir := filepath.Join(dataDir, "combos")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	path := filepath.Join(dir, tname+".tsv")

	rows := readRows(path)
	found := false
	for i, r := range rows {
		if r.Template == template {
			rows[i].Count++
			found = true
			break
		}
	}
	if !found {
		rows = append(rows, row{Count: 1, Template: template})
	}
	sort.SliceStable(rows, func(i, j int) bool {
		if rows[i].Count != rows[j].Count {
			return rows[i].Count > rows[j].Count
		}
		return rows[i].Template < rows[j].Template
	})
	return writeRows(path, rows)
}

// EmitPickerRows returns virtual index.Entry rows for every stored
// combo across every tool file. Columns match parser output so they
// can be merged into the picker feed alongside cheatsheet rows.
func EmitPickerRows(dataDir string) []index.Entry {
	dir := filepath.Join(dataDir, "combos")
	dents, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	var out []index.Entry
	for _, d := range dents {
		name := d.Name()
		if !strings.HasSuffix(name, ".tsv") {
			continue
		}
		tname := strings.TrimSuffix(name, ".tsv")
		for _, r := range readRows(filepath.Join(dir, name)) {
			out = append(out, index.Entry{
				Category: "combo",
				Tool:     tname,
				Title:    fmt.Sprintf("combo (used %d×)", r.Count),
				Desc:     "",
				Command:  r.Template,
				Risk:     "low",
				Phase:    "combo",
				Tags:     "combo," + tname,
				Source:   "combo:" + name,
				Platform: "any",
			})
		}
	}
	return out
}

// List prints a human-readable dump of every combo (all tools if
// filter is empty). Writes to w.
func List(dataDir, filter string, w *os.File) {
	dir := filepath.Join(dataDir, "combos")
	dents, err := os.ReadDir(dir)
	if err != nil {
		fmt.Fprintln(w, "no combos captured yet.")
		return
	}
	any := false
	for _, d := range dents {
		name := d.Name()
		if !strings.HasSuffix(name, ".tsv") {
			continue
		}
		tname := strings.TrimSuffix(name, ".tsv")
		if filter != "" && filter != tname {
			continue
		}
		rows := readRows(filepath.Join(dir, name))
		if len(rows) == 0 {
			continue
		}
		fmt.Fprintln(w, tname)
		for _, r := range rows {
			fmt.Fprintf(w, "  %4d×  %s\n", r.Count, r.Template)
		}
		any = true
	}
	if !any {
		if filter != "" {
			fmt.Fprintf(w, "no combos for '%s' yet.\n", filter)
		} else {
			fmt.Fprintln(w, "no combos captured yet.")
		}
	}
}

// Forget removes template (or all templates when template == "") for
// the given tool.
func Forget(dataDir, tname, template string) error {
	path := filepath.Join(dataDir, "combos", tname+".tsv")
	if template == "" {
		return os.Remove(path)
	}
	rows := readRows(path)
	kept := rows[:0]
	for _, r := range rows {
		if r.Template == template {
			continue
		}
		kept = append(kept, r)
	}
	if len(kept) == 0 {
		return os.Remove(path)
	}
	return writeRows(path, kept)
}

// ---------- unexported helpers ----------

type row struct {
	Count    int
	Template string
}

func readRows(path string) []row {
	f, err := os.Open(path)
	if err != nil {
		return nil
	}
	defer f.Close()
	var out []row
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 0, 64*1024), 4*1024*1024)
	for sc.Scan() {
		line := sc.Text()
		tab := strings.IndexByte(line, '\t')
		if tab <= 0 {
			continue
		}
		var count int
		if _, err := fmt.Sscanf(line[:tab], "%d", &count); err != nil || count <= 0 {
			continue
		}
		out = append(out, row{Count: count, Template: line[tab+1:]})
	}
	return out
}

func writeRows(path string, rows []row) error {
	tmp := path + ".tmp"
	f, err := os.Create(tmp)
	if err != nil {
		return err
	}
	bw := bufio.NewWriter(f)
	for _, r := range rows {
		if _, err := fmt.Fprintf(bw, "%d\t%s\n", r.Count, r.Template); err != nil {
			f.Close()
			os.Remove(tmp)
			return err
		}
	}
	if err := bw.Flush(); err != nil {
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

func normaliseWhitespace(s string) string {
	if s == "" {
		return s
	}
	s = strings.ReplaceAll(s, "\t", " ")
	s = strings.ReplaceAll(s, "\n", " ")
	for strings.Contains(s, "  ") {
		s = strings.ReplaceAll(s, "  ", " ")
	}
	return strings.TrimSpace(s)
}
