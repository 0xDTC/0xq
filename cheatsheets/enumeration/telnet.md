# Telnet

> Plaintext remote shell and banner-grab utility on TCP/23 and other text protocols

<!-- tags: telnet, banner, port-23, remote, plaintext -->

---

## Connect to Telnet Service
Open an interactive Telnet session to the target.

```bash
telnet {{TARGET:ip}} {{PORT:port:23}}
```

<!-- meta: risk=low | phase=enum | tags=telnet,connect,login -->

---

## Banner Grab via Telnet
Identify a service by reading its initial banner.

```bash
telnet {{TARGET:ip}} {{PORT:port:21}}
```

<!-- meta: risk=safe | phase=enum | tags=telnet,banner,probe -->

---

## Nmap Telnet Brute Force
Brute force telnet credentials with the Nmap NSE script.

```bash
nmap -p {{PORT:port:23}} --script telnet-brute --script-args userdb={{USERLIST:wordlist}},passdb={{PASSLIST:wordlist}} {{TARGET:ip}}
```

<!-- meta: risk=med | phase=passwords | tags=telnet,brute,nmap -->

---

## Hydra Telnet Brute Force
Brute force telnet logins with Hydra.

```bash
hydra -L {{USERLIST:wordlist}} -P {{PASSLIST:wordlist}} {{TARGET:ip}} telnet
```

<!-- meta: risk=med | phase=passwords | tags=hydra,telnet,brute -->
