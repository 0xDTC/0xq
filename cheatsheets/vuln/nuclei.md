# Nuclei

> Fast vulnerability scanner powered by community-maintained YAML templates

<!-- tags: nuclei, vuln-scan, templates, automation, web -->

---

## Basic Vulnerability Scan
Scan a target URL using all default templates.

```bash
nuclei -u {{URL:url}} -o {{OUTFILE:file:nuclei-results.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=basic,all-templates,scan -->

---

## Filter by Severity
Scan using only templates of a specific severity level.

```bash
nuclei -u {{URL:url}} -s {{SEVERITY:str:critical,high}} -o {{OUTFILE:file:nuclei-severity.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=severity,filter,critical -->

---

## Scan with Specific Template
Run a targeted scan using a specific template or template directory.

```bash
nuclei -u {{URL:url}} -t {{TEMPLATE:str:cves/}} -o {{OUTFILE:file:nuclei-template.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=template,targeted,specific -->

---

## Scan URL List
Scan multiple targets from a file of URLs.

```bash
nuclei -l {{URLLIST:file:urls.txt}} -s critical,high,medium -o {{OUTFILE:file:nuclei-batch.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=batch,list,multi-target -->

---

## Technology Detection Only
Detect technologies and services without running vulnerability checks.

```bash
nuclei -u {{URL:url}} -t technologies/ -o {{OUTFILE:file:nuclei-tech.txt}}
```

<!-- meta: risk=safe | phase=enum | tags=tech-detect,fingerprint,safe -->

---

## Rate-Limited Scan
Scan with controlled request rate to avoid detection or target overload.

```bash
nuclei -u {{URL:url}} -rl {{RATE:int:50}} -c {{THREADS:int:5}} -s critical,high -o {{OUTFILE:file:nuclei-rated.txt}}
```

<!-- meta: risk=low | phase=vuln | tags=rate-limit,stealth,controlled -->

---

## Headless Browser Scan
Run templates that require a headless browser for JavaScript-heavy targets.

```bash
nuclei -u {{URL:url}} -headless -t headless/ -o {{OUTFILE:file:nuclei-headless.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=headless,browser,javascript -->

---

## Update Templates
Download or update to the latest community templates.

```bash
nuclei -update-templates
```

<!-- meta: risk=safe | phase=misc | tags=update,templates,maintenance -->

---

## JSON Output with Full Details
Run a scan with detailed JSON output including matched evidence.

```bash
nuclei -u {{URL:url}} -s critical,high,medium -json -irr -o {{OUTFILE:file:nuclei-full.json}}
```

<!-- meta: risk=med | phase=vuln | tags=json,detailed,evidence -->

---

## Detect SQL Injection
Targeted scan for SQL injection vulnerabilities by tag.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags sqli -itags injection,sqli
```

<!-- meta: risk=med | phase=vuln | tags=sqli,injection,tag -->

---

## Detect XSS
Targeted scan for cross-site scripting issues.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags xss -itags xss
```

<!-- meta: risk=med | phase=vuln | tags=xss,tag -->

---

## Detect SSRF
Scan for server-side request forgery.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags ssrf -itags ssrf
```

<!-- meta: risk=med | phase=vuln | tags=ssrf,tag -->

---

## Detect Subdomain Takeover
Check subdomains for takeover vulnerabilities.

```bash
nuclei -l {{SUBDOMAINS:file:subdomains.txt}} -tags takeover -itags subdomain,takeover
```

<!-- meta: risk=med | phase=vuln | tags=takeover,subdomain -->

---

## Detect Path Traversal
Scan for directory traversal vulnerabilities.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags traversal -itags traversal,directory
```

<!-- meta: risk=med | phase=vuln | tags=traversal,lfi -->

---

## Detect RCE
Scan for known remote code execution vulnerabilities.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags rce -itags rce,code-execution
```

<!-- meta: risk=high | phase=vuln | tags=rce,exploitable -->

---

## Detect Default Credentials
Probe for default credential exposures.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags creds -itags default,credentials
```

<!-- meta: risk=med | phase=vuln | tags=creds,default -->

---

## Detect Exposed Git Repositories
Find publicly exposed .git directories.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags git -itags git,exposed
```

<!-- meta: risk=high | phase=vuln | tags=git,exposure -->

---

## Detect Cloud Misconfigurations
Scan for AWS/GCP/Azure misconfigurations.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags cloud -itags cloud,aws,gcp,azure,misconfig
```

<!-- meta: risk=med | phase=vuln | tags=cloud,misconfig -->

---

## Detect Login Panels
Discover exposed admin/login panels.

```bash
nuclei -l {{URLLIST:file:targets.txt}} -tags login -itags login,admin-panel
```

<!-- meta: risk=low | phase=enum | tags=login,panels -->

---

## Detect WordPress Vulns
WordPress-specific vulnerability scan.

```bash
nuclei -l {{URLLIST:file:wp-sites.txt}} -tags wordpress -itags wordpress,plugin
```

<!-- meta: risk=med | phase=vuln | tags=wordpress,cms -->

---

## Detect Phishing Sites
Quickly classify URLs as phishing.

```bash
nuclei -l {{URLLIST:file:phishing-candidates.txt}} -tags phishing -itags phishing
```

<!-- meta: risk=safe | phase=recon | tags=phishing,classify -->

---

## Scan by Template Tags
Run templates matching specific tags like cve, sqli, xss, etc.

```bash
nuclei -u {{URL:url}} -tags {{TAGS:str:cve,sqli,xss,lfi}} -o {{OUTFILE:file:nuclei-tags.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=template-tags,targeted,category -->
