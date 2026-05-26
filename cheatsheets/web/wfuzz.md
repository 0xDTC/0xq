# Wfuzz

> Web application fuzzer for brute-forcing paths, parameters, headers, and credentials.

<!-- tags: web, fuzzing, wfuzz, bruteforce, enumeration -->

---

## fuzz numeric range wfuzz
Fuzz a URL with an incrementing numeric range in place of FUZZ.

```bash
wfuzz -z range,1-1000 -u {{URL:url:http://target/FUZZ}}
```

<!-- meta: risk=low | phase=enum | tags=range,numeric -->

---

## fuzz directories wfuzz
Fuzz a URL path with a wordlist to discover directories and files.

```bash
wfuzz -z file,{{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -u {{URL:url:http://target/FUZZ}} | tee {{OUTFILE:file:wfuzz.txt}}
```

<!-- meta: risk=low | phase=enum | tags=wordlist,directory -->

---

## fuzz parameters wfuzz
Fuzz a POST body parameter value with a wordlist.

```bash
wfuzz -z file,{{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt}} -X POST -u {{URL:url:http://target}} -d "{{PARAM:str:username}}=FUZZ" | tee {{OUTFILE:file:wfuzz.txt}}
```

<!-- meta: risk=low | phase=enum | tags=post,parameters -->

---

## fuzz hide responses wfuzz
Fuzz while hiding noisy responses by status code, word, or char count.

```bash
wfuzz -z file,{{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} --hc {{HIDE_CODES:str:404}} --hw {{HIDE_WORDS:int:0}} -u {{URL:url:http://target/FUZZ}}
```

<!-- meta: risk=low | phase=enum | tags=filter,hide,noise -->

---

## fuzz show only codes wfuzz
Fuzz and display only responses that match given status codes.

```bash
wfuzz -z file,{{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} --sc {{SHOW_CODES:str:200,301,302}} -u {{URL:url:http://target/FUZZ}}
```

<!-- meta: risk=low | phase=enum | tags=filter,show,codes -->

---

## fuzz get parameter value wfuzz
Fuzz a GET query-string parameter value.

```bash
wfuzz -z file,{{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -u "{{URL:url:http://target/page.php}}?{{PARAM:str:id}}=FUZZ" --hc 404
```

<!-- meta: risk=low | phase=enum | tags=get,parameters -->

---

## fuzz subdomains vhost wfuzz
Brute-force virtual hosts by fuzzing the Host header.

```bash
wfuzz -z file,{{WORDLIST:wordlist:/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt}} -H "Host: FUZZ.{{DOMAIN:domain:target.com}}" --hw {{HIDE_WORDS:int:0}} -u {{URL:url:http://target}}
```

<!-- meta: risk=low | phase=enum | tags=vhost,subdomain,header -->

---

## brute login wfuzz
Brute-force a login form with two payloads for username and password.

```bash
wfuzz -z file,{{USERLIST:wordlist:/usr/share/seclists/Usernames/top-usernames-shortlist.txt}} -z file,{{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -X POST -d "username=FUZZ&password=FUZ2Z" --hc 401,403 -u {{URL:url:http://target/login}}
```

<!-- meta: risk=med | phase=exploit | tags=bruteforce,login,credentials -->

---

## fuzz cookie auth wfuzz
Fuzz protected paths while re-using an authenticated session cookie.

```bash
wfuzz -z file,{{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -b "{{COOKIE:str:session=abc123}}" --hc 404 -u {{URL:url:http://target/FUZZ}}
```

<!-- meta: risk=low | phase=enum | tags=auth,cookie,session -->

---

## fuzz throttled stealth wfuzz
Slow the scan with limited concurrency and a delay to dodge rate limits.

```bash
wfuzz -z file,{{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -t {{THREADS:int:5}} -s {{DELAY:int:1}} --hc 404 -u {{URL:url:http://target/FUZZ}}
```

<!-- meta: risk=low | phase=enum | tags=stealth,throttle,ratelimit -->
