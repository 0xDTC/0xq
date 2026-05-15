# SearchSploit

> Command-line interface to the Exploit-DB archive for offline exploit searching

<!-- tags: searchsploit, exploit-db, exploits, cve, vulnerability -->

---

## Basic Exploit Search
Search for exploits matching keywords in title and path.

```bash
searchsploit {{QUERY:str:apache 2.4}}
```

<!-- meta: risk=safe | phase=vuln | tags=search,basic,exploits -->

---

## Exact Match Search
Search using exact match to reduce false positives.

```bash
searchsploit -e "{{QUERY:str:Microsoft IIS 10.0}}"
```

<!-- meta: risk=safe | phase=vuln | tags=exact,precise,search -->

---

## Title-Only Search
Search only exploit titles, excluding file paths from results.

```bash
searchsploit -t "{{QUERY:str:privilege escalation}}"
```

<!-- meta: risk=safe | phase=vuln | tags=title,filtered,search -->

---

## Show Exploit-DB URL
Display the Exploit-DB URL for each result for online viewing.

```bash
searchsploit -w {{QUERY:str:wordpress 5}}
```

<!-- meta: risk=safe | phase=vuln | tags=url,exploit-db,reference -->

---

## Mirror (Copy) Exploit to Current Directory
Copy an exploit file to the current working directory for review or modification.

```bash
searchsploit -m {{EXPLOIT_ID:str:50383}}
```

<!-- meta: risk=safe | phase=vuln | tags=mirror,copy,download -->

---

## Examine Exploit Source Code
Display the full source code of an exploit for analysis.

```bash
searchsploit -x {{EXPLOIT_ID:str:50383}}
```

<!-- meta: risk=safe | phase=vuln | tags=examine,source,read -->

---

## Parse Nmap XML for Exploits
Automatically search for exploits matching services found in an nmap XML scan.

```bash
searchsploit --nmap {{NMAPXML:file:scan-results.xml}}
```

<!-- meta: risk=safe | phase=vuln | tags=nmap,automated,service-match -->

---

## JSON Output
Output search results in JSON format for scripting and automation.

```bash
searchsploit -j {{QUERY:str:ssh}} | tee {{OUTFILE:file:searchsploit.json}}
```

<!-- meta: risk=safe | phase=vuln | tags=json,automation,output -->

---

## Update Exploit Database
Update the local Exploit-DB database to the latest version.

```bash
searchsploit -u
```

<!-- meta: risk=safe | phase=misc | tags=update,database,maintenance -->

---

## Exclude Denial of Service Results
Search for exploits while filtering out DoS-only results.

```bash
searchsploit {{QUERY:str:apache}} --exclude="Denial of Service"
```

<!-- meta: risk=safe | phase=vuln | tags=filter,exclude,dos -->
