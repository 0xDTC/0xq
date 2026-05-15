# Wireshark / TShark

> Capture and analyze network traffic using Wireshark filters and tshark CLI

<!-- tags: wireshark, tshark, capture, pcap, network, sniff -->

---

## Capture on Interface (GUI)
Launch Wireshark capturing on a specific interface.

```bash
wireshark -i {{IFACE:iface:eth0}}
```

<!-- meta: risk=safe | phase=recon | tags=wireshark,gui,capture -->

---

## Capture to PCAP File (GUI)
Capture and write to a pcap for offline analysis.

```bash
wireshark -i {{IFACE:iface:eth0}} -w {{OUTFILE:file:capture.pcap}}
```

<!-- meta: risk=safe | phase=recon | tags=wireshark,write,pcap -->

---

## TShark Basic Capture
CLI capture to file (headless servers, scripts).

```bash
tshark -i {{IFACE:iface:eth0}} -w {{OUTFILE:file:capture.pcap}}
```

<!-- meta: risk=safe | phase=recon | tags=tshark,capture,cli -->

---

## TShark Filtered Capture
Capture only matching traffic via BPF filter.

```bash
tshark -i {{IFACE:iface:eth0}} -f "{{BPF:str:tcp port 80}}" -w {{OUTFILE:file:http.pcap}}
```

<!-- meta: risk=safe | phase=recon | tags=tshark,bpf,filter -->

---

## TShark Read & Extract Fields
Read a pcap and extract specific fields as TSV.

```bash
tshark -r {{INFILE:file:capture.pcap}} -T fields -e frame.time -e ip.src -e ip.dst -e tcp.dstport
```

<!-- meta: risk=safe | phase=recon | tags=tshark,fields,extract -->

---

## TShark IO Statistics
Print throughput statistics for a captured file.

```bash
tshark -r {{INFILE:file:capture.pcap}} -q -z io,stat,1
```

<!-- meta: risk=safe | phase=recon | tags=tshark,stats,io -->

---

## TShark Display Filter
Apply a Wireshark display filter while reading a pcap.

```bash
tshark -r {{INFILE:file:capture.pcap}} -Y "{{DISPLAY_FILTER:str:http.request.method == \"POST\"}}"
```

<!-- meta: risk=safe | phase=recon | tags=tshark,display,filter -->

---

## TShark Follow TCP Stream
Reassemble and print a specific TCP stream by index.

```bash
tshark -r {{INFILE:file:capture.pcap}} -q -z follow,tcp,ascii,{{STREAM:int:0}}
```

<!-- meta: risk=safe | phase=recon | tags=tshark,follow,stream -->

---

## TShark Extract Credentials
Pull common cleartext creds (HTTP, FTP, IMAP) using credentials tap.

```bash
tshark -r {{INFILE:file:capture.pcap}} -q -z credentials
```

<!-- meta: risk=low | phase=recon | tags=tshark,creds,sniff -->

---

## TShark Filter by Host
Show traffic to or from a specific host IP.

```bash
tshark -r {{INFILE:file:capture.pcap}} -Y "ip.addr == {{HOST:ip}}"
```

<!-- meta: risk=safe | phase=recon | tags=tshark,host,filter -->

---

## TShark Detect SYN Floods
Filter for SYN packets without ACK to spot scan/flood activity.

```bash
tshark -r {{INFILE:file:capture.pcap}} -Y "tcp.flags.syn == 1 and tcp.flags.ack == 0"
```

<!-- meta: risk=safe | phase=recon | tags=tshark,syn,flood,scan -->

---

## TShark Capture HTTP Only
CLI live capture restricted to HTTP traffic.

```bash
tshark -i {{IFACE:iface:eth0}} -f "tcp port 80" -Y http
```

<!-- meta: risk=safe | phase=recon | tags=tshark,http,live -->
