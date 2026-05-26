# ss (Socket Statistics)

> Modern replacement for netstat to inspect listening sockets and connections

<!-- tags: ss, sockets, network, listen, ports -->

---

## list listening tcp sockets names
Show TCP services listening locally with service names.

```bash
ss -tl
```

<!-- meta: risk=safe | phase=misc | tags=ss,tcp,listen,names -->

---

## list listening tcp sockets numeric
Show TCP listeners with numeric ports only.

```bash
ss -tln
```

<!-- meta: risk=safe | phase=misc | tags=ss,tcp,listen,numeric -->

---

## list listeners with process tcp udp
Show TCP and UDP listeners along with the owning process and PID.

```bash
sudo ss -tulnp4
```

<!-- meta: risk=safe | phase=misc | tags=ss,tcp,udp,process,pid -->

---

## list established tcp connections
Show every active TCP connection with both ends.

```bash
ss -tan state established
```

<!-- meta: risk=safe | phase=misc | tags=ss,established,connections -->

---

## filter connections by port
Show connections to or from a specific destination port.

```bash
ss -tan dst :{{PORT:port:443}}
```

<!-- meta: risk=safe | phase=misc | tags=ss,filter,port -->

---

## show socket summary statistics
Print counts of sockets in each state.

```bash
ss -s
```

<!-- meta: risk=safe | phase=misc | tags=ss,summary,stats -->
