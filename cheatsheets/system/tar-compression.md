# tar / Compression

> Archive and compress files with tar, gzip, bzip2, xz, zip, and 7z

<!-- tags: tar, gzip, bzip2, xz, zip, 7z, compression, archive -->

---

## Create Gzipped Archive
Create a tar.gz archive of a directory.

```bash
tar czf {{OUTFILE:file:archive.tar.gz}} {{PATH:dir:./target}}
```

<!-- meta: risk=low | phase=misc | tags=tar,gzip,create -->

---

## Extract Gzipped Archive
Extract a tar.gz archive to a directory.

```bash
tar xzf {{ARCHIVE:file:archive.tar.gz}} -C {{DEST:dir:.}}
```

<!-- meta: risk=low | phase=misc | tags=tar,gzip,extract -->

---

## Create Bzip2 Archive
Create a tar.bz2 archive with higher compression.

```bash
tar cjf {{OUTFILE:file:archive.tar.bz2}} {{PATH:dir:./target}}
```

<!-- meta: risk=low | phase=misc | tags=tar,bzip2,create -->

---

## Create XZ Archive
Create a tar.xz archive with maximum compression.

```bash
tar cJf {{OUTFILE:file:archive.tar.xz}} {{PATH:dir:./target}}
```

<!-- meta: risk=low | phase=misc | tags=tar,xz,create -->

---

## List Archive Contents
List files in a tar archive without extracting.

```bash
tar tf {{ARCHIVE:file:archive.tar.gz}}
```

<!-- meta: risk=safe | phase=misc | tags=tar,list,contents -->

---

## Extract Single File from Archive
Extract only a specific file from a tar archive.

```bash
tar xzf {{ARCHIVE:file:archive.tar.gz}} {{FILEPATH:str:path/to/file.txt}}
```

<!-- meta: risk=low | phase=misc | tags=tar,extract,single -->

---

## Zip Create
Create a zip archive of a directory.

```bash
zip -r {{OUTFILE:file:archive.zip}} {{PATH:dir:./target}}
```

<!-- meta: risk=low | phase=misc | tags=zip,create,archive -->

---

## Zip Extract
Extract a zip archive.

```bash
unzip {{ARCHIVE:file:archive.zip}} -d {{DEST:dir:.}}
```

<!-- meta: risk=low | phase=misc | tags=unzip,extract -->

---

## 7z Compress
Create a 7z archive with high compression.

```bash
7z a {{OUTFILE:file:archive.7z}} {{PATH:dir:./target}}
```

<!-- meta: risk=low | phase=misc | tags=7z,compress,archive -->

---

## 7z Extract
Extract a 7z archive.

```bash
7z x {{ARCHIVE:file:archive.7z}} -o{{DEST:dir:./output}}
```

<!-- meta: risk=low | phase=misc | tags=7z,extract -->

---

## Gzip Single File
Compress a single file with gzip (replaces original).

```bash
gzip -k {{FILE:file:input.txt}}
```

<!-- meta: risk=low | phase=misc | tags=gzip,compress,single -->

---

## Gunzip Decompress
Decompress a gzip file.

```bash
gunzip {{FILE:file:input.txt.gz}}
```

<!-- meta: risk=low | phase=misc | tags=gunzip,decompress -->
