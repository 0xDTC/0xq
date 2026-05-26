# Smbmap
> Enumerate SMB shares and access permissions, then walk readable paths for loot.

<!-- tags: smb, smbmap, shares, permissions, enumeration, windows -->

---

## list shares smbmap
Enumerate SMB shares with a valid username and password.

```bash
smbmap -H {{TARGET:ip}} -u {{USERNAME}} -p {{PASSWORD}} -d {{DOMAIN:domain:WORKGROUP}}
```

<!-- meta: risk=low | phase=enum | tags=smbmap,shares,creds -->

---

## null session smbmap
Enumerate SMB shares with null access (anonymous session) on port 445.

```bash
smbmap -u "" -p "" -P 445 -H {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=smbmap,null,anonymous -->

---

## guest access smbmap
Enumerate SMB shares as the guest account on port 445.

```bash
smbmap -u "guest" -p "" -P 445 -H {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=smbmap,guest -->

---

## list share roots smbmap
List the root of all readable shares with valid credentials.

```bash
smbmap -H {{TARGET:ip}} -u {{USERNAME}} -p {{PASSWORD}} -d {{DOMAIN:domain:WORKGROUP}} -r
```

<!-- meta: risk=low | phase=enum | tags=smbmap,shares,roots -->

---

## recursive list path smbmap
Recursively list a path across readable shares to a chosen depth.

```bash
smbmap -H {{TARGET:ip}} -u {{USERNAME}} -p {{PASSWORD}} -d {{DOMAIN:domain:WORKGROUP}} -R {{SHARE:str}} --depth {{DEPTH:int:1}}
```

<!-- meta: risk=low | phase=enum | tags=smbmap,recursive,path -->
