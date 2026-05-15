# TruffleHog

> Scan git repositories, S3 buckets, and filesystems for leaked secrets

<!-- tags: trufflehog, secrets, git, leaks, recon -->

---

## Scan a GitHub Organization (Docker)
Scan all repositories in an organization for secrets.

```bash
docker run -it -v "$PWD:/pwd" trufflesecurity/trufflehog:latest github --org={{ORG:str}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,github,org -->

---

## Scan a Single Repo (Docker)
Scan a specific GitHub repository URL.

```bash
docker run -it -v "$PWD:/pwd" trufflesecurity/trufflehog:latest github --repo={{REPO_URL:url}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,github,repo -->

---

## Scan Local Git Working Tree
Scan a cloned git repository on disk.

```bash
trufflehog git file://{{REPO_DIR:dir:./repo}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,git,local -->

---

## Scan Filesystem
Scan a filesystem path for hardcoded secrets.

```bash
trufflehog filesystem {{TARGET_DIR:dir:/srv}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,filesystem -->

---

## Only Verified Secrets
Show only secrets that successfully validated against their service.

```bash
trufflehog git file://{{REPO_DIR:dir:./repo}} --only-verified
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,verified,filter -->

---

## JSON Output
Emit findings as JSON for tooling.

```bash
trufflehog git file://{{REPO_DIR:dir:./repo}} --json > {{OUTFILE:file:trufflehog.json}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,json,report -->

---

## Scan S3 Bucket
Search a public or authorized S3 bucket for credentials.

```bash
trufflehog s3 --bucket={{BUCKET:str}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,s3,aws -->
