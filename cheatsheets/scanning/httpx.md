# httpx

> Fast and multi-purpose HTTP toolkit for probing and analyzing web servers

<!-- tags: httpx, http, probe, web, scanning, fingerprint -->

---

## probe live http hosts
Probe a list of hosts to identify live HTTP/HTTPS services.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -o {{OUTFILE:file:live-hosts.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=probe,alive,http -->

---

## probe status title tech detect
Enumerate live web servers with status code, page title, and technology detection.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -sc -title -tech-detect -o {{OUTFILE:file:httpx-detailed.txt}}
```

<!-- meta: risk=safe | phase=enum | tags=status,title,tech,fingerprint -->

---

## probe multi-port web
Probe hosts across multiple common web ports.

```bash
httpx -l {{HOSTLIST:file:hosts.txt}} -p 80,443,8080,8443,8000,3000,9090 -sc -title -o {{OUTFILE:file:httpx-multiport.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=ports,multi-port,web -->

---

## probe filter by status code
Probe and show only hosts matching specific HTTP status codes.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -mc {{STATUS:str:200,301,302}} -o {{OUTFILE:file:httpx-filtered.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=filter,status-code,alive -->

---

## probe follow redirects final url
Follow HTTP redirects and display the final destination URL.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -fr -sc -title -location -o {{OUTFILE:file:httpx-redirects.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=redirects,follow,location -->

---

## probe full metadata json
Comprehensive probe with all metadata output in JSON format.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -sc -title -tech-detect -server -content-length -ip -cname -json -o {{OUTFILE:file:httpx-full.json}}
```

<!-- meta: risk=safe | phase=enum | tags=json,full,metadata -->

---

## capture screenshot hash visual
Capture page screenshots and content hashes for visual recon.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -screenshot -hash md5 -o {{OUTFILE:file:httpx-screens.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=screenshot,hash,visual -->

---

## probe single url headers server
Probe a single URL showing response headers and server info.

```bash
echo "{{URL:url}}" | httpx -sc -title -server -resp-header -fr
```

<!-- meta: risk=safe | phase=recon | tags=single,headers,server -->

---

## probe filter content-length pages
Filter responses by content length to find non-default pages.

```bash
httpx -l {{HOSTLIST:file:subdomains.txt}} -sc -cl -title -ml 0 -fl 0 -o {{OUTFILE:file:httpx-interesting.txt}}
```

<!-- meta: risk=safe | phase=enum | tags=content-length,filter,interesting -->
