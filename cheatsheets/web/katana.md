# Katana

> Fast web crawler that extracts routes, JavaScript links, forms, and endpoints.

<!-- tags: web, crawler, katana, recon, endpoints -->

---

## crawl site katana
Crawl a single target URL and print discovered endpoints.

```bash
katana -u {{URL:url:http://target}}
```

<!-- meta: risk=safe | phase=recon | tags=crawl,basic -->

---

## crawl list katana
Crawl every URL listed in a file.

```bash
katana -list {{URLS_FILE:file:urls.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=crawl,list -->

---

## crawl headless katana
Crawl with a headless browser to render JavaScript-driven pages.

```bash
katana -u {{URL:url:http://target}} -headless
```

<!-- meta: risk=safe | phase=recon | tags=crawl,headless,javascript -->

---

## crawl deep katana
Active crawl with increased depth and JavaScript parsing for fuller coverage.

```bash
katana -u {{URL:url:http://target}} -d {{DEPTH:int:5}} -jc -kf all
```

<!-- meta: risk=low | phase=recon | tags=crawl,depth,javascript -->

---

## crawl save output katana
Crawl and write discovered endpoints to a file.

```bash
katana -u {{URL:url:http://target}} -o {{OUTFILE:file:katana-endpoints.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=crawl,output -->

---

## crawl scope katana
Restrict crawling to a single domain scope to avoid wandering off target.

```bash
katana -u {{URL:url:http://target}} -fs {{SCOPE:str:fqdn}} -d {{DEPTH:int:3}}
```

<!-- meta: risk=safe | phase=recon | tags=crawl,scope -->

---

## crawl passive katana
Passively pull URLs from sources like the Wayback Machine and AlienVault.

```bash
katana -u {{URL:url:http://target}} -ps -o {{OUTFILE:file:katana-passive.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=crawl,passive,wayback -->

---

## crawl with cookie katana
Crawl an authenticated area by supplying a session cookie header.

```bash
katana -u {{URL:url:http://target}} -H "Cookie: {{COOKIE:str:session=abc123}}" -headless
```

<!-- meta: risk=low | phase=recon | tags=crawl,auth,cookie -->

---

## extract js endpoints katana
Crawl JavaScript files and extract endpoints, parameters, and paths from them.

```bash
katana -u {{URL:url:http://target}} -jc -jsl -o {{OUTFILE:file:katana-js.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=javascript,endpoints,parsing -->

---

## crawl match extensions katana
Crawl and keep only links matching specific file extensions.

```bash
katana -u {{URL:url:http://target}} -em {{EXTENSIONS:str:js,json,php,aspx}}
```

<!-- meta: risk=safe | phase=recon | tags=crawl,extensions,filter -->
