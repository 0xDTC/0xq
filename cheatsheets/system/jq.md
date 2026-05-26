# jq

> Command-line JSON processor

<!-- tags: jq,json,parse,filter -->

---

## pretty print json
Format JSON for readability.

```bash
jq . {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=format -->

---

## extract fields json
Pull a subset of top-level keys from each object.

```bash
jq '. | {{{FIELDS:str:timestamp,report}}}' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=extract -->

---

## iterate array json
Iterate items in an array and project fields.

```bash
jq '.{{ARRAY:str:results}}[] | {name, age}' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=array,iterate -->

---

## filter json equality
Select objects where a field matches a value.

```bash
jq '.{{ARRAY:str:results}}[] | select(.{{KEY:str:name}} == "{{VALUE:str:John}}")' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=filter,select -->

---

## filter json substring
Select objects whose field contains a substring.

```bash
jq '.{{ARRAY:str:results}}[] | select(.{{KEY:str:name}} | contains("{{NEEDLE:str}}"))' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=contains,substring -->

---

## raw strings json
Output raw strings without JSON quoting.

```bash
jq -r '.{{ARRAY:str:results}}[].{{KEY:str:name}}' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=raw -->

---

## get keys json
Get an array of keys from a JSON object.

```bash
jq '.{{KEY:str:items}} | keys' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=keys -->

---

## delete key json
Remove a key from JSON objects.

```bash
jq 'del(.{{KEY:str:secret}})' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=delete -->

---

## merge json files
Deep-merge two JSON files.

```bash
jq -s '.[0] * .[1]' {{FILE1:file:a.json}} {{FILE2:file:b.json}}
```

<!-- meta: risk=safe | phase=misc | tags=merge -->

---

## url encode json
Quick URL-encoding helper.

```bash
echo -n "{{INPUT:str}}" | jq -sRr @uri
```

<!-- meta: risk=safe | phase=misc | tags=url-encode -->

---

## extract to_entries json
Walk dynamic keys via to_entries.

```bash
jq '. | to_entries[] | select(.key | contains("{{NEEDLE:str:prop}}"))' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=dynamic-keys -->
