// Package search runs the interactive picker (fzf as subprocess).
// Ports the display half of lib/search.sh — fill/build/modify/chain
// keybinds will land in follow-up commits as their supporting
// packages (variables/builder/executor) come online.
//
// Design: fzf is invoked with a pipe of pre-formatted rows on stdin.
// The user's selection comes back on stdout. Combo rows (⚙) and MRU
// (★) markers are baked into the display column at build time; fzf
// itself doesn't know about q's semantics.
package search

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"sort"
	"strings"

	"github.com/0xDTC/0xq/go/internal/index"
)

// Selection is what the picker returns.
type Selection struct {
	Entry       index.Entry
	Query       string // final typed query (from --print-query)
	Cancelled   bool
	SentinelCmd string // reserved for future keybind dispatches
}

// Options tune the picker.
type Options struct {
	InitialQuery string
	Height       string   // e.g. "80%" — fzf --height flag
	MRU          []string // titles, newest first — used for ★
	OSFilter     string   // "windows", "linux", "macos", or "" for all
	CombosFirst  bool     // if true, combo rows sort above everything
	Combos       []index.Entry
	Entries      []index.Entry
}

// Run displays the picker and returns the selection. Requires `fzf`
// on PATH. Terminal is claimed for the duration.
func Run(opts Options) (*Selection, error) {
	fzf, err := exec.LookPath("fzf")
	if err != nil {
		return nil, fmt.Errorf("fzf not found on PATH: %w", err)
	}

	// Rank each row. Lower rank sorts earlier via `sort -k1,1n`.
	// Combos (cat="combo") get rank 0 (top).
	// MRU cheatsheets get rank 1..N based on MRU position.
	// Everything else gets rank 999999.
	mruRank := map[string]int{}
	for i, t := range opts.MRU {
		if _, ok := mruRank[t]; !ok {
			mruRank[t] = i + 1
		}
	}

	type row struct {
		Rank    int
		Display string
		Entry   index.Entry
	}
	all := make([]row, 0, len(opts.Combos)+len(opts.Entries))
	for _, e := range opts.Combos {
		if !platformOK(e.Platform, opts.OSFilter) {
			continue
		}
		all = append(all, row{Rank: 0, Display: renderRow(e, "⚙"), Entry: e})
	}
	for _, e := range opts.Entries {
		if !platformOK(e.Platform, opts.OSFilter) {
			continue
		}
		mark := "  "
		rk := 999999
		if r, ok := mruRank[e.Title]; ok {
			mark = "★ "
			rk = r + 100
		}
		all = append(all, row{Rank: rk, Display: renderRow(e, mark), Entry: e})
	}
	sort.SliceStable(all, func(i, j int) bool {
		if all[i].Rank != all[j].Rank {
			return all[i].Rank < all[j].Rank
		}
		return false // preserve emission order
	})

	// Feed rows to fzf: display\tindex — the index (row number in the
	// sorted list) is what fzf echoes back so we can map to Entry.
	// Keywords go into a hidden 3rd field so --nth=1,3 can search them.
	var buf strings.Builder
	buf.Grow(4096)
	for i, r := range all {
		keywords := r.Entry.Category + " " + r.Entry.Phase + " " + strings.ReplaceAll(r.Entry.Tags, ",", " ")
		fmt.Fprintf(&buf, "%d\t%s\t%s\n", i, r.Display, keywords)
	}

	height := opts.Height
	if height == "" {
		height = "80%"
	}

	args := []string{
		"--ansi",
		"--print-query",
		"--prompt=q> ",
		"--header=★ recent  ⚙ combo  Enter run  Esc quit",
		"--delimiter=\t",
		"--with-nth=2",
		"--nth=2,3",
		"--tabstop=4",
		"--height=" + height,
		"--reverse",
		"--border",
		"--exit-0",
		"--no-multi",
		"--color=pointer:cyan,prompt:cyan,hl:yellow,hl+:yellow:bold",
	}
	if opts.InitialQuery != "" {
		args = append(args, "--query="+opts.InitialQuery)
	}

	cmd := exec.Command(fzf, args...)
	cmd.Stdin = strings.NewReader(buf.String())
	cmd.Stderr = os.Stderr
	var stdout strings.Builder
	cmd.Stdout = writerFunc(func(p []byte) (int, error) {
		stdout.Write(p)
		return len(p), nil
	})
	err = cmd.Run()

	// fzf exits 130 on user cancel (Esc/Ctrl-C). Not fatal.
	if err != nil {
		if ee, ok := err.(*exec.ExitError); ok && ee.ExitCode() == 130 {
			return &Selection{Cancelled: true}, nil
		}
		if ee, ok := err.(*exec.ExitError); ok && ee.ExitCode() == 1 {
			// Exit 1 = no match. Not fatal.
			return &Selection{Cancelled: true, Query: firstLine(stdout.String())}, nil
		}
		return nil, err
	}

	// --print-query output: line 1 = query, line 2 = selected row.
	out := stdout.String()
	nl := strings.IndexByte(out, '\n')
	if nl < 0 {
		return &Selection{Cancelled: true, Query: out}, nil
	}
	query := out[:nl]
	rest := strings.TrimRight(out[nl+1:], "\n")
	if rest == "" {
		return &Selection{Cancelled: true, Query: query}, nil
	}
	// rest is "idx\tdisplay\tkeywords"; grab the idx.
	tab := strings.IndexByte(rest, '\t')
	if tab < 0 {
		return &Selection{Cancelled: true, Query: query}, nil
	}
	var idx int
	if _, err := fmt.Sscanf(rest[:tab], "%d", &idx); err != nil || idx < 0 || idx >= len(all) {
		return &Selection{Cancelled: true, Query: query}, nil
	}
	return &Selection{
		Entry: all[idx].Entry,
		Query: query,
	}, nil
}

// renderRow builds the visible label: "MARK  TOOL │ TITLE │ DESC" with
// ANSI colours matching lib/search.sh's palette.
func renderRow(e index.Entry, mark string) string {
	const (
		cyan   = "\x1b[36m"
		bold   = "\x1b[1m"
		dim    = "\x1b[2m"
		magenta = "\x1b[35m"
		reset  = "\x1b[0m"
	)
	sep := dim + "│" + reset

	tool := pad(e.Tool, 22)
	title := pad(e.Title, 38)
	desc := e.Desc
	if desc == "" {
		desc = "(no description)"
	}
	return fmt.Sprintf("%s%s%s%s %s %s%s%s %s %s%s%s",
		magenta, mark, reset,
		cyan+tool+reset, sep,
		bold, title, reset, sep,
		dim, desc, reset)
}

func pad(s string, w int) string {
	if len(s) >= w {
		return s[:w]
	}
	return s + strings.Repeat(" ", w-len(s))
}

func platformOK(rowPlatform, filter string) bool {
	if filter == "" {
		return true
	}
	if rowPlatform == "" || rowPlatform == "any" {
		return true
	}
	return strings.EqualFold(rowPlatform, filter)
}

func firstLine(s string) string {
	if i := strings.IndexByte(s, '\n'); i >= 0 {
		return s[:i]
	}
	return s
}

// writerFunc adapts a function into io.Writer without pulling in
// bytes.Buffer for a trivial closure.
type writerFunc func([]byte) (int, error)

func (f writerFunc) Write(p []byte) (int, error) { return f(p) }

// Ensure the io.Writer interface stays live in case the compiler
// elides the check (kept for clarity).
var _ io.Writer = writerFunc(nil)
