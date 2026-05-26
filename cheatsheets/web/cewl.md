# CeWL

> Spiders a website to build a custom wordlist from the words it finds.

<!-- tags: web, wordlist, cewl, recon, passwords -->

---

## build wordlist from site cewl
Spider a site and write words above a minimum length to a wordlist.

```bash
cewl -w {{OUTFILE:file:wordlist.txt}} -d {{DEPTH:int:3}} -m {{MIN_LEN:int:5}} {{URL:url:http://target}}
```

<!-- meta: risk=safe | phase=recon | tags=wordlist,spider -->

---

## build wordlist with counts cewl
Spider a site and show each word with how often it appeared.

```bash
cewl -c -d {{DEPTH:int:2}} -m {{MIN_LEN:int:5}} {{URL:url:http://target}}
```

<!-- meta: risk=safe | phase=recon | tags=wordlist,count,frequency -->

---

## build wordlist with emails cewl
Spider a site and also harvest email addresses for username lists.

```bash
cewl -e -d {{DEPTH:int:2}} -w {{OUTFILE:file:cewl-emails.txt}} {{URL:url:http://target}}
```

<!-- meta: risk=safe | phase=recon | tags=wordlist,emails,usernames -->

---

## build wordlist with metadata cewl
Spider a site and extract author/metadata from linked documents.

```bash
cewl -a --meta_file {{OUTFILE:file:cewl-meta.txt}} -d {{DEPTH:int:2}} {{URL:url:http://target}}
```

<!-- meta: risk=safe | phase=recon | tags=wordlist,metadata,documents -->

---

## build wordlist authenticated cewl
Spider an authenticated area by supplying a session cookie.

```bash
cewl --cookie_string "{{COOKIE:str:session=abc123}}" -d {{DEPTH:int:2}} -w {{OUTFILE:file:wordlist.txt}} {{URL:url:http://target}}
```

<!-- meta: risk=low | phase=recon | tags=wordlist,auth,cookie -->

---

## build wordlist with numbers cewl
Spider a site keeping words that contain numbers (e.g. passwords like admin2024).

```bash
cewl --with-numbers -d {{DEPTH:int:2}} -m {{MIN_LEN:int:5}} -w {{OUTFILE:file:wordlist.txt}} {{URL:url:http://target}}
```

<!-- meta: risk=safe | phase=recon | tags=wordlist,numbers,passwords -->
