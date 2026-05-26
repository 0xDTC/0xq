# DotDotPwn

> Directory traversal fuzzer for HTTP, FTP, TFTP, and Payload modules

<!-- tags: dotdotpwn, lfi, traversal, web, fuzzer -->

---

## fuzz path traversal http url linux
Fuzz a TRAVERSAL marker in a URL against a Linux target.

```bash
sudo dotdotpwn -m http-url -h {{TARGET:ip}} -x {{PORT:port:80}} -O -s -u "{{URL_TEMPLATE:url:http://target/cms/print.php?page=TRAVERSAL}}" -k {{KEYWORD:str:root:}} -b -q
```

<!-- meta: risk=low | phase=vuln | tags=http,traversal,linux,lfi -->

---

## fuzz path traversal http url windows
Same fuzz against a Windows host (different signature keyword).

```bash
sudo dotdotpwn -m http-url -h {{TARGET:ip}} -x {{PORT:port:8080}} -O -s -u "{{URL_TEMPLATE:url:http://target/cms/print.php?page=TRAVERSAL}}" -k WINDOWS -b -q
```

<!-- meta: risk=low | phase=vuln | tags=http,traversal,windows,lfi -->

---

## fuzz path traversal http headers
Fuzz using header/path traversal payloads against a host.

```bash
sudo dotdotpwn -m http -h {{TARGET:ip}} -x {{PORT:port:80}} -O -s -k {{KEYWORD:str:root:}} -b
```

<!-- meta: risk=low | phase=vuln | tags=http,headers,fuzz -->

---

## fuzz path traversal ftp
Test for path traversal on an FTP service with credentials.

```bash
sudo dotdotpwn -m ftp -h {{TARGET:ip}} -x {{PORT:port:21}} -U {{USERNAME:str:anonymous}} -P {{PASSWORD:str:guest}} -k root: -b
```

<!-- meta: risk=low | phase=vuln | tags=ftp,traversal -->
