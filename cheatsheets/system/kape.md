# kape

> KAPE (Kroll Artifact Parser and Extractor) triage output layout. KAPE runs on Windows and drops evidence into a target directory; these recipes walk that directory from Linux.

<!-- tags: dfir,kape,triage,hives,registry,evidence -->
<!-- platform: windows -->

## collected hives standard layout
Walk a `KapeTriage` / `RegistryHivesUser` collection and enumerate every registry hive KAPE typically pulls (NTUSER.DAT, UsrClass.dat, SAM, SYSTEM, SOFTWARE, SECURITY, Amcache.hve). Feed the paths into regripper / reglookup / hivex.

```bash
find {{TRIAGE:path:./KapeOutput/C}} -iname 'NTUSER.DAT' -o -iname 'UsrClass.dat' -o -iname 'SYSTEM' -o -iname 'SOFTWARE' -o -iname 'SECURITY' -o -iname 'SAM' -o -iname 'Amcache.hve' 2>/dev/null
```

<!-- meta: risk=safe | phase=dfir | tags=kape,triage,layout,find -->
