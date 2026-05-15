# IPSec / IKE

> IKE/IPSec VPN enumeration and PSK cracking

<!-- tags: ipsec,ike,vpn,psk -->

---

## Basic IKE Scan
Enumerate IKE responders.

```bash
ike-scan {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=basic -->

---

## IKE Version Detection
Detect IKE version on the target.

```bash
ike-scan -M {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=version -->

---

## Aggressive Mode Test
Probe for IKE Aggressive Mode (often weak).

```bash
ike-scan -A {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=aggressive -->

---

## Extract PSK Hash
Capture an Aggressive Mode PSK hash for offline cracking.

```bash
ike-scan -A {{TARGET:ip}} --pskcrack={{OUTFILE:file:ike_hash.txt}}
```

<!-- meta: risk=med | phase=enum | tags=psk,hash -->

---

## Crack PSK Hash
Crack an extracted PSK with psk-crack.

```bash
psk-crack {{HASHFILE:file:ike_hash.txt}} {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=crack,psk -->

---

## Custom Transform
Test specific encryption/hash/auth/group transforms (enc,hash,auth,group).

```bash
ike-scan --trans={{TRANSFORM:str:5,2,1,2}} {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=transform -->

---

## Vendor Fingerprinting
Probe for vendor IDs to identify implementation.

```bash
ike-scan --vendor-id {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=enum | tags=vendor,fingerprint -->

---

## strongSwan Connect
Bring up an IPSec connection (after editing /etc/ipsec.conf).

```bash
strongswan up {{CONN:str:target}}
```

<!-- meta: risk=med | phase=exploit | tags=strongswan,vpn -->

---

## strongSwan Status
Check tunnel status.

```bash
strongswan status
```

<!-- meta: risk=safe | phase=enum | tags=status -->

---

## strongSwan Down
Tear down a tunnel.

```bash
strongswan down {{CONN:str:target}}
```

<!-- meta: risk=safe | phase=misc | tags=down -->
