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
