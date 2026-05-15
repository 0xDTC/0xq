# AWS S3

> S3 bucket enumeration, exfiltration, and ACL/policy inspection commands

<!-- tags: aws, s3, bucket, cloud, recon, exfil -->

---

## List Bucket Contents Anonymously
List all objects in a bucket without signing the request.

```bash
aws s3 ls s3://{{BUCKET:str}} --recursive --no-sign-request
```

<!-- meta: risk=safe | phase=recon | tags=s3,anonymous,list -->

---

## List Bucket via Custom Endpoint
Hit a non-AWS S3-compatible endpoint (MinIO, Wasabi, R2, etc.).

```bash
aws --endpoint-url {{ENDPOINT:url:http://target.com}} s3 ls s3://{{BUCKET:str}} --recursive --no-sign-request
```

<!-- meta: risk=safe | phase=recon | tags=s3,endpoint,custom -->

---

## Download Bucket Contents (Recursive)
Recursively pull every object from a bucket to a local directory.

```bash
aws s3 cp s3://{{BUCKET:str}}/ {{LOCAL_DIR:dir:./loot/}} --no-sign-request --recursive
```

<!-- meta: risk=low | phase=post | tags=s3,download,exfil -->

---

## Get Bucket ACL
Inspect the access control list to identify public or misconfigured permissions.

```bash
aws s3api get-bucket-acl --bucket {{BUCKET:str}}
```

<!-- meta: risk=safe | phase=recon | tags=s3,acl,permissions -->

---

## Get Bucket Policy
Retrieve the bucket policy JSON for permissions analysis.

```bash
aws s3api get-bucket-policy --bucket {{BUCKET:str}}
```

<!-- meta: risk=safe | phase=recon | tags=s3,policy,iam -->

---

## Get Object ACL
Inspect ACL of a specific object, useful for finding public files.

```bash
aws s3api get-object-acl --bucket {{BUCKET:str}} --key {{KEY:str}}
```

<!-- meta: risk=safe | phase=recon | tags=s3,object,acl -->

---

## Get Bucket Region
Determine the region a bucket is hosted in (useful for endpoint targeting).

```bash
aws s3api get-bucket-location --bucket {{BUCKET:str}}
```

<!-- meta: risk=safe | phase=recon | tags=s3,location,region -->

---

## Head Object Metadata
Fetch object metadata (size, ETag, encryption headers) without downloading.

```bash
aws s3api head-object --bucket {{BUCKET:str}} --key {{KEY:str}}
```

<!-- meta: risk=safe | phase=recon | tags=s3,metadata,head -->

---

## Get Bucket Static Website Config
Check if a bucket is configured to serve as a static website.

```bash
aws s3api get-bucket-website --bucket {{BUCKET:str}}
```

<!-- meta: risk=safe | phase=recon | tags=s3,website,static -->

---

## Sync Bucket to Local
Mirror a bucket into a local directory, only transferring changed objects.

```bash
aws s3 sync s3://{{BUCKET:str}} {{LOCAL_DIR:dir:./bucket-mirror/}} --no-sign-request
```

<!-- meta: risk=low | phase=post | tags=s3,sync,mirror -->

---

## Generate Presigned URL
Generate a temporary public URL for an object you have access to.

```bash
aws s3 presign s3://{{BUCKET:str}}/{{KEY:str}}
```

<!-- meta: risk=safe | phase=recon | tags=s3,presign,sharing -->
