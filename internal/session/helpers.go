package session

import (
	"net"
	"strings"
	"time"
)

func looksLikeIP(v string) bool {
	ip := net.ParseIP(v)
	return ip != nil && ip.To4() != nil && !strings.Contains(v, ":")
}

func looksLikeCIDR(v string) bool {
	_, _, err := net.ParseCIDR(v)
	return err == nil
}

// looksLikeDomain — very loose: contains a dot, ends with a TLD-shaped
// suffix (2+ letters), doesn't start with a dot. Not RFC-perfect but
// matches lib/session.sh's regex.
func looksLikeDomain(v string) bool {
	if v == "" || strings.HasPrefix(v, ".") {
		return false
	}
	if !strings.Contains(v, ".") {
		return false
	}
	dot := strings.LastIndexByte(v, '.')
	if dot < 0 || dot == len(v)-1 {
		return false
	}
	tld := v[dot+1:]
	if len(tld) < 2 {
		return false
	}
	for _, r := range tld {
		if (r < 'a' || r > 'z') && (r < 'A' || r > 'Z') {
			return false
		}
	}
	return true
}

func nowTS() string { return time.Now().Format("2006-01-02 15:04:05") }
