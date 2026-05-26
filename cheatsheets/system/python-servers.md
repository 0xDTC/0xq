# Python Servers

> Quick-start file servers for pentesting: HTTP, SMB, FTP, and upload servers

<!-- tags: python, server, http, smb, ftp, upload, transfer -->

---

## serve http python
Start a simple HTTP file server for hosting payloads and tools.

```bash
python3 -m http.server {{PORT:port:8000}} --bind {{BIND:ip:0.0.0.0}} --directory {{DIR:dir:.}}
```

<!-- meta: risk=low | phase=misc | tags=python,http,server,hosting -->

---

## serve https python ssl
Start an HTTPS server using a self-signed certificate.

```bash
openssl req -new -x509 -keyout key.pem -out cert.pem -days 1 -nodes -subj "/CN={{DOMAIN:domain:localhost}}" && python3 -c "import http.server,ssl;s=http.server.HTTPServer(('{{BIND:ip:0.0.0.0}}',{{PORT:port:443}}),http.server.SimpleHTTPRequestHandler);s.socket=ssl.wrap_socket(s.socket,certfile='cert.pem',keyfile='key.pem');s.serve_forever()"
```

<!-- meta: risk=low | phase=misc | tags=python,https,ssl,server -->

---

## serve upload server python
Start an HTTP server that accepts file uploads via POST.

```bash
python3 -m uploadserver {{PORT:port:8000}} --bind {{BIND:ip:0.0.0.0}} --directory {{DIR:dir:.}}
```

<!-- meta: risk=low | phase=misc | tags=python,upload,server,receive -->

---

## serve smb impacket windows
Start an SMB server to share files (great for Windows file transfers).

```bash
sudo impacket-smbserver {{SHARE:str:share}} {{DIR:dir:.}} -smb2support -username {{USER:str:guest}} -password {{PASS:str:guest}}
```

<!-- meta: risk=low | phase=misc | tags=smb,impacket,server,windows -->

---

## serve anonymous smb impacket
Start an anonymous SMB share with no authentication required.

```bash
sudo impacket-smbserver {{SHARE:str:share}} {{DIR:dir:.}} -smb2support
```

<!-- meta: risk=low | phase=misc | tags=smb,impacket,anonymous,server -->

---

## serve ftp python
Start an FTP server using pyftpdlib for file transfers.

```bash
python3 -m pyftpdlib -p {{PORT:port:21}} -w -d {{DIR:dir:.}} -u {{USER:str:anonymous}} -P {{PASS:str:anonymous}}
```

<!-- meta: risk=low | phase=misc | tags=ftp,python,server,transfer -->

---

## serve web php
Start a PHP development server for testing web applications.

```bash
php -S {{BIND:ip:0.0.0.0}}:{{PORT:port:8080}} -t {{DIR:dir:.}}
```

<!-- meta: risk=low | phase=misc | tags=php,server,web,development -->

---

## serve http ruby
Start a simple HTTP server using Ruby.

```bash
ruby -run -e httpd {{DIR:dir:.}} -p {{PORT:port:8000}} -b {{BIND:ip:0.0.0.0}}
```

<!-- meta: risk=low | phase=misc | tags=ruby,http,server -->

---

## receive file netcat listener
Listen on a port and write incoming data to a file.

```bash
nc -lvnp {{PORT:port:9001}} > {{OUTFILE:file:received_file}}
```

<!-- meta: risk=low | phase=misc | tags=nc,listener,receive,file -->

---

## serve webdav python
Start a WebDAV server for file sharing with wsgidav.

```bash
wsgidav --host {{BIND:ip:0.0.0.0}} --port {{PORT:port:8080}} --root {{DIR:dir:.}} --auth anonymous
```

<!-- meta: risk=low | phase=misc | tags=webdav,server,share -->
