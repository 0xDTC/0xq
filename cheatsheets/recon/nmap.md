# Nmap

> Network discovery and security auditing with the most versatile port scanner

<!-- tags: nmap, port-scan, network, discovery, recon -->

---

## sweep live hosts ping
Discover live hosts on a subnet without port scanning.

```bash
sudo nmap -sn {{SUBNET:cidr:192.168.1.0/24}} -oG {{OUTFILE:file:ping-sweep.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=ping,sweep,discovery -->

---

## scan quick SYN stealth
Fast stealth SYN scan against the most common ports.

```bash
sudo nmap -sS {{TARGET:ip}} -oN {{OUTFILE:file:syn-scan.txt}}
```

<!-- meta: risk=low | phase=recon | tags=syn,stealth,fast -->

---

## scan all ports TCP
Scan all 65535 TCP ports with service detection.

```bash
sudo nmap -A -sC -sS -v -p- {{TARGET:ip}} -oN {{OUTFILE:file:full-port.txt}}
```

<!-- meta: risk=low | phase=recon | tags=full,all-ports,tcp -->

---

## scan udp services
Scan common UDP services. Slow but finds DNS, SNMP, TFTP, etc.

```bash
sudo nmap -sU -sS -v {{TARGET:ip}} -oN {{OUTFILE:file:udp-scan.txt}}
```

<!-- meta: risk=low | phase=recon | tags=udp,services -->

---

## scan service version OS detection
Enumerate service versions and attempt OS fingerprinting.

```bash
sudo nmap -sV -sC -O -p {{PORTS:port:22,80,443}} {{TARGET:ip}} -oN {{OUTFILE:file:version-scan.txt}}
```

<!-- meta: risk=low | phase=enum | tags=version,os,fingerprint -->

---

## scan aggressive all ports
Full enumeration with OS detection, version scanning, scripts, and traceroute.

```bash
sudo nmap -A -T4 -p- {{TARGET:ip}} -oA {{OUTFILE:file:aggressive-scan}}
```

<!-- meta: risk=med | phase=enum | tags=aggressive,comprehensive -->

---

## scan vuln NSE
Run NSE vulnerability detection scripts against discovered services.

```bash
sudo nmap --script vuln -p {{PORTS:port:22,80,443,445}} {{TARGET:ip}} -oN {{OUTFILE:file:vuln-scan.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=nse,vuln,scripts -->

---

## scan targeted NSE script
Run a targeted NSE script against the target.

```bash
sudo nmap --script {{SCRIPT:str:http-enum}} -p {{PORTS:port:80,443}} {{TARGET:ip}} -oN {{OUTFILE:file:nse-output.txt}}
```

<!-- meta: risk=med | phase=enum | tags=nse,targeted,scripts -->

---

## sweep subnet service port
Scan an entire subnet for a specific service port.

```bash
sudo nmap -sS -p {{PORTS:port:445}} {{SUBNET:cidr:192.168.1.0/24}} --open -oG {{OUTFILE:file:subnet-sweep.txt}}
```

<!-- meta: risk=low | phase=recon | tags=subnet,sweep,service -->

---

## scan firewall evasion stealth
Fragmented packets with decoy addresses to evade IDS/firewall detection.

```bash
sudo nmap -sS -f -D RND:5 --data-length 24 -T2 -p {{PORTS:port:80,443}} {{TARGET:ip}} -oN {{OUTFILE:file:evasion-scan.txt}}
```

<!-- meta: risk=med | phase=recon | tags=evasion,firewall,stealth -->

---

## scan full
Aggressive full scan: OS, version detection, default scripts, verbose.

```bash
sudo nmap -A -sC -sS -v {{TARGET:ip}} -oN nmap
```

<!-- meta: risk=low | phase=recon | tags=full,aggressive,scripts -->

---

## scan full fast
Same aggressive full scan, rate-capped to go faster.

```bash
sudo nmap -A -sC -sS -v --max-rate=1500 {{TARGET:ip}} -oN nmap
```

<!-- meta: risk=low | phase=recon | tags=full,fast,max-rate -->

---

## fast tcp port discovery nmap
Fast TCP all-ports discovery with --min-rate (no service detection — just which ports are open). Pipe the -oG output through `grep '/open/tcp'` to feed -p next.

```bash
sudo nmap -p- --min-rate {{MIN_RATE:int:5000}} -T4 -v -Pn {{TARGET:ip}} -oG {{OUTFILE:file:tcp-ports.gnmap}}
```

<!-- meta: risk=low | phase=recon | tags=tcp,fast,discovery,all-ports,min-rate -->

---

## deep tcp scan ports nmap
Deep TCP scan with -A -sV against pre-discovered ports; writes a markdown report named after the target. Set PORTS first (e.g. `q set PORTS 22,80,443`) or run via the `nmap_tcp` chain.

```bash
sudo nmap -A -sS -sV -v -p {{PORTS:str}} --max-rate {{RATE:int:1000}} {{TARGET:ip}} -oN {{TARGET:ip}}.md
```

<!-- meta: risk=low | phase=enum | tags=tcp,deep,version,aggressive,report -->

---

## fast udp top ports discovery nmap
Fast UDP top-100 ports discovery (UDP is intrinsically slow; top-100 is the pragmatic compromise vs -p-).

```bash
sudo nmap -sU --top-ports 100 -v --max-rate {{RATE:int:1000}} -Pn {{TARGET:ip}} -oG {{OUTFILE:file:udp-top.gnmap}}
```

<!-- meta: risk=low | phase=recon | tags=udp,fast,top-ports,discovery -->

---

## fast udp all ports discovery nmap
Exhaustive UDP all-ports discovery (-p-) — slow but thorough; use when top-100 came back too thin.

```bash
sudo nmap -sU -p- --min-rate {{MIN_RATE:int:1000}} -v -Pn {{TARGET:ip}} -oG {{OUTFILE:file:udp-all.gnmap}}
```

<!-- meta: risk=low | phase=recon | tags=udp,all-ports,thorough,min-rate -->

---

## deep udp scan ports nmap
Deep UDP scan with version detection on pre-discovered ports; markdown report.

```bash
sudo nmap -A -sU -sV -v -p {{PORTS:str}} --max-rate {{RATE:int:1000}} {{TARGET:ip}} -oN {{TARGET:ip}}-udp.md
```

<!-- meta: risk=low | phase=enum | tags=udp,deep,version,report -->

---

## combined tcp udp deep scan nmap
Single deep scan combining TCP + UDP on pre-discovered ports (set TCP_PORTS and UDP_PORTS). One report covers both.

```bash
sudo nmap -A -sS -sU -sV -v -p T:{{TCP_PORTS:str}},U:{{UDP_PORTS:str}} --max-rate {{RATE:int:1000}} {{TARGET:ip}} -oN {{TARGET:ip}}-full.md
```

<!-- meta: risk=low | phase=enum | tags=tcp,udp,combined,deep,report -->

---

## extract open ports from gnmap
Pull a comma-separated port list from an nmap -oG file — feed the result back into -p N,N,N.

```bash
grep -oE '[0-9]+/open/{{PROTO:str:tcp}}' {{INFILE:file:tcp-ports.gnmap}} | cut -d/ -f1 | paste -sd,
```

<!-- meta: risk=safe | phase=recon | tags=parse,ports,extract,gnmap,utility -->

---
