# curl-json

> Copy-paste recipes for the "I hit an API with curl, I need X out of the JSON response" moments. Every entry is one line — no jq theory, no XPath-ish esoterica.

<!-- tags: curl, jq, json, api, response, parse -->

> **How the jq expressions here read:**
> - `.field` — the value of `field` at the top level
> - `.a.b.c` — walk down nested objects
> - `.[]` — iterate over an array
> - `-r` — raw output (strings without quotes; needed when piping to other tools)
>
> If a field name has weird characters (spaces, dashes, etc.) wrap it: `.["odd field name"]`.
>
> **User-Agent policy:** every recipe sets `-A "{{UA:str:$(q-ua)}}"` so the request carries a real-browser UA. Alternates — Firefox: `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0` · Safari: `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15`.

---

## pretty print json api response
Turn a one-line wall of JSON into readable indented form. First thing you run when eyeballing an unknown endpoint.

```bash
curl -sfL -A "{{UA:str:$(q-ua)}}" {{URL:url}} | jq .
```

<!-- meta: risk=low | phase=recon | tags=curl,jq,pretty,inspect -->

---

## extract one field json api response
The response has a specific field you need — grab just that value. Use dots for nested (`.user.name`). `-r` strips the surrounding quotes so it pipes cleanly.

```bash
curl -sfL -A "{{UA:str:$(q-ua)}}" -X POST -d '{"user":"{{USER:str}}","pass":"{{PASS:str}}"}' -H "Content-Type: application/json" {{URL:url:https://target.com/login}} | jq -r '.{{FIELD:str:token}}'
```

<!-- meta: risk=low | phase=recon | tags=curl,jq,extract,field -->

---

## list all items from array response
API returns `[{"name":"alice"},{"name":"bob"}]` and you want each name on its own line, ready for grep / xargs / wc.

```bash
curl -sfL -A "{{UA:str:$(q-ua)}}" {{URL:url:https://target.com/api/users}} | jq -r '.[].{{FIELD:str:name}}'
```

<!-- meta: risk=low | phase=recon | tags=curl,jq,array,list -->

---

## filter array by field value
"Give me every user where `role` equals `admin`" — filter first, then print whichever field you want.

```bash
curl -sfL -A "{{UA:str:$(q-ua)}}" {{URL:url:https://target.com/api/users}} | jq -r '.[] | select(.{{FIELD:str:role}}=="{{VALUE:str:admin}}") | .{{PRINT:str:username}}'
```

<!-- meta: risk=low | phase=recon | tags=curl,jq,filter,select -->

---

## login get token then use it
Two-step: POST to login → grab token from response → use it as the Bearer in the next call. Token stashed in a shell var so you can reuse across further requests in the same session.

```bash
token=$(curl -sfL -A "{{UA:str:$(q-ua)}}" -X POST -H "Content-Type: application/json" -d '{"user":"{{USER:str}}","pass":"{{PASS:str}}"}' {{LOGIN_URL:url:https://target.com/api/login}} | jq -r '.{{TOKEN_FIELD:str:token}}'); echo "[+] token: $token"; curl -sfL -A "{{UA:str:$(q-ua)}}" -H "Authorization: Bearer $token" {{NEXT_URL:url:https://target.com/api/me}} | jq .
```

<!-- meta: risk=medium | phase=attack | tags=curl,jq,login,token,bearer -->

---

## count how many items array response
Quick sanity check: "did the API return anything?" or "how many pages of results roughly?".

```bash
curl -sfL -A "{{UA:str:$(q-ua)}}" {{URL:url}} | jq 'length'
```

<!-- meta: risk=low | phase=recon | tags=curl,jq,count,length -->

---

## extract nested field response
Value is buried like `.data.attributes.owner.email`. Just walk down with dots. If any step in the path doesn't exist you get `null` instead of a crash.

```bash
curl -sfL -A "{{UA:str:$(q-ua)}}" {{URL:url}} | jq -r '.{{PATH:str:data.attributes.owner.email}}'
```

<!-- meta: risk=low | phase=recon | tags=curl,jq,nested,deep -->

---

## save specific fields to csv
Grab only the columns you care about from a JSON array → CSV that opens in a spreadsheet or feeds grep/awk/sort.

```bash
curl -sfL -A "{{UA:str:$(q-ua)}}" {{URL:url}} | jq -r '.[] | [.{{F1:str:id}}, .{{F2:str:name}}, .{{F3:str:role}}] | @csv' | tee {{OUT:file:api-dump.csv}}
```

<!-- meta: risk=low | phase=recon | tags=curl,jq,csv,export,dump -->
