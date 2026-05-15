# SNMP Enumeration

> Enumerate network devices via SNMP using snmpwalk, snmpbulkwalk, and onesixtyone

<!-- tags: snmp, snmpwalk, onesixtyone, enumeration, network, community-string -->

---

## Community String Brute Force (onesixtyone)
Brute force SNMP community strings against a target.

```bash
onesixtyone -c {{WORDLIST:wordlist:/usr/share/seclists/Discovery/SNMP/snmp.txt}} {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=onesixtyone,bruteforce,community-string -->

---

## Bulk Community String Scan (onesixtyone)
Spray community strings across a list of targets for large-scale discovery.

```bash
onesixtyone -c {{WORDLIST:wordlist:/usr/share/seclists/Discovery/SNMP/snmp.txt}} -i {{TARGETLIST:file:targets.txt}}
```

<!-- meta: risk=low | phase=enum | tags=onesixtyone,bulk,spray -->

---

## Full SNMP Walk (SNMPv2)
Walk the entire SNMP MIB tree using a known community string.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} | tee {{OUTFILE:file:snmpwalk-full.txt}}
```

<!-- meta: risk=low | phase=enum | tags=snmpwalk,full,mib -->

---

## Enumerate Running Processes
Query the process list OID to discover running services and software.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} 1.3.6.1.2.1.25.4.2.1.2 | tee {{OUTFILE:file:snmp-processes.txt}}
```

<!-- meta: risk=low | phase=enum | tags=snmpwalk,processes,software -->

---

## Enumerate System Users
Query the user account OID to enumerate local user accounts.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} 1.3.6.1.4.1.77.1.2.25 | tee {{OUTFILE:file:snmp-users.txt}}
```

<!-- meta: risk=low | phase=enum | tags=snmpwalk,users,accounts -->

---

## Enumerate Installed Software
Query the installed software OID to list applications on the target.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} 1.3.6.1.2.1.25.6.3.1.2 | tee {{OUTFILE:file:snmp-software.txt}}
```

<!-- meta: risk=low | phase=enum | tags=snmpwalk,software,installed -->

---

## Enumerate Network Interfaces
Query network interface details including IP addresses and interface names.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} 1.3.6.1.2.1.2.2.1.2 | tee {{OUTFILE:file:snmp-interfaces.txt}}
```

<!-- meta: risk=low | phase=enum | tags=snmpwalk,interfaces,network -->

---

## Enumerate TCP Open Ports
Query the TCP connection table to discover open ports and connections.

```bash
snmpwalk -v2c -c {{COMMUNITY:str:public}} {{TARGET:ip}} 1.3.6.1.2.1.6.13.1.3 | tee {{OUTFILE:file:snmp-ports.txt}}
```

<!-- meta: risk=low | phase=enum | tags=snmpwalk,ports,tcp,connections -->

---

## SNMPv3 Authenticated Walk
Walk SNMP MIB using SNMPv3 with authentication and encryption.

```bash
snmpwalk -v3 -l authPriv -u {{USERNAME:str}} -a SHA -A {{PASSWORD:str}} -x AES -X {{PRIVPASS:str}} {{TARGET:ip}} | tee {{OUTFILE:file:snmpv3-walk.txt}}
```

<!-- meta: risk=low | phase=enum | tags=snmpv3,authenticated,encrypted -->
