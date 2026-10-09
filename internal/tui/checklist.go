package tui

// Checklist is a multi-select screen for the {{NAME:multichoice:...}}
// placeholder type. All items start pre-checked (because the common
// case is "I want most of these, uncheck a few"). Keys:
//
//	space / x    toggle the highlighted item
//	a            check every visible item
//	n            uncheck every visible item
//	↑ ↓ / j k    move cursor
//	type …       filter by substring (across label + hint)
//	Enter        confirm — returns the final checked set
//	Esc          cancel — Result.Cancelled = true, CancelKey = "esc"
//	Ctrl+C       same as Esc but CancelKey = "ctrl+c" so the fill
//	             flow can tell "skip this placeholder" from "abort fill"

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
)

// ChecklistItem is one togglable row.
type ChecklistItem struct {
	Label   string // visible text
	Value   string // what gets returned when checked (defaults to Label)
	Hint    string // dim trailing text
	Checked bool   // initial + mutated state
}

// ChecklistOptions configures the picker.
type ChecklistOptions struct {
	Prompt string
	Header string
	Items  []ChecklistItem
}

// ChecklistResult is what ShowChecklist returns.
type ChecklistResult struct {
	Items     []ChecklistItem // final state after user confirmed
	Cancelled bool
	CancelKey string // "esc" or "ctrl+c"
}

// ShowChecklist runs the picker and blocks until Enter / Esc / Ctrl+C.
// Uses the same /dev/tty routing as Show so stdout stays clean for
// --inline widget consumers.
func ShowChecklist(opts ChecklistOptions) (*ChecklistResult, error) {
	tty, err := openTTY()
	if err != nil {
		return nil, fmt.Errorf("open /dev/tty: %w", err)
	}
	defer tty.Close()

	m := &checklistModel{opts: opts, items: append([]ChecklistItem(nil), opts.Items...)}
	m.recompute()
	prog := tea.NewProgram(m,
		tea.WithAltScreen(),
		tea.WithInput(tty),
		tea.WithOutput(tty),
	)
	out, err := prog.Run()
	if err != nil {
		return nil, err
	}
	fm := out.(*checklistModel)
	return &ChecklistResult{
		Items:     fm.items,
		Cancelled: fm.cancelled,
		CancelKey: fm.cancelKey,
	}, nil
}

type checklistModel struct {
	opts      ChecklistOptions
	items     []ChecklistItem
	query     string
	filtered  []int // indices into items that match current query
	cursor    int
	offset    int
	width     int
	height    int
	cancelled bool
	cancelKey string
}

func (m *checklistModel) Init() tea.Cmd { return nil }

func (m *checklistModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
	case tea.KeyMsg:
		switch msg.String() {
		case "esc":
			m.cancelled = true
			m.cancelKey = "esc"
			return m, tea.Quit
		case "ctrl+c":
			m.cancelled = true
			m.cancelKey = "ctrl+c"
			return m, tea.Quit
		case "enter":
			return m, tea.Quit
		case "up", "ctrl+k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "ctrl+j":
			if m.cursor < len(m.filtered)-1 {
				m.cursor++
			}
		case " ", "x":
			if m.cursor < len(m.filtered) {
				idx := m.filtered[m.cursor]
				m.items[idx].Checked = !m.items[idx].Checked
			}
		case "a":
			// bulk-check only if query empty — otherwise "a" is just
			// a typing character; this mirrors the picker's conv.
			if m.query == "" {
				for _, idx := range m.filtered {
					m.items[idx].Checked = true
				}
				return m, nil
			}
			m.query += "a"
			m.recompute()
		case "n":
			if m.query == "" {
				for _, idx := range m.filtered {
					m.items[idx].Checked = false
				}
				return m, nil
			}
			m.query += "n"
			m.recompute()
		case "backspace", "ctrl+h":
			if len(m.query) > 0 {
				m.query = m.query[:len(m.query)-1]
				m.recompute()
			}
		case "ctrl+u":
			m.query = ""
			m.recompute()
		default:
			if len(msg.Runes) > 0 {
				m.query += string(msg.Runes)
				m.recompute()
			}
		}
	}
	return m, nil
}

func (m *checklistModel) recompute() {
	m.filtered = m.filtered[:0]
	q := strings.ToLower(m.query)
	for i, it := range m.items {
		if q == "" || strings.Contains(strings.ToLower(it.Label+" "+it.Hint), q) {
			m.filtered = append(m.filtered, i)
		}
	}
	if m.cursor >= len(m.filtered) {
		m.cursor = len(m.filtered) - 1
	}
	if m.cursor < 0 {
		m.cursor = 0
	}
}

func (m *checklistModel) View() string {
	var b strings.Builder
	// Prompt + query.
	b.WriteString(promptStyle.Render(m.prompt()))
	b.WriteString(m.query)
	b.WriteString(cursorStyle.Render("▏"))
	b.WriteByte('\n')

	// Count line.
	checkedCount := 0
	for _, it := range m.items {
		if it.Checked {
			checkedCount++
		}
	}
	b.WriteString(dimStyle.Render(fmt.Sprintf("  %d checked  |  %d shown  /  %d total",
		checkedCount, len(m.filtered), len(m.items))))
	if m.opts.Header != "" {
		b.WriteString("  ")
		b.WriteString(headerStyle.Render(m.opts.Header))
	}
	b.WriteByte('\n')

	// List.
	listH := m.height - 4
	if listH < 8 {
		listH = 8
	}
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
		it := m.items[m.filtered[i]]
		cur := "  "
		if i == m.cursor {
			cur = cursorStyle.Render("▸ ")
		}
		box := dimStyle.Render("[ ]")
		if it.Checked {
			box = cursorStyle.Render("[x]")
		}
		line := cur + box + " " + it.Label
		if it.Hint != "" {
			line += "  " + dimStyle.Render(it.Hint)
		}
		b.WriteString(line)
		b.WriteByte('\n')
	}
	for i := end - m.offset; i < listH; i++ {
		b.WriteByte('\n')
	}
	b.WriteString(headerStyle.Render("space=toggle  a=check all  n=uncheck all  Enter=confirm  Esc=skip  Ctrl+C=abort"))
	return b.String()
}

func (m *checklistModel) prompt() string {
	if m.opts.Prompt != "" {
		return m.opts.Prompt
	}
	return "> "
}
