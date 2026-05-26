# Shodan

> Internet-wide search engine for exposed devices, services, and vulnerabilities

<!-- tags: shodan, osint, recon, search, internet -->

---

## init API key
Save your Shodan API key locally for CLI use.

```bash
shodan init {{API_KEY:str}}
```

<!-- meta: risk=safe | phase=recon | tags=shodan,init,api -->

---

## show account credits
Show plan, query, and scan credit balance.

```bash
shodan info
```

<!-- meta: risk=safe | phase=recon | tags=shodan,info,credits -->

---

## lookup host IP
Get all indexed information for a single IP address.

```bash
shodan host {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=shodan,host,lookup -->

---

## submit active scan target
Trigger Shodan to actively scan a target IP, range, or subnet.

```bash
shodan scan submit {{TARGET:str:8.8.8.8/24}}
```

<!-- meta: risk=low | phase=recon | tags=shodan,scan,active -->

---

## submit active scan specific ports
Scan a target restricted to specific TCP ports.

```bash
shodan scan submit {{TARGET:ip}} --ports {{PORTS:str:80,443,22}}
```

<!-- meta: risk=low | phase=recon | tags=shodan,scan,ports -->

---

## list submitted scans
Show all scan jobs you have queued or completed.

```bash
shodan scan list
```

<!-- meta: risk=safe | phase=recon | tags=shodan,scan,list -->

---

## search vuln by CVE
Find devices indexed as vulnerable to a specific CVE.

```bash
shodan search "vuln:{{CVE:str:CVE-2022-26134}}"
```

<!-- meta: risk=safe | phase=recon | tags=shodan,cve,vuln -->

---

## search by open port
Find devices with a specific port open.

```bash
shodan search "port:{{PORT:port:22}}"
```

<!-- meta: risk=safe | phase=recon | tags=shodan,port,search -->

---

## search assets by org
Find assets indexed under a specific organization name.

```bash
shodan search "org:\"{{ORG:str:Example Corp}}\""
```

<!-- meta: risk=safe | phase=recon | tags=shodan,org,asset -->

---

## search by ASN
Find devices belonging to a specific Autonomous System.

```bash
shodan search "asn:{{ASN:str:AS15169}}"
```

<!-- meta: risk=safe | phase=recon | tags=shodan,asn,as -->

---

## search by country city geo
Filter results to a specific geography.

```bash
shodan search "country:{{COUNTRY:str:US}} city:\"{{CITY:str:New York}}\""
```

<!-- meta: risk=safe | phase=recon | tags=shodan,geo,country,city -->

---

## search by product fingerprint
Find systems running a specific product (e.g., mongodb, elasticsearch).

```bash
shodan search "product:{{PRODUCT:str:mongodb}}"
```

<!-- meta: risk=safe | phase=recon | tags=shodan,product,fingerprint -->

---

## search within IP range CIDR
Filter results to a CIDR or subnet.

```bash
shodan search "{{QUERY:str:apache}} net:{{CIDR:cidr}}"
```

<!-- meta: risk=safe | phase=recon | tags=shodan,net,range -->

---

## search by SSL cert issuer
Find hosts whose TLS certificate was issued by a specific CN.

```bash
shodan search "ssl.cert.issuer.cn:{{ISSUER:str:Lets Encrypt}}"
```

<!-- meta: risk=safe | phase=recon | tags=shodan,ssl,cert -->

---

## find expired SSL certs
List exposed services with expired TLS certificates.

```bash
shodan search "ssl.cert.expired:true"
```

<!-- meta: risk=safe | phase=recon | tags=shodan,ssl,expired -->

---

## search by tag ICS webcam
Find hosts tagged by Shodan (industrial control, compromised, webcams).

```bash
shodan search "tag:{{TAG:str:ics}}"
```

<!-- meta: risk=safe | phase=recon | tags=shodan,tag,ics -->

---

## aggregate stats facets
Aggregate top values by facet (e.g., top ports for an org).

```bash
shodan stats "{{QUERY:str:apache}}" --facets {{FACET:str:port}} --limit {{LIMIT:int:10}}
```

<!-- meta: risk=safe | phase=recon | tags=shodan,stats,facets -->

---

## search after date filter
Restrict search results to indexed entries after a date.

```bash
shodan search "{{QUERY:str:product:apache}}" --after "{{DATE:str:2023-01-01}}"
```

<!-- meta: risk=safe | phase=recon | tags=shodan,date,filter -->

---

## export results fields to file
Save selected fields from a search to a file.

```bash
shodan search "{{QUERY:str:port:22}}" --limit {{LIMIT:int:1000}} --fields ip_str,port,hostnames > {{OUTFILE:file:shodan-results.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=shodan,export,fields -->

---

## list supported protocols
Print all protocols Shodan can fingerprint.

```bash
shodan protocols
```

<!-- meta: risk=safe | phase=recon | tags=shodan,protocols,reference -->
