# Volatility

> Memory forensics framework for analyzing RAM dumps

<!-- tags: volatility, memory, forensics, dfir -->

---

## image info volatility v2
Detect the OS profile from a memory dump.

```bash
volatility -f {{DUMP:file:memory.raw}} imageinfo
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,imageinfo -->

---

## kdbg scan volatility v2
Find KDBG when imageinfo is inconclusive.

```bash
volatility -f {{DUMP:file:memory.raw}} kdbgscan
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,kdbg -->

---

## list processes volatility v2
List processes (pslist), hidden (psscan), and the tree (pstree).

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str:Win7SP1x64}} pslist
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,pslist -->

---

## scan hidden processes volatility v2
Find processes hidden via DKOM by scanning physical memory.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str:Win7SP1x64}} psscan
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,psscan,hidden -->

---

## dump process volatility v2
Dump an executable for a given PID with associated DLLs.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} procdump -p {{PID:int}} --dump-dir={{OUTDIR:dir:./dump}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,procdump -->

---

## dump process memory volatility v2
Dump full process memory for analysis.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} memdump -p {{PID:int}} --dump-dir={{OUTDIR:dir:./dump}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,memdump -->

---

## dump cmdline volatility v2
Show process command lines and historical console buffers.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} cmdline
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,cmdline -->

---

## list connections volatility v2 netscan
Show TCP/UDP endpoints captured in the memory image.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} netscan
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,network -->

---

## dump registry volatility v2 printkey
List loaded registry hives and dump a key by path.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} printkey -K "{{KEY:str:Software\\Microsoft\\Windows\\CurrentVersion}}"
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,registry -->

---

## scan files volatility v2
List files referenced in physical memory.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} filescan
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,filescan -->

---

## dump file offset volatility v2
Recover a specific file from memory by virtual offset.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} dumpfiles --dump-dir={{OUTDIR:dir:./out}} -Q {{OFFSET:str:0x000000007e6cd7f0}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,dumpfile -->

---

## find malware volatility v2 malfind
Detect injected/hollowed code regions in process memory.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} malfind
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,malfind -->

---

## yara scan volatility v2
Apply YARA rules across memory regions.

```bash
volatility -f {{DUMP:file:memory.raw}} --profile {{PROFILE:str}} yarascan -y {{RULES:file:rules.yar}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,yara -->

---

## dump clipboard volatility v2
Extract clipboard data captured at dump time.

```bash
volatility --profile={{PROFILE:str:Win7SP1x64}} -f {{DUMP:file:memory.raw}} clipboard
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v2,clipboard -->

---

## image info volatility v3
Modern Windows image info with arch, version, and KDBG.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.info
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,info -->

---

## list processes volatility v3
List processes using Volatility 3 (no profile required).

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.pslist
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,pslist -->

---

## process tree volatility v3
Show process parent/child relationships.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.pstree
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,pstree -->

---

## dump files volatility v3
Dump executable and DLLs for a PID with output directory.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} -o {{OUTDIR:dir:./out}} windows.dumpfiles --pid {{PID:int}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,dumpfiles -->

---

## scan files volatility v3 grep
Scan for files and grep for an interesting filename.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.filescan | grep -i "{{NEEDLE:str:secret}}"
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,filescan -->

---

## dump memmap volatility v3
Dump complete process memory mappings.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} -o {{OUTDIR:dir:./out}} windows.memmap --dump --pid {{PID:int}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,memmap -->

---

## list connections volatility v3
Modern netscan/netstat plugin for active connections.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.netscan
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,network -->

---

## dump registry volatility v3 printkey
Dump a registry key directly from the hive in memory.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.registry.printkey --key "{{KEY:str:Software\\Microsoft\\Windows\\CurrentVersion}}"
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,registry -->

---

## find malware volatility v3 malfind
Detect suspicious memory pages (RWX, hollowing).

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.malfind
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,malfind -->

---

## yara scan volatility v3 vad
Run YARA against process VAD regions.

```bash
python3 vol.py -f {{DUMP:file:memory.raw}} windows.vadyarascan --yara-file {{RULES:file:rules.yar}}
```

<!-- meta: risk=safe | phase=misc | tags=volatility,v3,yara -->
