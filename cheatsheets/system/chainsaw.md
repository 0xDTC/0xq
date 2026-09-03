# Chainsaw

> Fast Windows EVTX (event log) parser and hunter from WithSecure Countercept. Two modes: dump every event to YAML/JSON for offline grep, or hunt against Sigma / Chainsaw rules for known bad patterns. Runs on Kali natively.

<!-- tags: dfir,chainsaw,evtx,windows-event-log,sigma,hunt,triage -->

## dump one evtx to yaml
Convert a single EVTX to YAML for grep/awk work. Best when you know what to look for.

```bash
chainsaw dump -o {{OUT:file:./sec.yaml}} {{EVTX:file:./Security.evtx}}
```

<!-- meta: risk=safe | phase=dfir | tags=chainsaw,dump,yaml -->

---

## dump one evtx to json
JSON output for jq / structured pipelines.

```bash
chainsaw dump --json -o {{OUT:file:./sec.json}} {{EVTX:file:./Security.evtx}}
```

<!-- meta: risk=safe | phase=dfir | tags=chainsaw,dump,json,jq -->

---

## dump every evtx in a folder
Recurse a KAPE / triage evtx directory, one output file per input.

```bash
chainsaw dump -o {{OUTDIR:path:./yaml_out}} {{EVTXDIR:path:./Windows/System32/winevt/logs}}
```

<!-- meta: risk=safe | phase=dfir | tags=chainsaw,batch,triage -->

---

## hunt with default rules
Run Chainsaw + Sigma rules over an evtx directory. Prints hits ranked by severity.

```bash
chainsaw hunt {{EVTXDIR:path:./winevt/logs}} -s /usr/share/chainsaw/sigma -r /usr/share/chainsaw/rules --mapping /usr/share/chainsaw/mappings/sigma-event-logs-all.yml
```

<!-- meta: risk=safe | phase=dfir | tags=chainsaw,hunt,sigma,detection -->

---

## hunt into csv report
Same hunt, structured CSV output for a report or Timesketch import.

```bash
chainsaw hunt {{EVTXDIR:path:./winevt/logs}} -s /usr/share/chainsaw/sigma --mapping /usr/share/chainsaw/mappings/sigma-event-logs-all.yml --csv --output {{OUTDIR:path:./chainsaw_csv}}
```

<!-- meta: risk=safe | phase=dfir | tags=chainsaw,csv,report -->

---

## search evtx for a keyword/regex
Fastest way to find a string across every event in a directory (much quicker than dumping first).

```bash
chainsaw search {{PATTERN:str:cmd.exe}} {{EVTXDIR:path:./winevt/logs}} --tau /usr/share/chainsaw/mappings/sigma-event-logs-all.yml
```

<!-- meta: risk=safe | phase=dfir | tags=chainsaw,search,grep -->

---

## filter one specific event id
Only events whose EventID matches. Common IDs: 4624 (logon), 4688 (proc create), 4104 (PS scriptblock), 7036 (service state), 1102 (audit log cleared).

```bash
chainsaw search -e "^{{EID:str:4688}}$" {{EVTXDIR:path:./winevt/logs}}
```

<!-- meta: risk=safe | phase=dfir | tags=chainsaw,eventid,filter -->

---

## filter by field value
Match one XPath-style field. Example: only 4624 with a specific user.

```bash
chainsaw search -e "^4624$" {{EVTXDIR:path:./winevt/logs}} -t "Event.EventData.TargetUserName={{USER:str:administrator}}"
```

<!-- meta: risk=safe | phase=dfir | tags=chainsaw,field,filter -->
