# SMTP Enumeration

> Identify mail server users, banners, open relays, and version info on TCP/25, 465, 587

<!-- tags: smtp, mail, enum, port-25, vrfy, expn -->

---

## grab banner smtp netcat
Connect to SMTP and read the welcome banner for version info.

```bash
nc -nv {{TARGET:ip}} {{PORT:port:25}}
```

<!-- meta: risk=safe | phase=enum | tags=smtp,banner,nc -->

---

## grab banner smtp telnet
Use telnet for interactive SMTP command testing.

```bash
telnet {{TARGET:ip}} {{PORT:port:25}}
```

<!-- meta: risk=safe | phase=enum | tags=smtp,telnet,banner -->

---

## enum smtp commands nmap
Enumerate available SMTP commands supported by the server.

```bash
nmap -p {{PORT:port:25}} --script smtp-commands {{TARGET:ip}} -oN {{OUTFILE:file:smtp-commands.txt}}
```

<!-- meta: risk=safe | phase=enum | tags=nmap,smtp,nse -->

---

## scan smtp vuln nmap
Run all SMTP NSE scripts including known vulnerabilities and open relay checks.

```bash
nmap -p {{PORT:port:25}} --script "smtp-*" {{TARGET:ip}} -oN {{OUTFILE:file:smtp-nse.txt}}
```

<!-- meta: risk=low | phase=vuln | tags=nmap,smtp,vuln -->

---

## enum users smtp vrfy
Enumerate valid users via VRFY command using a username list.

```bash
smtp-user-enum -M VRFY -U {{USERLIST:wordlist:/usr/share/wordlists/seclists/Usernames/xato-net-10-million-usernames.txt}} -t {{TARGET:ip}} -w {{WAIT:int:100}} -m {{MAX:int:20}}
```

<!-- meta: risk=low | phase=enum | tags=smtp,users,vrfy -->

---

## enum users smtp expn
Enumerate users via EXPN method when VRFY is filtered.

```bash
smtp-user-enum -M EXPN -U {{USERLIST:wordlist}} -t {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=smtp,users,expn -->

---

## enum users smtp rcpt
Use RCPT TO method when both VRFY and EXPN are disabled.

```bash
smtp-user-enum -M RCPT -U {{USERLIST:wordlist}} -t {{TARGET:ip}} -D {{DOMAIN:domain}}
```

<!-- meta: risk=low | phase=enum | tags=smtp,users,rcpt -->

---

## enum smtp metasploit
Enumerate SMTP users with the auxiliary scanner.

```bash
msfconsole -q -x "use auxiliary/scanner/smtp/smtp_enum; set RHOSTS {{TARGET:ip}}; set USER_FILE {{USERLIST:wordlist}}; run; exit"
```

<!-- meta: risk=low | phase=enum | tags=metasploit,smtp,enum -->

---

## test smtp tls openssl
Test the implicit-TLS port and inspect the certificate chain.

```bash
openssl s_client -connect {{TARGET:ip}}:{{PORT:port:465}} -crlf
```

<!-- meta: risk=safe | phase=enum | tags=smtp,smtps,tls,openssl -->

---

## probe smtp starttls
Negotiate STARTTLS on submission ports for cipher and cert inspection.

```bash
openssl s_client -starttls smtp -connect {{TARGET:ip}}:{{PORT:port:587}} -crlf
```

<!-- meta: risk=safe | phase=enum | tags=smtp,starttls,587 -->

---

## enum users smtp vrfy manual
Send VRFY commands non-interactively to test user existence.

```bash
echo -e "VRFY {{USERNAME:str:root}}\nQUIT" | nc -nv {{TARGET:ip}} {{PORT:port:25}}
```

<!-- meta: risk=low | phase=enum | tags=smtp,vrfy,oneliner -->

---

## test smtp open relay
Probe whether the server relays mail for arbitrary external recipients.

```bash
nmap --script smtp-open-relay -p {{PORT:port:25}} {{TARGET:ip}} -oN {{OUTFILE:file:smtp-relay.txt}}
```

<!-- meta: risk=low | phase=vuln | tags=smtp,relay,abuse -->
