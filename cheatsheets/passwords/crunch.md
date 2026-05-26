# Crunch
> Generate custom wordlists by length, character set, or pattern for brute-force and password attacks.

<!-- tags: passwords,wordlist,bruteforce,generator -->

## generate wordlist hex crunch
Generate a hex-character wordlist between a minimum and maximum length.

```bash
crunch {{MIN:int:2}} {{MAX:int:8}} 0123456789ABCDEF -o {{OUTFILE:file:wordlist.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=hex,length,generator -->

---

## generate wordlist charset crunch
Generate a wordlist from a named Crunch charset (e.g. mixalpha-numeric, lalpha, ualpha-numeric-symbol14).

```bash
crunch {{MIN:int:1}} {{MAX:int:8}} -f /usr/share/crunch/charset.lst {{CHARSET:str:mixalpha-numeric}} -o {{OUTFILE:file:wordlist.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=charset,length,generator -->

---

## generate wordlist pattern crunch
Generate a wordlist from a placeholder pattern. `@`=lowercase, `,`=uppercase, `%`=digit, `^`=symbol.

```bash
crunch {{MIN:int:8}} {{MAX:int:8}} -t '{{PATTERN:str:,@@@%%%^}}' -o {{OUTFILE:file:wordlist.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=pattern,mask,generator -->

---

## generate wordlist keyword pattern crunch
Generate a fixed keyword followed by two digits and one symbol (e.g. password%%^).

```bash
crunch 10 10 -t '{{PATTERN:str:password%%^}}' -o {{OUTFILE:file:wordlist.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=pattern,keyword,generator -->
