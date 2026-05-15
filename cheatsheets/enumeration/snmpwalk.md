# Snmpwalk

> Walk SNMP MIB trees to enumerate network interfaces, processes, users, and configs

<!-- tags: snmpwalk, snmp, mib, oid, enum -->

---

## Basic SNMPv2c Walk
Retrieve every SNMP object using community string `public`.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,v2c,public -->

---

## Walk Specific MIB Subtree
Limit walk to a specific OID or named subtree (e.g., system).

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} {{OID:str:1.3.6.1.2.1.1}}
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,oid,subtree -->

---

## SNMPv1 Walk
Use SNMP version 1 for legacy devices that reject v2c.

```bash
snmpwalk -v1 -c {{COMMUNITY:str:public}} {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,v1,legacy -->

---

## SNMPv3 Authenticated Walk
Walk with SNMPv3 authentication and privacy enabled.

```bash
snmpwalk -v3 -u {{USERNAME:str}} -l authPriv -a MD5 -A {{AUTHPASS:str}} -x DES -X {{PRIVPASS:str}} {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=snmpwalk,v3,authpriv -->

---

## Network Interfaces (ifTable)
Enumerate network interface details.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} ifTable
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,interfaces,iftable -->

---

## ARP Table
Retrieve the device ARP cache via ipNetToMediaTable.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} ipNetToMediaTable
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,arp,cache -->

---

## System Uptime
Read just the system uptime OID.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} 1.3.6.1.2.1.1.3
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,uptime,system -->

---

## Walk with Custom Timeout / Retries
Tune timeout and retry count for slow or unreliable devices.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} -t {{TIMEOUT:int:10}} -r {{RETRIES:int:3}} {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,timeout,retries -->

---

## Custom UDP Port
Walk SNMP exposed on a non-standard port.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}}:{{PORT:port:161}}
```

<!-- meta: risk=safe | phase=enum | tags=snmpwalk,port,custom -->

---

## Bulk Walk (Faster)
Use snmpbulkwalk for faster mass enumeration. Don't forget the trailing dot.

```bash
snmpbulkwalk -c {{COMMUNITY:str:public}} -v2c {{TARGET:ip}} .
```

<!-- meta: risk=low | phase=enum | tags=snmpbulkwalk,bulk,fast -->

---

## Extended Output (NET-SNMP-EXTEND-MIB)
Retrieve extended objects, often containing custom command output on misconfigured agents.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} NET-SNMP-EXTEND-MIB::nsExtendObjects
```

<!-- meta: risk=low | phase=enum | tags=snmpwalk,extend,nsextend -->

---

## Install MIBs for Friendlier Output
Download MIB definitions so OIDs resolve to human-readable names.

```bash
sudo apt-get install snmp-mibs-downloader -y && sudo download-mibs
```

<!-- meta: risk=safe | phase=misc | tags=snmp,mibs,install -->

---

## Brute-Force Community Strings (onesixtyone)
Spray community strings against many hosts in parallel.

```bash
onesixtyone -c {{COMMLIST:wordlist:/usr/share/wordlists/seclists/Discovery/SNMP/common-snmp-community-strings.txt}} -i {{TARGETLIST:file:targets.txt}}
```

<!-- meta: risk=low | phase=enum | tags=onesixtyone,community,brute -->

---

## Mass SNMP Scan (braa)
Mass-query OIDs across many hosts using braa's own SNMP stack.

```bash
braa {{COMMUNITY:str:public}}@{{TARGET:ip}}:.1.3.6.*
```

<!-- meta: risk=low | phase=enum | tags=braa,mass,oid -->
