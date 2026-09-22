# Feroxbuster

> Fast, recursive content discovery tool written in Rust

<!-- tags: feroxbuster,web,fuzzing,bruteforce,recursion -->

> **UA policy:** every command below sets `{{UA:str:...}}` to a modern Chrome-on-Windows string via `--user-agent` so requests look like a real browser; override the placeholder at fill time when a target expects a different fingerprint. Alternates — Firefox 128 Linux: `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0` · Safari 17 macOS: `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15`.

---

## scan content smart recursive
Smart scan with auto recursion and only show 200 OK responses.

```bash
feroxbuster -u {{URL:url}} --user-agent "{{UA:str:$(q-ua)}}" --smart -s 200 -r --force-recursion -E -B -g -q -m GET,POST,DELETE,PUT
```

<!-- meta: risk=low | phase=enum | tags=smart,recursive -->

---

## brute directories multi extension
Scan with a wide range of common web file extensions.

```bash
feroxbuster -u {{URL:url}} --user-agent "{{UA:str:$(q-ua)}}" -x .php,.asp,.aspx,.jsp,.cgi,.pl,.py,.rb,.sh,.dll,.exe,.bat,.ps1,.html,.htm,.txt,.json,.zip,.bak,.config,.conf -w {{WORDLIST:wordlist:/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt}} -k --force-recursion -t 200
```

<!-- meta: risk=low | phase=enum | tags=extensions,bruteforce -->

---

## scan directories rate limited methods
Scan with multiple HTTP methods and a rate limit to avoid detection.

```bash
feroxbuster -u {{URL:url}} --user-agent "{{UA:str:$(q-ua)}}" -m GET,POST,DELETE,PUT --rate-limit {{RATE:int:4}}
```

<!-- meta: risk=safe | phase=enum | tags=rate-limit,methods -->
