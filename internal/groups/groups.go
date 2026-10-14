// Package groups defines broad categories ("Global", "AD", "Web", ...)
// that collapse the 15 cheatsheet directories into a short list for the
// pre-picker. Edit Defaults below to re-shape the mapping — nothing
// else in the tool depends on this ordering.
package groups

import "strings"

// Group is one top-level bucket shown in the group picker. Dirs lists
// the cheatsheets/<name> directories whose Category field feeds into
// this bucket. Hint is the one-line description shown next to the name.
type Group struct {
	Name string
	Dirs []string
	Hint string
}

// Defaults is the shipped group mapping. 8 buckets covering the 15
// on-disk cheatsheet dirs. Change the slice to adjust what collapses
// into what — no code changes needed elsewhere.
var Defaults = []Group{
	{Name: "Global", Dirs: []string{"recon", "enumeration", "scanning", "network", "vuln"}, Hint: "recon, scanning, enum, network, vuln scans"},
	{Name: "AD", Dirs: []string{"ad"}, Hint: "active directory, kerberos, bloodhound, impacket, nxc"},
	{Name: "Web", Dirs: []string{"web"}, Hint: "web app, sqli, xss, ffuf, nuclei, sqlmap"},
	{Name: "System", Dirs: []string{"system"}, Hint: "windows cmd/powershell/registry, linux host"},
	{Name: "Post", Dirs: []string{"post-exploit", "exploit", "shells", "chains"}, Hint: "post-exploit, exploit chains, shells"},
	{Name: "Passwords", Dirs: []string{"passwords"}, Hint: "hashcat, hydra, john, sqlmap creds"},
	{Name: "Cloud", Dirs: []string{"cloud"}, Hint: "aws, azure, gcp"},
	{Name: "Wireless", Dirs: []string{"wireless"}, Hint: "wifi, aircrack, bettercap"},
}

// FindByName returns the group whose Name matches (case-insensitive).
// Returns nil + false when no group matches — caller treats as "all".
func FindByName(name string) (*Group, bool) {
	for i := range Defaults {
		if strings.EqualFold(Defaults[i].Name, name) {
			return &Defaults[i], true
		}
	}
	return nil, false
}

// Matches reports whether category belongs to the group. Case-
// insensitive exact match against one of the group's dirs.
func (g *Group) Matches(category string) bool {
	for _, d := range g.Dirs {
		if strings.EqualFold(d, category) {
			return true
		}
	}
	return false
}
