package tool

import "testing"

func TestExtract(t *testing.T) {
	cases := []struct {
		in, want string
	}{
		// Plain
		{"nmap -sV 10.0.0.1", "nmap"},
		{"ls -la", "ls"},
		{"", ""},

		// sudo variants
		{"sudo nmap -sV 10.0.0.1", "nmap"},
		{"sudo -u alice regripper -r hive", "regripper"},
		{"sudo -u alice -g wheel regripper -r hive", "regripper"},
		{"sudo -n -u root apt-get update", "apt-get"},

		// Env prefix
		{"FOO=bar nmap -sV target", "nmap"},
		{"FOO=bar BAZ=qux sudo -u alice regripper hive", "regripper"},
		{"PATH=/opt/bin nmap target", "nmap"},

		// Path stripping
		{"/usr/local/bin/nmap -sV target", "nmap"},
		{"./scan.py --host target", "scan"},
		{"/opt/tools/whatever.exe -flag", "whatever"},

		// Degenerate
		{"sudo", ""},
		{"sudo -u alice", ""},
		{"FOO=bar", ""},
		{"--just-flags -h", ""},

		// Not env — leading = or non-identifier
		{"=broken nmap x", "=broken"}, // treated as tool since not valid env
		{"1FOO=bar nmap x", "1FOO=bar"},
	}
	for _, tc := range cases {
		got := Extract(tc.in)
		if got != tc.want {
			t.Errorf("Extract(%q) = %q, want %q", tc.in, got, tc.want)
		}
	}
}
