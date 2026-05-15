# Dirsearch

> Web path scanner for directory and file brute-forcing

<!-- tags: dirsearch, directory, fuzzing, web, content-discovery -->

---

## Basic Directory Scan
Scan a target with default wordlists, recursing into discovered directories.

```bash
dirsearch -u {{URL:url:http://target.com/}} -i 200 -r -F -o {{OUTFILE:file:dirsearch.txt}}
```

<!-- meta: risk=low | phase=enum | tags=basic,directory,recursive -->

---

## Scan with Common Extensions
Brute force paths with common web file extensions.

```bash
dirsearch -u {{URL:url:http://target.com/}} -i 200 -r -F -e {{EXTENSIONS:str:php,asp,aspx,jsp,html,htm,txt,bak,zip,config,conf,bak,json}} -o {{OUTFILE:file:dirsearch-ext.txt}}
```

<!-- meta: risk=low | phase=enum | tags=extensions,fuzzing -->

---

## Rate-Limited Scan
Throttle requests to avoid WAF/rate-limit triggers.

```bash
dirsearch -u {{URL:url:http://target.com/}} -i 200,403,302 -r -F --max-rate {{RATE:int:3}} -o {{OUTFILE:file:dirsearch-slow.txt}}
```

<!-- meta: risk=low | phase=enum | tags=rate-limit,stealth -->

---

## Custom HTTP Method
Scan using a non-default HTTP method (e.g., POST, PUT, OPTIONS).

```bash
dirsearch -u {{URL:url:http://target.com/}} -m {{METHOD:str:POST}} --max-rate {{RATE:int:10}} -e {{EXTENSIONS:str:php,html,bak}} --exclude-sizes={{EXCLUDE_SIZE:str:0B}}
```

<!-- meta: risk=low | phase=enum | tags=method,post,options -->

---

## Custom User-Agent
Send requests with a real-browser User-Agent to bypass naive filters.

```bash
dirsearch -u {{URL:url:http://target.com/}} --user-agent="{{UA:str:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36}}" -e {{EXTENSIONS:str:php,html,txt,bak}} --max-rate {{RATE:int:10}}
```

<!-- meta: risk=low | phase=enum | tags=user-agent,bypass -->

---

## Authenticated Scan with Cookie
Re-use a session cookie when scanning protected paths.

```bash
dirsearch -u {{URL:url:http://target.com/}} --cookie="{{COOKIE:str:session=abc123}}" -e {{EXTENSIONS:str:php,html}} -o {{OUTFILE:file:dirsearch-auth.txt}}
```

<!-- meta: risk=low | phase=enum | tags=auth,cookie,session -->
