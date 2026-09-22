# ffuf

> Fast web fuzzer for directory discovery, vhost enumeration, and parameter brute-forcing

<!-- tags: fuzzing, web, directory, vhost, bruteforce -->

> **UA policy:** every command below sets `{{UA:str:...}}` to a modern Chrome-on-Windows string so requests look like a real browser; override the placeholder at fill time when a target expects a different fingerprint. Alternates — Firefox 128 Linux: `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0` · Safari 17 macOS: `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15`.

---

## fuzz directories
Discover hidden directories and files on a web server.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ -H "User-Agent: {{UA:str:$(q-ua)}}" -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt}} -t {{THREADS:int:40}} -o {{OUTFILE:file:ffuf-dirs.json}}
```

<!-- meta: risk=low | phase=enum | tags=directory,discovery -->

---

## fuzz file extensions
Brute-force file extensions on a known or fuzzed path.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ -H "User-Agent: {{UA:str:$(q-ua)}}" -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt}} -e {{EXTENSIONS:str:.php,.html,.txt,.bak,.asp,.aspx,.jsp}} -t {{THREADS:int:40}}
```

<!-- meta: risk=low | phase=enum | tags=extensions,discovery -->

---

## fuzz vhosts
Enumerate virtual hosts on a target web server.

```bash
ffuf -u {{URL:url:http://target.com}} -H "Host: FUZZ.{{DOMAIN:domain:target.com}}" -H "User-Agent: {{UA:str:$(q-ua)}}" -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt}} -fs {{FILTER_SIZE:int:0}}
```

<!-- meta: risk=low | phase=enum | tags=vhost,subdomain -->

---

## fuzz GET parameters
Discover hidden GET parameters on a URL.

```bash
ffuf -u {{URL:url:http://target.com/page.php}}?FUZZ=test -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -fs {{FILTER_SIZE:int:0}}
```

<!-- meta: risk=low | phase=enum | tags=parameters,get -->

---

## fuzz POST data brute creds
Fuzz POST request body parameters.

```bash
ffuf -u {{URL:url:http://target.com/login.php}} -X POST -d "{{PARAM:str:username}}=admin&{{PARAM2:str:password}}=FUZZ" -H "Content-Type: application/x-www-form-urlencoded" -H "User-Agent: {{UA:str:$(q-ua)}}" -w {{WORDLIST:wordlist:/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt}} -fc 401,403
```

<!-- meta: risk=med | phase=passwords | tags=post,bruteforce -->

---

## fuzz directories recursive depth
Recursively fuzz directories up to a specified depth.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ -H "User-Agent: {{UA:str:$(q-ua)}}" -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt}} -recursion -recursion-depth {{DEPTH:int:2}} -t {{THREADS:int:30}} -o {{OUTFILE:file:ffuf-recursive.json}}
```

<!-- meta: risk=low | phase=enum | tags=recursive,directory -->

---

## fuzz multi wordlist keywords
Use multiple FUZZ keywords with separate wordlists.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ1/FUZZ2 -H "User-Agent: {{UA:str:$(q-ua)}}" -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt}}:FUZZ1 -w {{WORDLIST2:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}}:FUZZ2
```

<!-- meta: risk=low | phase=enum | tags=multi-wordlist,fuzzing -->

---

