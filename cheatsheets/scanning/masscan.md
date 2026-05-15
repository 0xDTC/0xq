# Masscan

> Massively fast TCP port scanner capable of scanning the entire Internet

<!-- tags: masscan, port-scan, fast, tcp, scanning -->

---

## Fast Top Ports Scan
Quickly scan the most common ports on a target range.

```bash
sudo masscan {{SUBNET:cidr:192.168.1.0/24}} --top-ports 100 --rate {{RATE:int:1000}} -oL {{OUTFILE:file:masscan-top.txt}}
```

<!-- meta: risk=low | phase=recon | tags=fast,top-ports,quick -->

---

## All TCP Ports Scan
Scan all 65535 TCP ports across a target range.

```bash
sudo masscan {{SUBNET:cidr:192.168.1.0/24}} -p 0-65535 --rate {{RATE:int:10000}} -oL {{OUTFILE:file:masscan-allports.txt}}
```

<!-- meta: risk=low | phase=recon | tags=all-ports,full,tcp -->

---

## Scan with Banner Grabbing
Capture service banners during the port scan for version identification.

```bash
sudo masscan {{SUBNET:cidr:192.168.1.0/24}} -p {{PORTS:port:21,22,80,443,445,3389,8080}} --banners --rate {{RATE:int:1000}} -oL {{OUTFILE:file:masscan-banners.txt}}
```

<!-- meta: risk=low | phase=enum | tags=banners,version,services -->

---

## Scan from Input File
Read target ranges from a file and scan specific ports.

```bash
sudo masscan -iL {{TARGETLIST:file:targets.txt}} -p {{PORTS:port:80,443,8080,8443}} --rate {{RATE:int:1000}} -oL {{OUTFILE:file:masscan-fromfile.txt}}
```

<!-- meta: risk=low | phase=recon | tags=batch,input-file,list -->

---

## Specific Ports with JSON Output
Scan targeted ports and output results in JSON for processing.

```bash
sudo masscan {{SUBNET:cidr:192.168.1.0/24}} -p {{PORTS:port:22,80,443,445,3306,5432,8080}} --rate {{RATE:int:1000}} -oJ {{OUTFILE:file:masscan-results.json}}
```

<!-- meta: risk=low | phase=recon | tags=json,targeted,output -->

---

## Single Target Detailed Scan
Scan a single host across all ports with banner grabbing.

```bash
sudo masscan {{TARGET:ip}} -p 0-65535 --banners --rate {{RATE:int:1000}} -oL {{OUTFILE:file:masscan-single.txt}}
```

<!-- meta: risk=low | phase=recon | tags=single,detailed,banners -->

---

## Web Server Discovery
Find web servers across a large range by scanning HTTP/HTTPS ports.

```bash
sudo masscan {{SUBNET:cidr:10.0.0.0/8}} -p 80,443,8080,8443,8000,8888 --rate {{RATE:int:50000}} -oL {{OUTFILE:file:masscan-web.txt}}
```

<!-- meta: risk=low | phase=recon | tags=web,http,discovery,large-range -->

---

## Scan with Source Port and Interface
Scan using a specific source port and network interface for routing control.

```bash
sudo masscan {{SUBNET:cidr:192.168.1.0/24}} -p {{PORTS:port:80,443}} --rate {{RATE:int:1000}} --adapter-port 61000 -e {{INTERFACE:iface:eth0}} -oL {{OUTFILE:file:masscan-iface.txt}}
```

<!-- meta: risk=low | phase=recon | tags=interface,source-port,routing -->
