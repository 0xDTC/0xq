// Package promote parses command output for high-signal artifacts —
// IPs, hostnames, URLs, open ports, hashes, user principals — that a
// pentester will almost certainly want to reuse as session targets or
// vars in the next command.
//
// Deliberately conservative: only well-shaped, unambiguous matches
// get promoted. False positives are worse than false negatives here
// (a spurious "target" costs the user a prompt-no every future scan).
package promote

import (
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// Kind names the class of a Finding. Keep the vocabulary short —
// callers switch on it to route into targets, vars, or ignore.
type Kind string

const (
	KindIP     Kind = "ip"     // IPv4 dotted
	KindDomain Kind = "domain" // FQDN
	KindURL    Kind = "url"    // http(s)://…
	KindPort   Kind = "port"   // nmap-style N/tcp|udp open service
	KindNTLM   Kind = "ntlm"   // LM:NT hash pair
	KindHash   Kind = "hash"   // hashcat-mode-detectable string
	KindUPN    Kind = "upn"    // user@realm (Kerberos style)
)

// Finding is one artefact spotted in output.
type Finding struct {
	Kind    Kind
	Value   string // canonical form (e.g. "10.10.11.42:80" for a port)
	Context string // one source line for user review
}

var (
	// Anchor IPv4 on non-word boundaries so we don't cut inside version
	// strings ("2.4.41" gets rejected because the trailing octet gate
	// takes the whole string as one candidate but validateIPv4 filters
	// it out — octets > 255 or fewer than 4 parts).
	reIPv4   = regexp.MustCompile(`\b(?:\d{1,3}\.){3}\d{1,3}\b`)
	reURL    = regexp.MustCompile(`\bhttps?://[^\s"'<>()\[\]]+`)
	reDomain = regexp.MustCompile(`\b[a-z0-9][a-z0-9\-]{0,62}(?:\.[a-z0-9][a-z0-9\-]{0,62})+\.[a-z]{2,24}\b`)
	// nmap-style "80/tcp open http" or "443/tcp open  ssl/https"
	reOpenPort = regexp.MustCompile(`^\s*(\d{1,5})/(tcp|udp)\s+open\s+([A-Za-z0-9\-\.\_\/]+)`)
	// hashcat-format LM:NT pair (32:32 hex, colon-separated)
	reNTLM     = regexp.MustCompile(`\b[a-fA-F0-9]{32}:[a-fA-F0-9]{32}\b`)
	// Kerberos-style user@realm — realm has to look like a domain
	reUPN      = regexp.MustCompile(`\b[a-zA-Z][a-zA-Z0-9._-]{0,63}@[a-zA-Z0-9][a-zA-Z0-9-]*(?:\.[a-zA-Z0-9][a-zA-Z0-9-]*)+\b`)
)

// Parse scans text for well-shaped artefacts and returns them deduped,
// grouped by Kind (URLs first, then ports, IPs, domains, hashes, UPNs).
// Each Finding.Context is the source line the match was found on so
// the user can eyeball for sanity when the promoter asks to accept.
func Parse(text string) []Finding {
	out := []Finding{}
	seen := map[string]bool{}
	add := func(k Kind, v, ctx string) {
		key := string(k) + "|" + v
		if seen[key] || v == "" {
			return
		}
		seen[key] = true
		out = append(out, Finding{Kind: k, Value: v, Context: strings.TrimSpace(ctx)})
	}

	lines := strings.Split(text, "\n")
	for _, line := range lines {
		trimmed := strings.TrimRight(line, "\r\n\t ")
		// Skip obviously-noise banner lines.
		if strings.HasPrefix(trimmed, "Starting Nmap") ||
			strings.HasPrefix(trimmed, "Nmap done") {
			continue
		}

		// nmap-style open port — extract before generic IP scan so the
		// context line makes it into the port Finding.
		if m := reOpenPort.FindStringSubmatch(trimmed); m != nil {
			// Value: "N/proto service"
			add(KindPort, m[1]+"/"+m[2]+" "+m[3], trimmed)
		}

		for _, m := range reURL.FindAllString(trimmed, -1) {
			add(KindURL, strings.TrimRight(m, ".,;:"), trimmed)
		}
		for _, m := range reIPv4.FindAllString(trimmed, -1) {
			if !validIPv4(m) {
				continue
			}
			if isPrivateOrPublicRoutable(m) {
				add(KindIP, m, trimmed)
			}
		}
		for _, m := range reDomain.FindAllString(strings.ToLower(trimmed), -1) {
			if looksLikeVersion(m) {
				continue
			}
			add(KindDomain, m, trimmed)
		}
		for _, m := range reNTLM.FindAllString(trimmed, -1) {
			add(KindNTLM, m, trimmed)
		}
		for _, m := range reUPN.FindAllString(trimmed, -1) {
			add(KindUPN, m, trimmed)
		}
	}

	sort.SliceStable(out, func(i, j int) bool {
		if out[i].Kind != out[j].Kind {
			return kindOrder(out[i].Kind) < kindOrder(out[j].Kind)
		}
		return out[i].Value < out[j].Value
	})
	return out
}

func kindOrder(k Kind) int {
	switch k {
	case KindURL:
		return 0
	case KindPort:
		return 1
	case KindIP:
		return 2
	case KindDomain:
		return 3
	case KindNTLM:
		return 4
	case KindHash:
		return 5
	case KindUPN:
		return 6
	}
	return 9
}

// validIPv4 rejects candidates whose octets exceed 255.
func validIPv4(s string) bool {
	parts := strings.Split(s, ".")
	if len(parts) != 4 {
		return false
	}
	for _, p := range parts {
		n, err := strconv.Atoi(p)
		if err != nil || n < 0 || n > 255 {
			return false
		}
		if len(p) > 1 && p[0] == '0' {
			// reject leading-zero octets — they're never real addresses
			return false
		}
	}
	return true
}

// isPrivateOrPublicRoutable filters out obvious noise addresses
// (0.0.0.0, 127.x, 255.255.255.255) while keeping RFC1918, HTB-style
// 10.10.x.x, and public routable IPs. Loopback stays out because
// it's rarely a useful target from an offensive standpoint.
func isPrivateOrPublicRoutable(s string) bool {
	switch s {
	case "0.0.0.0", "255.255.255.255":
		return false
	}
	if strings.HasPrefix(s, "127.") {
		return false
	}
	// broadcast-y stuff already excluded via octet check above
	return true
}

// looksLikeVersion filters strings like "1.2.3" or "2.4.41" that
// syntactically match the domain regex but are really version stamps.
// Heuristic: no letters after the last dot → probably a version.
func looksLikeVersion(s string) bool {
	dot := strings.LastIndexByte(s, '.')
	if dot < 0 {
		return true
	}
	tld := s[dot+1:]
	for _, r := range tld {
		if r < 'a' || r > 'z' {
			return true
		}
	}
	if len(tld) < 2 {
		return true
	}
	return false
}
