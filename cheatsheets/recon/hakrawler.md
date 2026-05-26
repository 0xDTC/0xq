# Hakrawler

> Fast web crawler for endpoint and URL discovery

<!-- tags: hakrawler,crawl,recon,urls -->

---

## crawl single domain urls
Pipe a domain to hakrawler to extract URLs.

```bash
echo {{URL:url}} | hakrawler
```

<!-- meta: risk=safe | phase=recon | tags=crawl,single -->

---

## crawl deep depth
Crawl deeper into the application.

```bash
echo {{URL:url}} | hakrawler -depth {{DEPTH:int:3}}
```

<!-- meta: risk=safe | phase=recon | tags=depth -->

---

## crawl include subdomains
Include subdomains of the target.

```bash
echo {{URL:url}} | hakrawler -subs
```

<!-- meta: risk=safe | phase=recon | tags=subdomains -->
