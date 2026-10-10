# ssh

> Only the patterns you actually use. Eight entries, nothing extra.

<!-- tags: ssh, tunnel, forward, keygen, connect -->

> **Interactive escape sequences** (type after `Enter` while connected):
> `~.` disconnect · `~^Z` background · `~C` open command line (add port-forwards live, `-L localport:host:remoteport`) · `~#` list forwarded connections

---

## connect direct
Password login — simplest form.

```bash
ssh {{USER:str}}@{{TARGET:ip}}
```

<!-- meta: risk=low | phase=connect | tags=basic -->

---

## connect with key
Private-key auth. `-i` points to your key file (id_rsa / id_ed25519 / etc).

```bash
ssh -i {{KEY:file:~/.ssh/id_rsa}} {{USER:str}}@{{TARGET:ip}}
```

<!-- meta: risk=low | phase=connect | tags=key,auth -->

---

## local port forward
Forward LOCAL_PORT on your box → REMOTE_HOST:REMOTE_PORT via the ssh target. Classic pivot: `-L 8443:127.0.0.1:8443` lets you hit a service bound to localhost on the remote.

```bash
ssh -L {{LPORT:port:8443}}:{{RHOST:str:127.0.0.1}}:{{RPORT:port:8443}} {{USER:str}}@{{TARGET:ip}}
```

<!-- meta: risk=low | phase=pivot | tags=forward,tunnel,local -->

---

## credentials spray via ncrack
NOT ssh — ncrack brute against sshd. Lives here because it's part of the ssh workflow note. Use `-U` for userlist + `-P` for passlist.

```bash
ncrack -U {{USERS:file:users.txt}} -P {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} ssh://{{TARGET:ip}}
```

<!-- meta: risk=medium | phase=brute | tags=ncrack,ssh,spray -->

---

## generate key rsa 4096
Classic RSA keypair, maximum reasonable key size.

```bash
ssh-keygen -t rsa -b 4096 -f {{KEYFILE:file:~/.ssh/id_rsa_new}}
```

<!-- meta: risk=low | phase=setup | tags=keygen,rsa -->

---

## generate key dsa
DSA keypair. Deprecated by OpenSSH defaults but still useful for legacy systems.

```bash
ssh-keygen -t dsa -f {{KEYFILE:file:~/.ssh/id_dsa_new}}
```

<!-- meta: risk=low | phase=setup | tags=keygen,dsa,legacy -->

---

## generate key ecdsa 521
ECDSA keypair at 521 bits (max). Smaller than RSA 4096, same security level.

```bash
ssh-keygen -t ecdsa -b 521 -f {{KEYFILE:file:~/.ssh/id_ecdsa_new}}
```

<!-- meta: risk=low | phase=setup | tags=keygen,ecdsa -->

---

## generate key ed25519
Modern default — small, fast, strong. Fixed 256-bit, no `-b` needed.

```bash
ssh-keygen -t ed25519 -f {{KEYFILE:file:~/.ssh/id_ed25519_new}}
```

<!-- meta: risk=low | phase=setup | tags=keygen,ed25519,modern -->
