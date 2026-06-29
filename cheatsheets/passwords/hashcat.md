# Hashcat

> Advanced GPU-accelerated password recovery tool

<!-- tags: hashcat, cracking, passwords, gpu, offline -->

---

## crack wordlist
Crack hashes using a wordlist. Common modes: 0=MD5, 100=SHA1, 1000=NTLM, 1400=SHA256, 1700=SHA512, 1800=sha512crypt, 3200=bcrypt, 5600=NetNTLMv2, 13100=Kerberoast, 18200=AS-REP.

```bash
hashcat -m {{MODE:int:0}} {{HASHFILE:file:hashes.txt}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -o {{OUTFILE:file:cracked.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=dictionary,wordlist -->

---

## crack wordlist rules
Apply rule-based mangling to increase wordlist coverage.

```bash
hashcat -m {{MODE:int:1000}} {{HASHFILE:file:hashes.txt}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -r {{RULES:file:/usr/share/hashcat/rules/best64.rule}} -o {{OUTFILE:file:cracked.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=rules,mangling -->

---

## brute mask attack
Brute-force with a character mask pattern. Mask chars: ?l=lowercase, ?u=uppercase, ?d=digit, ?s=special, ?a=all.

```bash
hashcat -m {{MODE:int:1000}} {{HASHFILE:file:hashes.txt}} -a 3 '{{MASK:str:?u?l?l?l?l?d?d?d}}' -o {{OUTFILE:file:cracked.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=mask,bruteforce -->

---

## crack hybrid wordlist mask
Append a mask pattern to each word in the wordlist.

```bash
hashcat -m {{MODE:int:1000}} {{HASHFILE:file:hashes.txt}} -a 6 {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} '{{MASK:str:?d?d?d?s}}' -o {{OUTFILE:file:cracked.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=hybrid,combo -->

---

## crack hybrid mask wordlist
Prepend a mask pattern before each word in the wordlist.

```bash
hashcat -m {{MODE:int:1000}} {{HASHFILE:file:hashes.txt}} -a 7 '{{MASK:str:?d?d}}' {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -o {{OUTFILE:file:cracked.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=hybrid,prepend -->

---

## show cracked potfile
Display previously cracked hashes from the potfile.

```bash
hashcat -m {{MODE:int:1000}} {{HASHFILE:file:hashes.txt}} --show
```

<!-- meta: risk=safe | phase=passwords | tags=show,results -->

---

## lookup hash mode example
Look up a hashcat mode number by example hash or name.

```bash
hashcat --example-hashes | grep -B 3 -i '{{HASH_TYPE:str:ntlm}}'
```

<!-- meta: risk=safe | phase=passwords | tags=identify,mode -->

---

## crack ntlm
Crack Windows NTLM hashes (mode 1000).

```bash
hashcat -m 1000 {{HASHFILE:file:ntlm-hashes.txt}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -r /usr/share/hashcat/rules/best64.rule -o {{OUTFILE:file:cracked-ntlm.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=ntlm,windows -->

---

## crack kerberoast krb5tgs
Crack Kerberoast TGS-REP hashes (mode 13100).

```bash
hashcat -m 13100 {{HASHFILE:file:kerberoast-hashes.txt}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -r /usr/share/hashcat/rules/best64.rule -o {{OUTFILE:file:cracked-tgs.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=kerberoast,kerberos -->

---

## identify hash mode
Use hashcat's built-in identifier to suggest the mode for a hash.

```bash
hashcat --identify '{{HASH:str}}'
```

<!-- meta: risk=safe | phase=passwords | tags=identify,detect -->

---

## crack auto-detect mode oneliner
Identify the hash mode and crack with rockyou in one step.

```bash
hash='{{HASH:str}}'; hashcat -m $(hashcat --identify "$hash" | grep -Eo '^[[:space:]]*[0-9]+' | head -n 1 | xargs) "$hash" --quiet --wordlist {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} --force
```

<!-- meta: risk=safe | phase=passwords | tags=auto-detect,one-liner -->

---

## crack bcrypt
Hashcat mode 1470 cracks yescrypt and 3200 cracks bcrypt; use this for bcrypt files.

```bash
hashcat -m 3200 --quiet {{HASHFILE:file:hashes}} --wordlist {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} --force
```

<!-- meta: risk=safe | phase=passwords | tags=bcrypt -->

---

## crack ansible vault
Hashcat mode 16900 cracks Ansible Vault hashes (after ansible2john).

```bash
hashcat -a 0 -m 16900 {{HASHFILE:file:hash.txt}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=ansible,vault -->

---

## chained bitlocker crack hashcat
One-shot BitLocker crack: bitlocker2john extracts the hashes from the VHD, grep filters to the $0 (user password) mode, then hashcat rips it with -m 22100.

```bash
bitlocker2john -i {{VHD:file:Backup.vhd}} > /tmp/q-bl.hashes && grep 'bitlocker$0' /tmp/q-bl.hashes > /tmp/q-bl.hash && hashcat -a 0 -m 22100 /tmp/q-bl.hash {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=high | phase=passwords | tags=bitlocker,chained,hashcat,crack -->

---

## chained zip crack hashcat
Zip password crack via zip2john → hashcat -m 17225 (compressed encrypted zip). Use -m 13600 for classic ZipCrypto.

```bash
zip2john {{ZIPFILE:file:secret.zip}} > /tmp/q-zip.hash && hashcat -a 0 -m 17225 /tmp/q-zip.hash {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=zip,chained,hashcat,crack -->

---

## chained rar crack hashcat
RAR5 password crack via rar2john → hashcat -m 13000. Use -m 12500 for RAR3.

```bash
rar2john {{RARFILE:file:secret.rar}} > /tmp/q-rar.hash && hashcat -a 0 -m 13000 /tmp/q-rar.hash {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=rar,chained,hashcat,crack -->

---

## chained 7z crack hashcat
7-Zip password crack via 7z2john → hashcat -m 11600.

```bash
7z2john {{ARCHIVE:file:secret.7z}} > /tmp/q-7z.hash && hashcat -a 0 -m 11600 /tmp/q-7z.hash {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=7z,chained,hashcat,crack -->

---

## chained pdf crack hashcat
PDF password crack: pdf2john.pl → hashcat -m 10500 (PDF 1.4–1.6). For PDF 1.7 Level 8 use -m 10700.

```bash
pdf2john.pl {{PDFFILE:file:doc.pdf}} > /tmp/q-pdf.hash && hashcat -a 0 -m 10500 /tmp/q-pdf.hash {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=pdf,chained,hashcat,crack -->

---

## chained office doc crack hashcat
MS Office doc/xlsx/pptx password crack: office2john → hashcat -m 9600 (2013+). Use -m 9500 for Office 2010, -m 9400 for 2007.

```bash
office2john.py {{OFFICEFILE:file:doc.docx}} > /tmp/q-office.hash && hashcat -a 0 -m 9600 /tmp/q-office.hash {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=office,doc,chained,hashcat,crack -->

---

## chained keepass crack hashcat
KeePass .kdbx database crack: keepass2john → hashcat -m 13400.

```bash
keepass2john {{KDBXFILE:file:passwords.kdbx}} > /tmp/q-kp.hash && hashcat -a 0 -m 13400 /tmp/q-kp.hash {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=high | phase=passwords | tags=keepass,chained,hashcat,crack -->

---

## chained ssh key crack hashcat
Passphrase-protected SSH private key crack: ssh2john → hashcat -m 22921.

```bash
ssh2john {{KEYFILE:file:id_rsa}} > /tmp/q-ssh.hash && hashcat -a 0 -m 22921 /tmp/q-ssh.hash {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=high | phase=passwords | tags=ssh,key,chained,hashcat,crack -->
