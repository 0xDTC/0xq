package tui

import (
	"testing"

	tea "github.com/charmbracelet/bubbletea"
)

// Enter with no matching rows AND a typed query must NOT set
// Cancelled — Enter is an explicit commit, not a cancel. The
// fill flow uses `res.Query` as the placeholder value in that
// case; marking it Cancelled made resolveOne discard the typed
// value and substitute empty, which (bug 2026-10-18) silently
// dropped the user's IP from the nmap chain.
func TestEnterEmptyFilteredWithQueryIsNotCancelled(t *testing.T) {
	m := initModel(Options{
		Rows: []Row{
			{Display: "foo", Search: "foo", Payload: "foo"},
			{Display: "bar", Search: "bar", Payload: "bar"},
		},
	})
	// Type a query that matches nothing.
	for _, r := range "zzz-no-match" {
		next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{r}})
		m = next.(*model)
	}
	if len(m.filtered) != 0 {
		t.Fatalf("expected 0 filtered rows, got %d", len(m.filtered))
	}
	// Press Enter.
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyEnter})
	m = next.(*model)

	if m.result.Cancelled {
		t.Fatalf("Enter with empty filtered + typed query must not set Cancelled")
	}
	if m.result.Query != "zzz-no-match" {
		t.Fatalf("Query not preserved: got %q, want %q", m.result.Query, "zzz-no-match")
	}
	if m.result.Selected != nil {
		t.Fatalf("Selected must stay nil when no row matched (got %+v)", m.result.Selected)
	}
}

// Esc remains a cancel — must set Cancelled regardless of typed query.
func TestEscIsCancel(t *testing.T) {
	m := initModel(Options{
		Rows: []Row{{Display: "foo", Search: "foo", Payload: "foo"}},
	})
	for _, r := range "something" {
		next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{r}})
		m = next.(*model)
	}
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyEsc})
	m = next.(*model)

	if !m.result.Cancelled {
		t.Fatalf("Esc must set Cancelled")
	}
	if m.result.CancelKey != "esc" {
		t.Fatalf("CancelKey = %q, want %q", m.result.CancelKey, "esc")
	}
}
