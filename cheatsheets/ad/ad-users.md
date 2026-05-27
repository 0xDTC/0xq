# Active Directory Users
> Active Directory user, group, and computer enumeration & management from a Windows host with the RSAT `ActiveDirectory` PowerShell module. Cmdlets run in any PowerShell session once the module is installed; {{USERNAME}} is the sam/account name you look up or create, {{DOMAIN}} the target domain.

<!-- tags: ad,activedirectory,users,powershell,rsat -->

## install rsat tools
Install all Remote Server Administration Tools (incl. the ActiveDirectory module) as Windows on-demand capabilities.

```bash
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
```

<!-- meta: risk=safe | phase=misc | tags=rsat,install,setup -->

---

## locate active directory module
Confirm the `ActiveDirectory` PowerShell module is present before importing/using its cmdlets.

```bash
Get-Module -Name ActiveDirectory -ListAvailable
```

<!-- meta: risk=safe | phase=misc | tags=rsat,module,setup -->

---

## list domain users get-aduser
List every user object in the domain — the baseline user inventory.

```bash
Get-ADUser -Filter *
```

<!-- meta: risk=low | phase=enum | tags=users,enum,get-aduser -->

---

## get domain user properties get-aduser
Return one user with all properties — descriptions, group membership, last logon, account flags.

```bash
Get-ADUser -Identity {{USERNAME:str:Administrator}} -Properties *
```

<!-- meta: risk=low | phase=enum | tags=users,enum,properties -->

---

## filter domain users by property get-aduser
Query users by an attribute filter — here matching an email-address suffix; swap the clause for any property.

```bash
Get-ADUser -Filter {{FILTER:str:EmailAddress -like '*greenhorn.corp'}}
```

<!-- meta: risk=low | phase=enum | tags=users,enum,filter -->

---

## create domain user new-aduser
Create an enabled domain user, prompting for the account password as a SecureString.

```bash
New-ADUser -Name "{{USERNAME:str:UserName}}" -Surname "{{DESCRIPTION:str:Surname}}" -GivenName "{{DESCRIPTION:str:GivenName}}" -AccountPassword (Read-Host -AsSecureString "AccountPassword") -Enabled $true
```

<!-- meta: risk=med | phase=post | tags=users,create,new-aduser -->

---

## modify domain user set-aduser
Modify an existing user object — example sets the Description attribute.

```bash
Set-ADUser -Identity {{USERNAME:str:UserName}} -Description "{{DESCRIPTION:str:Account managed by IT}}"
```

<!-- meta: risk=med | phase=post | tags=users,modify,set-aduser -->

---

## list domain groups get-adgroup
List all (or filter) domain groups — locate privileged groups worth targeting.

```bash
Get-ADGroup -Filter * -Properties Description
```

<!-- meta: risk=low | phase=enum | tags=groups,enum,get-adgroup -->

---

## list domain group members get-adgroupmember
Enumerate the members of a group recursively — confirm who actually holds membership of e.g. Domain Admins.

```bash
Get-ADGroupMember -Identity "{{GROUP:str:Domain Admins}}" -Recursive
```

<!-- meta: risk=low | phase=enum | tags=groups,members,get-adgroupmember -->

---

## list domain computers get-adcomputer
List every computer object with OS and last-logon details — the machine inventory for lateral movement.

```bash
Get-ADComputer -Filter * -Properties OperatingSystem,DNSHostName,LastLogonDate
```

<!-- meta: risk=low | phase=enum | tags=computers,enum,get-adcomputer -->
