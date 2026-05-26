# GF

> Pattern wrapper for grep used in bug bounty pipelines to match URL classes

<!-- tags: gf,grep,patterns,bugbounty -->

---

## list patterns
Show all installed patterns.

```bash
gf -list
```

<!-- meta: risk=safe | phase=recon | tags=list -->

---

## filter urls by pattern xss sqli
Pipe URL list through a gf pattern (xss, sqli, ssrf, lfi, redirect, etc.).

```bash
cat {{URLS:file:urls.txt}} | gf {{PATTERN:str:xss}}
```

<!-- meta: risk=safe | phase=recon | tags=filter -->

---

## filter waybackurls vuln candidates
Pull historical URLs and filter for vulnerability candidates.

```bash
waybackurls {{DOMAIN:domain}} | gf {{PATTERN:str:sqli}}
```

<!-- meta: risk=safe | phase=recon | tags=waybackurls,combo -->

---

## install patterns setup
One-liner install and pattern bundle setup.

```bash
go install github.com/tomnomnom/gf@latest && sudo cp ~/go/bin/gf /usr/bin/ && mkdir -p ~/.gf && git clone https://github.com/Sherlock297/gf_patterns.git /tmp/gfp && cp /tmp/gfp/*.json ~/.gf
```

<!-- meta: risk=safe | phase=misc | tags=install -->
