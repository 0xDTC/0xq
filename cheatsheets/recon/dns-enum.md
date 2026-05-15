# DNS Enumeration

> DNS reconnaissance using dig, host, fierce, dnsenum, and dnsrecon

<!-- tags: dns, dig, host, fierce, dnsenum, dnsrecon, zone-transfer, recon -->

---

## DNS Zone Transfer (dig)
Attempt a full zone transfer against the target's nameserver.

```bash
dig axfr {{DOMAIN:domain}} @{{NAMESERVER:ip}}
```

<!-- meta: risk=low | phase=recon | tags=zone-transfer,axfr,dig -->

---

## Query All DNS Record Types (dig)
Retrieve all available DNS records for a domain.

```bash
dig any {{DOMAIN:domain}} +noall +answer
```

<!-- meta: risk=safe | phase=recon | tags=dig,records,any -->

---

## MX and TXT Record Lookup (dig)
Enumerate mail exchange and TXT records including SPF and DKIM.

```bash
dig {{DOMAIN:domain}} MX +short && dig {{DOMAIN:domain}} TXT +short
```

<!-- meta: risk=safe | phase=recon | tags=mx,txt,spf,mail -->

---

## Reverse DNS Lookup (host)
Resolve an IP address back to its hostname.

```bash
host {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=reverse,ptr,host -->

---

## DNS Brute Force (fierce)
Brute force subdomains using fierce with a wordlist.

```bash
fierce --domain {{DOMAIN:domain}} --subdomain-file {{WORDLIST:wordlist:/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt}}
```

<!-- meta: risk=low | phase=recon | tags=fierce,bruteforce,subdomains -->

---

## Full DNS Enumeration (dnsenum)
Comprehensive DNS enumeration including zone transfers, brute force, and Google scraping.

```bash
dnsenum --enum -f {{WORDLIST:wordlist:/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt}} --threads {{THREADS:int:10}} {{DOMAIN:domain}}
```

<!-- meta: risk=low | phase=recon | tags=dnsenum,comprehensive,enum -->

---

## Standard DNS Recon (dnsrecon)
Run standard DNS reconnaissance covering common record types and zone transfers.

```bash
dnsrecon -d {{DOMAIN:domain}} -t std
```

<!-- meta: risk=safe | phase=recon | tags=dnsrecon,standard,records -->

---

## DNS Brute Force (dnsrecon)
Brute force subdomains using dnsrecon with a custom wordlist.

```bash
dnsrecon -d {{DOMAIN:domain}} -t brt -D {{WORDLIST:wordlist:/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt}}
```

<!-- meta: risk=low | phase=recon | tags=dnsrecon,bruteforce,subdomains -->

---

## Reverse DNS Sweep (dnsrecon)
Perform reverse DNS lookups across a CIDR range to discover hostnames.

```bash
dnsrecon -r {{SUBNET:cidr:192.168.1.0/24}} -t rvl
```

<!-- meta: risk=safe | phase=recon | tags=dnsrecon,reverse,sweep,cidr -->

---

## DNS Cache Snooping (dnsrecon)
Check if a DNS server has cached records for specific domains.

```bash
dnsrecon -t snoop -n {{NAMESERVER:ip}} -D {{DOMAINLIST:file:domains.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=dnsrecon,cache,snooping -->

---

## DNS Trace Path (dig)
Trace the full path of a DNS query from root servers to authoritative ones, useful for hijack detection.

```bash
dig +trace {{DOMAIN:domain}}
```

<!-- meta: risk=safe | phase=recon | tags=dig,trace,hijack -->

---

## DNSSEC Validation Check (dig)
Query the domain with DNSSEC enabled to confirm signed responses.

```bash
dig {{DOMAIN:domain}} +dnssec +multiline
```

<!-- meta: risk=safe | phase=recon | tags=dig,dnssec,validation -->

---

## Reverse DNS Sweep over Subnet (dig loop)
Bash loop to perform reverse DNS lookup over a /24 subnet using dig.

```bash
for ip in $(seq 1 254); do dig -x {{SUBNET_PREFIX:str:192.168.1}}.$ip +short; done
```

<!-- meta: risk=safe | phase=recon | tags=dig,reverse,loop,sweep -->

---

## Subdomain Brute Force via dig Loop
Iterate a wordlist of candidate subdomains and resolve each via dig.

```bash
for sub in $(cat {{WORDLIST:wordlist:/usr/share/seclists/Discovery/DNS/fierce-hostlist.txt}}); do dig $sub.{{DOMAIN:domain}} @{{NAMESERVER:ip}} +short | grep -v -E '^(;|$)'; done
```

<!-- meta: risk=low | phase=recon | tags=dig,bruteforce,loop -->

---

## Subdomain Takeover Hunt (dig CNAME)
Resolve a subdomain's CNAME chain to look for unclaimed third-party services.

```bash
dig {{SUBDOMAIN:domain}} CNAME +short
```

<!-- meta: risk=safe | phase=recon | tags=dig,cname,takeover -->
