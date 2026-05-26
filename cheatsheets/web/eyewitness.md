# EyeWitness

> Takes screenshots of websites, RDP, and VNC services and builds a categorized HTML report from URL lists or nmap XML.

<!-- tags: web, screenshot, eyewitness, rdp, vnc, recon -->

---

## screenshot urls from file eyewitness
Screenshot all web services listed in a URL file.

```bash
eyewitness --web -f {{URLLIST:file:urls.txt}}
```

<!-- meta: risk=low | phase=recon | tags=eyewitness,screenshot,file -->

---

## screenshot single url eyewitness
Screenshot a single web target via a one-line URL file.

```bash
eyewitness --web --single {{URL:url:http://target}}
```

<!-- meta: risk=low | phase=recon | tags=eyewitness,screenshot,single -->

---

## screenshot from nmap xml eyewitness
Screenshot web services parsed from an nmap XML file.

```bash
eyewitness --web -x {{INFILE:file:scan.xml}}
```

<!-- meta: risk=low | phase=recon | tags=eyewitness,screenshot,nmap -->

---

## screenshot with results dir eyewitness
Screenshot URLs and write the report to a chosen output directory.

```bash
eyewitness --web -f {{URLLIST:file:urls.txt}} -d {{OUTDIR:dir:eyewitness-report}}
```

<!-- meta: risk=low | phase=recon | tags=eyewitness,screenshot,output -->

---

## screenshot web rdp vnc eyewitness
Screenshot web, RDP, and VNC services from a single URL/host list.

```bash
eyewitness --all-protocols -f {{URLLIST:file:targets.txt}}
```

<!-- meta: risk=low | phase=enum | tags=eyewitness,rdp,vnc -->

---

## screenshot prepend https eyewitness
Prepend https:// to bare hosts so TLS services are captured too.

```bash
eyewitness --web -f {{URLLIST:file:hosts.txt}} --prepend-https
```

<!-- meta: risk=low | phase=recon | tags=eyewitness,https,screenshot -->

---

## screenshot via docker nmap xml eyewitness
Run EyeWitness in Docker against an nmap XML file, prepending https.

```bash
docker run --rm -it -v "$(pwd):/tmp/EyeWitness" eyewitness --web -x /tmp/EyeWitness/{{INFILE:file:scan.xml}} --prepend-https
```

<!-- meta: risk=low | phase=recon | tags=eyewitness,docker,nmap -->
