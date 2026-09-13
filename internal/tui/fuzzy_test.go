package tui

import "testing"

func TestScore(t *testing.T) {
	cases := []struct {
		target, query string
		wantPositive  bool
	}{
		{"nmap", "nmap", true},
		{"nmap", "map", true},
		{"nmap", "mp", true},
		{"nmap", "xyz", false},
		{"regripper single plugin", "regr plug", true},
		{"regripper single plugin", "PLUGIN", true},   // case-insensitive
		{"regripper single plugin", "zzzzz", false},
		{"", "nmap", false},
		{"nmap", "", true},
	}
	for _, tc := range cases {
		got := Score(tc.target, tc.query)
		if (got > 0) != tc.wantPositive {
			t.Errorf("Score(%q, %q) = %d, want positive=%v", tc.target, tc.query, got, tc.wantPositive)
		}
	}
}

func TestScoreOrdering(t *testing.T) {
	// Contiguous match should beat non-contiguous.
	contig := Score("run nmap now", "nmap")
	scatter := Score("n-m-a-p", "nmap")
	if !(contig > scatter) {
		t.Errorf("expected contiguous match (%d) > scattered (%d)", contig, scatter)
	}
	// Prefix match should beat mid-string match of the same subsequence.
	prefix := Score("nmap scan", "nma")
	mid := Score("run nmap", "nma")
	if !(prefix > mid) {
		t.Errorf("expected prefix (%d) > mid (%d)", prefix, mid)
	}
}
