# SharpHound

> BloodHound data collector for Active Directory enumeration

<!-- tags: sharphound, bloodhound, ad, ldap, enumeration -->

---

## Default Collection
Collect group membership, domain trust, local admin, and session information.

```bash
SharpHound --CollectionMethod Default --OutputDirectory {{OUTDIR:dir:./output}} --OutputPrefix {{PREFIX:str:default}}
```

<!-- meta: risk=med | phase=enum | tags=sharphound,bloodhound,default -->

---

## All Collection Methods (Windows EXE)
Collect everything BloodHound supports in a single run.

```bash
.\SharpHound.exe -C All --OutputDirectory {{OUTDIR:dir:.}}
```

<!-- meta: risk=med | phase=enum | tags=sharphound,all,exe -->

---

## PowerShell Module Ingestor
Run SharpHound from the PowerShell wrapper script with explicit credentials.

```bash
powershell -ep bypass -c ". .\SharpHound.ps1; Invoke-BloodHound -CollectionMethod All --LdapUsername {{USERNAME:str}} --LdapPassword {{PASSWORD:str}} --OutputDirectory {{OUTDIR:dir:.}}"
```

<!-- meta: risk=med | phase=enum | tags=sharphound,powershell,bloodhound -->

---

## Computer-Only Collection
Collect local admin, RDP, DCOM, and session information from machines.

```bash
SharpHound --CollectionMethod ComputerOnly --OutputDirectory {{OUTDIR:dir:./output}} --OutputPrefix {{PREFIX:str:computer_only}}
```

<!-- meta: risk=med | phase=enum | tags=sharphound,computer,sessions -->

---

## Domain Trust Collection
Map domain trust relationships across the forest.

```bash
SharpHound --CollectionMethod Trusts --OutputDirectory {{OUTDIR:dir:./output}} --OutputPrefix {{PREFIX:str:trusts}}
```

<!-- meta: risk=low | phase=enum | tags=sharphound,trusts,forest -->

---

## Targeted Domain Collection
Collect default information for a specific domain.

```bash
SharpHound --CollectionMethod Default -d {{DOMAIN:domain}} --OutputDirectory {{OUTDIR:dir:./output}} --OutputPrefix {{PREFIX:str:default_domain}}
```

<!-- meta: risk=med | phase=enum | tags=sharphound,domain,targeted -->

---

## Stealth Mode (Skip DCs)
Run in stealth mode while excluding domain controllers to avoid ATA detection.

```bash
SharpHound --CollectionMethod Default --Stealth --ExcludeDomainControllers --OutputDirectory {{OUTDIR:dir:./output}} --OutputPrefix {{PREFIX:str:stealth_no_dc}}
```

<!-- meta: risk=low | phase=enum | tags=sharphound,stealth,evasion -->

---

## Limit by Search Base (OU)
Restrict collection to a specific organizational unit.

```bash
SharpHound.exe --SearchBase "{{OU:str:OU=New York,DC=Contoso,DC=Local}}"
```

<!-- meta: risk=low | phase=enum | tags=sharphound,ou,searchbase -->

---

## Custom LDAP Filter
Collect only objects matching an LDAP filter expression.

```bash
SharpHound.exe --LDAPFilter "{{FILTER:str:(CN=*,OU=New York,DC=Contoso,DC=Local)}}"
```

<!-- meta: risk=low | phase=enum | tags=sharphound,ldap,filter -->

---

## Loop Session Collection
Repeatedly collect session info over a duration with intervals between loops.

```bash
SharpHound.exe --CollectionMethods Session --Loop --LoopDuration {{DURATION:str:12:30:12}} --LoopInterval {{INTERVAL:str:00:15:00}}
```

<!-- meta: risk=med | phase=enum | tags=sharphound,loop,sessions -->

---

## Alternate LDAP Credentials
Bind with explicit username/password rather than current user context.

```bash
SharpHound.exe --LdapUsername {{USERNAME:str}} --LdapPassword {{PASSWORD:str}}
```

<!-- meta: risk=med | phase=enum | tags=sharphound,credentials,ldap -->

---

## Real DNS Name Override
Provide a DNS suffix when DNS is not synchronized with AD.

```bash
SharpHound.exe --RealDNSName {{DNS_NAME:domain:COMPANY.COM}}
```

<!-- meta: risk=low | phase=enum | tags=sharphound,dns,override -->

---

## List Domain Trusts (nltest)
Replacement for the deprecated --SearchForest flag.

```bash
nltest /domain_trusts
```

<!-- meta: risk=safe | phase=enum | tags=nltest,trusts,domain -->
