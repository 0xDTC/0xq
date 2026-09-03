# keepassxc-cli

> Command-line client for KeePass v2 (.kdbx) password databases. Comes with the `keepassxc` package on Kali. Handles listing, showing, adding, editing, importing/exporting entries, database create/backup, and crack-friendly hash extraction via `keepass2john`.

<!-- tags: passwords,keepass,kdbx,keepassxc-cli,keepass2john,hashcat,john -->

## list entries in a kdbx
Prompts for master password. Lists every entry title in group tree order.

```bash
keepassxc-cli ls {{KDBX:file:./passwords.kdbx}}
```

<!-- meta: risk=safe | phase=dfir | tags=keepass,list -->

---

## list entries recursively
Every entry across every subgroup.

```bash
keepassxc-cli ls -R {{KDBX:file:./passwords.kdbx}}
```

<!-- meta: risk=safe | phase=dfir | tags=keepass,list,recursive -->

---

## show one entry (title, url, username, password, notes)
Enter the entry path exactly as `ls` printed it.

```bash
keepassxc-cli show {{KDBX:file:./passwords.kdbx}} '{{ENTRY:str:Servers/Heisen-9-WS-6}}'
```

<!-- meta: risk=safe | phase=dfir | tags=keepass,show,cred -->

---

## show only password (pipe-friendly)
Just the password field, ready to feed into ssh / smbclient / rdp.

```bash
keepassxc-cli show -a Password -s {{KDBX:file:./passwords.kdbx}} '{{ENTRY:str:Servers/host}}'
```

<!-- meta: risk=safe | phase=dfir | tags=keepass,password,pipe -->

---

## export whole database as CSV
Every entry to CSV (title,url,user,pass,notes). Use with `--sort` for stable order.

```bash
keepassxc-cli export -f csv {{KDBX:file:./passwords.kdbx}} > {{OUT:file:./out.csv}}
```

<!-- meta: risk=low | phase=dfir | tags=keepass,export,csv -->

---

## export as XML
XML export - full structure, all fields (attachments referenced by base64 in the XML).

```bash
keepassxc-cli export -f xml {{KDBX:file:./passwords.kdbx}} > {{OUT:file:./out.xml}}
```

<!-- meta: risk=low | phase=dfir | tags=keepass,export,xml -->

---

## search entries by substring
Match anywhere in title/user/url.

```bash
keepassxc-cli search {{KDBX:file:./passwords.kdbx}} '{{KW:str:aws}}'
```

<!-- meta: risk=safe | phase=dfir | tags=keepass,search -->

---

## keepass2john - extract crackable hash
Convert the kdbx header + master key metadata into a John/hashcat-compatible line. hashcat mode 13400 = KDBX3, 13600 = KDBX4.

```bash
keepass2john {{KDBX:file:./passwords.kdbx}} > {{OUT:file:./kp.hash}}
```

<!-- meta: risk=safe | phase=passwords | tags=keepass,hash,extract -->

---

## hashcat crack kdbx with wordlist
Mode 13400 for KDBX 3.x (most common in the wild).

```bash
hashcat -a 0 -m 13400 {{HASH:file:./kp.hash}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=passwords | phase=crack | tags=hashcat,kdbx,wordlist -->

---

## john crack kdbx with wordlist
Alternate path via John the Ripper.

```bash
john --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{HASH:file:./kp.hash}}
```

<!-- meta: risk=passwords | phase=crack | tags=john,kdbx,wordlist -->

---

## generate a strong password with keepassxc-cli
Handy standalone generator (letters+numbers+symbols, custom length).

```bash
keepassxc-cli generate -L {{LEN:int:24}} -luns
```

<!-- meta: risk=safe | phase=util | tags=keepass,generate,password -->
