# John the Ripper

> Versatile offline password cracker with format auto-detection and *2john conversion tools

<!-- tags: john, cracking, passwords, offline, converter -->

---

## Basic Crack (Auto-Detect Format)
Crack hashes with automatic format detection using default mode.

```bash
john {{HASHFILE:file:hashes.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=basic,auto -->

---

## Wordlist Attack
Crack hashes using a specified wordlist.

```bash
john {{HASHFILE:file:hashes.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=wordlist,dictionary -->

---

## Wordlist with Rules
Apply mangling rules to increase wordlist coverage.

```bash
john {{HASHFILE:file:hashes.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} --rules={{RULES:str:best64}}
```

<!-- meta: risk=safe | phase=passwords | tags=rules,mangling -->

---

## Format-Specific Cracking
Specify a hash format explicitly when auto-detection fails.
<!-- Common formats: raw-md5, raw-sha1, raw-sha256, raw-sha512, nt, bcrypt, sha512crypt, krb5tgs, krb5asrep -->

```bash
john {{HASHFILE:file:hashes.txt}} --format={{FORMAT:str:raw-md5}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=format,specific -->

---

## Show Cracked Passwords
Display previously cracked passwords from the potfile.

```bash
john {{HASHFILE:file:hashes.txt}} --show
```

<!-- meta: risk=safe | phase=passwords | tags=show,results -->

---

## ssh2john - Convert SSH Key
Extract a crackable hash from a passphrase-protected SSH private key.

```bash
ssh2john {{KEYFILE:file:id_rsa}} > {{OUTFILE:file:ssh_hash.txt}} && john {{OUTFILE:file:ssh_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=ssh,key,converter -->

---

## zip2john - Convert ZIP Archive
Extract a crackable hash from a password-protected ZIP file.

```bash
zip2john {{ZIPFILE:file:protected.zip}} > {{OUTFILE:file:zip_hash.txt}} && john {{OUTFILE:file:zip_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=zip,archive,converter -->

---

## rar2john - Convert RAR Archive
Extract a crackable hash from a password-protected RAR file.

```bash
rar2john {{RARFILE:file:protected.rar}} > {{OUTFILE:file:rar_hash.txt}} && john {{OUTFILE:file:rar_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=rar,archive,converter -->

---

## keepass2john - Convert KeePass Database
Extract a crackable hash from a KeePass database file.

```bash
keepass2john {{KDBX:file:database.kdbx}} > {{OUTFILE:file:keepass_hash.txt}} && john {{OUTFILE:file:keepass_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=keepass,converter -->

---

## pdf2john - Convert PDF
Extract a crackable hash from a password-protected PDF file.

```bash
pdf2john {{PDFFILE:file:protected.pdf}} > {{OUTFILE:file:pdf_hash.txt}} && john {{OUTFILE:file:pdf_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=pdf,converter -->

---

## ansible2john - Convert Ansible Vault
Extract a crackable hash from an Ansible Vault encrypted file.

```bash
ansible2john {{VAULTFILE:file:vault.yml}} > {{OUTFILE:file:ansible_hash.txt}} && john {{OUTFILE:file:ansible_hash.txt}} --wordlist={{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=ansible,vault,converter -->

---

## Decrypt Ansible Vault After Cracking
Decrypt the Ansible Vault file once the password is known.

```bash
ansible-vault decrypt {{VAULTFILE:file:vault.yml}} --output {{OUTFILE:file:decrypted.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=ansible,decrypt -->
