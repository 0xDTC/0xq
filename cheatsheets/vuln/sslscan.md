# sslscan

> Test TLS/SSL configurations, ciphers, and known protocol weaknesses

<!-- tags: sslscan, tls, ssl, ciphers, vuln -->

---

## scan ssl tls
Scan a target host's TLS configuration.

```bash
sslscan {{TARGET:str:example.com:443}}
```

<!-- meta: risk=safe | phase=vuln | tags=sslscan,basic,tls -->

---

## scan ssl lean
Skip heavy checks for fast iteration.

```bash
sslscan --no-ciphersuites --no-heartbleed --no-groups --no-fallback --no-compression --no-cipher-details {{TARGET:str:example.com:443}}
```

<!-- meta: risk=safe | phase=vuln | tags=sslscan,lean,skip -->

---

## show ssl certificate
Print the server certificate chain without cipher enumeration.

```bash
sslscan --no-ciphersuites --no-renegotiation --no-compression --no-fallback --no-heartbleed {{TARGET:str:example.com:443}}
```

<!-- meta: risk=safe | phase=vuln | tags=sslscan,cert,chain -->

---

## scan ssl starttls
Probe a service that uses STARTTLS (smtp, ftp, imap, pop3, ldap).

```bash
sslscan --starttls-{{PROTO:str:smtp}} {{TARGET:str:mail.example.com:25}}
```

<!-- meta: risk=safe | phase=vuln | tags=sslscan,starttls -->

---

## scan ssl xml
Save full results to XML for parsing.

```bash
sslscan --xml={{OUTFILE:file:sslscan.xml}} {{TARGET:str:example.com:443}}
```

<!-- meta: risk=safe | phase=vuln | tags=sslscan,xml,report -->
