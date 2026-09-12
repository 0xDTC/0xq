# John the Ripper

> Versatile offline password cracker with format auto-detection and *2john conversion tools

<!-- tags: john, cracking, passwords, offline, converter -->

---

## crack auto-detect format
Crack hashes with automatic format detection using default mode.

```bash
john {{HASHFILE:file:hashes.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=basic,auto -->

---

## crack wordlist
Crack hashes using a specified wordlist.

```bash
john {{HASHFILE:file:hashes.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=wordlist,dictionary -->

---

## crack wordlist rules
Apply mangling rules to increase wordlist coverage.

```bash
john {{HASHFILE:file:hashes.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} --rules={{RULES:choice:best64=top 64 rules,all=every rule,single=single mode,wordlist=wordlist mode,extra=extra transforms,jumbo=jumbo bundle,korelogic=KoreLogic set,NT=NT-optimised,T0XlC=heavy mangling}}
```

<!-- meta: risk=safe | phase=passwords | tags=rules,mangling -->

---

## crack specific format
Specify a hash format explicitly when auto-detection fails.
<!-- Common formats: raw-md5, raw-sha1, raw-sha256, raw-sha512, nt, bcrypt, sha512crypt, krb5tgs, krb5asrep -->

```bash
john {{HASHFILE:file:hashes.txt}} --format={{FORMAT:choice:raw-md5=raw MD5,raw-sha1=raw SHA-1,raw-sha256=raw SHA-256,raw-sha512=raw SHA-512,nt=NT hash,lm=LM hash,bcrypt=Blowfish crypt,sha512crypt=Unix SHA-512,krb5tgs=Kerberos TGS-REP,krb5asrep=Kerberos AS-REP,net-ntlmv2=NetNTLMv2 responder,mysql=MySQL hash,mysql-sha1=MySQL SHA-1,oracle=Oracle hash}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=format,specific -->

---

## show cracked potfile
Display previously cracked passwords from the potfile.

```bash
john {{HASHFILE:file:hashes.txt}} --show
```

<!-- meta: risk=safe | phase=passwords | tags=show,results -->

---

## crack ssh key ssh2john
Extract a crackable hash from a passphrase-protected SSH private key.

```bash
ssh2john {{KEYFILE:file:id_rsa}} > {{OUTFILE:file:ssh_hash.txt}} && john {{OUTFILE:file:ssh_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=ssh,key,converter -->

---

## crack zip zip2john
Extract a crackable hash from a password-protected ZIP file.

```bash
zip2john {{ZIPFILE:file:protected.zip}} > {{OUTFILE:file:zip_hash.txt}} && john {{OUTFILE:file:zip_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=zip,archive,converter -->

---

## crack rar rar2john
Extract a crackable hash from a password-protected RAR file.

```bash
rar2john {{RARFILE:file:protected.rar}} > {{OUTFILE:file:rar_hash.txt}} && john {{OUTFILE:file:rar_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=rar,archive,converter -->

---

## crack keepass keepass2john
Extract a crackable hash from a KeePass database file.

```bash
keepass2john {{KDBX:file:database.kdbx}} > {{OUTFILE:file:keepass_hash.txt}} && john {{OUTFILE:file:keepass_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=keepass,converter -->

---

## crack pdf pdf2john
Extract a crackable hash from a password-protected PDF file.

```bash
pdf2john {{PDFFILE:file:protected.pdf}} > {{OUTFILE:file:pdf_hash.txt}} && john {{OUTFILE:file:pdf_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=pdf,converter -->

---

## crack ansible vault ansible2john
Extract a crackable hash from an Ansible Vault encrypted file.

```bash
ansible2john {{VAULTFILE:file:vault.yml}} > {{OUTFILE:file:ansible_hash.txt}} && john {{OUTFILE:file:ansible_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=ansible,vault,converter -->

---

## decrypt ansible vault
Decrypt the Ansible Vault file once the password is known.

```bash
ansible-vault decrypt {{VAULTFILE:file:vault.yml}} --output {{OUTFILE:file:decrypted.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=ansible,decrypt -->

---

## crack bitlocker bitlocker2john
Extract the BitLocker password hash from a VHD, filter to the $0 (user password) mode, then crack with john.

```bash
bitlocker2john -i {{VHD:file:Backup.vhd}} > /tmp/q-bl.hashes && grep 'bitlocker$0' /tmp/q-bl.hashes > /tmp/q-bl.hash && john --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} /tmp/q-bl.hash
```

<!-- meta: risk=high | phase=passwords | tags=bitlocker,chained,john,crack -->

---

## crack 7z 7z2john
Extract a crackable hash from a password-protected 7-Zip archive and hand it to john.

```bash
7z2john {{ARCHIVE:file:secret.7z}} > /tmp/q-7z.hash && john --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} /tmp/q-7z.hash
```

<!-- meta: risk=safe | phase=passwords | tags=7z,chained,john,crack -->

---

## crack office doc office2john
Extract a crackable hash from an MS Office doc/xlsx/pptx and hand it to john.

```bash
office2john.py {{OFFICEFILE:file:doc.docx}} > /tmp/q-office.hash && john --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} /tmp/q-office.hash
```

<!-- meta: risk=safe | phase=passwords | tags=office,doc,chained,john,crack -->
