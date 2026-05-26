# dnsrecon
> DNS reconnaissance — standard enumeration, zone transfers, and reverse lookups.

<!-- tags: dns, dnsrecon, zone-transfer, reverse-lookup, recon -->

---

## standard enum dnsrecon
Run standard dnsrecon enumeration against a domain.

```bash
dnsrecon -d {{DOMAIN:domain}}
```

<!-- meta: risk=safe | phase=recon | tags=dnsrecon,enum,standard -->

---

## zone transfer dnsrecon
Attempt zone transfers (AXFR) against the domain's nameservers.

```bash
dnsrecon -d {{DOMAIN:domain}} -t axfr
```

<!-- meta: risk=low | phase=recon | tags=dnsrecon,zone-transfer,axfr -->

---

## reverse range dnsrecon
Reverse-lookup an explicit IP range, using a specific nameserver.

```bash
dnsrecon -r {{START_IP:ip}}-{{END_IP:ip}} -n {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=dnsrecon,reverse-lookup,range -->

---

## reverse cidr dnsrecon
Reverse-lookup a CIDR range, using a specific nameserver.

```bash
dnsrecon -r {{CIDR:str:10.10.10.0/24}} -n {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=dnsrecon,reverse-lookup,cidr -->
