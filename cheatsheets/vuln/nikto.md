# Nikto

> Web server scanner that tests for dangerous files, outdated software, and misconfigurations

<!-- tags: nikto, web, vuln-scan, misconfig, server -->

---

## scan web server
Run a standard scan against a target web server.

```bash
nikto -h {{URL:url}} -o {{OUTFILE:file:nikto-results.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=basic,web,server -->

---

## scan https SSL
Force SSL mode for scanning HTTPS targets.

```bash
nikto -h {{TARGET:ip}} -p {{PORT:port:443}} -ssl -o {{OUTFILE:file:nikto-ssl.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=ssl,https,tls -->

---

## scan custom port
Scan a web server running on a non-standard port.

```bash
nikto -h {{TARGET:ip}} -p {{PORT:port:8080}} -o {{OUTFILE:file:nikto-port.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=port,non-standard,custom -->

---

## output html report
Generate a formatted HTML report of scan findings.

```bash
nikto -h {{URL:url}} -Format htm -o {{OUTFILE:file:nikto-report.html}}
```

<!-- meta: risk=med | phase=vuln | tags=html,report,output -->

---

## scan specific test categories
Run only specific test categories (1=files, 2=misconfig, 3=info, 4=XSS, 9=SQL injection).

```bash
nikto -h {{URL:url}} -Tuning {{TUNING:str:1249}} -o {{OUTFILE:file:nikto-tuned.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=tuning,selective,categories -->

---

## scan with basic auth
Run a scan using HTTP basic authentication credentials.

```bash
nikto -h {{URL:url}} -id {{USERNAME:str}}:{{PASSWORD:str}} -o {{OUTFILE:file:nikto-auth.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=auth,authenticated,basic -->

---

## scan all cgi directories
Scan all possible CGI directories regardless of server type.

```bash
nikto -h {{URL:url}} -Cgidirs all -o {{OUTFILE:file:nikto-cgi.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=cgi,directories,exhaustive -->

---

## scan with evasion user-agent
Use evasion techniques and a custom user-agent to reduce detection.

```bash
nikto -h {{URL:url}} -useragent "{{USERAGENT:str:Mozilla/5.0 (Windows NT 10.0; Win64; x64)}}" -evasion {{EVASION:str:1}} -o {{OUTFILE:file:nikto-evasion.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=evasion,stealth,user-agent -->

---

## scan multiple hosts file
Scan a list of target hosts from a file.

```bash
nikto -h {{HOSTLIST:file:targets.txt}} -o {{OUTFILE:file:nikto-multi.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=batch,multi-host,list -->
