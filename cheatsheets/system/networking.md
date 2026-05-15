# Networking

> Network configuration, socket inspection, firewall rules, and diagnostics

<!-- tags: ip, ss, netstat, iptables, route, ping, dns, networking -->

---

## Show IP Addresses
Display all network interface addresses.

```bash
ip -c addr show
```

<!-- meta: risk=safe | phase=misc | tags=ip,address,interface -->

---

## Show Routing Table
Display the kernel routing table.

```bash
ip route show
```

<!-- meta: risk=safe | phase=misc | tags=ip,route,gateway -->

---

## Listening Sockets (ss)
Show all listening TCP/UDP sockets with process info.

```bash
ss -tulnp
```

<!-- meta: risk=safe | phase=misc | tags=ss,listening,ports,sockets -->

---

## Connections by Port (ss)
Find which process is using a specific port.

```bash
ss -tlnp sport = :{{PORT:port:80}}
```

<!-- meta: risk=safe | phase=misc | tags=ss,port,process,filter -->

---

## Add Interface IP
Assign an IP address to a network interface.

```bash
sudo ip addr add {{IP:ip:192.168.1.100}}/{{MASK:int:24}} dev {{IFACE:iface:eth0}}
```

<!-- meta: risk=med | phase=misc | tags=ip,add,interface,config -->

---

## Bring Interface Up/Down
Enable or disable a network interface.

```bash
sudo ip link set {{IFACE:iface:eth0}} {{STATE:str:up}}
```

<!-- meta: risk=med | phase=misc | tags=interface,up,down,link -->

---

## Iptables List Rules
List all current firewall rules with line numbers.

```bash
sudo iptables -L -n -v --line-numbers
```

<!-- meta: risk=safe | phase=misc | tags=iptables,list,firewall,rules -->

---

## Iptables Allow Port
Allow incoming traffic on a specific port.

```bash
sudo iptables -A INPUT -p {{PROTO:str:tcp}} --dport {{PORT:port:443}} -j ACCEPT
```

<!-- meta: risk=med | phase=misc | tags=iptables,allow,accept,port -->

---

## Iptables Block IP
Drop all traffic from a specific IP address.

```bash
sudo iptables -A INPUT -s {{IP:ip:10.10.10.1}} -j DROP
```

<!-- meta: risk=med | phase=misc | tags=iptables,block,drop,deny -->

---

## Iptables NAT Port Forward
Forward incoming traffic on one port to another host and port.

```bash
sudo iptables -t nat -A PREROUTING -p tcp --dport {{SPORT:port:80}} -j DNAT --to-destination {{DEST:ip:192.168.1.100}}:{{DPORT:port:8080}}
```

<!-- meta: risk=high | phase=misc | tags=iptables,nat,forward,redirect -->

---

## Iptables Flush All Rules
Remove all firewall rules. Use with caution.

```bash
sudo iptables -F && sudo iptables -X && sudo iptables -t nat -F
```

<!-- meta: risk=high | phase=misc | tags=iptables,flush,reset,dangerous -->

---

## DNS Resolve
Perform DNS lookups for a domain.

```bash
dig {{DOMAIN:domain:target.com}} {{TYPE:str:ANY}} +short @{{DNS:ip:8.8.8.8}}
```

<!-- meta: risk=safe | phase=misc | tags=dns,dig,resolve,lookup -->

---

## Ping and Traceroute
Test connectivity and trace the network path to a host.

```bash
ping -c {{COUNT:int:4}} {{HOST:ip:10.10.10.1}} && traceroute {{HOST:ip:10.10.10.1}}
```

<!-- meta: risk=safe | phase=misc | tags=ping,traceroute,connectivity -->
