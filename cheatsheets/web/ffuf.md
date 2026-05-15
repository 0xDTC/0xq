# ffuf

> Fast web fuzzer for directory discovery, vhost enumeration, and parameter brute-forcing

<!-- tags: fuzzing, web, directory, vhost, bruteforce -->

---

## Directory Brute-Force
Discover hidden directories and files on a web server.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt}} -t {{THREADS:int:40}} -o {{OUTFILE:file:ffuf-dirs.json}}
```

<!-- meta: risk=low | phase=enum | tags=directory,discovery -->

---

## Extension Fuzzing
Brute-force file extensions on a known or fuzzed path.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt}} -e {{EXTENSIONS:str:.php,.html,.txt,.bak,.asp,.aspx,.jsp}} -t {{THREADS:int:40}}
```

<!-- meta: risk=low | phase=enum | tags=extensions,discovery -->

---

## VHost Fuzzing
Enumerate virtual hosts on a target web server.

```bash
ffuf -u {{URL:url:http://target.com}} -H "Host: FUZZ.{{DOMAIN:domain:target.com}}" -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt}} -fs {{FILTER_SIZE:int:0}}
```

<!-- meta: risk=low | phase=enum | tags=vhost,subdomain -->

---

## GET Parameter Fuzzing
Discover hidden GET parameters on a URL.

```bash
ffuf -u {{URL:url:http://target.com/page.php}}?FUZZ=test -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt}} -fs {{FILTER_SIZE:int:0}}
```

<!-- meta: risk=low | phase=enum | tags=parameters,get -->

---

## POST Data Fuzzing
Fuzz POST request body parameters.

```bash
ffuf -u {{URL:url:http://target.com/login.php}} -X POST -d "{{PARAM:str:username}}=admin&{{PARAM2:str:password}}=FUZZ" -H "Content-Type: application/x-www-form-urlencoded" -w {{WORDLIST:wordlist:/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt}} -fc 401,403
```

<!-- meta: risk=med | phase=passwords | tags=post,bruteforce -->

---

## Recursive Discovery
Recursively fuzz directories up to a specified depth.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt}} -recursion -recursion-depth {{DEPTH:int:2}} -t {{THREADS:int:30}} -o {{OUTFILE:file:ffuf-recursive.json}}
```

<!-- meta: risk=low | phase=enum | tags=recursive,directory -->

---

## Multi-Wordlist Fuzzing
Use multiple FUZZ keywords with separate wordlists.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ1/FUZZ2 -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt}}:FUZZ1 -w {{WORDLIST2:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}}:FUZZ2
```

<!-- meta: risk=low | phase=enum | tags=multi-wordlist,fuzzing -->

---

## With Filters and Matchers
Filter responses by status code, size, words, or lines to reduce noise.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -mc {{MATCH_CODES:str:200,301,302}} -fc {{FILTER_CODES:str:404,403}} -fs {{FILTER_SIZE:int:0}} -fw {{FILTER_WORDS:int:0}}
```

<!-- meta: risk=low | phase=enum | tags=filters,matchers -->

---

## Rate-Limited Fuzzing
Throttle requests to avoid WAF detection or rate limiting.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -rate {{RATE:int:50}} -t {{THREADS:int:5}} -p {{DELAY:str:0.1-0.5}}
```

<!-- meta: risk=low | phase=enum | tags=ratelimit,stealth -->

---

## Fuzz From Saved Request File
Use a saved raw HTTP request (e.g. exported from Burp) and FUZZ marker.

```bash
ffuf -request {{REQUEST:file:request.txt}} -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -mc {{MATCH_CODES:str:200}}
```

<!-- meta: risk=low | phase=enum | tags=request,burp -->

---

## Recursion with Multiple Extensions
Recurse and try a wide range of extensions per directory.

```bash
ffuf -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt}} -ic -u {{URL:url}}/FUZZ -e .php,.asp,.aspx,.jsp,.html,.txt,.json,.zip,.bak,.config -recursion -t {{THREADS:int:200}}
```

<!-- meta: risk=low | phase=enum | tags=recursion,extensions -->
