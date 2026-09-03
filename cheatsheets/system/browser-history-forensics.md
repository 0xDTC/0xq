# Browser History Forensics (SQLite)

> Chrome, Edge, Brave, Vivaldi, Opera, and Firefox all store history / downloads / logins in SQLite databases. Query them offline with `sqlite3` from a triage. Chrome/Edge timestamps are microseconds since 1601-01-01; Firefox is microseconds since Unix epoch.

<!-- tags: dfir,browser,chrome,edge,firefox,history,downloads,sqlite -->

## chrome/edge database paths
Standard on Windows. Copy the whole `Default/` folder if you need cookies, saved passwords, etc.

```bash
find {{USERPROFILE:path:./Users/user}}/AppData/Local -iname "History" -o -iname "Cookies" -o -iname "Login Data" 2>/dev/null
```

<!-- meta: risk=safe | phase=dfir | tags=chrome,edge,paths -->

---

## Chrome/Edge - recent URLs
Top N most-recent URLs with title and last visit time (converted from Chrome epoch).

```bash
sqlite3 {{HIST:file:./History}} "SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch'), title, url FROM urls ORDER BY last_visit_time DESC LIMIT {{N:int:30}};"
```

<!-- meta: risk=safe | phase=dfir | tags=chrome,urls,recent -->

---

## Chrome/Edge - URLs in a time window
All URLs the user visited between two datetimes (UTC).

```bash
sqlite3 {{HIST:file:./History}} "SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch'), url FROM urls WHERE datetime(last_visit_time/1000000-11644473600,'unixepoch') BETWEEN '{{FROM:str:2025-08-11 07:00}}' AND '{{TO:str:2025-08-11 07:30}}' ORDER BY last_visit_time;"
```

<!-- meta: risk=safe | phase=dfir | tags=chrome,window,time -->

---

## Chrome/Edge - keyword search
Match a substring across url and title (case-insensitive by SQLite default).

```bash
sqlite3 {{HIST:file:./History}} "SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch'), url, title FROM urls WHERE url LIKE '%{{KW:str:github}}%' OR title LIKE '%{{KW:str:github}}%' ORDER BY last_visit_time DESC;"
```

<!-- meta: risk=safe | phase=dfir | tags=chrome,search,keyword -->

---

## Chrome/Edge - downloads
Every downloaded file with target path, size, tab URL, and referrer.

```bash
sqlite3 {{HIST:file:./History}} "SELECT datetime(start_time/1000000-11644473600,'unixepoch'), target_path, received_bytes, tab_url, referrer FROM downloads ORDER BY start_time DESC;"
```

<!-- meta: risk=safe | phase=dfir | tags=chrome,downloads -->

---

## Chrome/Edge - saved logins (URL + username only)
The `Login Data` DB has origin URL + username. Passwords are DPAPI-encrypted; you need the user's OS master key to decrypt them.

```bash
sqlite3 {{LOGIN:file:./Login\ Data}} "SELECT origin_url, username_value, datetime(date_created/1000000-11644473600,'unixepoch') FROM logins ORDER BY date_created DESC;"
```

<!-- meta: risk=safe | phase=dfir | tags=chrome,logins,creds -->

---

## Chrome/Edge - cookies (session tokens)
The `Cookies` DB. Values encrypted with the profile's key; hostname and name are plaintext.

```bash
sqlite3 {{COOKIES:file:./Network/Cookies}} "SELECT host_key, name, datetime(expires_utc/1000000-11644473600,'unixepoch') FROM cookies ORDER BY host_key;"
```

<!-- meta: risk=safe | phase=dfir | tags=chrome,cookies -->

---

## Firefox - recent URLs
Firefox stores history in `places.sqlite`; timestamp is microseconds since Unix epoch (no 1601 offset).

```bash
sqlite3 {{PLACES:file:./places.sqlite}} "SELECT datetime(last_visit_date/1000000,'unixepoch'), title, url FROM moz_places ORDER BY last_visit_date DESC LIMIT {{N:int:30}};"
```

<!-- meta: risk=safe | phase=dfir | tags=firefox,places,urls -->

---

## Firefox - downloads
`places.sqlite` also carries downloads via annotations, but the modern location is the `moz_annos` table.

```bash
sqlite3 {{PLACES:file:./places.sqlite}} "SELECT datetime(dateAdded/1000000,'unixepoch'), content FROM moz_annos JOIN moz_places USING(place_id) WHERE anno_attribute_id IN (SELECT id FROM moz_anno_attributes WHERE name='downloads/destinationFileURI');"
```

<!-- meta: risk=safe | phase=dfir | tags=firefox,downloads -->

---

## count visits by domain
Which sites did the user actually spend time on.

```bash
sqlite3 {{HIST:file:./History}} "SELECT COUNT(*) c, substr(url, 0, instr(substr(url, 9), '/')+9) domain FROM urls GROUP BY domain ORDER BY c DESC LIMIT 20;"
```

<!-- meta: risk=safe | phase=dfir | tags=chrome,aggregate,stats -->

---

## bulk parse every user's history in a triage
Loop across all users in a `C/Users/<name>/AppData/...` triage layout.

```bash
find {{USERSDIR:path:./C/Users}} -path "*/AppData/Local/Google/Chrome/User Data/Default/History" -o -path "*/AppData/Local/Microsoft/Edge/User Data/Default/History" 2>/dev/null | while read h; do echo "=== $h ==="; sqlite3 "$h" "SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch'), url FROM urls ORDER BY last_visit_time DESC LIMIT 5;"; done
```

<!-- meta: risk=safe | phase=dfir | tags=chrome,batch,triage -->
