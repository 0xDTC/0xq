# ffuf

> Only the patterns you actually use. Six entries, nothing extra.

<!-- tags: ffuf, fuzz, web, dir, vhost, recursion, request-file -->

> **UA policy:** every entry sets `-H "User-Agent: {{UA:str:$(q-ua)}}"` so ffuf doesn't send its default UA (instantly flagged by WAFs). Alternates — Firefox: `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0` · Safari: `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15`.

---

## fuzz endpoints of directories
Standard dir brute with recursion + aggressive thread count + 2 req/s rate cap. First thing on any new web target.

```bash
ffuf -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt}} -r -recursion -u {{URL:url:https://{{TARGET:ip}}}}/FUZZ -H "User-Agent: {{UA:str:$(q-ua)}}" -mc {{MATCH:str:200,302,301}} -t {{THREADS:int:1000}} -c -rate {{RATE:int:2}}
```

<!-- meta: risk=low | phase=recon | tags=dir,recursion,aggressive -->

---

## fuzz with file name extensions
Same wordlist, but append each extension to every entry — surfaces files that dir brute alone misses. EXTENSIONS is a multichoice: all pre-checked, uncheck what you don't want with space, Enter to confirm.

```bash
ffuf -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt}} -u {{URL:url:https://{{TARGET:ip}}}}/FUZZ -H "User-Agent: {{UA:str:$(q-ua)}}" -c -e {{EXTENSIONS:multichoice:.php=PHP,.asp=Classic ASP,.aspx=ASPNET,.jsp=Java Server Pages,.cgi=CGI script,.pl=Perl,.py=Python,.rb=Ruby,.sh=Shell,.dll=Windows DLL,.exe=Windows EXE,.com=DOS COM,.vbs=VBScript,.bat=Batch,.ps1=PowerShell,.md=Markdown,.psm1=PS module,.hta=HTA,.jar=Java JAR,.class=Java class,.swf=Flash,.js=JavaScript,.css=stylesheet,.html=HTML,.htm=HTM,.txt=text,.json=JSON,.zip=zip,.config=config,.conf=conf,.bak=backup}} -t {{THREADS:int:1000}} -mc {{MATCH:str:200}} -fs {{FILTER_SIZE:int:0}} -recursion
```

<!-- meta: risk=low | phase=recon | tags=extensions,recursion,aggressive -->

---

## using request file
Load a captured request (e.g. Burp "copy to file") and fuzz its FUZZ marker. Request file carries URL + headers + body; wordlist is the fuzz source.

```bash
ffuf -c -request {{REQUEST_FILE:file:request.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/common.txt}} -mc {{MATCH:str:200}}
```

<!-- meta: risk=low | phase=recon | tags=request-file,burp -->

---

## fuzz vhosts
Virtual-host discovery via the Host header. Filter noise lines count (`-fl`) with a value matching the garbage pages after you've eyeballed the first run.

```bash
ffuf -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/DNS/shubs-subdomains.txt}} -u {{URL:url:http://{{TARGET:ip}}}} -H "Host: FUZZ.{{DOMAIN:domain}}" -H "User-Agent: {{UA:str:$(q-ua)}}" -t {{THREADS:int:1000}} -c -fl {{FILTER_LINES:int:0}}
```

<!-- meta: risk=low | phase=recon | tags=vhost,dns -->

---

## recursion scan with extensions
Deeper variant — smaller/faster wordlist, `-ic` (ignore-comments so '#' lines count as valid entries), multichoice extension picker, recursion on.

```bash
ffuf -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt}} -ic -u {{URL:url:http://{{TARGET:ip}}}}/FUZZ -H "User-Agent: {{UA:str:$(q-ua)}}" -e {{EXTENSIONS:multichoice:.php=PHP,.asp=Classic ASP,.aspx=ASPNET,.jsp=Java Server Pages,.cgi=CGI script,.pl=Perl,.py=Python,.rb=Ruby,.sh=Shell,.dll=Windows DLL,.exe=Windows EXE,.com=DOS COM,.vbs=VBScript,.bat=Batch,.ps1=PowerShell,.md=Markdown,.psm1=PS module,.hta=HTA,.jar=Java JAR,.class=Java class,.swf=Flash,.js=JavaScript,.css=stylesheet,.html=HTML,.htm=HTM,.txt=text,.json=JSON,.zip=zip,.config=config,.conf=conf,.bak=backup}} -recursion -t {{THREADS:int:1000}}
```

<!-- meta: risk=low | phase=recon | tags=recursion,extensions,small-list -->

---

## run ffuf on file POST method
Request-file mode with explicit `-X POST` for multipart/form-data uploads where FUZZ sits inside the body (file-upload RCE paths, URL-ingest params, etc).

```bash
ffuf -u {{URL:url:http://localhost}} -request {{REQUEST_FILE:file:uploadreq}} -X POST -w {{WORDLIST:wordlist:/usr/share/seclists/Discovery/Web-Content/local-ports.txt}} -H "User-Agent: {{UA:str:$(q-ua)}}" -t {{THREADS:int:1000}}
```

<!-- meta: risk=low | phase=recon | tags=request-file,post,upload -->
