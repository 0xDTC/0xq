# ss (Socket Statistics)

> Modern replacement for netstat to inspect listening sockets and connections

<!-- tags: ss, sockets, network, listen, ports -->

---

## List Listening TCP Sockets (Names)
Show TCP services listening locally with service names.

```bash
ss -tl
```

<!-- meta: risk=safe | phase=misc | tags=ss,tcp,listen,names -->

---

## List Listening TCP Sockets (Numeric)
Show TCP listeners with numeric ports only.

```bash
ss -tln
```

<!-- meta: risk=safe | phase=misc | tags=ss,tcp,listen,numeric -->

---

## List All Listeners with Process (TCP+UDP, IPv4)
Show TCP and UDP listeners along with the owning process and PID.

```bash
sudo ss -tulnp4
```

<!-- meta: risk=safe | phase=misc | tags=ss,tcp,udp,process,pid -->

---

## All Established TCP Connections
Show every active TCP connection with both ends.

```bash
ss -tan state established
```

<!-- meta: risk=safe | phase=misc | tags=ss,established,connections -->

---

## Filter by Port
Show connections to or from a specific destination port.

```bash
ss -tan dst :{{PORT:port:443}}
```

<!-- meta: risk=safe | phase=misc | tags=ss,filter,port -->

---

## Summary Statistics
Print counts of sockets in each state.

```bash
ss -s
```

<!-- meta: risk=safe | phase=misc | tags=ss,summary,stats -->
