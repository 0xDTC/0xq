// Package tui — reusable fuzzy picker built on charmbracelet/bubbletea.
// Replaces the fzf subprocess wrapper. Single self-contained widget
// used by every interactive picker in q (main list, fill, builder,
// modify, chain, delete).
//
// Design goals:
//   - Zero runtime dependency on external tools (fzf, etc.)
//   - Generic over row payload — caller passes []Row where each Row
//     carries a display string, a hidden keyword string (for search
//     matching), a rank (lower sorts first), and an opaque payload
//     of type any that gets returned on selection.
//   - Multi-select via Tab, Ctrl-A / Ctrl-D bindings
//   - Optional custom keybinds so callers can hook Ctrl-B / Ctrl-M /
//     Ctrl-X / Ctrl-D without a helper-script + sideband dance.
package tui

import (
	"fmt"
	"sort"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/0xDTC/0xq/internal/qlog"
)

// Row is one entry in the picker.
type Row struct {
	// Display is the visible line rendered in the picker list. May
	// contain ANSI escape codes; they're passed through untouched.
	Display string
	// Search is what the fuzzy matcher scores against. Typically
	// display + a hidden keyword tail (category, phase, tags).
	// Not shown to the user.
	Search string
	// Rank is a stable sort key (lower first). Used for combos
	// (rank 0), MRU (rank 1..N), rest (rank max).
	Rank int
	// Payload is returned to the caller on selection. The caller
	// type-asserts back to their concrete type.
	Payload any
}

// KeyAction is a callback fired for a custom keybind. Receives the
// currently-highlighted Row (may be nil if the list is empty) and
// the current query. Return:
//   - accept=true to close the picker and return the selection as-is
//     (the caller decides what to do with the key + payload combo)
//   - accept=false to keep the picker open (the caller has already
//     side-effected: prompted for something, deleted a row, etc.);
//     the picker refreshes after the callback returns.
type KeyAction func(row *Row, query string) (accept bool, err error)

// Bind maps a key label (e.g. "ctrl+b") to a KeyAction. Bindings are
// consulted BEFORE the default handling so callers can override.
type Bind struct {
	Key    string    // bubbletea key spec — "ctrl+b", "alt+enter", etc.
	Label  string    // shown in the header
	Action KeyAction
}

// Options tune the picker.
type Options struct {
	Prompt       string
	Header       string
	Rows         []Row
	InitialQuery string
	Multi        bool
	Height       int  // list rows; 0 → autosize
	Binds        []Bind
	NoMarker     bool // set to true to hide the ⚙/★ MRU column

	// Preview, if non-nil, is called for the currently-highlighted row
	// every time the cursor moves. The returned string is rendered in
	// a bottom-split pane. Nil disables the preview and the list gets
	// the full terminal height.
	Preview func(row Row) string
	// PreviewRatio: fraction of terminal height allocated to the
	// preview (0.0-1.0). Default 0.4 when Preview is set.
	PreviewRatio float64
}

// Result is what Show returns.
type Result struct {
	// Selected is the highlighted row when Enter was pressed, or
	// the last row acted on via a Bind that returned accept=true.
	// Nil if the user cancelled (Esc) or the list was empty.
	Selected *Row
	// Multi holds every Tab-marked row when Options.Multi is true.
	// If the user hit Enter with nothing marked, Multi contains just
	// the highlighted row. Nil for non-multi pickers.
	Multi []Row
	// Query is the final typed query.
	Query string
	// FiredBind is the label of the custom bind that accepted (empty
	// if plain Enter closed the picker).
	FiredBind string
	// Cancelled reports whether Esc/Ctrl-C exited the picker.
	Cancelled bool
}

// Show runs the picker as a bubbletea program bound to /dev/tty for
// BOTH input and output. Critical for --inline mode: the shell
// widget captures q's stdout to slot the final command into BUFFER,
// so if bubbletea's alt-screen / cursor-hide / mouse-tracking
// escape sequences leak into stdout they end up as literal text in
// the user's shell (`zsh: substitution failed` etc.). Piping the
// UI through /dev/tty keeps stdout clean for the caller no matter
// how q was invoked.
func Show(opts Options) (*Result, error) {
	tty, err := openTTY()
	if err != nil {
		return nil, fmt.Errorf("open /dev/tty: %w", err)
	}
	defer tty.Close()

	m := initModel(opts)
	prog := tea.NewProgram(m,
		tea.WithAltScreen(),
		tea.WithMouseCellMotion(),
		tea.WithInput(tty),
		tea.WithOutput(tty),
	)
	out, err := prog.Run()
	if err != nil {
		return nil, err
	}
	final := out.(*model)
	return &final.result, nil
}

