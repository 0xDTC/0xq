# Katana

> Fast web crawler that extracts routes, JavaScript links, forms, and endpoints.

<!-- tags: web, crawler, katana, recon, endpoints -->

**UA policy:** every outbound request sets an explicit real-browser User-Agent via `{{UA}}` (session-shared across tools). Default = modern Chrome-on-Windows. Alternates: `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0` (Firefox 128 Linux), `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15` (Safari 17 macOS).

---

## crawl site katana
Crawl a single target URL and print discovered endpoints.

```bash
katana -u {{URL:url:http://target}} -H "User-Agent: {{UA:str:$(q-ua)}}"
```

<!-- meta: risk=safe | phase=recon | tags=crawl,basic -->

---

## crawl list katana
Crawl every URL listed in a file.

```bash
katana -list {{URLS_FILE:file:urls.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}"
```

<!-- meta: risk=safe | phase=recon | tags=crawl,list -->

---

## crawl headless katana
Crawl with a headless browser to render JavaScript-driven pages.

```bash
katana -u {{URL:url:http://target}} -headless -H "User-Agent: {{UA:str:$(q-ua)}}"
```

<!-- meta: risk=safe | phase=recon | tags=crawl,headless,javascript -->

---

## crawl deep katana
Active crawl with increased depth and JavaScript parsing for fuller coverage.

```bash
katana -u {{URL:url:http://target}} -d {{DEPTH:int:5}} -jc -kf all -H "User-Agent: {{UA:str:$(q-ua)}}"
```

<!-- meta: risk=low | phase=recon | tags=crawl,depth,javascript -->

---

## crawl save output katana
Crawl and write discovered endpoints to a file.

```bash
katana -u {{URL:url:http://target}} -o {{OUTFILE:file:katana-endpoints.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}"
```

<!-- meta: risk=safe | phase=recon | tags=crawl,output -->

---

## crawl scope katana
Restrict crawling to a single domain scope to avoid wandering off target.

```bash
katana -u {{URL:url:http://target}} -fs {{SCOPE:choice:fqdn=exact host only,rdn=root domain,dn=domain name}} -d {{DEPTH:int:3}} -H "User-Agent: {{UA:str:$(q-ua)}}"
```

<!-- meta: risk=safe | phase=recon | tags=crawl,scope -->

---

## crawl passive katana
Passively pull URLs from sources like the Wayback Machine and AlienVault.

```bash
katana -u {{URL:url:http://target}} -ps -o {{OUTFILE:file:katana-passive.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}"
```

<!-- meta: risk=safe | phase=recon | tags=crawl,passive,wayback -->

---

## crawl with cookie katana
Crawl an authenticated area by supplying a session cookie header.

```bash
katana -u {{URL:url:http://target}} -H "Cookie: {{COOKIE:str:session=abc123}}" -H "User-Agent: {{UA:str:$(q-ua)}}" -headless
```

<!-- meta: risk=low | phase=recon | tags=crawl,auth,cookie -->

---

## extract js endpoints katana
Crawl JavaScript files and extract endpoints, parameters, and paths from them.

```bash
katana -u {{URL:url:http://target}} -jc -jsl -o {{OUTFILE:file:katana-js.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}"
```

<!-- meta: risk=safe | phase=recon | tags=javascript,endpoints,parsing -->

---

## crawl match extensions katana
Crawl and keep only links matching specific file extensions.

```bash
katana -u {{URL:url:http://target}} -em {{EXTENSIONS:str:js,json,php,aspx}} -H "User-Agent: {{UA:str:$(q-ua)}}"
```

<!-- meta: risk=safe | phase=recon | tags=crawl,extensions,filter -->
