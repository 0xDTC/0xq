# Waybackurls

> Fetch URLs archived by the Wayback Machine for a domain

<!-- tags: waybackurls, archive, recon, urls -->

---

## Install via Go
Install the latest waybackurls binary using go install.

```bash
go install github.com/tomnomnom/waybackurls@latest && sudo cp ~/go/bin/waybackurls /usr/bin/
```

<!-- meta: risk=safe | phase=misc | tags=waybackurls,install,go -->

---

## Fetch Archived URLs for a Domain
Pull every wayback-known URL for a domain into a file.

```bash
waybackurls {{DOMAIN:domain}} > {{OUTFILE:file:wayback.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=waybackurls,domain,collect -->

---

## Probe Live URLs (httpx Pipe)
Pipe wayback URLs through httpx to find currently live ones.

```bash
waybackurls {{DOMAIN:domain}} | httpx -silent -mc 200 > {{OUTFILE:file:live-wayback.txt}}
```

<!-- meta: risk=low | phase=recon | tags=waybackurls,httpx,live -->

---

## Filter for JavaScript Files
Pull only .js URLs from wayback for source review.

```bash
waybackurls {{DOMAIN:domain}} | grep -Ei "\.js(\?|$)" | sort -u > {{OUTFILE:file:js-urls.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=waybackurls,js,filter -->

---

## Filter URLs with Parameters
Extract URLs that have query strings (potential injection candidates).

```bash
waybackurls {{DOMAIN:domain}} | grep "=" | sort -u > {{OUTFILE:file:params.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=waybackurls,params,injection -->
