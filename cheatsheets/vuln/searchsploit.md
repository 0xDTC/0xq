# SearchSploit

> Command-line interface to the Exploit-DB archive for offline exploit searching

<!-- tags: searchsploit, exploit-db, exploits, cve, vulnerability -->

---

## search exploits
Search for exploits matching keywords in title and path.

```bash
searchsploit {{QUERY:str:apache 2.4}}
```

<!-- meta: risk=safe | phase=vuln | tags=search,basic,exploits -->

---

## search exploits exact
Search using exact match to reduce false positives.

```bash
searchsploit -e "{{QUERY:str:Microsoft IIS 10.0}}"
```

<!-- meta: risk=safe | phase=vuln | tags=exact,precise,search -->

---

## search exploits title
Search only exploit titles, excluding file paths from results.

```bash
searchsploit -t "{{QUERY:str:privilege escalation}}"
```

<!-- meta: risk=safe | phase=vuln | tags=title,filtered,search -->

---

## show exploit url
Display the Exploit-DB URL for each result for online viewing.

```bash
searchsploit -w {{QUERY:str:wordpress 5}}
```

<!-- meta: risk=safe | phase=vuln | tags=url,exploit-db,reference -->

---

## mirror exploit local
Copy an exploit file to the current working directory for review or modification.

```bash
searchsploit -m {{EXPLOIT_ID:str:50383}}
```

<!-- meta: risk=safe | phase=vuln | tags=mirror,copy,download -->

---

## examine exploit source
Display the full source code of an exploit for analysis.

```bash
searchsploit -x {{EXPLOIT_ID:str:50383}}
```

<!-- meta: risk=safe | phase=vuln | tags=examine,source,read -->

---

## search exploits nmap xml
Automatically search for exploits matching services found in an nmap XML scan.

```bash
searchsploit --nmap {{NMAPXML:file:scan-results.xml}}
```

<!-- meta: risk=safe | phase=vuln | tags=nmap,automated,service-match -->

---

## search exploits json
Output search results in JSON format for scripting and automation.

```bash
searchsploit -j {{QUERY:str:ssh}} | tee {{OUTFILE:file:searchsploit.json}}
```

<!-- meta: risk=safe | phase=vuln | tags=json,automation,output -->

---

## update exploitdb
Update the local Exploit-DB database to the latest version.

```bash
searchsploit -u
```

<!-- meta: risk=safe | phase=misc | tags=update,database,maintenance -->

---

## search exploits exclude dos
Search for exploits while filtering out DoS-only results.

```bash
searchsploit {{QUERY:str:apache}} --exclude="Denial of Service"
```

<!-- meta: risk=safe | phase=vuln | tags=filter,exclude,dos -->
