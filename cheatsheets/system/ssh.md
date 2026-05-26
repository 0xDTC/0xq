# SSH

> Secure shell for remote access, file transfer, and encrypted tunneling

<!-- tags: ssh, scp, tunnel, port-forward, remote, keys -->

---

## connect to remote host
Connect to a remote host with username.

```bash
ssh {{USER:str:root}}@{{HOST:ip:10.10.10.1}} -p {{PORT:port:22}}
```

<!-- meta: risk=low | phase=misc | tags=connect,basic,remote -->

---

## connect with private key
Connect using a private key file.

```bash
ssh -i {{KEY:file:~/.ssh/id_rsa}} {{USER:str:root}}@{{HOST:ip:10.10.10.1}} -p {{PORT:port:22}}
```

<!-- meta: risk=low | phase=misc | tags=key,identity,authentication -->

---

## upload file scp
Copy a local file to a remote host.

```bash
scp -P {{PORT:port:22}} {{LOCAL:file:./payload.sh}} {{USER:str:root}}@{{HOST:ip:10.10.10.1}}:{{REMOTE:str:/tmp/payload.sh}}
```

<!-- meta: risk=low | phase=misc | tags=scp,upload,transfer -->

---

## download file scp
Copy a file from a remote host to local machine.

```bash
scp -P {{PORT:port:22}} {{USER:str:root}}@{{HOST:ip:10.10.10.1}}:{{REMOTE:str:/etc/passwd}} {{LOCAL:file:./loot/passwd}}
```

<!-- meta: risk=low | phase=misc | tags=scp,download,transfer -->

---

## local port forward tunnel
Forward a local port to a remote host through the SSH connection.

```bash
ssh -L {{LPORT:port:8080}}:{{RHOST:ip:127.0.0.1}}:{{RPORT:port:80}} {{USER:str:root}}@{{HOST:ip:10.10.10.1}} -N
```

<!-- meta: risk=low | phase=misc | tags=tunnel,local,forward,pivot -->

---

## remote port forward tunnel
Forward a remote port back to the local machine.

```bash
ssh -R {{RPORT:port:9090}}:{{LHOST:ip:127.0.0.1}}:{{LPORT:port:8080}} {{USER:str:root}}@{{HOST:ip:10.10.10.1}} -N
```

<!-- meta: risk=low | phase=misc | tags=tunnel,remote,forward,callback -->

---

## dynamic socks proxy pivot
Create a SOCKS proxy through the SSH connection for pivoting.

```bash
ssh -D {{LPORT:port:1080}} {{USER:str:root}}@{{HOST:ip:10.10.10.1}} -N
```

<!-- meta: risk=low | phase=misc | tags=socks,proxy,dynamic,pivot -->

---

## proxyjump bastion host pivot
Connect through a jump host to reach an internal target.

```bash
ssh -J {{JUMP_USER:str:user}}@{{JUMP:ip:10.10.10.1}} {{USER:str:root}}@{{TARGET:ip:192.168.1.100}}
```

<!-- meta: risk=low | phase=misc | tags=proxy,jump,bastion,pivot -->

---

## forward ssh agent keys
Forward your local SSH agent to the remote host for key reuse.

```bash
ssh -A {{USER:str:root}}@{{HOST:ip:10.10.10.1}}
```

<!-- meta: risk=med | phase=misc | tags=agent,forward,keys -->

---

## execute remote command
Run a command on a remote host without interactive shell.

```bash
ssh {{USER:str:root}}@{{HOST:ip:10.10.10.1}} "{{CMD:str:id && hostname && cat /etc/passwd}}"
```

<!-- meta: risk=low | phase=misc | tags=remote,execute,command -->

---

## inline password sshpass
Supply an SSH password inline for non-interactive automation.

```bash
sshpass -p '{{PASSWORD:str}}' ssh {{USERNAME:str}}@{{TARGET:ip}}
```

<!-- meta: risk=med | phase=misc | tags=sshpass,password,automation -->

---

## connect legacy cipher hosts
Connect to legacy SSH servers by enabling deprecated ciphers and key exchange.

```bash
ssh -c aes256-cbc -oKexAlgorithms=+diffie-hellman-group1-sha1 {{USERNAME:str}}@{{TARGET:ip}}
```

<!-- meta: risk=low | phase=misc | tags=ssh,legacy,cipher,kex -->

---

## key passphrase login sshpass
Use sshpass to pipe a passphrase into a key-based SSH login.

```bash
sshpass -P 'passphrase' -p '{{PASSPHRASE:str}}' ssh -i {{KEYFILE:file:id_rsa}} {{USERNAME:str}}@{{TARGET:ip}}
```

<!-- meta: risk=med | phase=misc | tags=sshpass,key,passphrase -->

---

## run single command shorthand
Run a single command on a remote host and exit (shorthand form).

```bash
ssh {{USERNAME:str}}@{{TARGET:ip}} '{{COMMAND:str}}'
```

<!-- meta: risk=low | phase=misc | tags=ssh,oneshot,command -->

---

## background socks5 proxy pivot
Create a SOCKS5 proxy in the background with no remote command.

```bash
ssh -D {{LPORT:port:1080}} -N -f {{USERNAME:str}}@{{TARGET:ip}}
```

<!-- meta: risk=low | phase=post | tags=socks5,proxy,background,pivot -->

---

## jump host pivot shorthand
Chain through a jump host to reach an internal target.

```bash
ssh -J {{JUMPUSER:str}}@{{JUMPHOST:ip}} {{USERNAME:str}}@{{TARGET:ip}}
```

<!-- meta: risk=low | phase=post | tags=ssh,jump,pivot,proxyjump -->

---

## generate rsa key pair
Create a 4096-bit RSA SSH key pair.

```bash
ssh-keygen -t rsa -b 4096 -f {{KEYFILE:file:~/.ssh/id_rsa}} -N ''
```

<!-- meta: risk=safe | phase=misc | tags=ssh-keygen,rsa,keys -->

---

## generate ed25519 key pair
Generate a modern Ed25519 SSH key.

```bash
ssh-keygen -t ed25519 -f {{KEYFILE:file:~/.ssh/id_ed25519}} -N ''
```

<!-- meta: risk=safe | phase=misc | tags=ssh-keygen,ed25519,keys -->

---

## generate ecdsa key pair
Generate a 521-bit ECDSA SSH key.

```bash
ssh-keygen -t ecdsa -b 521 -f {{KEYFILE:file:~/.ssh/id_ecdsa}} -N ''
```

<!-- meta: risk=safe | phase=misc | tags=ssh-keygen,ecdsa,keys -->

---

## spray ssh credentials ncrack
Spray usernames and passwords against SSH using ncrack.

```bash
ncrack -U {{USERLIST:wordlist}} -P {{PASSLIST:wordlist}} ssh://{{TARGET:ip}}:{{PORT:port:22}}
```

<!-- meta: risk=med | phase=passwords | tags=ncrack,ssh,spray -->
