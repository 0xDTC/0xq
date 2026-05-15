# Volatility

> Memory forensics framework for analyzing RAM dumps

<!-- tags: volatility, memory, forensics, dfir -->

---

## v2 - Image Info
Detect the OS profile from a memory dump.

```bash
volatility -f {{DUMP:file:memory.raw}} imageinfo
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,imageinfo -->

---

## v2 - KDBG Scan
Find KDBG when imageinfo is inconclusive.

```bash
volatility -f {{DUMP:file:memory.raw}} kdbgscan
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,kdbg -->

---

## v2 - Process List
List processes (pslist), hidden (psscan), and the tree (pstree).

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str:Win7SP1x64}} pslist
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,pslist -->

---

## v2 - Process Scan (Hidden)
Find processes hidden via DKOM by scanning physical memory.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str:Win7SP1x64}} psscan
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,psscan,hidden -->

---

## v2 - Procdump
Dump an executable for a given PID with associated DLLs.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} procdump -p {{PID:int}} --dump-dir={{OUTDIR:dir:./dump}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,procdump -->

---

## v2 - Memdump (Process Memory)
Dump full process memory for analysis.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} memdump -p {{PID:int}} --dump-dir={{OUTDIR:dir:./dump}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,memdump -->

---

## v2 - Cmdline / Cmdscan / Consoles
Show process command lines and historical console buffers.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} cmdline
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,cmdline -->

---

## v2 - Network Connections (Netscan)
Show TCP/UDP endpoints captured in the memory image.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} netscan
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,network -->

---

## v2 - Registry Hives & Printkey
List loaded registry hives and dump a key by path.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} printkey -K "{{KEY:str:Software\\Microsoft\\Windows\\CurrentVersion}}"
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,registry -->

---

## v2 - Filescan
List files referenced in physical memory.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} filescan
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,filescan -->

---

## v2 - Dump File by Offset
Recover a specific file from memory by virtual offset.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} dumpfiles --dump-dir={{OUTDIR:dir:./out}} -Q {{OFFSET:str:0x000000007e6cd7f0}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,dumpfile -->

---

## v2 - Malfind
Detect injected/hollowed code regions in process memory.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} malfind
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,malfind -->

---

## v2 - YARA Scan
Apply YARA rules across memory regions.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} yarascan -y {{RULES:file:rules.yar}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,yara -->

---

## v2 - Clipboard Contents
Extract clipboard data captured at dump time.

```bash
volatility --profile={{PROFILE:str:Win7SP1x64}} -f {{DUMP:file:memory.raw}} clipboard
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,clipboard -->

---

## v3 - Image Info (Windows)
Modern Windows image info with arch, version, and KDBG.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.info
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,info -->

---

## v3 - Process List
List processes using Volatility 3 (no profile required).

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.pslist
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,pslist -->

---

## v3 - Process Tree
Show process parent/child relationships.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.pstree
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,pstree -->

---

## v3 - Dump Files
Dump executable and DLLs for a PID with output directory.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} -o {{OUTDIR:dir:./out}} windows.dumpfiles --pid {{PID:int}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,dumpfiles -->

---

## v3 - File Scan + Grep
Scan for files and grep for an interesting filename.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.filescan | grep -i "{{NEEDLE:str:secret}}"
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,filescan -->

---

## v3 - Memmap Dump
Dump complete process memory mappings.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} -o {{OUTDIR:dir:./out}} windows.memmap --dump --pid {{PID:int}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,memmap -->

---

## v3 - Network State
Modern netscan/netstat plugin for active connections.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.netscan
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,network -->

---

## v3 - Registry Printkey
Dump a registry key directly from the hive in memory.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.registry.printkey --key "{{KEY:str:Software\\Microsoft\\Windows\\CurrentVersion}}"
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,registry -->

---

## v3 - Malfind
Detect suspicious memory pages (RWX, hollowing).

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.malfind
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,malfind -->

---

## v3 - YARA Scan (VAD)
Run YARA against process VAD regions.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.vadyarascan --yara-file {{RULES:file:rules.yar}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,yara -->
