# Dalfox

> Fast, parameter-aware XSS scanner and analysis CLI

<!-- tags: dalfox, xss, web, scanner, parameter -->

---

## Scan Single URL
Test a single URL for XSS, including DOM and reflected variants.

```bash
dalfox url {{URL:url:http://target.com/search?q=test}}
```

<!-- meta: risk=low | phase=vuln | tags=url,xss,reflected -->

---

## Scan URL List from File
Run XSS detection across many URLs in a file.

```bash
dalfox file {{URLLIST:file:urls.txt}} -o {{OUTFILE:file:dalfox-results.txt}}
```

<!-- meta: risk=low | phase=vuln | tags=file,bulk,xss -->

---

## Pipe from Other Tools (gau / hakrawler)
Stream URLs from another tool directly into dalfox.

```bash
gau {{DOMAIN:domain}} | dalfox pipe -o {{OUTFILE:file:dalfox-pipe.txt}}
```

<!-- meta: risk=low | phase=vuln | tags=pipe,gau,workflow -->

---

## With Custom Headers / Cookie
Inject headers or cookies for authenticated scans.

```bash
dalfox url {{URL:url}} --cookie "{{COOKIE:str:session=abc123}}" --header "{{HEADER:str:X-Auth: token}}"
```

<!-- meta: risk=low | phase=vuln | tags=auth,cookie,headers -->

---

## Blind XSS with Callback
Test for blind XSS using an out-of-band callback URL (e.g., XSSHunter).

```bash
dalfox url {{URL:url}} -b {{CALLBACK:url:https://your.xss.ht}}
```

<!-- meta: risk=low | phase=vuln | tags=blind,oob,callback -->
