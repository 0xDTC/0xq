package tui

import (
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"
)

// Replays the exact keystroke sequence from the 2026-10-18 bug
// report: operator paste-selected "10.129.177.117" into the TARGET
// placeholder prompt and pressed Enter. The picker then had to
// hand `Query = "10.129.177.117"` back to resolveOne so the fill
// flow could substitute it into all five {{TARGET:ip}} slots of
// the nmap chain.
//
// With the pre-fix picker, Enter on empty-filtered set Cancelled
// to true, resolveOne took the Esc = skip branch, and the IP was
// discarded. This test exercises the final assembled command the
// fill flow would produce after our fix — Cancelled stays false,
// Query carries the pasted IP, and Substitute fills every slot.
func TestNmapChainFillEndToEnd(t *testing.T) {
	// The nmap chain cheatsheet template, verbatim.
	template := `sudo nmap -p- --min-rate {{RATE_FAST:int:1500}} -T4 -v -Pn ` +
		`{{TARGET:ip}} -oG /tmp/q-tcp-{{TARGET:ip}}.gnmap && sudo nmap -A -sS -sV -v ` +
		`-p "$(grep -oE '[0-9]+/open/tcp' /tmp/q-tcp-{{TARGET:ip}}.gnmap | cut -d/ -f1 ` +
		`| paste -sd,)" --max-rate {{RATE_SLOW:int:1000}} {{TARGET:ip}} -oN {{TARGET:ip}}.md`

	// resolveOne would build a rows list from candidates (recent
	// values, session targets, defaults). None of those match a
	// fresh IP, so the picker opens with every row visible but
	// typing a new IP filters them all out.
	m := initModel(Options{
		Rows: []Row{
			{Display: "10.10.11.42 (recent)", Search: "10.10.11.42", Payload: "10.10.11.42"},
			{Display: "10.10.14.1  (LHOST)", Search: "10.10.14.1", Payload: "10.10.14.1"},
		},
	})
	// Operator pastes "10.129.177.117". bubbletea reports a paste
	// as a single KeyRunes message carrying the whole payload.
	paste := "10.129.177.117"
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune(paste)})
	m = next.(*model)

	if len(m.filtered) != 0 {
		t.Fatalf("expected the paste to filter rows to zero (nothing matches a fresh IP), got %d rows", len(m.filtered))
	}

	// Operator hits Enter.
	next, _ = m.Update(tea.KeyMsg{Type: tea.KeyEnter})
	m = next.(*model)

	// Pre-fix: this was Cancelled=true, so resolveOne discarded
	// the typed value. Post-fix: Cancelled stays false and
	// resolveOne reads res.Query as the verbatim typed value.
	if m.result.Cancelled {
		t.Fatalf("regression: Enter on empty-filtered must not set Cancelled")
	}
	if m.result.Selected != nil {
		t.Fatalf("Selected must stay nil — no row was chosen (got %+v)", m.result.Selected)
	}
	if m.result.Query != paste {
		t.Fatalf("Query = %q, want %q", m.result.Query, paste)
	}

	// Reproduce the final fill-flow substitution. The fill package
	// is internal to this one in intent (same operator-facing
	// pipeline), but to avoid an import cycle this test does the
	// substitution directly — identical algorithm, lifted inline.
	filled := substituteAll(template, map[string]string{
		"TARGET":    m.result.Query,
		"RATE_FAST": "1500",
		"RATE_SLOW": "1000",
	})

	// Every {{TARGET:ip}} must be filled with the pasted IP.
	if strings.Contains(filled, "{{") {
		t.Fatalf("placeholder left unsubstituted:\n%s", filled)
	}
	wantOccurrences := 5 // five {{TARGET:ip}} slots in the chain
	if n := strings.Count(filled, paste); n != wantOccurrences {
		t.Fatalf("TARGET substituted %d times, want %d\n%s", n, wantOccurrences, filled)
	}
	// Spot-check the specific positions that were empty in the bug.
	for _, want := range []string{
		"-Pn " + paste + " -oG",
		"/tmp/q-tcp-" + paste + ".gnmap",
		"--max-rate 1000 " + paste + " -oN",
		paste + ".md",
	} {
		if !strings.Contains(filled, want) {
			t.Errorf("missing %q in filled command:\n%s", want, filled)
		}
	}
}

// substituteAll is a local copy of fill.Substitute's semantics
// so this test can live in the tui package without pulling in
// the fill package (which depends on tui, creating a cycle).
// Mirrors the behaviour verified by fill's own unit tests.
func substituteAll(cmd string, vars map[string]string) string {
	for name, val := range vars {
		open := "{{" + name
		var b strings.Builder
		rest := cmd
		for {
			i := strings.Index(rest, open)
			if i < 0 {
				b.WriteString(rest)
				break
			}
			b.WriteString(rest[:i])
			after := rest[i+len(open):]
			if len(after) == 0 || (after[0] != '}' && after[0] != ':') {
				b.WriteString(open)
				rest = after
				continue
			}
			end := strings.Index(after, "}}")
			if end < 0 {
				b.WriteString(open)
				b.WriteString(after)
				break
			}
			b.WriteString(val)
			rest = after[end+2:]
		}
		cmd = b.String()
	}
	return cmd
}
