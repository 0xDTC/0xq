# find

> Search for files and directories in a hierarchy based on name, size, time, permissions, and more

<!-- tags: find, search, files, privesc, enumeration -->

---

## Find by Name
Locate files by exact or partial name match.

```bash
find {{PATH:dir:/}} -name "{{PATTERN:str:*.conf}}" 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=name,search,basic -->

---

## Find by Extension
Find all files with a specific extension recursively.

```bash
find {{PATH:dir:.}} -type f -name "*.{{EXT:str:txt}}" 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=extension,type,files -->

---

## Find by Size
Find files larger or smaller than a given size (use + for larger, - for smaller).

```bash
find {{PATH:dir:/}} -type f -size +{{SIZE:str:100M}} 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=size,large,disk -->

---

## Find by Modification Time
Find files modified within the last N days (use -mmin for minutes).

```bash
find {{PATH:dir:/}} -type f -mtime -{{DAYS:int:7}} 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=time,modified,recent -->

---

## Find SUID Binaries
Find all SUID binaries on the system. Critical for privilege escalation.

```bash
find / -perm -4000 -type f 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=suid,privesc,permissions -->

---

## Find SGID Binaries
Find all SGID binaries on the system.

```bash
find / -perm -2000 -type f 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=sgid,privesc,permissions -->

---

## Find World-Writable Directories
Find directories writable by anyone. Useful for dropping payloads.

```bash
find / -type d -writable 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=writable,directories,privesc -->

---

## Find by Owner
Find all files owned by a specific user.

```bash
find {{PATH:dir:/}} -user {{USER:str:root}} -type f 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=owner,user,permissions -->

---

## Find and Execute Command
Find files matching a pattern and run a command on each result.

```bash
find {{PATH:dir:.}} -name "{{PATTERN:str:*.log}}" -exec {{CMD:str:grep -l "password"}} {} \;
```

<!-- meta: risk=low | phase=misc | tags=exec,command,action -->

---

## Find and Delete
Find and remove files matching a pattern. Use with caution.

```bash
find {{PATH:dir:.}} -name "{{PATTERN:str:*.tmp}}" -type f -delete
```

<!-- meta: risk=high | phase=misc | tags=delete,cleanup,dangerous -->

---

## Find Files Containing Text
Find files that contain a specific string (combines find with grep).

```bash
find {{PATH:dir:.}} -type f -name "{{PATTERN:str:*.php}}" -exec grep -l "{{TEXT:str:password}}" {} \; 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=content,grep,search -->

---

## Find Files with No Owner
Find orphaned files with no valid user or group. May indicate compromise.

```bash
find {{PATH:dir:/}} -nouser -o -nogroup 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=noowner,orphan,audit -->

---

## Find by Size Range
Files larger than min and smaller than max size.

```bash
find {{PATH:dir:/}} -type f -size +{{MIN:str:100M}} -size -{{MAX:str:500M}} 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=size,range -->

---

## Files Accessed in Last Hour
Find files accessed within the last N minutes.

```bash
find {{PATH:dir:/}} -type f -amin -{{MINUTES:int:60}} 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=atime,recent -->

---

## Find Conf Files Newer Than Date
Locate root-owned conf files modified after a given date.

```bash
find {{PATH:dir:/}} -type f -name "*.{{EXT:str:conf}}" -user {{USER:str:root}} -newermt {{DATE:str:2025-01-01}} 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=date,conf,owner -->

---

## Find Files Modified Between Dates
Files modified after one date but not after another.

```bash
find {{PATH:dir:/}} -newermt "{{START:str:2025-01-01}}" ! -newermt "{{END:str:2025-03-15}}" 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=date-range -->

---

## Find Files with 777 Permissions
Discover world-writable/executable files.

```bash
find {{PATH:dir:/}} -type f -perm 0777 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=permissions,777 -->
