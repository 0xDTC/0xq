# Subfinder

> Fast passive subdomain discovery tool using multiple online sources

<!-- tags: subfinder, subdomains, passive, recon, osint -->

---

## Basic Subdomain Enumeration
Discover subdomains for a target domain using default sources.

```bash
subfinder -d {{DOMAIN:domain}} -o {{OUTFILE:file:subdomains.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=subdomains,passive,basic -->

---

## Silent Mode (Clean Output)
Output only discovered subdomains with no banner or status info.

```bash
subfinder -d {{DOMAIN:domain}} -silent
```

<!-- meta: risk=safe | phase=recon | tags=subdomains,silent,pipe -->

---

## Recursive Subdomain Enumeration
Recursively enumerate subdomains of discovered subdomains.

```bash
subfinder -d {{DOMAIN:domain}} -recursive -o {{OUTFILE:file:recursive-subs.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=subdomains,recursive,deep -->

---

## Enumerate from Domain List
Run subdomain discovery against multiple domains from a file.

```bash
subfinder -dL {{DOMAINLIST:file:domains.txt}} -o {{OUTFILE:file:all-subdomains.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=subdomains,batch,list -->

---

## With Specific Sources
Use only specified data sources for enumeration.

```bash
subfinder -d {{DOMAIN:domain}} -sources crtsh,virustotal,shodan,chaos -o {{OUTFILE:file:sourced-subs.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=subdomains,sources,selective -->

---

## High-Performance with Threading
Increase concurrency for faster enumeration on large targets.

```bash
subfinder -d {{DOMAIN:domain}} -t {{THREADS:int:50}} -timeout {{TIMEOUT:int:30}} -o {{OUTFILE:file:fast-subs.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=subdomains,fast,threads -->

---

## JSON Output with All Fields
Output results in JSON format including source information.

```bash
subfinder -d {{DOMAIN:domain}} -json -o {{OUTFILE:file:subdomains.json}}
```

<!-- meta: risk=safe | phase=recon | tags=subdomains,json,detailed -->

---

## Exclude Specific Sources
Enumerate using all sources except specified ones.

```bash
subfinder -d {{DOMAIN:domain}} -es github,rapiddns -o {{OUTFILE:file:filtered-subs.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=subdomains,exclude,filter -->

---

## Pipe Through httpx for Live Hosts
Probe each discovered subdomain to find live HTTP services.

```bash
subfinder -d {{DOMAIN:domain}} -silent | httpx -silent -mc 200,301,302 > {{OUTFILE:file:live-subs.txt}}
```

<!-- meta: risk=low | phase=recon | tags=subfinder,httpx,live -->
