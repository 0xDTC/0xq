# reglookup

> Flat, greppable dump of Windows registry hives. Preferred when you want to keyword-search an entire hive for a filename, path, or domain — every key/value on one line with type + mtime.

<!-- tags: dfir,registry,hive,reglookup,csv,grep,offline -->
<!-- platform: windows -->

## dump every key value in a hive
Full flat dump: `/path/subkey,TYPE,value,mtime`. Best when you want to grep the whole hive for a keyword (a domain, a path, a filename).

```bash
reglookup {{HIVE:file:./SYSTEM}} > {{OUT:file:./system.csv}}
```

<!-- meta: risk=safe | phase=dfir | tags=reglookup,dump,csv -->

---

## one specific key
Query only a subpath. Useful for PortProxy, Services, Run, etc.

```bash
reglookup -p {{KEYPATH:str:/ControlSet001/Services/PortProxy}} {{HIVE:file:./SYSTEM}}
```

<!-- meta: risk=safe | phase=dfir | tags=reglookup,portproxy,targeted -->

---

## search hive by value name pattern
Regex-match value names across every key in the hive.

```bash
reglookup {{HIVE:file:./SYSTEM}} | grep -E {{REGEX:str:'PortProxy|PortMapping|Enabled'}}
```

<!-- meta: risk=safe | phase=dfir | tags=reglookup,grep,search -->
