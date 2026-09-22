# Nikto

> Web server scanner that tests for dangerous files, outdated software, and misconfigurations

<!-- tags: nikto, web, vuln-scan, misconfig, server -->

> **User-Agent policy:** every command below sends a real-browser UA (default: Chrome 131 on Windows). Override at fill time. Alternate UAs to paste in when the default is fingerprinted:
> - Firefox 128 Linux: `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0`
> - Safari 17 macOS: `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15`

---

## scan web server
Run a standard scan against a target web server.

```bash
nikto -h {{URL:url}} -useragent "{{UA:str:$(q-ua)}}" -o {{OUTFILE:file:nikto-results.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=basic,web,server -->

---

## scan https SSL
Force SSL mode for scanning HTTPS targets.

```bash
nikto -h {{TARGET:ip}} -p {{PORT:port:443}} -ssl -useragent "{{UA:str:$(q-ua)}}" -o {{OUTFILE:file:nikto-ssl.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=ssl,https,tls -->

---

## scan custom port
Scan a web server running on a non-standard port.

```bash
nikto -h {{TARGET:ip}} -p {{PORT:port:8080}} -useragent "{{UA:str:$(q-ua)}}" -o {{OUTFILE:file:nikto-port.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=port,non-standard,custom -->

---

## output html report
Generate a formatted HTML report of scan findings.

```bash
nikto -h {{URL:url}} -useragent "{{UA:str:$(q-ua)}}" -Format htm -o {{OUTFILE:file:nikto-report.html}}
```

<!-- meta: risk=med | phase=vuln | tags=html,report,output -->

---

## scan specific test categories
Run only specific test categories (1=files, 2=misconfig, 3=info, 4=XSS, 9=SQL injection).

```bash
nikto -h {{URL:url}} -useragent "{{UA:str:$(q-ua)}}" -Tuning {{TUNING:choice:1249=files+misconfig+xss+sqli preset,1=interesting files,2=misconfig/default files,3=information disclosure,4=xss/injection,5=remote file retrieval,6=denial of service,8=command execution,9=SQL injection,0=file upload,a=auth bypass,b=software identification,c=remote source inclusion,x=reverse tuning (exclude)}} -o {{OUTFILE:file:nikto-tuned.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=tuning,selective,categories -->

---

## scan with basic auth
Run a scan using HTTP basic authentication credentials.

```bash
nikto -h {{URL:url}} -id {{USERNAME:str}}:{{PASSWORD:str}} -useragent "{{UA:str:$(q-ua)}}" -o {{OUTFILE:file:nikto-auth.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=auth,authenticated,basic -->

---

## scan all cgi directories
Scan all possible CGI directories regardless of server type.

```bash
nikto -h {{URL:url}} -useragent "{{UA:str:$(q-ua)}}" -Cgidirs all -o {{OUTFILE:file:nikto-cgi.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=cgi,directories,exhaustive -->

---

## scan with evasion user-agent
Use evasion techniques and a custom user-agent to reduce detection.

```bash
nikto -h {{URL:url}} -useragent "{{UA:str:$(q-ua)}}" -evasion {{EVASION:choice:1=random URI encoding,2=self-reference dirs,3=premature URL ending,4=prepend long string,5=fake parameter,6=TAB request separator,7=URL case change,8=Windows dir separator,A=carriage return separator,B=binary line feed,C=session splicing}} -o {{OUTFILE:file:nikto-evasion.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=evasion,stealth,user-agent -->

---

## scan multiple hosts file
Scan a list of target hosts from a file.

```bash
nikto -h {{HOSTLIST:file:targets.txt}} -useragent "{{UA:str:$(q-ua)}}" -o {{OUTFILE:file:nikto-multi.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=batch,multi-host,list -->
