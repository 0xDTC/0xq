# Gowitness

> Fast web screenshot utility — captures site screenshots from URLs, files, nmap XML, or CIDR ranges and serves an HTML report.

<!-- tags: web, screenshot, gowitness, recon, enum -->

---

## screenshot single url gowitness
Capture a screenshot of a single target URL.

```bash
gowitness single {{URL:url:http://target}}
```

<!-- meta: risk=low | phase=recon | tags=gowitness,screenshot,single -->

---

## screenshot urls from file gowitness
Screenshot every URL listed in a file.

```bash
gowitness file -f {{URLLIST:file:urls.txt}}
```

<!-- meta: risk=low | phase=recon | tags=gowitness,screenshot,file -->

---

## screenshot from nmap xml gowitness
Screenshot web services discovered in an nmap XML output file.

```bash
gowitness nmap -f {{INFILE:file:scan.xml}}
```

<!-- meta: risk=low | phase=recon | tags=gowitness,screenshot,nmap -->

---

## screenshot cidr range gowitness
Scan and screenshot every host across a CIDR range.

```bash
gowitness scan --cidr {{CIDR:str:10.0.0.0/24}}
```

<!-- meta: risk=low | phase=enum | tags=gowitness,screenshot,cidr -->

---

## start report server gowitness
Launch the built-in web UI to browse captured screenshots.

```bash
gowitness report serve --address 0.0.0.0:{{LPORT:port:7171}}
```

<!-- meta: risk=low | phase=recon | tags=gowitness,report,server -->

---

## screenshot via docker nmap xml gowitness
Screenshot web services from an nmap XML file using the gowitness Docker image.

```bash
docker run --rm -v "$(pwd):/data" -p {{LPORT:port:7171}}:7171 leonjza/gowitness gowitness nmap -f /data/{{INFILE:file:scan.xml}}
```

<!-- meta: risk=low | phase=recon | tags=gowitness,docker,nmap -->

---

## screenshot via docker url file gowitness
Screenshot URLs from a file using the gowitness Docker image.

```bash
docker run --rm -v "$(pwd):/data" -p {{LPORT:port:7171}}:7171 leonjza/gowitness gowitness file -f /data/{{URLLIST:file:urls.txt}}
```

<!-- meta: risk=low | phase=recon | tags=gowitness,docker,file -->
