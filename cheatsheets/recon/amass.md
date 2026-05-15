# Amass

> In-depth attack surface mapping and asset discovery via DNS enumeration

<!-- tags: amass, subdomains, dns, osint, recon, attack-surface -->

---

## Passive Enumeration
Discover subdomains using only passive data sources (no direct target contact).

```bash
amass enum -passive -d {{DOMAIN:domain}} -o {{OUTFILE:file:amass-passive.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=passive,subdomains,osint -->

---

## Active Enumeration
Perform DNS resolution and actively verify discovered subdomains.

```bash
amass enum -active -d {{DOMAIN:domain}} -o {{OUTFILE:file:amass-active.txt}}
```

<!-- meta: risk=low | phase=recon | tags=active,subdomains,dns -->

---

## Brute Force Subdomain Discovery
Combine passive sources with DNS brute forcing for deeper coverage.

```bash
amass enum -brute -d {{DOMAIN:domain}} -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt}} -o {{OUTFILE:file:amass-brute.txt}}
```

<!-- meta: risk=low | phase=recon | tags=bruteforce,subdomains,wordlist -->

---

## Intel Whois Reverse Lookup
Discover domains owned by an organization using reverse whois data.

```bash
amass intel -whois -d {{DOMAIN:domain}} -o {{OUTFILE:file:amass-intel.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=intel,whois,org,discovery -->

---

## Intel ASN Enumeration
Find domains associated with an autonomous system number.

```bash
amass intel -asn {{ASN:int}} -o {{OUTFILE:file:asn-domains.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=intel,asn,infrastructure -->

---

## Enumeration with Rate Limiting
Run active enumeration with controlled DNS query rate to avoid detection.

```bash
amass enum -active -d {{DOMAIN:domain}} -max-dns-queries {{RATE:int:200}} -o {{OUTFILE:file:amass-rated.txt}}
```

<!-- meta: risk=low | phase=recon | tags=active,rate-limit,stealth -->

---

## Database Query — Show Results
Query the local Amass database for previously discovered assets.

```bash
amass db -names -d {{DOMAIN:domain}}
```

<!-- meta: risk=safe | phase=recon | tags=database,query,history -->

---

## Enumeration with Config File
Run enumeration using a custom configuration file with API keys and settings.

```bash
amass enum -active -d {{DOMAIN:domain}} -config {{CONFIG:file:~/.config/amass/config.yaml}} -o {{OUTFILE:file:amass-full.txt}}
```

<!-- meta: risk=low | phase=recon | tags=config,api-keys,comprehensive -->

---

## Recursive Subdomain Enumeration
Recursively discover sub-subdomains under previously found names.

```bash
amass enum -recursive -d {{DOMAIN:domain}} -o {{OUTFILE:file:amass-recursive.txt}}
```

<!-- meta: risk=low | phase=recon | tags=recursive,deep -->

---

## Custom DNS Resolvers
Use specific DNS resolvers to avoid logging or rate limiting on the default ones.

```bash
amass enum -active -d {{DOMAIN:domain}} -r {{RESOLVERS:str:1.1.1.1,8.8.8.8}} -o {{OUTFILE:file:amass-resolvers.txt}}
```

<!-- meta: risk=low | phase=recon | tags=dns,resolvers,stealth -->

---

## Enumerate Through SOCKS Proxy
Route Amass traffic through a SOCKS5 proxy (e.g., Tor).

```bash
amass enum -active -d {{DOMAIN:domain}} -proxy {{PROXY:str:socks5://127.0.0.1:9050}}
```

<!-- meta: risk=low | phase=recon | tags=proxy,tor,socks -->

---

## CIDR-Based Discovery
Find domains hosted within a specific IP range.

```bash
amass intel -cidr {{SUBNET:cidr:192.168.0.0/24}}
```

<!-- meta: risk=safe | phase=recon | tags=intel,cidr,reverse -->

---

## Output Both TXT and JSON
Save enumeration results in human and machine-readable formats simultaneously.

```bash
amass enum -active -d {{DOMAIN:domain}} -o {{OUTFILE:file:amass.txt}} -json {{OUTJSON:file:amass.json}}
```

<!-- meta: risk=low | phase=recon | tags=output,json,txt -->
