# nmap

> Only the patterns you actually use. Nine entries, nothing extra.

<!-- tags: nmap, scan, recon, tcp, udp, smb, vhost -->

---

## fast all ports then deep service scan
**Preferred recipe.** Two stages chained with `&&`:
1. Blazing-fast all-port TCP sweep (`-p- --min-rate 1500 -T4 -Pn`) writes grep-friendly output to `/tmp/q-tcp-<ip>.gnmap`
2. Deep `-A -sS -sV` scan runs ONLY against the open ports pulled from stage 1 — saves ~10× time vs `-A -p-` directly.

Final output lands in `<ip>.md` next to your notes so grepping / linking is trivial.

```bash
sudo nmap -p- --min-rate {{RATE_FAST:int:1500}} -T4 -v -Pn {{TARGET:ip}} -oG /tmp/q-tcp-{{TARGET:ip}}.gnmap && sudo nmap -A -sS -sV -v -p "$(grep -oE '[0-9]+/open/tcp' /tmp/q-tcp-{{TARGET:ip}}.gnmap | cut -d/ -f1 | paste -sd,)" --max-rate {{RATE_SLOW:int:1000}} {{TARGET:ip}} -oN {{TARGET:ip}}.md
```

<!-- meta: risk=low | phase=recon | tags=tcp,two-stage,fast,deep,recipe,preferred -->

---

## tcp scan full ports
Baseline — all 65k TCP ports, aggressive (-A = sV + sC + O + traceroute), reasons shown, verbose, output to file.

```bash
sudo nmap -A -sC -sV -p- --reason -v {{TARGET:ip}} -oN {{OUT:file:nmap}}
```

<!-- meta: risk=low | phase=recon | tags=tcp,full,aggressive -->

---

## udp scan common services
UDP scan with --min-rate 1000 (otherwise glacial). Default top-1k UDP ports; add -p- if you want all.

```bash
sudo nmap -sU -sC -sV --reason -v --min-rate={{RATE:int:1000}} {{TARGET:ip}} -oN {{OUT:file:UDPnmap}}
```

<!-- meta: risk=low | phase=recon | tags=udp,rate -->

---

## ctf scan quick
Fast first-pass against HTB/CTF boxes — top 1k TCP ports, aggressive, no file output (you'll pivot to full-port shortly).

```bash
sudo nmap -A -sC -sV --reason -v {{TARGET:ip}}
```

<!-- meta: risk=low | phase=recon | tags=ctf,quick,top1k -->

---

## ctf scan all ports
Same as above but with `-p-` — all 65k. The one you leave running while you go through top-1k results.

```bash
sudo nmap -A -sC -sV --reason -p- -v {{TARGET:ip}}
```

<!-- meta: risk=low | phase=recon | tags=ctf,full,all-ports -->

---

## scan exclude cloudflare ports
Multichoice-pick which Cloudflare proxy ports to exclude (pre-checked all 11). dig/httpx of a CF-fronted target otherwise wastes time scanning CF-managed ports.

```bash
sudo nmap -A -sV -sC -p- -v --reason --exclude-ports={{EXCLUDE:multichoice:8080=CF HTTP alt,8880=CF HTTP alt,2052=CF HTTP alt,2082=CF HTTP alt,2086=CF HTTP alt,2095=CF HTTP alt,2053=CF HTTPS alt,2083=CF HTTPS alt,2087=CF HTTPS alt,2096=CF HTTPS alt,8443=CF HTTPS alt}} {{TARGET:ip}}
```

<!-- meta: risk=low | phase=recon | tags=cloudflare,exclude,multichoice -->

---

## smb protocol enumeration script
NSE script that lists which SMB dialects a target supports (SMB1/2/3). First check before trying auth.

```bash
nmap -p 445 --script smb-protocols {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=smb,nse,protocol -->

---

## smb vulnerability scan multi
Checklist of common smb-vuln-* NSE scripts (ms17-010 EternalBlue, cve-2017-7494 SambaCry, ms08-067, cve-2009-3103, regsvc-dos, webexec, DoublePulsar). All pre-checked; uncheck to skip. Shell wraps the picks into comma-separated --script arg.

```bash
sudo nmap -p 445 --script="{{SCRIPTS:multichoice:smb-vuln-ms17-010=EternalBlue CVE-2017-0144,smb-vuln-cve-2017-7494=SambaCry CVE-2017-7494,smb-vuln-ms08-067=netapi RCE CVE-2008-4250,smb-vuln-cve-2009-3103=Vista/2008 SMBv2 DoS,smb-vuln-regsvc-dos=regsvc DoS,smb-vuln-webexec=WebExService RCE,smb-double-pulsar-backdoor=DoublePulsar backdoor check}}" {{TARGET:ip}}
```

<!-- meta: risk=medium | phase=enum | tags=smb,vuln,nse,multichoice -->

---

## scan with parallelism bulk list
From an IP-list file, with tight parallelism caps so you don't blow the engagement's rate limits.

```bash
sudo nmap -v -A -sC -sS -sV --min-parallelism {{MIN:int:5}} --max-parallelism {{MAX:int:30}} -Pn -iL {{LIST:file:newlist}} -oN {{OUT:file:gggg}}
```

<!-- meta: risk=low | phase=recon | tags=bulk,parallelism,iL -->

---

## scan vhost enumeration script
NSE http-vhosts script against discovered web ports (80 + 443). Supply the base domain + a known hostname so it can brute neighboring vhosts.

```bash
sudo nmap -A -sS -sV -v --script http-vhosts --script-args http-vhosts.domain={{DOMAIN:domain}},host={{HOSTNAME:str}} -p80,443 {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=vhost,http-vhosts,nse,script-args -->
