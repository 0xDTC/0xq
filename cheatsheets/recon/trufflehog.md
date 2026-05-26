# TruffleHog

> Scan git repositories, S3 buckets, and filesystems for leaked secrets

<!-- tags: trufflehog, secrets, git, leaks, recon -->

---

## scan github org secrets docker
Scan all repositories in an organization for secrets.

```bash
docker run -it -v "$PWD:/pwd" trufflesecurity/trufflehog:latest github --org={{ORG:str}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,github,org -->

---

## scan single repo secrets docker
Scan a specific GitHub repository URL.

```bash
docker run -it -v "$PWD:/pwd" trufflesecurity/trufflehog:latest github --repo={{REPO_URL:url}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,github,repo -->

---

## scan local git secrets
Scan a cloned git repository on disk.

```bash
trufflehog git file://{{REPO_DIR:dir:./repo}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,git,local -->

---

## scan filesystem secrets
Scan a filesystem path for hardcoded secrets.

```bash
trufflehog filesystem {{TARGET_DIR:dir:/srv}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,filesystem -->

---

## scan git verified secrets only
Show only secrets that successfully validated against their service.

```bash
trufflehog git file://{{REPO_DIR:dir:./repo}} --only-verified
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,verified,filter -->

---

## scan git secrets json output
Emit findings as JSON for tooling.

```bash
trufflehog git file://{{REPO_DIR:dir:./repo}} --json > {{OUTFILE:file:trufflehog.json}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,json,report -->

---

## scan S3 bucket secrets
Search a public or authorized S3 bucket for credentials.

```bash
trufflehog s3 --bucket={{BUCKET:str}}
```

<!-- meta: risk=safe | phase=recon | tags=trufflehog,s3,aws -->
