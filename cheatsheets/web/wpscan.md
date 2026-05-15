# wpscan

> WordPress security scanner for vulnerability detection and enumeration

<!-- tags: wordpress, cms, vuln, enumeration, web -->

---

## Basic Scan
Run a default WordPress scan against a target.

```bash
wpscan --url {{URL:url:http://target.com}} --random-user-agent
```

<!-- meta: risk=low | phase=enum | tags=wordpress,basic -->

---

## Enumerate Users
Discover WordPress usernames via author archives and REST API.

```bash
wpscan --url {{URL:url:http://target.com}} --enumerate u --random-user-agent
```

<!-- meta: risk=low | phase=enum | tags=users,enumeration -->

---

## Enumerate Vulnerable Plugins
Scan for plugins with known vulnerabilities.

```bash
wpscan --url {{URL:url:http://target.com}} --enumerate vp --plugins-detection {{DETECTION:str:aggressive}} --random-user-agent
```

<!-- meta: risk=low | phase=vuln | tags=plugins,vulnerable -->

---

## Enumerate Themes
Discover installed WordPress themes.

```bash
wpscan --url {{URL:url:http://target.com}} --enumerate vt --random-user-agent
```

<!-- meta: risk=low | phase=enum | tags=themes,enumeration -->

---

## Full Enumeration
Enumerate users, plugins, themes, timthumbs, and config backups.

```bash
wpscan --url {{URL:url:http://target.com}} --enumerate u,vp,vt,tt,cb,dbe --random-user-agent
```

<!-- meta: risk=low | phase=enum | tags=full,comprehensive -->

---

## Password Brute Force
Brute-force WordPress login for discovered users.

```bash
wpscan --url {{URL:url:http://target.com}} -U {{USERNAME:str:admin}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} --max-threads {{THREADS:int:20}}
```

<!-- meta: risk=med | phase=passwords | tags=bruteforce,login -->

---

## With WPVulnDB API Token
Use a WPScan API token for vulnerability database lookups.

```bash
wpscan --url {{URL:url:http://target.com}} --api-token {{API_TOKEN:str:YOUR_TOKEN}} --enumerate vp,vt,u --random-user-agent
```

<!-- meta: risk=low | phase=vuln | tags=api,vulndb -->

---

## Aggressive Detection Mode
Run all detection methods at maximum aggressiveness.

```bash
wpscan --url {{URL:url:http://target.com}} --detection-mode aggressive --plugins-detection aggressive --plugins-version-detection aggressive --enumerate vp,vt,u --api-token {{API_TOKEN:str:YOUR_TOKEN}} --random-user-agent
```

<!-- meta: risk=med | phase=vuln | tags=aggressive,thorough -->

---

## Disable TLS Cert Checks
Scan an HTTPS site with a self-signed or expired certificate.

```bash
wpscan --url {{URL:url:https://target.com}} --disable-tls-checks -e {{ENUM:str:ap}}
```

<!-- meta: risk=low | phase=enum | tags=tls,disable,selfsigned -->

---

## Force All Plugins (Aggressive + Threads)
Force-enumerate every plugin with high concurrency.

```bash
wpscan --url {{URL:url:http://target.com}} -e ap --plugins-detection aggressive --force -t {{THREADS:int:1000}}
```

<!-- meta: risk=med | phase=enum | tags=plugins,aggressive,force -->
