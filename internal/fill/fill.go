package fill

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/0xDTC/0xq/internal/session"
	"github.com/0xDTC/0xq/internal/snippets"
	"github.com/0xDTC/0xq/internal/tui"
)

// State is the run-time context for a fill session. Bundles the
// session-vars store, per-var recent-value history, and the transient
// picks made during THIS fill run so a var referenced twice only
// prompts once.
type State struct {
	Sess       *session.Session
	VarHistory string                       // dir for per-name value history TSVs
	Detectors  map[string]func() []string // name → auto-detect func (LHOST etc.)
	transient  map[string]string
}

// NewState returns a State ready to run Interactive against cmd.
func NewState(s *session.Session, historyDir string) *State {
	return &State{
		Sess:       s,
		VarHistory: historyDir,
		Detectors:  defaultAutoDetectors(),
		transient:  map[string]string{},
	}
}

// Interactive walks every placeholder in cmd (after processing
// optional blocks), prompts for each unresolved value via a tui
// picker, substitutes, and returns the fully-filled command. If the
// user cancels any prompt, returns "" with a nil error.
func (st *State) Interactive(cmd string) (string, error) {
	// 1) Expand optional blocks first — a "no" answer drops the
	//    whole segment (flag + placeholder together) so we don't
	//    prompt for placeholders inside dropped blocks.
	cmd = ProcessOptionalBlocks(cmd, func(tag string) bool {
		return askYesNo(fmt.Sprintf("include %s ?", tag))
	})

	// 2) Walk placeholders. Dedupe by name — first occurrence wins,
	//    later duplicates get the same value. Loop the extract-resolve
	//    pass because a snippet payload injects fresh placeholders
	//    (e.g. {{PAYLOAD:snippet:rshell-bash-linux}} substitutes to
	//    text containing {{LHOST}} and {{LPORT}}). Bounded so a
	//    malformed snippet that keeps expanding can't spin forever.
	const maxPasses = 8
	for pass := 0; pass < maxPasses; pass++ {
		phs := UniqueNames(Extract(cmd))
		progressed := false
		for _, p := range phs {
			if _, done := st.transient[p.Name]; done {
				continue
			}
			val, ok, err := st.resolveOne(p)
			if err != nil {
				return "", err
			}
			if !ok {
				// User cancelled a prompt — abort the whole fill.
				return "", nil
			}
			cmd = Substitute(cmd, p.Name, val)
			st.transient[p.Name] = val
			// Persist: session (so next time it's the top candidate) +
			// per-name history (deduped, cap 20).
			_ = st.Sess.SetVar(p.Name, val)
			st.appendHistory(p.Name, val)
			progressed = true
		}
		if !progressed {
			break
		}
	}
	return cmd, nil
}

// resolveOne prompts for one placeholder, honouring:
//   - transient state (same var referenced twice in a fill run)
//   - existing session value (already offered as top candidate)
//   - the placeholder's declared default (auto-select if user just Enters)
//
// Returns (value, true, nil) on success; ("", false, nil) on cancel.
func (st *State) resolveOne(p Placeholder) (string, bool, error) {
	if v, ok := st.transient[p.Name]; ok {
		return v, true, nil
	}
	src := Sources{
		SessionValue: st.Sess.GetVar(p.Name),
		RecentValues: st.readHistory(p.Name),
	}
	if auto, ok := st.Detectors[p.Name]; ok {
		src.AutoValues = auto()
	}
	// Add matching session targets.
	for _, t := range st.Sess.Targets() {
		if targetCompat(p.Type, p.Name, t.Type) {
			src.Targets = append(src.Targets, t.Value)
		}
	}

	cands := BuildCandidates(p, src)
	rows := make([]tui.Row, 0, len(cands))
	for _, c := range cands {
		rows = append(rows, tui.Row{
			Display: c.Display(),
			Search:  c.Value + " " + c.Hint,
			Payload: c.Value,
		})
	}

	res, err := tui.Show(tui.Options{
		Prompt: "  {{" + p.Name + "}}> ",
		Header: PromptLabel(p) + "  |  Enter=pick  Type=custom  Esc=cancel",
		Rows:   rows,
	})
	if err != nil {
		return "", false, err
	}
	if res == nil || res.Cancelled {
		// Ctrl+C / Esc — but if the user TYPED something, use it as
		// a custom value; otherwise treat it as skip.
		if res != nil && res.Query != "" {
			return res.Query, true, nil
		}
		// If a default exists, offer it as the fallback so plain
		// Esc still lets the pipeline proceed.
		if def := p.EffectiveDefault(); def != "" {
			return def, true, nil
		}
		return "", false, nil
	}
	// Selected a row from the list.
	if res.Selected != nil {
		return res.Selected.Payload.(string), true, nil
	}
	// Typed text without a match — take it verbatim.
	if res.Query != "" {
		return res.Query, true, nil
	}
	if def := p.EffectiveDefault(); def != "" {
		return def, true, nil
	}
	return "", false, nil
}

