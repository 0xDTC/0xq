package fill

import (
	"fmt"
	"strings"
)

// Candidate is one row in the per-variable picker.
type Candidate struct {
	// Value is what gets substituted into the command if picked.
	Value string
	// Tag renders in front of the value ("session", "choice", "recent",
	// "auto" — mirrors the bash tree's [tag] convention).
	Tag string
	// Hint is dimmed after the value (choice option description, port
	// service name, file size, etc.).
	Hint string
}

// Display is the visible line for a Candidate. ANSI-styled: tag in
// magenta, value bold, hint dim.
func (c Candidate) Display() string {
	const (
		magenta = "\x1b[35m"
		bold    = "\x1b[1m"
		dim     = "\x1b[2m"
		reset   = "\x1b[0m"
	)
	tag := ""
	if c.Tag != "" {
		tag = magenta + "[" + c.Tag + "]" + reset + " "
	}
	line := tag + bold + c.Value + reset
	if c.Hint != "" {
		line += "\t" + dim + c.Hint + reset
	}
	return line
}

// Sources holds every state the candidate builder can pull from.
// The caller assembles this before each variable prompt so the
// pipeline is explicit (not hidden inside globals like the bash tree).
type Sources struct {
	// SessionValue is what session.GetVar returned for this name,
	// or "" if unset. Rendered as a `[session]` candidate on top.
	SessionValue string
	// RecentValues is the ordered per-type/per-name value history
	// (newest first). Rendered as `[recent] value` rows.
	RecentValues []string
	// AutoValues carries type-specific auto-detected values (LHOST
	// interface IP, etc.). Rendered as `[auto] value`.
	AutoValues []string
	// Targets are the current session's targets whose type is
	// compatible with the placeholder's type. Rendered as `[target] value`.
	Targets []string
}

// BuildCandidates assembles the candidate list for one placeholder
// prompt. Order matters — first entries appear at the top of the
// picker and win the default-Enter action.
//
// The order (matching the bash tree so muscle memory transfers):
//   1. [session]   whatever the session var already holds
//   2. [choice]    for CHOICE type, every option (with hints)
//   3. [default]   the placeholder's declared default (non-choice)
//   4. [auto]      auto-detected values (LHOST, iface IP)
//   5. [target]    matching session targets
//   6. [recent]    per-var value history, newest first
func BuildCandidates(p Placeholder, src Sources) []Candidate {
	var out []Candidate
	seen := map[string]bool{}
	add := func(c Candidate) {
		if c.Value == "" || seen[c.Value] {
			return
		}
		seen[c.Value] = true
		out = append(out, c)
	}

	if src.SessionValue != "" {
		add(Candidate{Value: src.SessionValue, Tag: "session"})
	}

	switch p.Type {
	case "choice", "enum":
		for _, o := range p.Options() {
			add(Candidate{Value: o.Value, Tag: "choice", Hint: o.Hint})
		}
	default:
		if p.Default != "" {
			add(Candidate{Value: p.Default, Tag: "default"})
		}
	}

	for _, v := range src.AutoValues {
		add(Candidate{Value: v, Tag: "auto"})
	}
	for _, v := range src.Targets {
		add(Candidate{Value: v, Tag: "target"})
	}
	for _, v := range src.RecentValues {
		add(Candidate{Value: v, Tag: "recent"})
	}

	// Common port hints for PORT-typed vars — ported from the bash
	// tree's common_ports list, top-tier subset only.
	if isPortType(p.Type, p.Name) {
		for _, e := range commonPorts {
			add(Candidate{Value: e.port, Tag: "port", Hint: e.svc})
		}
	}
	// LPORT reverse-shell callback presets.
	if isLPortType(p.Type, p.Name) {
		for _, e := range lportPresets {
			add(Candidate{Value: e.port, Tag: "lport", Hint: e.svc})
		}
	}

	return out
}

// PromptLabel is the header shown at the top of a per-var picker.
// Mentions type + default in a concise line.
func PromptLabel(p Placeholder) string {
	def := p.EffectiveDefault()
	label := fmt.Sprintf("fill {{%s}}", p.Name)
	if p.Type != "" && p.Type != "str" {
		label += "  type=" + p.Type
	}
	if def != "" {
		label += "  default=" + def
	}
	return label
}

// ---------- built-in candidate tables ----------

type portEntry struct{ port, svc string }

var commonPorts = []portEntry{
	{"21", "FTP"}, {"22", "SSH"}, {"23", "Telnet"}, {"25", "SMTP"},
	{"53", "DNS"}, {"80", "HTTP"}, {"110", "POP3"}, {"135", "MSRPC"},
	{"139", "NetBIOS-ssn"}, {"143", "IMAP"}, {"389", "LDAP"}, {"443", "HTTPS"},
	{"445", "SMB"}, {"636", "LDAPS"}, {"1433", "MSSQL"}, {"3306", "MySQL"},
	{"3389", "RDP"}, {"5432", "PostgreSQL"}, {"5985", "WinRM"},
	{"6379", "Redis"}, {"8080", "HTTP-alt"}, {"27017", "MongoDB"},
	{"1-1000", "top 1k"}, {"1-65535", "all TCP"},
}

var lportPresets = []portEntry{
	{"4444", "Metasploit default"}, {"9001", "Cobalt/HTTPS-alt"},
	{"443", "blends with HTTPS egress"}, {"80", "blends with HTTP egress"},
	{"8080", "HTTP-alt"}, {"1234", "CTF classic"},
	{"4443", "HTTPS-alt"}, {"1080", "SOCKS-proxy port"},
}

func isPortType(typ, name string) bool {
	if strings.EqualFold(typ, "port") {
		return true
	}
	up := strings.ToUpper(name)
	return strings.Contains(up, "PORT") && !strings.Contains(up, "LPORT")
}

func isLPortType(typ, name string) bool {
	if strings.EqualFold(typ, "lport") {
		return true
	}
	return strings.Contains(strings.ToUpper(name), "LPORT")
}
