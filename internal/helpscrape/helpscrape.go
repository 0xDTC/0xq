// Package helpscrape parses a tool's `--help` output into a list of
// flags + short descriptions. Used by the fill package to power the
// `helpflags` placeholder type — a cheatsheet author writes
// `{{NAME:helpflags:tool}}` and, at run time, the user gets a picker
// of every flag the tool reports, with proper names and hints.
//
// Zero-config: tries `--help` then `-h` then `--help-all` until one
// yields a parseable list. Hard 2s timeout per invocation so a hung
// tool can't stall the picker. No caching — results are cheap enough
// (the fill flow only runs this on demand, per selected cheatsheet).
package helpscrape

import (
	"bufio"
	"bytes"
	"os/exec"
	"regexp"
	"strings"
	"time"
)

// Flag is one parsed row.
type Flag struct {
	Flag string // "-A", "--script"
	Arg  string // "SCRIPT", "" for boolean flags
	Desc string
}

// Scrape runs `tool --help` and returns its flag list. Empty slice
// when the tool isn't installed, times out, or emits nothing parseable.
// Never returns an error — a failed scrape is a "no flags found",
// not a program-level fault.
func Scrape(tool string) []Flag {
	if _, err := exec.LookPath(tool); err != nil {
		return nil
	}
	for _, args := range [][]string{{"--help"}, {"-h"}, {"--help-all"}} {
		out := runHelp(tool, args...)
		if strings.TrimSpace(out) == "" {
			continue
		}
		flags := parseOutput(out)
		if len(flags) > 0 {
			return flags
		}
	}
	return nil
}

func runHelp(tool string, args ...string) string {
	c := exec.Command(tool, args...)
	var buf bytes.Buffer
	c.Stdout = &buf
	c.Stderr = &buf
	if err := c.Start(); err != nil {
		return ""
	}
	done := make(chan error, 1)
	go func() { done <- c.Wait() }()
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		_ = c.Process.Kill()
	}
	return buf.String()
}

// Flag-line regex accepts three shapes so we don't miss flags whose
// description wraps to the next line:
//
//	-x, --long ARG   description         (desc same line, double-space)
//	--long=ARG       description         (desc same line, = separator)
//	-x                                   (desc on next line, indented)
//
// Groups: 1 = flag or "-x, --long", 2 = optional ARG token,
// 3 = optional description tail. When (3) is empty, a following
// continuation line (matched by reContLine) becomes the description.
var (
	reFlagLine = regexp.MustCompile(`^\s{1,10}(-{1,2}[A-Za-z][A-Za-z0-9\-]*(?:,\s*--[A-Za-z][A-Za-z0-9\-]*)?)(?:\s+([A-Z][A-Z0-9_<>]*))?(?:(?:\s{2,}|=)(.*))?$`)
	reContLine = regexp.MustCompile(`^\s{6,}(\S.*)$`)
)

func parseOutput(text string) []Flag {
	var out []Flag
	var last *Flag
	sc := bufio.NewScanner(strings.NewReader(text))
	sc.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	for sc.Scan() {
		line := strings.TrimRight(sc.Text(), " \t")
		if line == "" {
			last = nil
			continue
		}
		if m := reFlagLine.FindStringSubmatch(line); m != nil {
			flagPart := strings.TrimSpace(m[1])
			arg := ""
			if len(m) > 2 {
				arg = strings.TrimSpace(m[2])
			}
			desc := ""
			if len(m) > 3 {
				desc = strings.TrimSpace(m[3])
			}
			primary := flagPart
			if i := strings.Index(flagPart, ","); i > 0 {
				primary = strings.TrimSpace(flagPart[:i])
			}
			f := Flag{Flag: primary, Arg: strings.Trim(arg, "<>"), Desc: desc}
			out = append(out, f)
			last = &out[len(out)-1]
			continue
		}
		if last != nil {
			if m := reContLine.FindStringSubmatch(line); m != nil {
				if last.Desc == "" {
					last.Desc = strings.TrimSpace(m[1])
				} else {
					last.Desc += " " + strings.TrimSpace(m[1])
				}
			}
		}
	}
	return out
}
