# VNC

> Connect to and assess Virtual Network Computing servers (typically TCP/5900-5906)

<!-- tags: vnc, vncviewer, remote, enum -->

---

## Connect with vncviewer
Connect to a VNC service using a password file.

```bash
vncviewer {{TARGET:ip}}:{{PORT:port:5901}} -passwd {{PASSFILE:file:vnc.passwd}}
```

<!-- meta: risk=low | phase=enum | tags=vncviewer,connect,passwd -->

---

## Connect without Password File
Connect interactively prompting for the password.

```bash
vncviewer {{TARGET:ip}}:{{PORT:port:5900}}
```

<!-- meta: risk=low | phase=enum | tags=vncviewer,interactive -->

---

## Decrypt Stored VNC Password
Decrypt a captured VNC `passwd` file using vncpwd or python.

```bash
python3 -c "from Crypto.Cipher import DES; key=bytes.fromhex('e84ad660c4721ae0'); print(DES.new(key, DES.MODE_ECB).decrypt(open('{{PASSFILE:file:vnc.passwd}}','rb').read()).rstrip(b'\\x00').decode())"
```

<!-- meta: risk=low | phase=passwords | tags=vnc,decrypt,passwd -->

---

## Nmap VNC NSE
Scan and enumerate VNC server info, security types, and brute force support.

```bash
nmap -p {{PORT:port:5900}} --script vnc-info,vnc-title,realvnc-auth-bypass {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=nmap,vnc,nse -->

---

## Hydra VNC Brute Force
Brute force VNC password authentication.

```bash
hydra -P {{PASSLIST:wordlist}} -s {{PORT:port:5900}} {{TARGET:ip}} vnc
```

<!-- meta: risk=med | phase=passwords | tags=hydra,vnc,brute -->

---

## Metasploit VNC Login Scanner
Spray passwords against VNC with Metasploit.

```bash
msfconsole -q -x "use auxiliary/scanner/vnc/vnc_login; set RHOSTS {{TARGET:ip}}; set PASS_FILE {{PASSLIST:wordlist}}; run; exit"
```

<!-- meta: risk=med | phase=passwords | tags=metasploit,vnc,login -->
