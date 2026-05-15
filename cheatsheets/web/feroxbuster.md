# Feroxbuster

> Fast, recursive content discovery tool written in Rust

<!-- tags: feroxbuster,web,fuzzing,bruteforce,recursion -->

---

## Smart Recursive Scan
Smart scan with auto recursion and only show 200 OK responses.

```bash
feroxbuster -u {{URL:url}} --smart -s 200 -r --force-recursion -E -B -g -q -m GET,POST,DELETE,PUT
```

<!-- meta: risk=low | phase=enum | tags=smart,recursive -->

---

## Multi-Extension Brute Force
Scan with a wide range of common web file extensions.

```bash
feroxbuster -u {{URL:url}} -x .php,.asp,.aspx,.jsp,.cgi,.pl,.py,.rb,.sh,.dll,.exe,.bat,.ps1,.html,.htm,.txt,.json,.zip,.bak,.config,.conf -w {{WORDLIST:wordlist:/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt}} -k --force-recursion -t 200
```

<!-- meta: risk=low | phase=enum | tags=extensions,bruteforce -->

---

## Rate-Limited Method Scan
Scan with multiple HTTP methods and a rate limit to avoid detection.

```bash
feroxbuster -u {{URL:url}} -m GET,POST,DELETE,PUT --rate-limit {{RATE:int:4}}
```

<!-- meta: risk=safe | phase=enum | tags=rate-limit,methods -->
