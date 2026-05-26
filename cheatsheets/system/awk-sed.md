# awk / sed

> Stream processing and text transformation for structured and unstructured data

<!-- tags: awk, sed, text, processing, transform, columns -->

---

## print columns awk
Print specific columns from whitespace-delimited output.

```bash
awk '{print ${{COL1:int:1}}, ${{COL2:int:3}}}' {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,columns,print -->

---

## awk custom field separator
Split fields on a custom delimiter.

```bash
awk -F'{{DELIM:str::}}' '{print ${{COL:int:1}}}' {{FILE:file:/etc/passwd}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,delimiter,separator -->

---

## awk match pattern lines
Print lines matching a pattern.

```bash
awk '/{{PATTERN:str:root}}/' {{FILE:file:/etc/passwd}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,pattern,filter -->

---

## sum column awk
Sum all values in a numeric column.

```bash
awk '{sum += ${{COL:int:1}}} END {print sum}' {{FILE:file:data.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,sum,math -->

---

## count lines by pattern awk
Count occurrences of lines matching a pattern.

```bash
awk '/{{PATTERN:str:error}}/{count++} END {print count}' {{FILE:file:log.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,count,pattern -->

---

## extract csv column awk
Extract a column from CSV data.

```bash
awk -F',' '{print ${{COL:int:2}}}' {{FILE:file:data.csv}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,csv,extract -->

---

## sed find and replace
Replace first occurrence of a pattern on each line.

```bash
sed 's/{{FIND:str:old}}/{{REPLACE:str:new}}/' {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=sed,replace,substitute -->

---

## sed global replace inplace
Replace all occurrences in a file, editing it in place with backup.

```bash
sed -i.bak 's/{{FIND:str:old}}/{{REPLACE:str:new}}/g' {{FILE:file:input.txt}}
```

<!-- meta: risk=med | phase=misc | tags=sed,global,inplace,backup -->

---

## sed delete lines by pattern
Remove lines matching a pattern.

```bash
sed '/{{PATTERN:str:^#}}/d' {{FILE:file:config.conf}}
```

<!-- meta: risk=safe | phase=misc | tags=sed,delete,lines,filter -->

---

## sed extract line range
Print a specific range of lines from a file.

```bash
sed -n '{{START:int:10}},{{END:int:20}}p' {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=sed,range,extract,lines -->

---

## sed insert line before match
Insert text before the first line matching a pattern.

```bash
sed '/{{PATTERN:str:match}}/i {{TEXT:str:inserted line}}' {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=sed,insert,before -->
