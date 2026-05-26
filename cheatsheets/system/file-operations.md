# File Operations

> Core file management: copy, move, link, permissions, ownership, and disk usage

<!-- tags: files, cp, mv, chmod, chown, ln, stat, du, df, rsync -->

---

## copy files recursively
Copy a directory and all contents to a new location.

```bash
cp -r {{SRC:dir:./source}} {{DEST:dir:./destination}}
```

<!-- meta: risk=low | phase=misc | tags=cp,copy,recursive -->

---

## move or rename file
Move or rename a file or directory.

```bash
mv {{SRC:file:oldname.txt}} {{DEST:file:newname.txt}}
```

<!-- meta: risk=low | phase=misc | tags=mv,move,rename -->

---

## create symlink
Create a symlink pointing to a target file or directory.

```bash
ln -sf {{TARGET:file:/path/to/target}} {{LINK:file:/path/to/link}}
```

<!-- meta: risk=low | phase=misc | tags=ln,symlink,link -->

---

## set permissions chmod
Set standard permissions on files or directories recursively.

```bash
chmod -R {{MODE:str:755}} {{PATH:dir:./target}}
```

<!-- meta: risk=med | phase=misc | tags=chmod,permissions,recursive -->

---

## set SUID bit privesc
Set the SUID bit on a binary so it runs as the file owner.

```bash
chmod u+s {{FILE:file:/path/to/binary}}
```

<!-- meta: risk=high | phase=misc | tags=suid,chmod,privesc -->

---

## change ownership chown
Change the owner and group of a file or directory recursively.

```bash
chown -R {{OWNER:str:www-data}}:{{GROUP:str:www-data}} {{PATH:dir:/var/www}}
```

<!-- meta: risk=med | phase=misc | tags=chown,owner,group,recursive -->

---

## detect file type magic
Identify a file's actual type regardless of extension.

```bash
file {{FILE:file:unknown_file}}
```

<!-- meta: risk=safe | phase=misc | tags=file,type,identify,magic -->

---

## show file metadata stat
Display detailed metadata about a file including timestamps and permissions.

```bash
stat {{FILE:file:target.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=stat,metadata,timestamps -->

---

## disk usage directory size
Show the total size of a directory tree in human-readable format.

```bash
du -sh {{PATH:dir:.}}/*
```

<!-- meta: risk=safe | phase=misc | tags=du,disk,usage,size -->

---

## show filesystem disk space
Show available disk space on all mounted filesystems.

```bash
df -h
```

<!-- meta: risk=safe | phase=misc | tags=df,disk,space,filesystem -->

---

## rsync local copy sync
Efficiently copy and sync files locally with progress.

```bash
rsync -avh --progress {{SRC:dir:./source/}} {{DEST:dir:./destination/}}
```

<!-- meta: risk=low | phase=misc | tags=rsync,sync,copy,progress -->
