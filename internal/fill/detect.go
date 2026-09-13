package fill

import (
	"net"
	"strings"
)

// detectLHost mirrors _q_detect_lhost from lib/variables.sh — pick
// the first plausible attacker-side IPv4. Prefers VPN interfaces
// (tun*, utun*, wg*, ppp*, tap*, ipsec*) since they're almost always
// the right choice on an engagement, then falls back to any non-
// loopback IPv4.
func detectLHost() []string {
	ifaces, err := net.Interfaces()
	if err != nil {
		return nil
	}
	var vpn, other []string
	for _, ifi := range ifaces {
		if ifi.Flags&net.FlagUp == 0 || ifi.Flags&net.FlagLoopback != 0 {
			continue
		}
		addrs, err := ifi.Addrs()
		if err != nil {
			continue
		}
		for _, a := range addrs {
			ipn, ok := a.(*net.IPNet)
			if !ok {
				continue
			}
			ip4 := ipn.IP.To4()
			if ip4 == nil || ip4.IsLinkLocalUnicast() {
				continue
			}
			if isVPNIface(ifi.Name) {
				vpn = append(vpn, ip4.String())
			} else {
				other = append(other, ip4.String())
			}
		}
	}
	return append(vpn, other...)
}

func isVPNIface(name string) bool {
	for _, prefix := range []string{"tun", "utun", "wg", "ppp", "tap", "ipsec"} {
		if strings.HasPrefix(name, prefix) {
			return true
		}
	}
	return false
}