// Auto returns the placeholder-filled command WITHOUT prompting,
// pulling values only from session vars + declared defaults. If any
// placeholder can't be resolved, returns "" with a non-nil sentinel
// error so the caller can fall back to Interactive.
func (st *State) Auto(cmd string) (string, error) {
	if HasOptionalBlocks(cmd) {
		return "", ErrOptional
	}
	// Loop the extract-substitute pass so a snippet-typed placeholder
	// can inject fresh placeholders that later passes then resolve.
	// Bounded to keep a self-referential snippet from spinning forever.
	const maxPasses = 8
	for pass := 0; pass < maxPasses; pass++ {
		phs := UniqueNames(Extract(cmd))
		if len(phs) == 0 {
			break
		}
		before := cmd
		for _, p := range phs {
			v := st.Sess.GetVar(p.Name)
			if v == "" {
				if p.Type == "snippet" {
					if payload, ok := snippets.Get(strings.TrimSpace(p.Default)); ok {
						v = payload
					}
				} else {
					v = p.EffectiveDefault()
				}
			}
			if v == "" {
				return "", fmt.Errorf("%w: %s", ErrUnresolved, p.Name)
			}
			cmd = Substitute(cmd, p.Name, v)
		}
		if cmd == before {
			break
		}
	}
	return cmd, nil
}

// Sentinels the caller can check with errors.Is.
var (
	ErrOptional   = fmt.Errorf("command has optional blocks — needs interactive fill")
	ErrUnresolved = fmt.Errorf("placeholder unresolved")
)

// ---------- helpers ----------

// askYesNo pops a tiny 2-row picker for a boolean prompt. Enter on
// [n] (default) or [y] returns bool. Esc = no.
func askYesNo(prompt string) bool {
	res, err := tui.Show(tui.Options{
		Prompt: prompt + "  ",
		Header: "↑↓ pick  Enter=confirm  Esc=no",
		Rows: []tui.Row{
			{Display: "no",  Search: "no",  Payload: false, Rank: 0},
			{Display: "yes", Search: "yes", Payload: true,  Rank: 1},
		},
		Height: 3,
	})
	if err != nil || res == nil || res.Cancelled || res.Selected == nil {
		return false
	}
	return res.Selected.Payload.(bool)
}

func (st *State) readHistory(name string) []string {
	if st.VarHistory == "" {
		return nil
	}
	f, err := os.Open(filepath.Join(st.VarHistory, strings.ToUpper(name)))
	if err != nil {
		return nil
	}
	defer f.Close()
	buf, _ := os.ReadFile(f.Name())
	lines := strings.Split(strings.TrimRight(string(buf), "\n"), "\n")
	// Cap at 20 — matches bash tree.
	if len(lines) > 20 {
		lines = lines[:20]
	}
	return lines
}

func (st *State) appendHistory(name, value string) {
	if st.VarHistory == "" || value == "" {
		return
	}
	_ = os.MkdirAll(st.VarHistory, 0o755)
	path := filepath.Join(st.VarHistory, strings.ToUpper(name))
	existing, _ := os.ReadFile(path)
	var out []string
	out = append(out, value)
	for _, line := range strings.Split(strings.TrimRight(string(existing), "\n"), "\n") {
		if line == "" || line == value {
			continue
		}
		out = append(out, line)
		if len(out) >= 20 {
			break
		}
	}
	_ = os.WriteFile(path, []byte(strings.Join(out, "\n")+"\n"), 0o644)
}

// targetCompat mirrors lib/variables.sh — some placeholder types
// accept some target types.
func targetCompat(phType, phName, targetType string) bool {
	up := strings.ToUpper(phName)
	switch strings.ToUpper(phType) {
	case "IP":
		return targetType == "ip"
	case "URL":
		return targetType == "url"
	case "DOMAIN":
		return targetType == "url" || targetType == "domain"
	case "TARGET", "HOST", "RHOST":
		return targetType == "ip" || targetType == "url" || targetType == "domain"
	case "SUBNET", "CIDR":
		return targetType == "cidr"
	}
	switch up {
	case "TARGET", "RHOST", "RHOSTS", "HOST", "IP":
		return targetType == "ip" || targetType == "url" || targetType == "domain"
	case "URL":
		return targetType == "url"
	case "DOMAIN":
		return targetType == "url" || targetType == "domain"
	}
	return false
}

// defaultAutoDetectors — the set of NAMES that get auto-computed
// values (currently just LHOST). Extend as needed.
func defaultAutoDetectors() map[string]func() []string {
	return map[string]func() []string{
		"LHOST": detectLHost,
	}
}
