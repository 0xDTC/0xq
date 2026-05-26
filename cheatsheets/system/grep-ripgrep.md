# grep / ripgrep

> Search file contents for patterns using regular expressions

<!-- tags: grep, ripgrep, rg, search, regex, text -->

---

## recursive search pattern
Search for a pattern recursively through all files in a directory.

```bash
grep -r "{{PATTERN:str:password}}" {{PATH:dir:.}}
```

<!-- meta: risk=safe | phase=misc | tags=recursive,search,basic -->

---

## case-insensitive search
Search ignoring case distinctions.

```bash
grep -ri "{{PATTERN:str:admin}}" {{PATH:dir:.}}
```

<!-- meta: risk=safe | phase=misc | tags=case,insensitive -->

---

## search with context lines
Show N lines before (-B), after (-A), or around (-C) each match.

```bash
grep -rn -C {{LINES:int:3}} "{{PATTERN:str:error}}" {{PATH:dir:.}}
```

<!-- meta: risk=safe | phase=misc | tags=context,surrounding,lines -->

---

## invert match exclude lines
Show lines that do NOT match the pattern.

```bash
grep -v "{{PATTERN:str:comment}}" {{FILE:file:input.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=invert,exclude,filter -->

---

## count matches per file
Count the number of matching lines per file.

```bash
grep -rc "{{PATTERN:str:TODO}}" {{PATH:dir:.}}
```

<!-- meta: risk=safe | phase=misc | tags=count,statistics -->

---

## print only matched text
Print only the matched text, not the whole line.

```bash
grep -oP "{{REGEX:str:\b\d{1,3}(\.\d{1,3}){3}\b}}" {{FILE:file:access.log}}
```

<!-- meta: risk=safe | phase=misc | tags=extract,only,regex -->

---

## search by file glob
Search only in files matching a glob pattern.

```bash
grep -rn --include="{{GLOB:str:*.py}}" "{{PATTERN:str:import}}" {{PATH:dir:.}}
```

<!-- meta: risk=safe | phase=misc | tags=include,filter,filetype -->

---

## search multiple patterns regex
Match any of several patterns using extended regex.

```bash
grep -rE "{{PATTERN:str:password|secret|token|api_key}}" {{PATH:dir:.}}
```

<!-- meta: risk=safe | phase=misc | tags=multiple,extended,regex -->

---

## ripgrep recursive search fast
Fast recursive search with ripgrep (respects .gitignore by default).

```bash
rg "{{PATTERN:str:password}}" {{PATH:dir:.}}
```

<!-- meta: risk=safe | phase=misc | tags=rg,fast,recursive -->

---

## ripgrep filter by filetype
Search only specific file types with ripgrep.

```bash
rg -t {{TYPE:str:py}} "{{PATTERN:str:import}}" {{PATH:dir:.}}
```

<!-- meta: risk=safe | phase=misc | tags=rg,filetype,filter -->

---

## ripgrep context and stats
Ripgrep search with surrounding lines and match statistics.

```bash
rg -C {{LINES:int:3}} --stats "{{PATTERN:str:error}}" {{PATH:dir:.}}
```

<!-- meta: risk=safe | phase=misc | tags=rg,context,stats -->

---

## ripgrep search hidden ignored files
Search all files including hidden and gitignored ones.

```bash
rg -uuu "{{PATTERN:str:secret}}" {{PATH:dir:.}}
```

<!-- meta: risk=safe | phase=misc | tags=rg,hidden,all,unrestricted -->

---

## match whole word recursive
Match whole words recursively (avoids substring noise).

```bash
grep -rw "{{PATTERN:str:password}}" {{PATH:dir:.}}
```

<!-- meta: risk=safe | phase=misc | tags=word,whole -->

---

## extract substring around keyword creds
Pull a few characters around a keyword for quick credential scanning.

```bash
grep -oiR "{{KEYWORD:str:password}} .\{0,{{N:int:60}}\}" {{PATH:dir:.}} 2>/dev/null
```

<!-- meta: risk=safe | phase=misc | tags=extract,context,creds -->

---

## extract public IPs from files
Pull all IPv4 addresses from one or more files and dedupe.

```bash
cat {{FILES:str:file1.txt file2.txt}} | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u
```

<!-- meta: risk=safe | phase=recon | tags=ip,extract -->
