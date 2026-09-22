# Dirsearch

> Web path scanner for directory and file brute-forcing

<!-- tags: dirsearch, directory, fuzzing, web, content-discovery -->

> **UA policy:** every command below sets `{{UA:str:...}}` to a modern Chrome-on-Windows string via `--user-agent=` so requests look like a real browser; override the placeholder at fill time when a target expects a different fingerprint. Alternates — Firefox 128 Linux: `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0` · Safari 17 macOS: `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15`.

---

## scan directories recursive
Scan a target with default wordlists, recursing into discovered directories.

```bash
dirsearch -u {{URL:url:http://target.com/}} --user-agent="{{UA:str:$(q-ua)}}" -i 200 -r -F -o {{OUTFILE:file:dirsearch.txt}}
```

<!-- meta: risk=low | phase=enum | tags=basic,directory,recursive -->

---

## scan directories common extensions
Brute force paths with common web file extensions.

```bash
dirsearch -u {{URL:url:http://target.com/}} --user-agent="{{UA:str:$(q-ua)}}" -i 200 -r -F -e {{EXTENSIONS:str:php,asp,aspx,jsp,html,htm,txt,bak,zip,config,conf,bak,json}} -o {{OUTFILE:file:dirsearch-ext.txt}}
```

<!-- meta: risk=low | phase=enum | tags=extensions,fuzzing -->

---

## scan directories rate limited
Throttle requests to avoid WAF/rate-limit triggers.

```bash
dirsearch -u {{URL:url:http://target.com/}} --user-agent="{{UA:str:$(q-ua)}}" -i 200,403,302 -r -F --max-rate {{RATE:int:3}} -o {{OUTFILE:file:dirsearch-slow.txt}}
```

<!-- meta: risk=low | phase=enum | tags=rate-limit,stealth -->

---

## scan directories custom http method
Scan using a non-default HTTP method (e.g., POST, PUT, OPTIONS).

```bash
dirsearch -u {{URL:url:http://target.com/}} --user-agent="{{UA:str:$(q-ua)}}" -m {{METHOD:choice:POST=submit data,GET=fetch resource,PUT=replace resource,DELETE=remove resource,PATCH=partial update,HEAD=headers only,OPTIONS=allowed methods}} --max-rate {{RATE:int:10}} -e {{EXTENSIONS:str:php,html,bak}} --exclude-sizes={{EXCLUDE_SIZE:str:0B}}
```

<!-- meta: risk=low | phase=enum | tags=method,post,options -->

---

## scan directories custom user-agent
Send requests with a real-browser User-Agent to bypass naive filters.

```bash
dirsearch -u {{URL:url:http://target.com/}} --user-agent="{{UA:str:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36}}" -e {{EXTENSIONS:str:php,html,txt,bak}} --max-rate {{RATE:int:10}}
```

<!-- meta: risk=low | phase=enum | tags=user-agent,bypass -->

---

## scan directories authenticated cookie
Re-use a session cookie when scanning protected paths.

```bash
dirsearch -u {{URL:url:http://target.com/}} --cookie="{{COOKIE:str:session=abc123}}" --user-agent="{{UA:str:$(q-ua)}}" -e {{EXTENSIONS:str:php,html}} -o {{OUTFILE:file:dirsearch-auth.txt}}
```

<!-- meta: risk=low | phase=enum | tags=auth,cookie,session -->