## fuzz with filters matchers
Filter responses by status code, size, words, or lines to reduce noise.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -mc {{MATCH_CODES:str:200,301,302}} -fc {{FILTER_CODES:str:404,403}} -fs {{FILTER_SIZE:int:0}} -fw {{FILTER_WORDS:int:0}}
```

<!-- meta: risk=low | phase=enum | tags=filters,matchers -->

---

## fuzz rate limited stealth
Throttle requests to avoid WAF detection or rate limiting.

```bash
ffuf -u {{URL:url:http://target.com}}/FUZZ -H "User-Agent: {{UA:str:$(q-ua)}}" -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -rate {{RATE:int:50}} -t {{THREADS:int:5}} -p {{DELAY:str:0.1-0.5}}
```

<!-- meta: risk=low | phase=enum | tags=ratelimit,stealth -->

---

## fuzz from saved request file
Use a saved raw HTTP request (e.g. exported from Burp) and FUZZ marker.

```bash
ffuf -request {{REQUEST:file:request.txt}} -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -mc {{MATCH_CODES:str:200}}
```

<!-- meta: risk=low | phase=enum | tags=request,burp -->

---

## fuzz recursive multiple extensions
Recurse and try a wide range of extensions per directory.

```bash
ffuf -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt}} -ic -u {{URL:url}}/FUZZ -H "User-Agent: {{UA:str:$(q-ua)}}" -e .php,.asp,.aspx,.jsp,.html,.txt,.json,.zip,.bak,.config -recursion -t 50 -sf -maxtime 600
```

<!-- meta: risk=low | phase=enum | tags=recursion,extensions -->

---

## fuzz directories auto calibrate
Auto-calibrate the "not found" baseline instead of eyeballing -fs per target. Best default for dir brute.

```bash
ffuf -u {{URL:url}}/FUZZ -w {{WORDLIST:file:/usr/share/seclists/Discovery/Web-Content/common.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -mc 200,301,401,403,405 -ac -noninteractive -t 40
```

<!-- meta: risk=low | phase=recon | tags=ffuf,dirs,auto-calibrate,ac -->

---

## fuzz vhosts per host auto calibrate
VHOST discovery — auto-calibrate per Host header (each vhost has its own baseline).

```bash
ffuf -u {{URL:url}} -H "Host: FUZZ.{{DOMAIN:domain}}" -H "User-Agent: {{UA:str:$(q-ua)}}" -w {{WORDLIST:file:/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt}} -ach -noninteractive -t 40
```

<!-- meta: risk=low | phase=recon | tags=ffuf,vhost,ach,auto-calibrate -->

---

## fuzz pitchfork user pass lockstep
Lockstep two wordlists (user[i] with pass[i]) — 10k tries instead of 10k×10k clusterbomb.

```bash
ffuf -u {{URL:url}} -X POST -d "user=USER&pass=PASS" -H "Content-Type: application/x-www-form-urlencoded" -H "User-Agent: {{UA:str:$(q-ua)}}" -w {{USERLIST:file:users.txt}}:USER -w {{PASSLIST:file:pass.txt}}:PASS -mode pitchfork -mc 200 -fs 0 -noninteractive
```

<!-- meta: risk=medium | phase=attack | tags=ffuf,pitchfork,creds,brute -->

---

## fuzz rate limited stealth stop on flood
Stealth mode with rate cap + stop-on-403-flood + 10min max. Prevents runaway on WAF/hung target.

```bash
ffuf -u {{URL:url}}/FUZZ -w {{WORDLIST:file:/usr/share/seclists/Discovery/Web-Content/common.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -mc 200,301,401,403 -rate 20 -t 4 -sf -maxtime 600 -noninteractive
```

<!-- meta: risk=low | phase=recon | tags=ffuf,stealth,rate-limit,sf,maxtime -->

---

## fuzz lfi regex match root
LFI check — regex-match "root:x:0:" instead of guessing content size. Precise hit detection.

```bash
ffuf -u "{{URL:url}}?file=FUZZ" -w {{WORDLIST:file:/usr/share/seclists/Fuzzing/LFI/LFI-Jhaddix.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -mr "root:x:0:" -noninteractive
```

<!-- meta: risk=medium | phase=attack | tags=ffuf,lfi,mr,regex -->

---

## fuzz output all formats
Write results in json, html, md, csv all at once — CI-friendly, feeds into report tools.

```bash
ffuf -u {{URL:url}}/FUZZ -w {{WORDLIST:file:/usr/share/seclists/Discovery/Web-Content/common.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -mc 200,301,401,403 -o {{OUT_STEM:file:ffuf-run}} -of all -noninteractive
```

<!-- meta: risk=low | phase=recon | tags=ffuf,output,json,html,md,csv -->

---

## fuzz directories follow redirects
Follow 3xx so auth-walled apps that 302 to /login don't cluster into one giant meaningless class.

```bash
ffuf -u {{URL:url}}/FUZZ -w {{WORDLIST:file:/usr/share/seclists/Discovery/Web-Content/common.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -mc 200,301,401,403 -r -ac -noninteractive -t 40
```

<!-- meta: risk=low | phase=recon | tags=ffuf,follow-redirects,r -->

---

## fuzz get parameter url encoded
URL-encode the fuzz keyword — for strict URL parsers that reject raw special chars.

```bash
ffuf -u "{{URL:url}}?id=FUZZ" -w {{WORDLIST:file:/usr/share/seclists/Fuzzing/SQLi/Generic-SQLi.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -enc "FUZZ:urlencode" -mc 200,500 -noninteractive
```

<!-- meta: risk=medium | phase=attack | tags=ffuf,enc,urlencode,sqli -->

---

## fuzz from live command subfinder
Chain a live command as the wordlist source (e.g. subfinder streaming subs into ffuf) — no intermediate file.

```bash
ffuf -input-cmd 'subfinder -d {{DOMAIN:domain}} -silent' -input-num 500 -u https://FUZZ -H "User-Agent: {{UA:str:$(q-ua)}}" -mc 200,301,302,403 -noninteractive
```

<!-- meta: risk=low | phase=recon | tags=ffuf,input-cmd,chain,subfinder -->

---

## fuzz filter response regex error
Negative filter on regex — hide any response matching "error" (or your app's error signature).

```bash
ffuf -u {{URL:url}}/FUZZ -w {{WORDLIST:file:/usr/share/seclists/Discovery/Web-Content/common.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -mc all -fr "error" -noninteractive
```

<!-- meta: risk=low | phase=recon | tags=ffuf,fr,regex,filter -->