// ---------- bubbletea model ----------

type model struct {
	opts Options
	// query is stored as []rune so cursor math is per-character (not
	// per-byte) — a UTF-8 name shouldn't trap the cursor mid-codepoint.
	query    []rune
	qcur     int // cursor position within query (rune index)
	cursor   int // highlighted row index in filtered
	offset   int
	filtered []scored
	marked   map[int]bool // key: original Rows index
	width    int
	height   int
	result   Result
}

type scored struct {
	OrigIdx int
	Score   int
	Row     Row
}

func initModel(o Options) *model {
	m := &model{
		opts:   o,
		query:  []rune(o.InitialQuery),
		marked: map[int]bool{},
	}
	m.qcur = len(m.query)
	m.recompute()
	return m
}

func (m *model) Init() tea.Cmd { return nil }

func (m *model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		m.clampCursor()
	case tea.KeyMsg:
		key := msg.String()
		qlog.Action("picker", "key", "key=%q query=%q qcur=%d filtered=%d", key, string(m.query), m.qcur, len(m.filtered))
		// Custom binds first.
		for _, b := range m.opts.Binds {
			if key == b.Key {
				var row *Row
				if len(m.filtered) > 0 && m.cursor < len(m.filtered) {
					row = &m.filtered[m.cursor].Row
				}
				accept, _ := b.Action(row, string(m.query))
				if accept {
					m.result.Selected = row
					m.result.Query = string(m.query)
					m.result.FiredBind = b.Label
					return m, tea.Quit
				}
				m.recompute()
				return m, nil
			}
		}
		switch key {
		case "esc", "ctrl+c":
			m.result.Cancelled = true
			m.result.Query = string(m.query)
			return m, tea.Quit
		case "enter":
			if len(m.filtered) == 0 {
				// No matches — but the caller may want the typed
				// query as a custom value. Return it verbatim.
				m.result.Cancelled = true
				m.result.Query = string(m.query)
				return m, tea.Quit
			}
			m.result.Selected = &m.filtered[m.cursor].Row
			m.result.Query = string(m.query)
			if m.opts.Multi {
				m.result.Multi = m.collectMarked()
			}
			return m, tea.Quit

		// ── list navigation ───────────────────────────────────
		case "up", "ctrl+k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "ctrl+j":
			if m.cursor < len(m.filtered)-1 {
				m.cursor++
			}
		case "pgup":
			m.cursor -= 10
			if m.cursor < 0 {
				m.cursor = 0
			}
		case "pgdown":
			m.cursor += 10
			if m.cursor >= len(m.filtered) {
				m.cursor = len(m.filtered) - 1
			}

		// ── query cursor movement ─────────────────────────────
		// Home/End now move within the query (was: jump to first/
		// last row). Use PgUp/PgDn for that instead.
		case "left", "ctrl+b":
			if m.qcur > 0 {
				m.qcur--
			}
		case "right":
			// Ctrl+F is reserved for a caller bind (change-vars in the
			// main picker), so no ctrl+f alias here.
			if m.qcur < len(m.query) {
				m.qcur++
			}
		case "home", "ctrl+a":
			if m.opts.Multi {
				for _, s := range m.filtered {
					m.marked[s.OrigIdx] = true
				}
			} else {
				m.qcur = 0
			}
		case "end":
			m.qcur = len(m.query)

		// ── query editing ─────────────────────────────────────
		case "backspace", "ctrl+h":
			// Some terminals send Ctrl+H instead of the backspace
			// escape (readline's `stty erase` binding). Handle both.
			if m.qcur > 0 {
				m.query = append(m.query[:m.qcur-1], m.query[m.qcur:]...)
				m.qcur--
				m.recompute()
			}
		case "delete":
			// Forward-delete: nuke char UNDER the cursor.
			if m.qcur < len(m.query) {
				m.query = append(m.query[:m.qcur], m.query[m.qcur+1:]...)
				m.recompute()
			}
		case "ctrl+u":
			// kill-line-backward — matches readline / fzf convention.
			m.query = m.query[m.qcur:]
			m.qcur = 0
			m.recompute()
		case "alt+backspace", "alt+ctrl+h":
			// kill-word-backward: chop back through spaces then a run
			// of non-space characters. Two aliases because terminals
			// disagree on what to send for Alt+Backspace:
			//   - "alt+backspace" : gnome-terminal, kitty, wezterm, iTerm2
			//   - "alt+ctrl+h"    : xterm-family / kali default (Alt is the
			//                       meta-escape prefix, Backspace is Ctrl+H)
			// Ctrl+W deliberately left unbound for future custom shortcuts.
			end := m.qcur
			for m.qcur > 0 && m.query[m.qcur-1] == ' ' {
				m.qcur--
			}
			for m.qcur > 0 && m.query[m.qcur-1] != ' ' {
				m.qcur--
			}
			m.query = append(m.query[:m.qcur], m.query[end:]...)
			m.recompute()

		// ── multi-select controls (only when Options.Multi) ───
		case "tab":
			if m.opts.Multi && len(m.filtered) > 0 {
				idx := m.filtered[m.cursor].OrigIdx
				if m.marked[idx] {
					delete(m.marked, idx)
				} else {
					m.marked[idx] = true
				}
				if m.cursor < len(m.filtered)-1 {
					m.cursor++
				}
			}
		case "ctrl+d":
			if m.opts.Multi {
				m.marked = map[int]bool{}
			} else if m.qcur < len(m.query) {
				// Non-Multi picker: use Ctrl+D as an alternative to
				// Delete (some terminals never send Delete cleanly).
				m.query = append(m.query[:m.qcur], m.query[m.qcur+1:]...)
				m.recompute()
			}

		default:
			// Any printable rune → insert at cursor (was: append to end).
			if len(msg.Runes) > 0 {
				prefix := append([]rune{}, m.query[:m.qcur]...)
				suffix := append([]rune{}, m.query[m.qcur:]...)
				m.query = append(append(prefix, msg.Runes...), suffix...)
				m.qcur += len(msg.Runes)
				m.recompute()
			}
		}
	}
	return m, nil
}

