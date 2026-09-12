# hivex

> libhivex family (`hivexregedit`, `hivexget`, `hivexml`) — read/export Windows registry hives from Linux. Faster than regripper for one-off value grabs or full-hive dumps to text.

<!-- tags: dfir,registry,hive,hivex,hivexregedit,hivexget,hivexml,export,offline -->
<!-- platform: windows -->

## hivexregedit export hive to .reg
Convert a whole hive to a Windows-style .reg text file (import-back-friendly, human readable).

```bash
hivexregedit --export {{HIVE:file:./NTUSER.DAT}} {{PREFIX:choice:HKEY_CURRENT_USER=NTUSER.DAT hive,HKEY_LOCAL_MACHINE=SAM/SYSTEM/SOFTWARE,HKEY_USERS=all loaded user hives,HKEY_CLASSES_ROOT=file assoc + COM,HKEY_CURRENT_CONFIG=current hardware profile}} > {{OUT:file:./ntuser.reg}}
```

<!-- meta: risk=safe | phase=dfir | tags=hivex,hivexregedit,export,reg -->

---

## hivexget single value quickly
Grab one value without a full export. Faster than reglookup for one-shots inside scripts.

```bash
hivexget {{HIVE:file:./SYSTEM}} {{KEYPATH:str:'ControlSet001\Services\PortProxy\v4tov4\tcp'}} {{VALUE:str:'0.0.0.0/9999'}}
```

<!-- meta: risk=safe | phase=dfir | tags=hivex,hivexget,value -->

---

## hivexml dump whole hive to xml
Emit the entire hive as XML — machine-parseable, good for feeding into custom tooling or diffing between hives.

```bash
hivexml {{HIVE:file:./SYSTEM}} > {{OUT:file:./system.xml}}
```

<!-- meta: risk=safe | phase=dfir | tags=hivex,hivexml,xml,dump -->
