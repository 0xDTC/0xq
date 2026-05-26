# Text Processing

> Essential text manipulation tools: cut, sort, uniq, tr, wc, xargs, and more

<!-- tags: text, cut, sort, uniq, tr, wc, xargs, processing -->

---

## cut fields by delimiter
Extract specific fields from delimited text.

```bash
cut -d'{{DELIM:str::}}' -f{{FIELDS:str:1,3}} {{FILE:file:/etc/passwd}}
```

<!-- meta: risk=safe | phase=misc | tags=cut,delimiter,fields -->

---

## sort unique numerically
Sort lines numerically and remove duplicates.

```bash
sort -un {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=sort,unique,numeric -->

---

## sort by column
Sort by a specific column field.

```bash
sort -t'{{DELIM:str::}}' -k{{COL:int:3}} -n {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=sort,column,field -->

---

## count duplicate lines
Count and sort duplicate lines, showing most frequent first.

```bash
sort {{FILE:file:input.txt}} | uniq -c | sort -rn
```

<!-- meta: risk=safe | phase=misc | tags=uniq,count,duplicates,frequency -->

---

## show only duplicate lines
Display only lines that appear more than once.

```bash
sort {{FILE:file:input.txt}} | uniq -d
```

<!-- meta: risk=safe | phase=misc | tags=uniq,duplicates,repeated -->

---

## translate characters tr
Replace or transliterate characters (e.g., lowercase to uppercase).

```bash
cat {{FILE:file:input.txt}} | tr '{{FROM:str:a-z}}' '{{TO:str:A-Z}}'
```

<!-- meta: risk=safe | phase=misc | tags=tr,translate,case -->

---

## delete characters tr
Remove specific characters from input.

```bash
cat {{FILE:file:input.txt}} | tr -d '{{CHARS:str:\r\n}}'
```

<!-- meta: risk=safe | phase=misc | tags=tr,delete,strip -->

---

## count lines words bytes
Count lines, words, and bytes in a file.

```bash
wc -lwc {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=wc,count,lines,words -->

---

## run parallel xargs
Run a command on each line of input in parallel.

```bash
cat {{FILE:file:hosts.txt}} | xargs -I {} -P {{PROCS:int:10}} {{CMD:str:ping -c 1}} {}
```

<!-- meta: risk=low | phase=misc | tags=xargs,parallel,batch -->

---

## view head and tail lines
View the first or last N lines of a file.

```bash
head -n {{LINES:int:20}} {{FILE:file:input.txt}} && tail -n {{LINES2:int:20}} {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=head,tail,preview -->

---

## format aligned columns
Format delimited output into aligned columns for readability.

```bash
cat {{FILE:file:input.txt}} | column -t -s'{{DELIM:str:,}}'
```

<!-- meta: risk=safe | phase=misc | tags=column,format,align -->

---

## tee output to file
Write output to a file while also passing it through to stdout.

```bash
{{CMD:str:ls -la}} | tee {{OUTFILE:file:output.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=tee,output,file,pipe -->
