# awk / sed

> Stream processing and text transformation for structured and unstructured data

<!-- tags: awk, sed, text, processing, transform, columns -->

---

## Awk Print Columns
Print specific columns from whitespace-delimited output.

```bash
awk '{print ${{COL1:int:1}}, ${{COL2:int:3}}}' {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,columns,print -->

---

## Awk Custom Field Separator
Split fields on a custom delimiter.

```bash
awk -F'{{DELIM:str::}}' '{print ${{COL:int:1}}}' {{FILE:file:/etc/passwd}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,delimiter,separator -->

---

## Awk Pattern Matching
Print lines matching a pattern.

```bash
awk '/{{PATTERN:str:root}}/' {{FILE:file:/etc/passwd}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,pattern,filter -->

---

## Awk Sum a Column
Sum all values in a numeric column.

```bash
awk '{sum += ${{COL:int:1}}} END {print sum}' {{FILE:file:data.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,sum,math -->

---

## Awk Count Lines by Pattern
Count occurrences of lines matching a pattern.

```bash
awk '/{{PATTERN:str:error}}/{count++} END {print count}' {{FILE:file:log.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,count,pattern -->

---

## Awk CSV Column Extraction
Extract a column from CSV data.

```bash
awk -F',' '{print ${{COL:int:2}}}' {{FILE:file:data.csv}}
```

<!-- meta: risk=safe | phase=misc | tags=awk,csv,extract -->

---

## Sed Find and Replace
Replace first occurrence of a pattern on each line.

```bash
sed 's/{{FIND:str:old}}/{{REPLACE:str:new}}/' {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=sed,replace,substitute -->

---

## Sed Global Replace In-Place
Replace all occurrences in a file, editing it in place with backup.

```bash
sed -i.bak 's/{{FIND:str:old}}/{{REPLACE:str:new}}/g' {{FILE:file:input.txt}}
```

<!-- meta: risk=med | phase=misc | tags=sed,global,inplace,backup -->

---

## Sed Delete Lines by Pattern
Remove lines matching a pattern.

```bash
sed '/{{PATTERN:str:^#}}/d' {{FILE:file:config.conf}}
```

<!-- meta: risk=safe | phase=misc | tags=sed,delete,lines,filter -->

---

## Sed Extract Line Range
Print a specific range of lines from a file.

```bash
sed -n '{{START:int:10}},{{END:int:20}}p' {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=sed,range,extract,lines -->

---

## Sed Insert Line Before Match
Insert text before the first line matching a pattern.

```bash
sed '/{{PATTERN:str:match}}/i {{TEXT:str:inserted line}}' {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=sed,insert,before -->
