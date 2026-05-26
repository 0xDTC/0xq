# Snmpwalk

> Walk SNMP MIB trees to enumerate network interfaces, processes, users, and configs

<!-- tags: snmpwalk, snmp, mib, oid, enum -->

---

## walk snmp v2c
Retrieve every SNMP object using community string `public`.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,v2c,public -->

---

## walk snmp mib subtree
Limit walk to a specific OID or named subtree (e.g., system).

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} {{OID:str:1.3.6.1.2.1.1}}
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,oid,subtree -->

---

## walk snmp v1
Use SNMP version 1 for legacy devices that reject v2c.

```bash
snmpwalk -v1 -c {{COMMUNITY:str:public}} {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,v1,legacy -->

---

## walk snmp v3 authenticated
Walk with SNMPv3 authentication and privacy enabled.

```bash
snmpwalk -v3 -u {{USERNAME:str}} -l authPriv -a MD5 -A {{AUTHPASS:str}} -x DES -X {{PRIVPASS:str}} {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=snmpwalk,v3,authpriv -->

---

## walk snmp interfaces iftable
Enumerate network interface details.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} ifTable
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,interfaces,iftable -->

---

## walk snmp arp table
Retrieve the device ARP cache via ipNetToMediaTable.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} ipNetToMediaTable
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,arp,cache -->

---

## walk snmp uptime
Read just the system uptime OID.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} 1.3.6.1.2.1.1.3
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,uptime,system -->

---

## walk snmp timeout retries
Tune timeout and retry count for slow or unreliable devices.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} -t {{TIMEOUT:int:10}} -r {{RETRIES:int:3}} {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,timeout,retries -->

---

## walk snmp custom port
Walk SNMP exposed on a non-standard port.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}}:{{PORT:port:161}}
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,port,custom -->

---

## walk snmp bulk fast
Use snmpbulkwalk for faster mass enumeration. Don't forget the trailing dot.

```bash
snmpbulkwalk -c {{COMMUNITY:str:public}} -v2c {{TARGET:ip}} .
```

<!-- meta: risk=low | phase=enum | tags=snmpbulkwalk,bulk,fast -->

---

## walk snmp extend mib
Retrieve extended objects, often containing custom command output on misconfigured agents.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} NET-SNMP-EXTEND-MIB::nsExtendObjects
```

<!-- meta: risk=low | phase=enum | tags=snmpwalk,extend,nsextend -->

---

## install snmp mibs
Download MIB definitions so OIDs resolve to human-readable names.

```bash
sudo apt-get install snmp-mibs-downloader -y && sudo download-mibs
```

<!-- meta: risk=safe | phase=misc | tags=snmp,mibs,install -->

---

## brute snmp community onesixtyone
Spray community strings against many hosts in parallel.

```bash
onesixtyone -c {{COMMLIST:wordlist:/usr/share/wordlists/seclists/Discovery/SNMP/common-snmp-community-strings.txt}} -i {{TARGETLIST:file:targets.txt}}
```

<!-- meta: risk=low | phase=enum | tags=onesixtyone,community,brute -->

---

## scan snmp mass braa
Mass-query OIDs across many hosts using braa's own SNMP stack.

```bash
braa {{COMMUNITY:str:public}}@{{TARGET:ip}}:.1.3.6.*
```

<!-- meta: risk=low | phase=enum | tags=braa,mass,oid -->
