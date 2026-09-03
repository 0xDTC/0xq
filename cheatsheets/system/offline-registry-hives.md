# Offline Registry Hive Analysis

> Parse dead Windows registry hives (NTUSER.DAT, UsrClass.dat, SAM, SYSTEM, SOFTWARE, SECURITY, DEFAULT, Amcache.hve) pulled from KAPE, Velociraptor, F-Response, or an image mount. Live-system registry lives in windows-registry.md. Kali ships regripper, reglookup, hivex tools out of the box.

<!-- tags: dfir,registry,hives,regripper,reglookup,hivex,amcache,shellbags,userassist,offline -->

## regripper list all plugins
Print every RegRipper plugin (v20xxx). Grep this list to find the plugin for the artifact you want (shellbags, userassist, appcompatcache, amcache, mountpoints2, comdlg32, typedpaths, wordwheelquery, runmru, sizes, syscache).

```bash
regripper -l | less
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,plugins,discovery -->

---

## regripper run all applicable plugins on a hive
Auto-detect the hive type (NTUSER, SOFTWARE, SAM, SYSTEM, SECURITY, USRCLASS, AMCACHE) and run every plugin that applies. Fast triage of an unfamiliar hive.

```bash
regripper -r {{HIVE:file:./NTUSER.DAT}} -a > {{OUT:file:./ripper.txt}}
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,triage,all-plugins -->

---

## regripper single plugin
Run one named plugin. Most-used plugins on NTUSER/USRCLASS: `userassist` (executed GUI programs with counts + last-run), `recentdocs` (recently opened files by ext), `shellbags` (folders navigated in Explorer, incl. network shares + zip contents), `typedpaths` (Explorer address bar history), `runmru` (Win+R commands), `wordwheelquery` (Start Menu searches), `comdlg32` (Open/Save dialog history), `mountpoints2` (mapped drives).

```bash
regripper -r {{HIVE:file:./NTUSER.DAT}} -p {{PLUGIN:str:userassist}}
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,plugin,artifact -->

---

## regripper shellbags with columns
USRCLASS.DAT shellbags is the single most useful DFIR key on modern Windows. Columns from left to right: MRU Time | Modified | Accessed | Created | Zip_Subfolder_Time | MFT ref | Resource path. `Accessed` is when the shell touched the folder (subject to NTFS last-access flag).

```bash
regripper -r {{USRCLASS:file:./UsrClass.dat}} -p shellbags | column -t -s '|'
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,shellbags,timeline -->

---

## regripper amcache installed + run history
Amcache.hve records every PE the OS has seen (installers, EXEs, drivers) with SHA-1 and product info. Best single source for "did this binary ever run".

```bash
regripper -r {{AMCACHE:file:./Amcache.hve}} -p amcache > {{OUT:file:./amcache.txt}}
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,amcache,executed,sha1 -->

---

## regripper SAM local users
Pull local account names, RIDs, creation dates, last login, failed-logon counts, group memberships from the SAM hive.

```bash
regripper -r {{SAM:file:./SAM}} -p samparse
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,sam,users,accounts -->

---

## regripper SYSTEM services + boot config
Enumerate services (name, start type, image path), scheduled tasks references, and mounted volumes from SYSTEM.

```bash
regripper -r {{SYSTEM:file:./SYSTEM}} -p services
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,system,services -->

---

## regripper SOFTWARE persistence keys
Dump Run, RunOnce, Winlogon Shell/Userinit, AppInit_DLLs, IFEO, LSA, image-hijack keys from SOFTWARE. Compare against a known-good baseline to spot persistence.

```bash
regripper -r {{SOFTWARE:file:./SOFTWARE}} -p uninstall > {{OUT:file:./software-uninstall.txt}}
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,software,persistence -->

---

## reglookup dump every key value in a hive
Full flat dump: `/path/subkey,TYPE,value,mtime`. Best when you want to grep the whole hive for a keyword (a domain, a path, a filename).

```bash
reglookup {{HIVE:file:./SYSTEM}} > {{OUT:file:./system.csv}}
```

<!-- meta: risk=safe | phase=dfir | tags=reglookup,dump,csv -->

---

## reglookup one specific key
Query only a subpath. Useful for PortProxy, Services, Run, etc.

```bash
reglookup -p {{KEYPATH:str:/ControlSet001/Services/PortProxy}} {{HIVE:file:./SYSTEM}}
```

<!-- meta: risk=safe | phase=dfir | tags=reglookup,portproxy,targeted -->

---

## reglookup search hive by value name pattern
Regex-match value names across every key in the hive.

```bash
reglookup {{HIVE:file:./SYSTEM}} | grep -E {{REGEX:str:'PortProxy|PortMapping|Enabled'}}
```

<!-- meta: risk=safe | phase=dfir | tags=reglookup,grep,search -->

---

## hivexregedit export hive to .reg
Convert a whole hive to a Windows-style .reg text file (import-back-friendly, human readable).

```bash
hivexregedit --export {{HIVE:file:./NTUSER.DAT}} {{PREFIX:str:HKEY_CURRENT_USER}} > {{OUT:file:./ntuser.reg}}
```

<!-- meta: risk=safe | phase=dfir | tags=hivex,export,reg -->

---

## hivexget single value quickly
Grab one value without a full export. Faster than reglookup for one-shots inside scripts.

```bash
hivexget {{HIVE:file:./SYSTEM}} {{KEYPATH:str:'ControlSet001\Services\PortProxy\v4tov4\tcp'}} {{VALUE:str:'0.0.0.0/9999'}}
```

<!-- meta: risk=safe | phase=dfir | tags=hivex,hivexget,value -->

---

## hivex mount hive as filesystem (fuse)
Mount the hive at a path so you can `ls` and `cat` it. Handy for interactive exploration.

```bash
hivexml {{HIVE:file:./SYSTEM}} > {{OUT:file:./system.xml}}
```

<!-- meta: risk=safe | phase=dfir | tags=hivex,xml,mount -->

---

## KAPE-collected hives standard layout
Typical KAPE `KapeTriage` / `RegistryHivesUser` layout to walk when you receive a triage zip.

```bash
find {{TRIAGE:path:./KapeOutput/C}} -iname 'NTUSER.DAT' -o -iname 'UsrClass.dat' -o -iname 'SYSTEM' -o -iname 'SOFTWARE' -o -iname 'SECURITY' -o -iname 'SAM' -o -iname 'Amcache.hve' 2>/dev/null
```

<!-- meta: risk=safe | phase=dfir | tags=kape,triage,layout -->

---

## batch all hives with regripper (per-user + system)
Loop each hive through the right plugin set into a per-hive output file.

```bash
for h in NTUSER.DAT UsrClass.dat SAM SYSTEM SOFTWARE SECURITY Amcache.hve; do f=$(find {{TRIAGE:path:./KapeOutput/C}} -iname "$h" 2>/dev/null | head -1); [ -n "$f" ] && regripper -r "$f" -a > {{OUTDIR:path:./ripper}}/"$h".txt; done
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,batch,triage -->

---

## rebuild fzf index after adding this cheatsheet
Force `q` to re-scan and pick up the new file.

```bash
q rebuild
```

<!-- meta: risk=safe | phase=util | tags=q,rebuild,index -->
