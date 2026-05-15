# Metabigor

> OSINT tool for IP, organization, and ASN intelligence without API keys

<!-- tags: metabigor,osint,asn,ip -->

---

## Enumerate Organization IPs
Find IP ranges associated with an organization name.

```bash
echo "{{ORG:str:Acme Corp}}" | metabigor net --org -o {{OUTFILE:file:org-ips.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=org,ip-range -->

---

## ASN to IP Range
Resolve an ASN to its announced prefixes.

```bash
echo "{{ASN:str:AS15169}}" | metabigor net --asn -o {{OUTFILE:file:asn-ips.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=asn -->

---

## Reverse Whois by Email/Term
Search reverse whois records.

```bash
echo "{{TERM:str:example@target.com}}" | metabigor related --src whoxy -o {{OUTFILE:file:related.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=whois,reverse -->
