package fill

import (
	"fmt"
	"os"
	"strings"

	"github.com/0xDTC/0xq/internal/helpscrape"
	"github.com/0xDTC/0xq/internal/snippets"
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
	case "helpflags":
		// Default field carries the tool name. Scrape its --help and
		// offer one candidate per parsed flag with its description.
		// Value is the flag literal (e.g. "-sV") so it drops straight
		// into the assembled command; a `--long ARG` form keeps just
		// the flag — the user follows up with the value themselves.
		tool := strings.TrimSpace(p.Default)
		if tool != "" {
			for _, f := range helpscrape.Scrape(tool) {
				hint := f.Desc
				if f.Arg != "" {
					hint = f.Arg + " — " + hint
				}
				add(Candidate{Value: f.Flag, Tag: "flag", Hint: hint})
			}
		}
	case "wordlist":
		// Offer curated wordlist files from the standard seclists /
		// wordlists trees, plus whatever the placeholder default names.
		// A file the user pinned via Default gets top billing.
		if p.Default != "" {
			add(Candidate{Value: p.Default, Tag: "default"})
		}
		for _, w := range findWordlists() {
			add(Candidate{Value: w.path, Tag: "wordlist", Hint: w.size})
		}
	case "snippet":
		// Default field carries the snippet key. Substitute the payload
		// text — placeholders inside it (e.g. {{LHOST}}) surface on the
		// next fill pass. The user can override at prompt time by typing
		// a custom value, exactly like other candidate rows.
		key := strings.TrimSpace(p.Default)
		if payload, ok := snippets.Get(key); ok {
			hint := key
			for _, s := range snippets.List() {
				if s.Key == key {
					if s.Description != "" {
						hint = s.Description
					}
					break
				}
			}
			add(Candidate{Value: payload, Tag: "snippet", Hint: hint})
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

// wordlistEntry pairs a path with a display-size hint for the picker.
type wordlistEntry struct{ path, size string }

// findWordlists sweeps a curated list of standard SecLists + wordlists
// paths and returns those that actually exist. Not a wide FS crawl —
// keeps the picker focused on the top-N files a pentester reaches for.
// Cached for the process lifetime; box layout doesn't change mid-run.
var (
	wordlistCache  []wordlistEntry
	wordlistLoaded bool
)

func findWordlists() []wordlistEntry {
	if wordlistLoaded {
		return wordlistCache
	}
	wordlistLoaded = true

	candidates := []string{
		// Web content
		"/usr/share/seclists/Discovery/Web-Content/common.txt",
		"/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt",
		"/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt",
		"/usr/share/seclists/Discovery/Web-Content/big.txt",
		"/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt",
		"/usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt",
		// DNS / subdomain
		"/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt",
		"/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt",
		"/usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt",
		"/usr/share/seclists/Discovery/DNS/bitquark-subdomains-top100000.txt",
		// Usernames
		"/usr/share/seclists/Usernames/Names/names.txt",
		"/usr/share/seclists/Usernames/xato-net-10-million-usernames.txt",
		"/usr/share/seclists/Usernames/xato-net-10-million-usernames-dup.txt",
		// Passwords
		"/usr/share/wordlists/rockyou.txt",
		"/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt",
		"/usr/share/seclists/Passwords/Common-Credentials/best110.txt",
		"/usr/share/seclists/Passwords/Leaked-Databases/rockyou-75.txt",
		// Payloads
		"/usr/share/seclists/Fuzzing/LFI/LFI-Jhaddix.txt",
		"/usr/share/seclists/Fuzzing/SQLi/Generic-SQLi.txt",
		// Parameters
		"/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt",
	}

	for _, p := range candidates {
		info, err := os.Stat(p)
		if err != nil {
			continue
		}
		wordlistCache = append(wordlistCache, wordlistEntry{
			path: p,
			size: humanSize(info.Size()),
		})
	}
	return wordlistCache
}

// humanSize formats a byte count as "12K" / "34M" / "1.2G".
func humanSize(n int64) string {
	switch {
	case n >= 1<<30:
		return fmtBytes(float64(n)/(1<<30), "G")
	case n >= 1<<20:
		return fmtBytes(float64(n)/(1<<20), "M")
	case n >= 1<<10:
		return fmtBytes(float64(n)/(1<<10), "K")
	}
	return fmt.Sprintf("%dB", n)
}

func fmtBytes(v float64, unit string) string {
	if v >= 10 {
		return fmt.Sprintf("%.0f%s", v, unit)
	}
	return fmt.Sprintf("%.1f%s", v, unit)
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
