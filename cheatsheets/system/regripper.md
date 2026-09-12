# regripper

> Offline Windows registry hive analysis. Runs plugins that decode NTUSER.DAT, USRCLASS.DAT, SAM, SYSTEM, SOFTWARE, SECURITY, and Amcache.hve hives pulled from KAPE, Velociraptor, F-Response, or a mounted image. Live-system registry lives in windows-registry.md.

<!-- tags: dfir,registry,hive,regripper,ntuser,usrclass,sam,software,amcache,shellbags,userassist,offline -->
<!-- platform: windows -->

## list all plugins
Print every RegRipper plugin (v20xxx). Grep this list to find the plugin for the artifact you want (shellbags, userassist, appcompatcache, amcache, mountpoints2, comdlg32, typedpaths, wordwheelquery, runmru, sizes, syscache).

```bash
regripper -l | less
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,plugins,discovery -->

---

## run all applicable plugins on a hive
Auto-detect the hive type (NTUSER, SOFTWARE, SAM, SYSTEM, SECURITY, USRCLASS, AMCACHE) and run every plugin that applies. Fast triage of an unfamiliar hive.

```bash
regripper -r {{HIVE:file:./NTUSER.DAT}} -a > {{OUT:file:./ripper.txt}}
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,triage,all-plugins -->

---

## single plugin
Run one named plugin. Most-used plugins on NTUSER/USRCLASS: `userassist` (executed GUI programs with counts + last-run), `recentdocs` (recently opened files by ext), `shellbags` (folders navigated in Explorer, incl. network shares + zip contents), `typedpaths` (Explorer address bar history), `runmru` (Win+R commands), `wordwheelquery` (Start Menu searches), `comdlg32` (Open/Save dialog history), `mountpoints2` (mapped drives).

```bash
regripper -r {{HIVE:file:./NTUSER.DAT}} -p {{PLUGIN:choice:userassist=executed GUI programs,recentdocs=recently opened files,shellbags=folders navigated in Explorer,typedpaths=Explorer address bar history,runmru=Win+R command history,wordwheelquery=Start Menu search terms,comdlg32=Open/Save dialog history,mountpoints2=mapped network drives,muicache=binaries whose UI was shown,uninstall=installed programs list,samparse=local users and RIDs,services=Windows services list,appcompatcache=Shimcache execution evidence,amcache=every PE seen by OS,timezone=system timezone,mounted_devices=drive-letter history,usbstor=USB device history,portproxy=netsh portproxy rules,run=Run/RunOnce autostart,winlogon=Winlogon Shell+Userinit,appinit=AppInit_DLLs autoload}}
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,plugin,artifact -->

---

## shellbags with columns
USRCLASS.DAT shellbags is the single most useful DFIR key on modern Windows. Columns from left to right: MRU Time | Modified | Accessed | Created | Zip_Subfolder_Time | MFT ref | Resource path. `Accessed` is when the shell touched the folder (subject to NTFS last-access flag).

```bash
regripper -r {{USRCLASS:file:./UsrClass.dat}} -p shellbags | column -t -s '|'
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,shellbags,timeline -->

---

## amcache installed + run history
Amcache.hve records every PE the OS has seen (installers, EXEs, drivers) with SHA-1 and product info. Best single source for "did this binary ever run".

```bash
regripper -r {{AMCACHE:file:./Amcache.hve}} -p amcache > {{OUT:file:./amcache.txt}}
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,amcache,executed,sha1 -->

---

## SAM local users
Pull local account names, RIDs, creation dates, last login, failed-logon counts, group memberships from the SAM hive.

```bash
regripper -r {{SAM:file:./SAM}} -p samparse
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,sam,users,accounts -->

---

## SYSTEM services + boot config
Enumerate services (name, start type, image path), scheduled tasks references, and mounted volumes from SYSTEM.

```bash
regripper -r {{SYSTEM:file:./SYSTEM}} -p services
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,system,services -->

---

## SOFTWARE persistence keys
Dump Run, RunOnce, Winlogon Shell/Userinit, AppInit_DLLs, IFEO, LSA, image-hijack keys from SOFTWARE. Compare against a known-good baseline to spot persistence.

```bash
regripper -r {{SOFTWARE:file:./SOFTWARE}} -p uninstall > {{OUT:file:./software-uninstall.txt}}
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,software,persistence -->

---

## batch all hives (per-user + system)
Loop each hive through the auto-plugin set into a per-hive output file. Combine with KAPE triage output.

```bash
for h in NTUSER.DAT UsrClass.dat SAM SYSTEM SOFTWARE SECURITY Amcache.hve; do f=$(find {{TRIAGE:path:./KapeOutput/C}} -iname "$h" 2>/dev/null | head -1); [ -n "$f" ] && regripper -r "$f" -a > {{OUTDIR:path:./ripper}}/"$h".txt; done
```

<!-- meta: risk=safe | phase=dfir | tags=regripper,batch,triage -->
