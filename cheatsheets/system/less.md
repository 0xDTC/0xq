# less

> Terminal pager for viewing and searching large files

<!-- tags: less,pager,view -->

---

## view file
Open a file in less.

```bash
less {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=view -->

---

## view file line numbers
Display line numbers while paging.

```bash
less -N {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=line-numbers -->

---

## view file truncate lines
Disable line wrapping for tabular data.

```bash
less -S {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=truncate -->

---

## view file color
Render ANSI color escapes.

```bash
less -R {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=color -->

---

## view compressed file
Page a gzipped file without manual decompression.

```bash
less -z {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=gzip -->

---

## view csv columns
Combine column with less to view CSVs.

```bash
column -s, -t {{INFILE:file:data.csv}} | less -S
```

<!-- meta: risk=safe | phase=misc | tags=csv,column -->
