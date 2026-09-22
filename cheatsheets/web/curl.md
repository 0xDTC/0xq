# curl

> Command-line tool for transferring data with URLs

<!-- tags: http, request, download, api, web -->

**UA policy:** every outbound request sets an explicit real-browser User-Agent via `{{UA}}` (session-shared across tools). Default = modern Chrome-on-Windows. Alternates: `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0` (Firefox 128 Linux), `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15` (Safari 17 macOS).

---

## send GET request
Perform a basic HTTP GET request.

```bash
curl -s -A "{{UA:str:$(q-ua)}}" {{URL:url:http://target.com}}
```

<!-- meta: risk=safe | phase=recon | tags=get,http -->

---

## post json data
Send a POST request with a JSON body.

```bash
curl -s -X POST -A "{{UA:str:$(q-ua)}}" {{URL:url:http://target.com/api/login}} -H "Content-Type: application/json" -d '{"{{KEY1:str:username}}":"{{VAL1:str:admin}}","{{KEY2:str:password}}":"{{VAL2:str:password}}"}'
```

<!-- meta: risk=low | phase=enum | tags=post,json,api -->

---

## send custom headers
Send a request with custom HTTP headers.

```bash
curl -s -A "{{UA:str:$(q-ua)}}" {{URL:url:http://target.com/api/data}} -H "Authorization: Bearer {{TOKEN:str:eyJhbGciOi...}}" -H "{{HEADER:str:X-Custom-Header: value}}"
```

<!-- meta: risk=safe | phase=enum | tags=headers,auth -->

---

## send request with cookies
Send a request with specific cookies.

```bash
curl -s -A "{{UA:str:$(q-ua)}}" {{URL:url:http://target.com/dashboard}} -b "{{COOKIE:str:session=abc123; role=admin}}"
```

<!-- meta: risk=safe | phase=enum | tags=cookies,session -->

---

## route through proxy
Route the request through an HTTP or SOCKS proxy.

```bash
curl -s -A "{{UA:str:$(q-ua)}}" {{URL:url:http://target.com}} -x {{PROXY:str:http://127.0.0.1:8080}}
```

<!-- meta: risk=safe | phase=enum | tags=proxy,burp -->

---

## upload file multipart
Upload a file via multipart form POST.

```bash
curl -s -X POST -A "{{UA:str:$(q-ua)}}" {{URL:url:http://target.com/upload}} -F "file=@{{FILE:file:shell.php}}" -F "{{FIELD:str:submit}}=Upload"
```

<!-- meta: risk=med | phase=exploit | tags=upload,file -->

---

## follow redirects
Automatically follow HTTP 3xx redirects.

```bash
curl -s -L -A "{{UA:str:$(q-ua)}}" {{URL:url:http://target.com}}
```

<!-- meta: risk=safe | phase=recon | tags=redirect,follow -->

---

## ignore SSL cert errors
Connect to HTTPS targets with invalid or self-signed certificates.

```bash
curl -s -k -A "{{UA:str:$(q-ua)}}" {{URL:url:https://target.com}}
```

<!-- meta: risk=safe | phase=recon | tags=ssl,insecure -->

---

## show verbose request headers
Show full request and response headers for debugging.

```bash
curl -v {{URL:url:http://target.com}} 2>&1
```

<!-- meta: risk=safe | phase=recon | tags=verbose,debug -->

---

## download file to disk
Download a file and save it locally.

```bash
curl -s -L -A "{{UA:str:$(q-ua)}}" -o {{OUTFILE:file:downloaded_file}} {{URL:url:http://target.com/file.zip}}
```

<!-- meta: risk=safe | phase=misc | tags=download,save -->

---

## post form encoded data
Send an application/x-www-form-urlencoded POST body.

```bash
curl -X POST -A "{{UA:str:$(q-ua)}}" -d '{{PARAM:str:user}}={{VALUE:str}}' {{URL:url}}
```

<!-- meta: risk=low | phase=enum | tags=post,form,urlencoded -->

---

## save reuse cookie jar
Persist cookies to disk and replay them on subsequent requests.

```bash
curl -A "{{UA:str:$(q-ua)}}" -c {{COOKIEFILE:file:cookies.txt}} -b {{COOKIEFILE:file:cookies.txt}} {{URL:url}}
```

<!-- meta: risk=safe | phase=enum | tags=cookies,session,jar -->

---

## send basic auth creds
Send HTTP Basic Authentication credentials.

```bash
curl -A "{{UA:str:$(q-ua)}}" -u '{{USERNAME:str}}:{{PASSWORD:str}}' {{URL:url}}
```

<!-- meta: risk=low | phase=enum | tags=auth,basic -->

---

## force http version
Force the request to use HTTP/2 (swap `--http2` for `--http1.1` when needed).

```bash
curl --http2 -A "{{UA:str:$(q-ua)}}" {{URL:url}}
```

<!-- meta: risk=safe | phase=recon | tags=http2,version -->

---

## bypass DNS resolve vhost
Send an HTTPS request to a specific IP while keeping the SNI/Host as a domain.

```bash
curl --resolve {{DOMAIN:domain}}:{{PORT:port:443}}:{{TARGET:ip}} -A "{{UA:str:$(q-ua)}}" https://{{DOMAIN:domain}}/
```

<!-- meta: risk=safe | phase=recon | tags=dns,resolve,vhost,sni -->

---

## upload file simple multipart
Upload a file using a simple multipart form body.

```bash
curl -A "{{UA:str:$(q-ua)}}" -F 'file=@{{FILE:file}}' {{URL:url}}
```

<!-- meta: risk=med | phase=exploit | tags=upload,multipart -->

---

## loop status codes url list
Iterate a file of URLs and print each URL's final HTTP status.

```bash
while read url; do echo -n "$url: "; curl -IsSL -A "{{UA:str:$(q-ua)}}" -w '%{http_code}\n' -o /dev/null "$url"; done < {{URLLIST:file:urls.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=status,bulk,loop -->

---

## test CORS origin reflection
Probe a URL to see if it reflects an attacker-controlled Origin header.

```bash
curl -sIH "Origin: {{EVIL_ORIGIN:url:https://evil.com}}" -A "{{UA:str:$(q-ua)}}" -X GET {{URL:url}} | grep -i 'access-control-allow-origin'
```

<!-- meta: risk=safe | phase=vuln | tags=cors,origin,reflection -->

---

## upload shell via form post
Inject a malicious file through a multipart form, simulating a real upload form.

```bash
curl -X POST -A "{{UA:str:$(q-ua)}}" -F "{{SUBMIT_FIELD:str:submit}}={{SUBMIT_VALUE:str:Upload}}" -F "{{FILE_FIELD:str:file}}=@{{FILE:file:shell.php}}" {{URL:url}}
```

<!-- meta: risk=high | phase=exploit | tags=upload,multipart,shell -->
