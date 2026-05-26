# Swaks

> Swiss Army Knife for SMTP — craft and send test emails, probe relays, auth, STARTTLS, and attachments.

<!-- tags: network, smtp, email, swaks, phishing, recon -->

---

## send test email swaks
Send a basic test email through an SMTP server to confirm delivery.

```bash
swaks --to {{EMAIL:str:victim@target.com}} --from {{FROM:str:tester@target.com}} --server {{TARGET:ip}}
```

<!-- meta: risk=low | phase=recon | tags=swaks,smtp,test -->

---

## send email with auth swaks
Authenticate to the SMTP server with credentials before sending.

```bash
swaks --to {{EMAIL:str:victim@target.com}} --from {{FROM:str:tester@target.com}} --server {{TARGET:ip}} --auth LOGIN --auth-user {{USER:str:user@target.com}} --auth-password {{PASS:str:Password123}}
```

<!-- meta: risk=low | phase=recon | tags=swaks,smtp,auth -->

---

## send email with attachment swaks
Send an email with a file attached (payload or document delivery test).

```bash
swaks --to {{EMAIL:str:victim@target.com}} --from {{FROM:str:tester@target.com}} --server {{TARGET:ip}} --attach {{INFILE:file:payload.pdf}}
```

<!-- meta: risk=low | phase=recon | tags=swaks,smtp,attachment -->

---

## send email with custom header swaks
Inject a custom header (e.g. Subject) into the message.

```bash
swaks --to {{EMAIL:str:victim@target.com}} --from {{FROM:str:tester@target.com}} --server {{TARGET:ip}} --header "Subject: {{SUBJECT:str:Account Verification}}"
```

<!-- meta: risk=low | phase=recon | tags=swaks,smtp,header -->

---

## send spoofed sender email swaks
Spoof the From address to test sender validation / open relays.

```bash
swaks --to {{EMAIL:str:victim@target.com}} --from {{FROM:str:ceo@target.com}} --server {{TARGET:ip}} --header "From: {{FROM:str:CEO <ceo@target.com>}}"
```

<!-- meta: risk=med | phase=recon | tags=swaks,smtp,spoof,relay -->

---

## send email over starttls swaks
Use STARTTLS to send over an encrypted SMTP channel.

```bash
swaks --to {{EMAIL:str:victim@target.com}} --from {{FROM:str:tester@target.com}} --server {{TARGET:ip}} --tls
```

<!-- meta: risk=low | phase=recon | tags=swaks,smtp,starttls,tls -->

---

## send email body from file swaks
Send a message whose body is read from a file.

```bash
swaks --to {{EMAIL:str:victim@target.com}} --from {{FROM:str:tester@target.com}} --server {{TARGET:ip}} --body {{INFILE:file:body.txt}}
```

<!-- meta: risk=low | phase=recon | tags=swaks,smtp,body -->

---

## send phishing email swaks
Deliver a crafted phishing email with subject and body containing a link.

```bash
swaks --to {{EMAIL:str:victim@target.com}} --from {{FROM:str:it-support@target.com}} --server {{TARGET:ip}} --header "Subject: {{SUBJECT:str:Password Reset Required}}" --body "Please reset your password here: {{URL:url:http://target/reset}}"
```

<!-- meta: risk=med | phase=recon | tags=swaks,smtp,phishing -->

---

## send email to specific port swaks
Send to an explicit SMTP port (submission 587 / SMTPS 465 / relay 25).

```bash
swaks --to {{EMAIL:str:victim@target.com}} --from {{FROM:str:tester@target.com}} --server {{TARGET:ip}} --port {{LPORT:port:587}}
```

<!-- meta: risk=low | phase=recon | tags=swaks,smtp,port,submission -->

---

## test open relay swaks
Relay a message to an external recipient to check for an open mail relay.

```bash
swaks --to {{EMAIL:str:external@gmail.com}} --from {{FROM:str:attacker@evil.com}} --server {{TARGET:ip}}
```

<!-- meta: risk=med | phase=enum | tags=swaks,smtp,open-relay -->
