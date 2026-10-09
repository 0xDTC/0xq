# dig

> DNS lookup Swiss-army knife. Every entry uses `{{SERVER}}` for the resolver — pick `@1.1.1.1` / `@8.8.8.8` for public or `@{{DC_IP}}` for a target's own nameserver. Esc any optional placeholder to skip it.

<!-- tags: dig, dns, recon, lookup, nameserver -->

> **Record-type cheat:**
> - `A` — IPv4 host  ·  `AAAA` — IPv6 host  ·  `CNAME` — alias
> - `MX` — mail server  ·  `TXT` — SPF, DKIM, DMARC, verification tokens
> - `NS` — authoritative nameservers for a domain
> - `SOA` — zone origin (admin email + serial + refresh timers)
> - `SRV` — service record (Kerberos, LDAP, SIP — `_kerberos._tcp.DOMAIN`)
> - `AXFR` — full zone transfer (often misconfigured → everything)
> - `ANY` — ask for all record types (many servers refuse now)

---

## query record types multi
Pick one or many record types from the checklist (space toggles, Enter confirms). dig queries them all in ONE invocation — `dig DOMAIN A MX NS +short` style. `tr , ' '` converts the comma-joined picks into dig's space-separated arg list.

```bash
dig @{{SERVER:str:1.1.1.1}} {{DOMAIN:domain}} $(echo "{{TYPES:multichoice:A=IPv4 host,AAAA=IPv6 host,CNAME=alias,MX=mail servers,TXT=SPF+DKIM+verification,NS=nameservers,SOA=zone origin,SRV=service record,PTR=reverse lookup,ANY=all records}}" | tr , ' ') +short
```

<!-- meta: risk=low | phase=recon | tags=dig,dns,record,query,multichoice -->

---

## attempt zone transfer axfr
Classic misconfig — if the nameserver allows AXFR, you get every record for the zone. Try against each NS the domain publishes.

```bash
dig @{{NAMESERVER:str}} {{DOMAIN:domain}} AXFR
```

<!-- meta: risk=low | phase=recon | tags=dig,axfr,zone-transfer,misconfig -->

---

## find authoritative nameservers then try axfr
Combined: list the domain's NS records, then loop AXFR against each one — one of them often forgets to lock down transfers.

```bash
domain={{DOMAIN:domain}}; for ns in $(dig +short NS "$domain"); do echo "[+] trying AXFR against $ns"; dig @"$ns" "$domain" AXFR | grep -vE '^;|^$' | head -20; echo; done
```

<!-- meta: risk=low | phase=recon | tags=dig,axfr,ns,chain,loop -->

---

## reverse ptr lookup ip
Hostname for a given IP. Useful on CTF boxes to find the box's "real" name once nmap has an IP.

```bash
dig @{{SERVER:str:1.1.1.1}} -x {{TARGET:ip}} +short
```

<!-- meta: risk=low | phase=recon | tags=dig,ptr,reverse,ip -->

---

## cache snoop non-recursive
`+norecurse` asks the resolver NOT to go upstream — if it answers, it already has that record cached (someone there has been looking it up). Useful during internal engagements to see what the local resolver knows.

```bash
dig @{{SERVER:str}} {{DOMAIN:domain}} +norecurse
```

<!-- meta: risk=low | phase=recon | tags=dig,cache-snoop,norecurse,internal -->

---

## dnssec validation check
`+dnssec +cd` — ask for the signatures AND tell the resolver NOT to validate (so you see what the server actually returns, including broken sigs). Combine with +multi for human-readable DS/RRSIG rows.

```bash
dig @{{SERVER:str:1.1.1.1}} {{DOMAIN:domain}} +dnssec +cd +multi
```

<!-- meta: risk=low | phase=recon | tags=dig,dnssec,validation,rrsig -->

---

## trace delegation path
`+trace` walks from the root → TLD → authoritative, printing each hop. Reveals where DNS actually gets answered — fast way to spot DNS redirection / split-horizon weirdness.

```bash
dig {{DOMAIN:domain}} {{TYPE:choice:A,NS,MX,ANY}} +trace
```

<!-- meta: risk=low | phase=recon | tags=dig,trace,delegation,path -->

---

## query srv records ad services multi
AD-adjacent — SRV records expose Kerberos / LDAP / GC / SIP / password-change endpoints. Multi-select which services to query; a bash for-loop iterates each one against the DC and prints hostname+port. Checklist is pre-populated with the common AD service names.

```bash
dc={{DC_IP:ip}}; domain={{DOMAIN:domain}}; for svc in $(echo "{{SERVICES:multichoice:_kerberos._tcp=KDC,_ldap._tcp=LDAP,_gc._tcp=global catalog,_kpasswd._tcp=Kerberos password change,_sip._tcp=SIP,_ldap._tcp.dc._msdcs=DC LDAP,_kerberos._tcp.dc._msdcs=DC KDC}}" | tr , ' '); do echo "[+] $svc.$domain"; dig @"$dc" "$svc.$domain" SRV +short; echo; done
```

<!-- meta: risk=low | phase=enum | tags=dig,srv,ad,kerberos,ldap,multichoice -->

---

## brute subdomains dig loop
No dedicated tool needed — bash while-loop + wordlist. Prints only the lines that resolve (filters NOERROR without an ANSWER). Slow but no deps.

```bash
domain={{DOMAIN:domain}}; wordlist={{WORDLIST:file:/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt}}; while read sub; do answer=$(dig +short "$sub.$domain" A 2>/dev/null | head -1); [ -n "$answer" ] && echo "$sub.$domain  $answer"; done < "$wordlist" | tee {{OUT:file:dig-brute.txt}}
```

<!-- meta: risk=low | phase=recon | tags=dig,brute,subdomains,loop,wordlist -->

---

## find subdomain takeover cname
List every subdomain in a file, show its CNAME. Dangling CNAMEs pointing at unregistered S3/Heroku/GitHub Pages buckets = takeover candidates.

```bash
while read sub; do cname=$(dig +short CNAME "$sub" 2>/dev/null); [ -n "$cname" ] && echo "$sub → $cname"; done < {{SUBS_FILE:file:live-subs.txt}} | tee {{OUT:file:cname-dump.txt}}
```

<!-- meta: risk=low | phase=recon | tags=dig,cname,subdomain-takeover,hunt -->
