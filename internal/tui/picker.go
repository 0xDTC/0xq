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
	Height       int    // list rows; 0 → autosize
	Binds        []Bind
	NoMarker     bool  // set to true to hide the ⚙/★ MRU column
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
	opts     Options
	query    string
	cursor   int
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
		query:  o.InitialQuery,
		marked: map[int]bool{},
	}
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
		// Custom binds first.
		for _, b := range m.opts.Binds {
			if msg.String() == b.Key {
				var row *Row
				if len(m.filtered) > 0 && m.cursor < len(m.filtered) {
					row = &m.filtered[m.cursor].Row
				}
				accept, _ := b.Action(row, m.query)
				if accept {
					m.result.Selected = row
					m.result.Query = m.query
					m.result.FiredBind = b.Label
					return m, tea.Quit
				}
				m.recompute()
				return m, nil
			}
		}
		switch msg.String() {
		case "esc", "ctrl+c":
			m.result.Cancelled = true
			m.result.Query = m.query
			return m, tea.Quit
		case "enter":
			if len(m.filtered) == 0 {
				m.result.Cancelled = true
				m.result.Query = m.query
				return m, tea.Quit
			}
			m.result.Selected = &m.filtered[m.cursor].Row
			m.result.Query = m.query
			if m.opts.Multi {
				m.result.Multi = m.collectMarked()
			}
			return m, tea.Quit
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
		case "home":
			m.cursor = 0
		case "end":
			m.cursor = len(m.filtered) - 1
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
		case "ctrl+a":
			if m.opts.Multi {
				for _, s := range m.filtered {
					m.marked[s.OrigIdx] = true
				}
			}
		case "ctrl+d":
			if m.opts.Multi {
				m.marked = map[int]bool{}
			}
		case "backspace":
			if len(m.query) > 0 {
				m.query = m.query[:len(m.query)-1]
				m.recompute()
			}
		case "ctrl+u":
			m.query = ""
			m.recompute()
		default:
			// Type-to-filter (printable characters).
			if len(msg.Runes) > 0 {
				m.query += string(msg.Runes)
				m.recompute()
			}
		}
	}
	return m, nil
}

// recompute filters + sorts rows against the current query.
// Rank + fuzzy score are combined: rank 0 rows (combos) still lose
// to a strong fuzzy hit on a rank-999999 row when the user types
// something that only matches the low-rank row.
func (m *model) recompute() {
	m.filtered = m.filtered[:0]
	for i, r := range m.opts.Rows {
		sc := Score(r.Search, m.query)
		if sc == 0 {
			continue
		}
		m.filtered = append(m.filtered, scored{OrigIdx: i, Score: sc, Row: r})
	}
	sort.SliceStable(m.filtered, func(i, j int) bool {
		// If a query is active, prefer higher score.
		if m.query != "" {
			if m.filtered[i].Score != m.filtered[j].Score {
				return m.filtered[i].Score > m.filtered[j].Score
			}
		}
		// Otherwise (or ties): prefer lower rank.
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

	// Prompt line
	b.WriteString(promptStyle.Render(m.prompt()))
	b.WriteString(m.query)
	b.WriteString(cursorStyle.Render("▏"))
	b.WriteString("\n")

	// Count + header
	b.WriteString(dimStyle.Render(fmt.Sprintf("  %d/%d", len(m.filtered), len(m.opts.Rows))))
	if hdr := m.headerLine(); hdr != "" {
		b.WriteString("  ")
		b.WriteString(headerStyle.Render(hdr))
	}
	b.WriteString("\n")

	// List — sized to fit remaining terminal rows.
	listH := m.opts.Height
	if listH <= 0 {
		listH = m.height - 3
		if listH < 8 {
			listH = 8
		}
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
				prefix = dimStyle.Render("○ ") + prefix[len(prefix)-2:]
				prefix = prefix[:len(prefix)/2] // keep alignment
			}
		}
		b.WriteString(prefix)
		b.WriteString(row.Row.Display)
		b.WriteString("\n")
	}
	// Blank lines to fill for stable frame.
	for i := end - m.offset; i < listH; i++ {
		b.WriteString("\n")
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
