# S3Scanner
> Scan for open S3 buckets and dump their contents across AWS, GCP, DigitalOcean, Linode, Scaleway, DreamHost, and custom S3-compatible providers.

<!-- tags: cloud,aws,s3,bucket,storage -->

## generate bucket candidates from domains
Build common bucket-name candidates from in-scope domains and root names.

```bash
sed 's/^www\.//' {{DOMAIN_FILE:file:domains.txt}} | awk '{print; print $0"-assets"; print $0"-backup"; print $0"-backups"; print $0"-dev"; print $0"-prod"; print $0"-staging"; print $0"-static"; print $0"-uploads"}' | sort -u > {{BUCKET_FILE:file:buckets.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=candidates,domains,wordlist -->

---

## generate bucket candidates from root name
Generate quick mutations for one company or product root string.

```bash
printf '%s\n' "{{ROOT:str:acme}}" "{{ROOT:str:acme}}-assets" "{{ROOT:str:acme}}-backup" "{{ROOT:str:acme}}-backups" "{{ROOT:str:acme}}-dev" "{{ROOT:str:acme}}-prod" "{{ROOT:str:acme}}-public" "{{ROOT:str:acme}}-stage" "{{ROOT:str:acme}}-staging" "{{ROOT:str:acme}}-static" "{{ROOT:str:acme}}-uploads" | sort -u > {{BUCKET_FILE:file:buckets.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=candidates,mutations,wordlist -->

---

## normalize bucket list
Lowercase, deduplicate, and remove blank lines before scanning.

```bash
tr '[:upper:]' '[:lower:]' < {{RAW_BUCKET_FILE:file:raw-buckets.txt}} | sed '/^$/d' | sort -u > {{BUCKET_FILE:file:buckets.txt}}
```

<!-- meta: risk=safe | phase=recon | tags=normalize,dedupe,prep -->

---

## scan bucket s3scanner
Check permissions for one AWS bucket name.

```bash
s3scanner -bucket {{BUCKET:str:example-bucket}}
```

<!-- meta: risk=low | phase=recon | tags=aws,scan,single -->

---

## scan bucket json s3scanner
Scan one bucket and emit JSON lines for evidence capture and parsing.

```bash
s3scanner -bucket {{BUCKET:str:example-bucket}} -json
```

<!-- meta: risk=low | phase=recon | tags=aws,scan,json -->

---

## scan bucket list s3scanner
Check permissions for bucket names listed one per line.

```bash
s3scanner -bucket-file {{BUCKET_FILE:file:buckets.txt}}
```

<!-- meta: risk=low | phase=recon | tags=aws,scan,bulk -->

---

## scan bucket list json s3scanner
Scan a bucket list and save machine-readable JSON lines for reporting.

```bash
s3scanner -bucket-file {{BUCKET_FILE:file:buckets.txt}} -json | tee {{OUTFILE:file:s3scanner.jsonl}}
```

<!-- meta: risk=low | phase=recon | tags=aws,scan,bulk,json -->

---

## scan bucket list threads s3scanner
Increase concurrent bucket permission checks to speed up large scans.

```bash
s3scanner -bucket-file {{BUCKET_FILE:file:buckets.txt}} -threads {{THREADS:int:16}}
```

<!-- meta: risk=low | phase=recon | tags=aws,scan,threads,concurrency -->

---

## scan and enumerate bucket s3scanner
Check permissions and enumerate object names if listing is allowed.

```bash
s3scanner -bucket {{BUCKET:str:example-bucket}} -enumerate
```

<!-- meta: risk=low | phase=enum | tags=aws,enumerate,objects -->

---

## scan and enumerate bucket json s3scanner
Enumerate one bucket and preserve object evidence as JSON lines.

```bash
s3scanner -bucket {{BUCKET:str:example-bucket}} -enumerate -json | tee {{OUTFILE:file:s3scanner-enum.jsonl}}
```

<!-- meta: risk=low | phase=enum | tags=aws,enumerate,objects,json -->

---

## scan and enumerate bucket list s3scanner
Scan bucket names from a file and enumerate accessible objects.

```bash
s3scanner -bucket-file {{BUCKET_FILE:file:buckets.txt}} -enumerate
```

<!-- meta: risk=low | phase=enum | tags=aws,enumerate,bulk -->

---

## scan and enumerate bucket list json s3scanner
Enumerate accessible objects across a bucket list and save JSON lines.

```bash
s3scanner -bucket-file {{BUCKET_FILE:file:buckets.txt}} -enumerate -json | tee {{OUTFILE:file:s3scanner-enum.jsonl}}
```

<!-- meta: risk=low | phase=enum | tags=aws,enumerate,bulk,json -->

---

## scan bucket gcp s3scanner
Check a Google Cloud Storage bucket using S3Scanner's provider option.

```bash
s3scanner -provider gcp -bucket {{BUCKET:str:example-bucket}}
```

<!-- meta: risk=low | phase=recon | tags=gcp,scan,provider -->

---

## scan bucket digitalocean s3scanner
Scan a DigitalOcean Spaces bucket.

```bash
s3scanner -provider digitalocean -bucket {{BUCKET:str:example-bucket}}
```

<!-- meta: risk=low | phase=recon | tags=digitalocean,spaces,provider -->

---

## scan bucket linode s3scanner
Scan a Linode object storage bucket.

```bash
s3scanner -provider linode -bucket {{BUCKET:str:example-bucket}}
```

<!-- meta: risk=low | phase=recon | tags=linode,provider -->

---

## scan bucket custom provider s3scanner
Scan an S3-compatible custom provider using config.yml from `.`, `/etc/s3scanner/`, or `$HOME/.s3scanner/`.

```bash
s3scanner -provider custom -bucket {{BUCKET:str:example-bucket}}
```

<!-- meta: risk=low | phase=recon | tags=custom,provider,s3-compatible -->

---

## scan bucket list to database s3scanner
Save scan results to Postgres. Use a dedicated schema because S3Scanner runs Gorm automigration.

```bash
s3scanner -bucket-file {{BUCKET_FILE:file:buckets.txt}} -db
```

<!-- meta: risk=low | phase=recon | tags=database,postgres,output -->

---

## extract existing buckets json
Print bucket name and region for buckets that exist from JSON output.

```bash
jq -r 'select(.bucket.exists==1) | [.bucket.name, .bucket.region] | @tsv' {{OUTFILE:file:s3scanner.jsonl}}
```

<!-- meta: risk=safe | phase=recon | tags=triage,json,parse -->

---

## find public bucket records json
Print JSON records that mention public user permissions.

```bash
jq -c 'select((tostring | test("Public|public")))' {{OUTFILE:file:s3scanner.jsonl}}
```

<!-- meta: risk=safe | phase=recon | tags=triage,public,exposure -->

---

## grep read list leads
Search JSON output for read/list indicators for manual verification.

```bash
grep -iE 'read|list|get|public|full control' {{OUTFILE:file:s3scanner.jsonl}}
```

<!-- meta: risk=safe | phase=recon | tags=triage,read,list -->

---

## grep write leads
Search JSON output for write, put, or full-control indicators for careful exploitation planning.

```bash
grep -iE 'write|put|full control|write acp' {{OUTFILE:file:s3scanner.jsonl}}
```

<!-- meta: risk=safe | phase=recon | tags=triage,write,privesc -->

---

## extract object names from enumeration json
Extract object names from enumeration output for sampling and sensitive-name review.

```bash
jq -r '.. | objects | .key? // empty' {{OUTFILE:file:s3scanner-enum.jsonl}} | sort -u
```

<!-- meta: risk=safe | phase=enum | tags=triage,objects,json -->

---

## list bucket anonymously aws
Manually verify recursive anonymous object listing with a size summary.

```bash
aws s3 ls "s3://{{BUCKET:str:example-bucket}}" --recursive --human-readable --summarize --no-sign-request
```

<!-- meta: risk=low | phase=enum | tags=aws,verify,anonymous,list -->

---

## download object anonymously aws
Download one approved sample object anonymously for proof. Avoid bulk download unless authorized.

```bash
aws s3 cp "s3://{{BUCKET:str:example-bucket}}/{{OBJECT_KEY:str:path/to/object}}" {{OUTFILE:file:loot.bin}} --no-sign-request
```

<!-- meta: risk=med | phase=exploit | tags=aws,download,anonymous,loot -->

---

## probe write access anonymously aws
If explicitly authorized, upload a harmless proof file to validate write access, then remove it.

```bash
printf 'authorized security test\n' > {{PROOF_FILE:file:s3scanner-proof.txt}} && aws s3 cp {{PROOF_FILE:file:s3scanner-proof.txt}} "s3://{{BUCKET:str:example-bucket}}/{{PROOF_KEY:str:s3scanner-proof.txt}}" --no-sign-request && aws s3 rm "s3://{{BUCKET:str:example-bucket}}/{{PROOF_KEY:str:s3scanner-proof.txt}}" --no-sign-request
```

<!-- meta: risk=high | phase=exploit | tags=aws,write,probe,anonymous -->
