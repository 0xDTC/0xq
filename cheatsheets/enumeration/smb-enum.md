# SMB Enumeration

> Enumerate SMB shares, users, and resources using enum4linux, smbmap, and smbclient

<!-- tags: smb, enum4linux, smbmap, smbclient, shares, enumeration, windows -->

---

## Full SMB Enumeration (enum4linux)
Run comprehensive SMB enumeration including users, shares, groups, and OS info.

```bash
enum4linux -a {{TARGET:ip}} | tee {{OUTFILE:file:enum4linux.txt}}
```

<!-- meta: risk=low | phase=enum | tags=enum4linux,full,comprehensive -->

---

## User Enumeration via RID Cycling (enum4linux)
Brute force user accounts through RID cycling via null session.

```bash
enum4linux -r -R 500-1100 {{TARGET:ip}} | tee {{OUTFILE:file:rid-cycle.txt}}
```

<!-- meta: risk=low | phase=enum | tags=enum4linux,users,rid,cycling -->

---

## List Shares with Permissions (smbmap)
Enumerate SMB shares and display access permissions for each.

```bash
smbmap -H {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=smbmap,shares,permissions -->

---

## Authenticated Share Enumeration (smbmap)
List shares and permissions using valid credentials.

```bash
smbmap -H {{TARGET:ip}} -u {{USERNAME:str}} -p {{PASSWORD:str}} -d {{DOMAIN:domain:WORKGROUP}}
```

<!-- meta: risk=low | phase=enum | tags=smbmap,authenticated,shares -->

---

## Recursive File Listing (smbmap)
Recursively list files in accessible shares to find interesting content.

```bash
smbmap -H {{TARGET:ip}} -u {{USERNAME:str}} -p {{PASSWORD:str}} -R {{SHARE:str}} --depth 3
```

<!-- meta: risk=low | phase=enum | tags=smbmap,recursive,files,listing -->

---

## Download File from Share (smbmap)
Download a specific file from an SMB share.

```bash
smbmap -H {{TARGET:ip}} -u {{USERNAME:str}} -p {{PASSWORD:str}} --download '{{FILEPATH:str:share\path\to\file.txt}}'
```

<!-- meta: risk=low | phase=enum | tags=smbmap,download,exfil -->

---

## Anonymous Share Access (smbclient)
Connect to an SMB share using a null session for anonymous browsing.

```bash
smbclient //{{TARGET:ip}}/{{SHARE:str}} -N
```

<!-- meta: risk=low | phase=enum | tags=smbclient,anonymous,null-session -->

---

## Authenticated Share Access (smbclient)
Connect to an SMB share with credentials for interactive browsing.

```bash
smbclient //{{TARGET:ip}}/{{SHARE:str}} -U '{{USERNAME:str}}%{{PASSWORD:str}}'
```

<!-- meta: risk=low | phase=enum | tags=smbclient,authenticated,interactive -->

---

## List All Available Shares (smbclient)
List all shares advertised by the target SMB server.

```bash
smbclient -L //{{TARGET:ip}}/ -N
```

<!-- meta: risk=low | phase=enum | tags=smbclient,list,shares,null -->

---

## Enum4linux-ng Full Scan
Run the updated Python version with JSON output for comprehensive SMB enumeration.

```bash
enum4linux-ng -A {{TARGET:ip}} -oJ {{OUTFILE:file:enum4linux-ng}}
```

<!-- meta: risk=low | phase=enum | tags=enum4linux-ng,full,json -->

---

## Windows UNC Path (smbclient)
Connect using a Windows-style UNC path copy-pasted from cmd output.

```bash
smbclient '\\\\{{TARGET:ip}}\\{{SHARE:str}}' -U '{{USERNAME:str}}%{{PASSWORD:str}}'
```

<!-- meta: risk=low | phase=enum | tags=smbclient,unc,windows -->

---

## Pass-the-Hash (smbclient)
Authenticate to a share using an NTLM hash instead of a password.

```bash
smbclient //{{TARGET:ip}}/{{SHARE:str}} -U '{{USERNAME:str}}' --pw-nt-hash {{NTHASH:str}}
```

<!-- meta: risk=med | phase=enum | tags=smbclient,pth,hash -->

---

## Force SMB Version (smbclient)
Pin the SMB dialect when the server rejects the default negotiation.

```bash
smbclient //{{TARGET:ip}}/{{SHARE:str}} -U '{{USERNAME:str}}%{{PASSWORD:str}}' -m SMB3
```

<!-- meta: risk=low | phase=enum | tags=smbclient,smb3,version -->

---

## Kerberos Auth (smbclient)
Authenticate using an existing Kerberos ticket in the local cache.

```bash
smbclient //{{TARGET:domain}}/{{SHARE:str}} -k
```

<!-- meta: risk=low | phase=enum | tags=smbclient,kerberos,ccache -->

---

## Single-File Download (smbclient -c)
Grab a specific file non-interactively with a scripted command.

```bash
smbclient //{{TARGET:ip}}/{{SHARE:str}} -U '{{USERNAME:str}}%{{PASSWORD:str}}' -c 'get {{REMOTE_FILE:str}} {{LOCAL_FILE:file:loot.bin}}'
```

<!-- meta: risk=low | phase=enum | tags=smbclient,download,scripted -->

---

## Mount CIFS (Linux mount)
Mount an SMB share on the local filesystem with credentials.

```bash
sudo mount -t cifs //{{TARGET:ip}}/{{SHARE:str}} {{MOUNT_POINT:dir:/mnt/smb}} -o username={{USERNAME:str}},password={{PASSWORD:str}},vers=3.0
```

<!-- meta: risk=low | phase=enum | tags=mount,cifs,smb3 -->

---

## Guest Mount (CIFS)
Mount an SMB share as guest, forcing legacy SMB1 when needed.

```bash
sudo mount -t cifs //{{TARGET:ip}}/{{SHARE:str}} {{MOUNT_POINT:dir:/mnt/smb}} -o guest,vers=1.0
```

<!-- meta: risk=low | phase=enum | tags=mount,cifs,guest,smb1 -->

---

## smbmap Pass-the-Hash
Enumerate shares using an NTLM hash. Note: `-H` is reused for both host and hash flags.

```bash
smbmap -H {{TARGET:ip}} -u {{USERNAME:str}} -H {{NTHASH:str}}
```

<!-- meta: risk=med | phase=enum | tags=smbmap,pth,hash -->

---

## rpcclient Null Session
Connect to rpcclient anonymously to enumerate domain info without credentials.

```bash
rpcclient -U '' -N {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,null-session,anonymous -->

---

## rpcclient Authenticated
Open an authenticated rpcclient session for interactive enumeration.

```bash
rpcclient -U '{{USERNAME:str}}%{{PASSWORD:str}}' {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,authenticated -->

---

## rpcclient Enumerate Domain Users
Run `enumdomusers` non-interactively to list domain users.

```bash
rpcclient -U '{{USERNAME:str}}%{{PASSWORD:str}}' {{TARGET:ip}} -c 'enumdomusers'
```

<!-- meta: risk=low | phase=enum | tags=rpcclient,users,enumdomusers -->

---

## smbget Recursive Share Download
Bulk-download an entire share to local disk.

```bash
smbget -R smb://{{TARGET:ip}}/{{SHARE:str}} -U {{USERNAME:str}}
```

<!-- meta: risk=low | phase=enum | tags=smbget,download,recursive -->

---

## smbmap Anonymous Recursive Listing
Anonymous probe with recursive directory listing for read-everywhere checks.

```bash
smbmap -H {{TARGET:ip}} -u anonymous -r --depth {{DEPTH:int:3}}
```

<!-- meta: risk=safe | phase=enum | tags=smbmap,anonymous,recursive -->
