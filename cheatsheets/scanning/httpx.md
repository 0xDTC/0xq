# httpx

> Fast and multi-purpose HTTP toolkit for probing and analyzing web servers

<!-- tags: httpx, http, probe, web, scanning, fingerprint -->

---

## Basic HTTP Probe
Probe a list of hosts to identify live HTTP/HTTPS services.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -o {{OUTFILE:file:live-hosts.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=probe,alive,http -->

---

## Probe with Status, Title, and Tech
Enumerate live web servers with status code, page title, and technology detection.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -sc -title -tech-detect -o {{OUTFILE:file:httpx-detailed.txt}}
```

<!-- meta: risk=safe | phase=enum | tags=status,title,tech,fingerprint -->

---

## Multi-Port HTTP Probing
Probe hosts across multiple common web ports.

```bash
httpx -l {{HOSTLIST:file:hosts.txt}} -p 80,443,8080,8443,8000,3000,9090 -sc -title -o {{OUTFILE:file:httpx-multiport.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=ports,multi-port,web -->

---

## Filter by Status Code
Probe and show only hosts matching specific HTTP status codes.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -mc {{STATUS:str:200,301,302}} -o {{OUTFILE:file:httpx-filtered.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=filter,status-code,alive -->

---

## Follow Redirects with Final URL
Follow HTTP redirects and display the final destination URL.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -fr -sc -title -location -o {{OUTFILE:file:httpx-redirects.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=redirects,follow,location -->

---

## Full JSON Output
Comprehensive probe with all metadata output in JSON format.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -sc -title -tech-detect -server -content-length -ip -cname -json -o {{OUTFILE:file:httpx-full.json}}
```

<!-- meta: risk=safe | phase=enum | tags=json,full,metadata -->

---

## Screenshot and Hash
Capture page screenshots and content hashes for visual recon.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -screenshot -hash md5 -o {{OUTFILE:file:httpx-screens.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=screenshot,hash,visual -->

---

## Single Target Probe with Headers
Probe a single URL showing response headers and server info.

```bash
echo "{{URL:url}}" | httpx -sc -title -server -resp-header -fr
```

<!-- meta: risk=safe | phase=recon | tags=single,headers,server -->

---

## Content-Length Filter for Interesting Pages
Filter responses by content length to find non-default pages.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -sc -cl -title -ml 0 -fl 0 -o {{OUTFILE:file:httpx-interesting.txt}}
```

<!-- meta: risk=safe | phase=enum | tags=content-length,filter,interesting -->