// recompute filters + sorts rows against the current query.
// Rank + fuzzy score combine: rank 0 rows still lose to a strong
// fuzzy hit on a rank-999999 row when the user types something that
// only matches the low-rank row.
func (m *model) recompute() {
	q := string(m.query)
	m.filtered = m.filtered[:0]
	for i, r := range m.opts.Rows {
		sc := Score(r.Search, q)
		if sc == 0 {
			continue
		}
		m.filtered = append(m.filtered, scored{OrigIdx: i, Score: sc, Row: r})
	}
	sort.SliceStable(m.filtered, func(i, j int) bool {
		if q != "" {
			if m.filtered[i].Score != m.filtered[j].Score {
				return m.filtered[i].Score > m.filtered[j].Score
			}
		}
		return m.filtered[i].Row.Rank < m.filtered[j].Row.Rank
	})
	m.clampCursor()
}

func (m *model) clampCursor() {
	if m.cursor >= len(m.filtered) {
		m.cursor = len(m.filtered) - 1
	}
	if m.cursor < 0 {
		m.cursor = 0
	}
}

func (m *model) collectMarked() []Row {
	if len(m.marked) == 0 {
		if len(m.filtered) > 0 {
			return []Row{m.filtered[m.cursor].Row}
		}
		return nil
	}
	// Preserve original order.
	var out []Row
	for i, r := range m.opts.Rows {
		if m.marked[i] {
			out = append(out, r)
		}
	}
	return out
}

// ---------- rendering ----------

var (
	promptStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("6")).Bold(true)
	headerStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	cursorStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("5")).Bold(true)
	markStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("5"))
	dimStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
)

