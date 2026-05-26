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
