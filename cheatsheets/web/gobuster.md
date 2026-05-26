# gobuster

> Directory, DNS, and vhost brute-forcing tool written in Go

<!-- tags: bruteforce, directory, dns, vhost, web -->

---

## brute directories
Brute-force directories and files on a web server.

```bash
gobuster dir -u {{URL:url:http://target.com}} -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt}} -t {{THREADS:int:50}} -o {{OUTFILE:file:gobuster-dirs.txt}}
```

<!-- meta: risk=low | phase=enum | tags=directory,discovery -->

---

## brute directories with extensions
Append file extensions to each word in the wordlist.

```bash
gobuster dir -u {{URL:url:http://target.com}} -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt}} -x {{EXTENSIONS:str:php,html,txt,bak,asp,aspx}} -t {{THREADS:int:50}} -o {{OUTFILE:file:gobuster-ext.txt}}
```

<!-- meta: risk=low | phase=enum | tags=extensions,directory -->

---

## brute dns subdomains
Enumerate subdomains via DNS resolution.

```bash
gobuster dns -d {{DOMAIN:domain:target.com}} -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt}} -t {{THREADS:int:50}} -o {{OUTFILE:file:gobuster-dns.txt}}
```

<!-- meta: risk=low | phase=enum | tags=dns,subdomain -->

---

## brute vhosts
Discover virtual hosts on a target web server.

```bash
gobuster vhost -u {{URL:url:http://target.com}} -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt}} --append-domain -t {{THREADS:int:50}} -o {{OUTFILE:file:gobuster-vhosts.txt}}
```

<!-- meta: risk=low | phase=enum | tags=vhost,subdomain -->

---

## brute directories authenticated cookie
Brute-force directories using a session cookie or auth header.

```bash
gobuster dir -u {{URL:url:http://target.com}} -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -c "{{COOKIE:str:PHPSESSID=abc123}}" -t {{THREADS:int:50}}
```

<!-- meta: risk=low | phase=enum | tags=authenticated,cookie -->

---

## brute directories follow redirects
Follow redirects and only show specific HTTP status codes.

```bash
gobuster dir -u {{URL:url:http://target.com}} -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -s {{STATUS_CODES:str:200,204,301,302,307,401,403}} -r -t {{THREADS:int:50}}
```

<!-- meta: risk=low | phase=enum | tags=redirects,statuscodes -->

---

## brute directories exclude codes user-agent
Hide specific status codes from output and use a custom User-Agent.

```bash
gobuster dir -u {{URL:url:http://target.com}} -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt}} -b {{EXCLUDE_CODES:str:404,403}} -a "{{USERAGENT:str:Mozilla/5.0 (Windows NT 10.0; Win64; x64)}}" -t {{THREADS:int:50}}
```

<!-- meta: risk=low | phase=enum | tags=stealth,useragent -->
