# FTP

> File Transfer Protocol enumeration and authenticated access

<!-- tags: ftp,enum,file-transfer -->

---

## login anonymous
Try to access the FTP service as anonymous.

```bash
ftp anonymous@{{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=anon -->

---

## login authenticated
Log in with credentials.

```bash
ftp {{USERNAME:str}}@{{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=auth -->

---

## brute login hydra
Brute force FTP credentials with Hydra.

```bash
hydra -l {{USERNAME:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} ftp://{{TARGET:ip}}
```

<!-- meta: risk=med | phase=passwords | tags=hydra,brute -->

---

## scan nse scripts nmap
Run FTP NSE scripts for anonymous, brute force, and version info.

```bash
nmap -p {{PORT:port:21}} --script=ftp-anon,ftp-syst,ftp-bounce,ftp-brute {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=nmap,nse -->

---

## grab banner netcat
Read the FTP banner directly.

```bash
nc -nv {{TARGET:ip}} {{PORT:port:21}}
```

<!-- meta: risk=safe | phase=enum | tags=banner -->
