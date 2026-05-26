# Nuclei

> Fast vulnerability scanner powered by community-maintained YAML templates

<!-- tags: nuclei, vuln-scan, templates, automation, web -->

---

## scan url all templates
Scan a target URL using all default templates.

```bash
nuclei -u {{URL:url}} -o {{OUTFILE:file:nuclei-results.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=basic,all-templates,scan -->

---

## scan filter by severity
Scan using only templates of a specific severity level.

```bash
nuclei -u {{URL:url}} -s {{SEVERITY:str:critical,high}} -o {{OUTFILE:file:nuclei-severity.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=severity,filter,critical -->

---

## scan specific template
Run a targeted scan using a specific template or template directory.

```bash
nuclei -u {{URL:url}} -t {{TEMPLATE:str:cves/}} -o {{OUTFILE:file:nuclei-template.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=template,targeted,specific -->

---

## scan url list
Scan multiple targets from a file of URLs.

```bash
nuclei -l {{URLLIST:file:urls.txt}} -s critical,high,medium -o {{OUTFILE:file:nuclei-batch.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=batch,list,multi-target -->

---

## detect technologies fingerprint
Detect technologies and services without running vulnerability checks.

```bash
nuclei -u {{URL:url}} -t technologies/ -o {{OUTFILE:file:nuclei-tech.txt}}
```

<!-- meta: risk=safe | phase=enum | tags=tech-detect,fingerprint,safe -->

---

## scan rate-limited stealth
Scan with controlled request rate to avoid detection or target overload.

```bash
nuclei -u {{URL:url}} -rl {{RATE:int:50}} -c {{THREADS:int:5}} -s critical,high -o {{OUTFILE:file:nuclei-rated.txt}}
```

<!-- meta: risk=low | phase=vuln | tags=rate-limit,stealth,controlled -->

---

## scan headless browser
Run templates that require a headless browser for JavaScript-heavy targets.

```bash
nuclei -u {{URL:url}} -headless -t headless/ -o {{OUTFILE:file:nuclei-headless.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=headless,browser,javascript -->

---

## update templates
Download or update to the latest community templates.

```bash
nuclei -update-templates
```

<!-- meta: risk=safe | phase=misc | tags=update,templates,maintenance -->

---

## output json with evidence
Run a scan with detailed JSON output including matched evidence.

```bash
nuclei -u {{URL:url}} -s critical,high,medium -json -irr -o {{OUTFILE:file:nuclei-full.json}}
```

<!-- meta: risk=med | phase=vuln | tags=json,detailed,evidence -->

---

## scan sqli injection
Targeted scan for SQL injection vulnerabilities by tag.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags sqli -itags injection,sqli
```

<!-- meta: risk=med | phase=vuln | tags=sqli,injection,tag -->

---

## scan xss
Targeted scan for cross-site scripting issues.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags xss -itags xss
```

<!-- meta: risk=med | phase=vuln | tags=xss,tag -->

---

## scan ssrf
Scan for server-side request forgery.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags ssrf -itags ssrf
```

<!-- meta: risk=med | phase=vuln | tags=ssrf,tag -->

---

## scan subdomain takeover
Check subdomains for takeover vulnerabilities.

```bash
nuclei -l {{SUBDOMAINS:file:subdomains.txt}} -tags takeover -itags subdomain,takeover
```

<!-- meta: risk=med | phase=vuln | tags=takeover,subdomain -->

---

## scan path traversal lfi
Scan for directory traversal vulnerabilities.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags traversal -itags traversal,directory
```

<!-- meta: risk=med | phase=vuln | tags=traversal,lfi -->

---

## scan rce
Scan for known remote code execution vulnerabilities.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags rce -itags rce,code-execution
```

<!-- meta: risk=high | phase=vuln | tags=rce,exploitable -->

---

## scan default credentials
Probe for default credential exposures.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags creds -itags default,credentials
```

<!-- meta: risk=med | phase=vuln | tags=creds,default -->

---

## scan exposed git repos
Find publicly exposed .git directories.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags git -itags git,exposed
```

<!-- meta: risk=high | phase=vuln | tags=git,exposure -->

---

## scan cloud misconfig
Scan for AWS/GCP/Azure misconfigurations.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags cloud -itags cloud,aws,gcp,azure,misconfig
```

<!-- meta: risk=med | phase=vuln | tags=cloud,misconfig -->

---

## find login admin panels
Discover exposed admin/login panels.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags login -itags login,admin-panel
```

<!-- meta: risk=low | phase=enum | tags=login,panels -->

---

## scan wordpress vulns
WordPress-specific vulnerability scan.

```bash
nuclei -l {{URLLIST:file:wp-sites.txt}} -tags wordpress -itags wordpress,plugin
```

<!-- meta: risk=med | phase=vuln | tags=wordpress,cms -->

---

## classify phishing sites
Quickly classify URLs as phishing.

```bash
nuclei -l {{URLLIST:file:phishing-candidates.txt}} -tags phishing -itags phishing
```

<!-- meta: risk=safe | phase=recon | tags=phishing,classify -->

---

## scan by template tags
Run templates matching specific tags like cve, sqli, xss, etc.

```bash
nuclei -u {{URL:url}} -tags {{TAGS:str:cve,sqli,xss,lfi}} -o {{OUTFILE:file:nuclei-tags.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=template-tags,targeted,category -->
