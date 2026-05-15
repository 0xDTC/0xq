# jq

> Command-line JSON processor

<!-- tags: jq,json,parse,filter -->

---

## Pretty Print
Format JSON for readability.

```bash
jq . {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=format -->

---

## Extract Top-Level Fields
Pull a subset of top-level keys from each object.

```bash
jq '. | {{{FIELDS:str:timestamp,report}}}' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=extract -->

---

## Iterate Over Array
Iterate items in an array and project fields.

```bash
jq '.{{ARRAY:str:results}}[] | {name, age}' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=array,iterate -->

---

## Filter by Equality
Select objects where a field matches a value.

```bash
jq '.{{ARRAY:str:results}}[] | select(.{{KEY:str:name}} == "{{VALUE:str:John}}")' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=filter,select -->

---

## Filter by Substring
Select objects whose field contains a substring.

```bash
jq '.{{ARRAY:str:results}}[] | select(.{{KEY:str:name}} | contains("{{NEEDLE:str}}"))' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=contains,substring -->

---

## Raw Strings (No Quotes)
Output raw strings without JSON quoting.

```bash
jq -r '.{{ARRAY:str:results}}[].{{KEY:str:name}}' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=raw -->

---

## Get Object Keys
Get an array of keys from a JSON object.

```bash
jq '.{{KEY:str:items}} | keys' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=keys -->

---

## Delete a Key
Remove a key from JSON objects.

```bash
jq 'del(.{{KEY:str:secret}})' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=delete -->

---

## Merge Two Files
Deep-merge two JSON files.

```bash
jq -s '.[0] * .[1]' {{FILE1:file:a.json}} {{FILE2:file:b.json}}
```

<!-- meta: risk=safe | phase=misc | tags=merge -->

---

## URL-Encode Input
Quick URL-encoding helper.

```bash
echo -n "{{INPUT:str}}" | jq -sRr @uri
```

<!-- meta: risk=safe | phase=misc | tags=url-encode -->

---

## Extract via to_entries
Walk dynamic keys via to_entries.

```bash
jq '. | to_entries[] | select(.key | contains("{{NEEDLE:str:prop}}"))' {{INFILE:file:data.json}}
```

<!-- meta: risk=safe | phase=misc | tags=dynamic-keys -->
