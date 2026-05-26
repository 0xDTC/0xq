# OpenSSL
> Inspect TLS certificates, test SSL/TLS endpoints, and probe vulnerabilities
<!-- tags: openssl,tls,ssl,certificates,recon -->

---

## connect tls service
Establish TLS connection and inspect handshake.

```bash
openssl s_client -connect {{TARGET:domain}}:{{PORT:port:443}} -servername {{TARGET:domain}}
```

<!-- meta: risk=safe | phase=recon | tags=openssl,tls,connect -->

---

## inspect tls certificate x509
Display server certificate as decoded text.

```bash
openssl s_client -connect {{TARGET:domain}}:{{PORT:port:443}} -servername {{TARGET:domain}} </dev/null 2>/dev/null | openssl x509 -text -noout
```

<!-- meta: risk=safe | phase=recon | tags=openssl,certificate,x509 -->

---

## check tls pubkey strength
Inspect server public key bit length and parameters.

```bash
openssl s_client -connect {{TARGET:domain}}:{{PORT:port:443}} -servername {{TARGET:domain}} </dev/null 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -text -noout
```

<!-- meta: risk=safe | phase=recon | tags=openssl,pubkey,strength -->

---

## check heartbleed CVE-2014-0160
Test if server advertises heartbeat extension (CVE-2014-0160 indicator).

```bash
echo "Q" | openssl s_client -connect {{TARGET:domain}}:{{PORT:port:443}} 2>&1 | grep 'server extension "heartbeat" (id=15)'
```

<!-- meta: risk=med | phase=vuln | tags=openssl,heartbleed,cve-2014-0160 -->

---

## sweep heartbleed subdomains
Iterate over a list of subdomains and report heartbeat-enabled ones.

```bash
for s in $(cat {{SUBDOMAINS:file:subdomains.txt}}); do echo "Q" | openssl s_client -connect "${s}:443" 2>&1 | grep -q 'heartbeat" (id=15)' && echo "$s"; done | tee {{OUTFILE:file:heartbleed.txt}}
```

<!-- meta: risk=med | phase=vuln | tags=openssl,heartbleed,sweep -->

---

## connect starttls smtp pop3 imap
Probe STARTTLS-enabled services.

```bash
openssl s_client -connect {{TARGET:ip}}:{{PORT:port:25}} -starttls {{PROTO:str:smtp}}
```

<!-- meta: risk=safe | phase=recon | tags=openssl,starttls,smtp,pop3 -->

---

## generate self-signed cert
Create cert + key for fake services or relay attacks.

```bash
openssl req -x509 -newkey rsa:2048 -keyout {{KEY:file:key.pem}} -out {{CERT:file:cert.pem}} -days 365 -nodes -subj "/CN={{TARGET:domain:fakeserver}}"
```

<!-- meta: risk=safe | phase=misc | tags=openssl,cert,self-signed -->

---

## encrypt file AES-256
Quickly encrypt a file with passphrase.

```bash
openssl enc -aes-256-cbc -salt -in {{INFILE:file:loot.tar}} -out {{OUTFILE:file:loot.tar.enc}}
```

<!-- meta: risk=safe | phase=post | tags=openssl,encrypt,exfil -->

---

## decrypt file AES-256
Decrypt previously-encrypted file.

```bash
openssl enc -d -aes-256-cbc -in {{INFILE:file:loot.tar.enc}} -out {{OUTFILE:file:loot.tar}}
```

<!-- meta: risk=safe | phase=post | tags=openssl,decrypt -->

---

## enumerate tls cipher suites
Inspect supported cipher suites on target.

```bash
openssl s_client -connect {{TARGET:domain}}:{{PORT:port:443}} -cipher 'ALL:eNULL' -servername {{TARGET:domain}}
```

<!-- meta: risk=safe | phase=recon | tags=openssl,ciphers -->

---

## connect pop3s ssl
Connect to POP3S service.

```bash
openssl s_client -connect {{TARGET:ip}}:{{PORT:port:995}}
```

<!-- meta: risk=safe | phase=enum | tags=openssl,pop3s -->