func (m *model) View() string {
	var b strings.Builder

	// Prompt line — render query with the cursor bar at the current
	// qcur position so left/right/home/end/delete have a visible
	// anchor, not just an invisible append point at the end.
	b.WriteString(promptStyle.Render(m.prompt()))
	if m.qcur < 0 {
		m.qcur = 0
	}
	if m.qcur > len(m.query) {
		m.qcur = len(m.query)
	}
	b.WriteString(string(m.query[:m.qcur]))
	b.WriteString(cursorStyle.Render("▏"))
	b.WriteString(string(m.query[m.qcur:]))
	b.WriteString("\n")

	// Count + header
	b.WriteString(dimStyle.Render(fmt.Sprintf("  %d/%d", len(m.filtered), len(m.opts.Rows))))
	if hdr := m.headerLine(); hdr != "" {
		b.WriteString("  ")
		b.WriteString(headerStyle.Render(hdr))
	}
	b.WriteString("\n")

	// Split total available rows between list and preview.
	//   totalH = terminal height - 3 (prompt, header, one trailing gap)
	//   previewH = totalH * PreviewRatio  (default 0.4 when Preview set)
	//   listH    = totalH - previewH - 1  (1 line for divider)
	totalH := m.height - 3
	if totalH < 8 {
		totalH = 8
	}
	listH := totalH
	previewH := 0
	if m.opts.Preview != nil {
		r := m.opts.PreviewRatio
		if r <= 0 || r >= 1 {
			r = 0.4
		}
		previewH = int(float64(totalH) * r)
		if previewH < 4 {
			previewH = 4
		}
		listH = totalH - previewH - 1 // divider line
		if listH < 4 {
			listH = 4
		}
	}
	if m.opts.Height > 0 && m.opts.Height < listH {
		listH = m.opts.Height
	}

	// Scroll offset so cursor stays visible.
	if m.cursor < m.offset {
		m.offset = m.cursor
	}
	if m.cursor >= m.offset+listH {
		m.offset = m.cursor - listH + 1
	}
	end := m.offset + listH
	if end > len(m.filtered) {
		end = len(m.filtered)
	}
	for i := m.offset; i < end; i++ {
		row := m.filtered[i]
		var prefix string
		if i == m.cursor {
			prefix = cursorStyle.Render("▸ ")
		} else {
			prefix = "  "
		}
		if m.opts.Multi {
			if m.marked[row.OrigIdx] {
				prefix = cursorStyle.Render("● ")
			} else {
				prefix = dimStyle.Render("○ ")
			}
		}
		b.WriteString(prefix)
		b.WriteString(row.Row.Display)
		b.WriteString("\n")
	}
	// Blank lines so the divider stays in the same spot regardless
	// of how many rows are visible.
	for i := end - m.offset; i < listH; i++ {
		b.WriteString("\n")
	}

	// Preview pane (when enabled).
	if m.opts.Preview != nil {
		// Divider
		divWidth := m.width
		if divWidth <= 0 {
			divWidth = 80
		}
		b.WriteString(dimStyle.Render(strings.Repeat("─", divWidth)))
		b.WriteString("\n")
		// Preview body — call the callback for the highlighted row.
		var preview string
		if len(m.filtered) > 0 && m.cursor < len(m.filtered) {
			preview = m.opts.Preview(m.filtered[m.cursor].Row)
		} else {
			preview = dimStyle.Render("(no selection)")
		}
		// Truncate preview to previewH lines so it doesn't push
		// the frame around.
		lines := strings.Split(preview, "\n")
		if len(lines) > previewH {
			lines = lines[:previewH]
		}
		for _, ln := range lines {
			b.WriteString(ln)
			b.WriteString("\n")
		}
		for i := len(lines); i < previewH; i++ {
			b.WriteString("\n")
		}
	}
	return b.String()
}

func (m *model) prompt() string {
	if m.opts.Prompt != "" {
		return m.opts.Prompt
	}
	return "> "
}

func (m *model) headerLine() string {
	if m.opts.Header != "" {
		return m.opts.Header
	}
	// Default header includes any registered custom binds so users see them.
	parts := []string{"Enter=run", "Esc=quit", "↑↓ = move"}
	if m.opts.Multi {
		parts = append(parts, "Tab=mark", "^A=all", "^D=clear")
	}
	for _, b := range m.opts.Binds {
		if b.Label != "" {
			parts = append(parts, b.Key+"="+b.Label)
		}
	}
	return strings.Join(parts, "  ")
}
