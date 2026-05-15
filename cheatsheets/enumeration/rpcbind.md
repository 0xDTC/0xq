# RPCBind
> Enumerate RPC services on port 111 and exploit related NFS/RPC misconfigurations
<!-- tags: rpcbind,rpc,nfs,portmap,enumeration -->

---

## List RPC Services
Show services registered with rpcbind.

```bash
rpcinfo -p {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=rpcbind,rpcinfo -->

---

## Detailed RPC Service Listing
List all RPC programs with versions and protocols.

```bash
rpcinfo -s {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=rpcbind,detailed -->

---

## Nmap RPC Scripts
Run NSE scripts for RPC enumeration.

```bash
nmap -sV -sC -p 111 --script "rpcinfo,rpcbind-info,rpc-grind" {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=rpcbind,nmap,nse -->

---

## NFS Discovery via RPC
Discover NFS shares via portmap.

```bash
nmap -p 111 --script "nfs-showmount,nfs-ls,nfs-statfs" {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=rpcbind,nfs,discovery -->

---

## rpcclient Anonymous Bind
Connect to RPC with NULL session for SAMR enumeration.

```bash
rpcclient -U "" -N {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=rpcbind,rpcclient,null-session -->

---

## rpcclient Authenticated
Authenticate to RPC service with credentials.

```bash
rpcclient -U {{USERNAME:str}}%{{PASSWORD:str}} {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=rpcbind,rpcclient,auth -->

---

## RPC UDP Scan
Scan RPC services over UDP.

```bash
sudo nmap -sU -p 111 --script rpcinfo {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=rpcbind,udp -->

---

## TCP Connect to Portmap
Manually inspect portmap service via TCP.

```bash
nc {{TARGET:ip}} 111
```

<!-- meta: risk=safe | phase=recon | tags=rpcbind,netcat -->

---

## Enumerate by Program Number
Query specific RPC program number.

```bash
rpcinfo -T tcp {{TARGET:ip}} {{PROG_NUM:int:100000}}
```

<!-- meta: risk=safe | phase=enum | tags=rpcbind,prognum -->

---

## Capture RPC Traffic
Capture portmap traffic for offline analysis.

```bash
sudo tcpdump -i {{IFACE:iface:eth0}} port 111 -w {{OUTFILE:file:rpc.pcap}}
```

<!-- meta: risk=med | phase=recon | tags=rpcbind,pcap,sniff -->
