package helpscrape

import "testing"

func TestParseOutput_ClassicHelp(t *testing.T) {
	sample := `Usage: ffuf [options]

  -u URL        Target URL
  -w, --wordlist WORDLIST
                Wordlist file path
  -mc CODES     Match HTTP status codes (default: 200)
  -H HEADER     Header 'Name: Value'
`
	flags := parseOutput(sample)
	if len(flags) < 3 {
		t.Fatalf("got %d flags, want ≥3: %+v", len(flags), flags)
	}
	seen := map[string]string{}
	for _, f := range flags {
		seen[f.Flag] = f.Desc
	}
	for _, want := range []string{"-u", "-mc", "-H", "-w"} {
		if _, ok := seen[want]; !ok {
			t.Errorf("expected %s in output: %+v", want, flags)
		}
	}
	// -w should have its wrapped continuation appended.
	if !contains(seen["-w"], "Wordlist") {
		t.Errorf("-w desc lost continuation line: %q", seen["-w"])
	}
}

func contains(hay, needle string) bool {
	for i := 0; i+len(needle) <= len(hay); i++ {
		if hay[i:i+len(needle)] == needle {
			return true
		}
	}
	return false
}
