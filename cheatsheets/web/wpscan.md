# wpscan

> WordPress security scanner for vulnerability detection and enumeration

<!-- tags: wordpress, cms, vuln, enumeration, web -->

**UA policy:** every outbound request sets an explicit real-browser User-Agent via `{{UA}}` (session-shared across tools). Default = modern Chrome-on-Windows. Alternates: `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0` (Firefox 128 Linux), `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15` (Safari 17 macOS). `--random-user-agent` is avoided because its built-in pool includes flagged strings.

---

## scan wordpress
Run a default WordPress scan against a target.

```bash
wpscan --url {{URL:url:http://target.com}} --user-agent "{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=low | phase=enum | tags=wordpress,basic -->

---

## enum users wordpress
Discover WordPress usernames via author archives and REST API.

```bash
wpscan --url {{URL:url:http://target.com}} --enumerate u --user-agent "{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=low | phase=enum | tags=users,enumeration -->

---

## enum plugins wordpress vuln
Scan for plugins with known vulnerabilities.

```bash
wpscan --url {{URL:url:http://target.com}} --enumerate vp --plugins-detection {{DETECTION:choice:aggressive=brute force paths,passive=parse HTML only,mixed=combined methods}} --user-agent "{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=low | phase=vuln | tags=plugins,vulnerable -->

---

## enum themes wordpress
Discover installed WordPress themes.

```bash
wpscan --url {{URL:url:http://target.com}} --enumerate vt --user-agent "{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=low | phase=enum | tags=themes,enumeration -->

---

## enum wordpress full
Enumerate users, plugins, themes, timthumbs, and config backups.

```bash
wpscan --url {{URL:url:http://target.com}} --enumerate u,vp,vt,tt,cb,dbe --user-agent "{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=low | phase=enum | tags=full,comprehensive -->

---

## brute passwords wordpress
Brute-force WordPress login for discovered users.

```bash
wpscan --url {{URL:url:http://target.com}} -U {{USERNAME:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} --max-threads {{THREADS:int:20}} --user-agent "{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=med | phase=passwords | tags=bruteforce,login -->

---

## scan wordpress api token
Use a WPScan API token for vulnerability database lookups.

```bash
wpscan --url {{URL:url:http://target.com}} --api-token {{API_TOKEN:str:YOUR_TOKEN}} --enumerate vp,vt,u --user-agent "{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=low | phase=vuln | tags=api,vulndb -->

---

## scan wordpress aggressive
Run all detection methods at maximum aggressiveness.

```bash
wpscan --url {{URL:url:http://target.com}} --detection-mode aggressive --plugins-detection aggressive --plugins-version-detection aggressive --enumerate vp,vt,u --api-token {{API_TOKEN:str:YOUR_TOKEN}} --user-agent "{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=med | phase=vuln | tags=aggressive,thorough -->

---

## scan wordpress no tls check
Scan an HTTPS site with a self-signed or expired certificate.

```bash
wpscan --url {{URL:url:https://target.com}} --disable-tls-checks -e {{ENUM:choice:ap=all plugins,vp=vulnerable plugins,at=all themes,vt=vulnerable themes,u=user IDs,m=media IDs,tt=timthumbs,cb=config backups,dbe=db exports,p=popular plugins,t=popular themes}} --user-agent "{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=low | phase=enum | tags=tls,disable,selfsigned -->

---

## enum plugins wordpress all aggressive
Force-enumerate every plugin with high concurrency.

```bash
wpscan --url {{URL:url:http://target.com}} -e ap --plugins-detection aggressive --force -t {{THREADS:int:1000}} --user-agent "{{UA:str:$(q-ua)}}"
```

<!-- meta: risk=med | phase=enum | tags=plugins,aggressive,force -->
