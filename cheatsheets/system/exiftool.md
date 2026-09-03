# exiftool

> Read and write metadata for hundreds of file types. In DFIR/malware work most-used for PE Version Info (CompanyName, ProductName, FileVersion, OriginalFilename), image EXIF (GPS, camera model), PDF metadata (author, creation tool), and Office document metadata (creator, template).

<!-- tags: dfir,malware,exiftool,metadata,pe,exif,pdf -->

## dump all metadata
Everything exiftool can read from the file.

```bash
exiftool {{FILE:file:./sample.exe}}
```

<!-- meta: risk=safe | phase=dfir | tags=exiftool,all -->

---

## PE Version Info (Windows binary attribution)
Company, product name, original filename, file version. Reveals when a binary is renamed AutoIt3 or a legitimate signed tool.

```bash
exiftool {{FILE:file:./sample.exe}} | grep -iE "^(File Name|Original File Name|Product Name|Company Name|File Version|Product Version|Internal Name|Legal Copyright)"
```

<!-- meta: risk=safe | phase=dfir | tags=exiftool,pe,version-info -->

---

## PDF metadata (author, creator tool)
Reveals authoring tool, template, revision history hints. Useful for phishing PDFs.

```bash
exiftool {{PDF:file:./document.pdf}} | grep -iE "^(Author|Creator|Producer|Title|Create Date|Modify Date|Company)"
```

<!-- meta: risk=safe | phase=dfir | tags=exiftool,pdf -->

---

## Office document metadata (docx, xlsx, pptx)
Original author, revision number, last saved by, template used.

```bash
exiftool {{DOC:file:./file.docx}} | grep -iE "^(Author|Creator|Last Modified By|Template|Application|Revision Number|Total Edit Time|Create Date|Modify Date)"
```

<!-- meta: risk=safe | phase=dfir | tags=exiftool,office,docx -->

---

## image EXIF (camera, GPS)
Photo forensics: what camera, when, and where (if geotagging was on).

```bash
exiftool {{IMG:file:./photo.jpg}} | grep -iE "^(Make|Model|GPS|Date/Time|Software|Serial)"
```

<!-- meta: risk=safe | phase=dfir | tags=exiftool,image,gps,exif -->

---

## strip all metadata (defensive)
Sanitize a file before publishing (removes EXIF, PDF authorship, docx creator, etc.). `-P` preserves file dates.

```bash
exiftool -all= -overwrite_original -P {{FILE:file:./sanitize.pdf}}
```

<!-- meta: risk=low | phase=util | tags=exiftool,strip,sanitize -->

---

## recursive scan of a directory
CSV of chosen tags across every file in a folder.

```bash
exiftool -csv -r -Author -Creator -Producer -Title {{DIR:path:./docs}} > {{OUT:file:./metadata.csv}}
```

<!-- meta: risk=safe | phase=dfir | tags=exiftool,batch,csv -->

---

## compare two files' metadata
Diff to spot timestamp forgery, template reuse, tampering.

```bash
diff <(exiftool {{A:file:./a.pdf}}) <(exiftool {{B:file:./b.pdf}})
```

<!-- meta: risk=safe | phase=dfir | tags=exiftool,diff,tamper -->
