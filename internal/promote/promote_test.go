package promote

import "testing"

func TestParse_NmapBasics(t *testing.T) {
	sample := `Starting Nmap 7.94 at 2026-09-21 23:15
Nmap scan report for 10.10.11.42
PORT     STATE SERVICE
22/tcp   open  ssh     OpenSSH 8.2p1
80/tcp   open  http    Apache 2.4.41
443/tcp  open  ssl/https
Nmap done.`

	got := Parse(sample)
	seen := map[string]bool{}
	for _, f := range got {
		seen[string(f.Kind)+"|"+f.Value] = true
	}
	if !seen["ip|10.10.11.42"] {
		t.Error("expected IP 10.10.11.42")
	}
	if !seen["port|22/tcp ssh"] {
		t.Error("expected port 22/tcp ssh")
	}
	if !seen["port|80/tcp http"] {
		t.Error("expected port 80/tcp http")
	}
	if !seen["port|443/tcp ssl/https"] {
		t.Error("expected port 443/tcp ssl/https")
	}
}

func TestParse_URLsAndDomains(t *testing.T) {
	sample := `[+] alive: https://api.htb.com
Also found: https://admin.htb.com/dashboard, http://legacy.htb.com`
	got := Parse(sample)
	seen := map[string]bool{}
	for _, f := range got {
		seen[string(f.Kind)+"|"+f.Value] = true
	}
	if !seen["url|https://api.htb.com"] {
		t.Errorf("expected api.htb.com URL — got %+v", got)
	}
	if !seen["url|https://admin.htb.com/dashboard"] {
		t.Errorf("expected admin URL — got %+v", got)
	}
	if !seen["domain|api.htb.com"] {
		t.Error("expected api.htb.com domain")
	}
}

func TestParse_IgnoreVersionAsDomain(t *testing.T) {
	sample := `Apache 2.4.41 installed
Nginx 1.18.0 running`
	got := Parse(sample)
	for _, f := range got {
		if f.Kind == KindDomain && (f.Value == "2.4.41" || f.Value == "1.18.0") {
			t.Errorf("version string promoted as domain: %s", f.Value)
		}
	}
}

func TestParse_HashesAndUPNs(t *testing.T) {
	sample := `administrator:500:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
[+] valid: j.smith@htb.local`
	got := Parse(sample)
	seen := map[string]bool{}
	for _, f := range got {
		seen[string(f.Kind)+"|"+f.Value] = true
	}
	if !seen["ntlm|aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0"] {
		t.Errorf("expected NTLM pair — got %+v", got)
	}
	if !seen["upn|j.smith@htb.local"] {
		t.Errorf("expected UPN j.smith@htb.local — got %+v", got)
	}
}

func TestParse_RejectLoopbackAndInvalid(t *testing.T) {
	sample := `bind to 127.0.0.1
octet-too-big 999.888.777.666
leading-zero 010.0.0.1
real target 10.10.11.42`
	got := Parse(sample)
	for _, f := range got {
		if f.Kind == KindIP {
			switch f.Value {
			case "127.0.0.1", "999.888.777.666", "010.0.0.1":
				t.Errorf("noise IP promoted: %s", f.Value)
			}
		}
	}
	seen := false
	for _, f := range got {
		if f.Kind == KindIP && f.Value == "10.10.11.42" {
			seen = true
		}
	}
	if !seen {
		t.Error("real IP 10.10.11.42 not promoted")
	}
}

// Two-label names must promote: on an AD engagement the domain FQDN is
// the most valuable artefact in the output, and an earlier regex that
// required three labels dropped every one of them.
func TestParse_TwoLabelDomains(t *testing.T) {
	sample := `Domain Name: amzcorp.local
[+] joined to htb.local
Host is example.com`
	got := Parse(sample)
	seen := map[string]bool{}
	for _, f := range got {
		seen[string(f.Kind)+"|"+f.Value] = true
	}
	for _, want := range []string{"domain|amzcorp.local", "domain|htb.local", "domain|example.com"} {
		if !seen[want] {
			t.Errorf("expected %s — got %+v", want, got)
		}
	}
}

// Allowing two-label domains makes filenames syntactically valid, so
// they have to be filtered or every bit of tool output becomes a target.
func TestParse_IgnoreFilenamesAsDomains(t *testing.T) {
	sample := `wrote results to scan.json and notes.txt
running exploit.py against the host
see report.pdf / payload.exe / dump.sqlite`
	got := Parse(sample)
	for _, f := range got {
		if f.Kind != KindDomain {
			continue
		}
		switch f.Value {
		case "scan.json", "notes.txt", "exploit.py", "report.pdf", "payload.exe", "dump.sqlite":
			t.Errorf("filename promoted as domain: %s", f.Value)
		}
	}
}

// Engagement-plausible TLDs must survive the filename filter.
func TestParse_KeepEngagementTLDs(t *testing.T) {
	sample := `dc01.corp.internal
fileserver.lan
web.htb`
	got := Parse(sample)
	seen := map[string]bool{}
	for _, f := range got {
		seen[string(f.Kind)+"|"+f.Value] = true
	}
	for _, want := range []string{"domain|dc01.corp.internal", "domain|fileserver.lan", "domain|web.htb"} {
		if !seen[want] {
			t.Errorf("expected %s — got %+v", want, got)
		}
	}
}
