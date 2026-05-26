# Rpcclient
> Samba's MS-RPC client — enumerate users, groups, shares, and SIDs over null or authenticated SMB sessions.

<!-- tags: smb, rpc, enum, msrpc, samr, lsa, active-directory -->

---

## null session connect rpcclient
Drop into an interactive rpcclient shell with no credentials to test whether the target allows null sessions.

```bash
rpcclient -U '' -N {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,null-session,anonymous -->

---

## enumerate domain users rpcclient
List all domain users with their RIDs over MS-SAMR.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'enumdomusers'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,enumdomusers,users -->

---

## query user info rpcclient
Show detailed info for a user by RID — last logon, bad password count, and UAC flags.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'queryuser {{TARGET_USER:str:0x44f}}'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,queryuser,user-detail -->

---

## query display info rpcclient
Dump all users with descriptions in one call via querydispinfo — fast way to spot creds left in comments.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'querydispinfo'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,querydispinfo,descriptions -->

---

## enumerate domain groups rpcclient
List all domain groups with their RIDs.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'enumdomgroups'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,enumdomgroups,groups -->

---

## query group members rpcclient
List the members of a group by its RID.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'querygroupmem {{SID:str:0x200}}'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,querygroupmem,membership -->

---

## query lsa policy rpcclient
Run lsaquery to read the target's domain name and SID via MS-LSAT.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'lsaquery'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,lsaquery,domain-sid -->

---

## enumerate lsa sids rpcclient
Enumerate every SID known to the local LSA — reveals well-known principals and SID-history values.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'lsaenumsid'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,lsaenumsid,sids -->

---

## lookup names to sids rpcclient
Translate one or more principal names to their SIDs.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'lookupnames {{TARGET_USER:str:administrator}}'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,lookupnames,name-to-sid -->

---

## lookup sids to names rpcclient
Translate a SID back to its principal name — pair with RID-cycling to enumerate accounts.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'lookupsids {{SID:str:S-1-5-21-0-0-0-500}}'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,lookupsids,sid-to-name -->

---

## server info rpcclient
Show the target's basic server info — OS version, server type flags, and comment.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'srvinfo'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,srvinfo,os-fingerprint -->

---

## enumerate shares rpcclient
List the shares exported by the target over MS-SRVS.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'netshareenum'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,netshareenum,shares -->

---

## enumerate privileges rpcclient
List the privileges the LSA knows about via enumprivs.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'enumprivs'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,enumprivs,privileges -->

---

## domain password policy rpcclient
Pull the domain password policy with getdompwinfo — check the lockout threshold before any spray.

```bash
rpcclient -U '{{USERNAME}}%{{PASSWORD}}' {{TARGET:ip}} -c 'getdompwinfo'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,getdompwinfo,password-policy -->
