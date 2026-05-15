# less

> Terminal pager for viewing and searching large files

<!-- tags: less,pager,view -->

---

## View File
Open a file in less.

```bash
less {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=view -->

---

## With Line Numbers
Display line numbers while paging.

```bash
less -N {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=line-numbers -->

---

## Truncate Long Lines
Disable line wrapping for tabular data.

```bash
less -S {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=truncate -->

---

## Honor Color Codes
Render ANSI color escapes.

```bash
less -R {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=color -->

---

## View Compressed File
Page a gzipped file without manual decompression.

```bash
less -z {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=gzip -->

---

## CSV as Columns
Combine column with less to view CSVs.

```bash
column -s, -t {{INFILE:file:data.csv}} | less -S
```

<!-- meta: risk=safe | phase=misc | tags=csv,column -->
