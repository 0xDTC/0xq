// Package nexthint suggests the logical next command after a scan
// finishes. Small rule table: cheatsheet tags → follow-up chain title.
//
// This is a pure lookup — no output-parsing, no ML. Point of taste:
// the hints deliberately point at CHAINS (curated multi-step flows)
// rather than individual tools so the recommendation is meaty enough
// to justify interrupting the user's flow with a message.
package nexthint

import "strings"

// rule maps a tag (lowercase, matched substring-in-any) to a
// suggestion sentence. First matching rule wins.
type rule struct {
	tag    string
	hint   string
	pickWith string // what to type into `q` to reach the suggested item
}

var rules = []rule{
	// SMB / Windows services
	{"nmap", "found open ports → try `q chain full smb null` or `q chain quick web recon` on the relevant port", "chain"},
	{"smb-enum", "have SMB creds now? → `q chain full smb authenticated` for spider + rpc + share perms", "chain full smb auth"},
	{"nxc", "explore forest → `q chain ad bloodhound collect and quick-triage` for attack paths", "chain ad bloodhound"},

	// AD
	{"kerberoast", "cracked a hash? → `q chain ad writable objects bloodyAD` to find where to abuse it", "chain ad writable"},
	{"kerbrute", "valid users? → try `q chain ad kerberoast get-hashes` next (needs one working cred first)", "chain ad kerberoast"},
	{"bloodhound", "check specific paths: `q chain ad writable objects bloodyAD` or `q chain ad cert attack certipy find`", "chain ad"},
	{"certipy", "got a PFX? → `q nxc ldap auth with certificate pfx` for cred-less LDAP recon", "nxc ldap cert"},
	{"gmsa", "post-dump → `q chain full smb authenticated` with the gMSA account for share access", "chain full smb auth"},

	// Web
	{"whatweb", "tech identified → `q chain quick web recon` or `q nuclei tech aware` if you want CVE coverage", "chain quick web"},
	{"ffuf", "found endpoints? → next: `q nuclei tech aware cve misconfig exposure` on interesting URLs", "nuclei tech aware"},
	{"gobuster", "found directories? → `q nuclei tech aware cve misconfig exposure` to check for vulns", "nuclei tech aware"},
	{"nuclei", "critical/high findings? → drop them into Burp via `q nuclei via burp caido proxy` to replay + tweak", "nuclei via burp"},
	{"wpscan", "WordPress creds? → `q hydra` for password brute or `q sqlmap` if you found a search box", "hydra"},

	// Post-exploit
	{"linpeas", "found kernel version → `q searchsploit` for local privesc CVEs", "searchsploit"},
	{"linenum", "same as above → `q searchsploit` for privesc leads", "searchsploit"},
	{"winpeas", "collected loot → `q chain ad bloodhound collect and quick-triage` to plan escalation", "chain ad bloodhound"},

	// Cracking
	{"hashcat", "cracked? → validate with `q chain full smb authenticated` or `q nxc winrm auto detect`", "chain full smb auth"},

	// Fallbacks by phase — matched last.
	{"recon", "post-recon → `q chain full smb null session` on port 445 targets or `q chain quick web recon` on port 80/443", "chain"},
	{"enum", "enum done → `q chain ad bloodhound` for path planning, or `q chain full smb authenticated` with creds", "chain"},
	{"attack", "attack landed → `q linpeas` (linux) or `q winpeas` (windows) for privesc leads", "peas"},
}

// For returns a one-line suggestion for a cheatsheet with the given
// title + tag list, or "" if no rule matches. Never wraps; caller
// prints as-is.
func For(title, tags string) string {
	haystack := strings.ToLower(title + " " + tags)
	for _, r := range rules {
		if strings.Contains(haystack, r.tag) {
			return r.hint
		}
	}
	return ""
}
