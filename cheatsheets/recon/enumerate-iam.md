# Enumerate-IAM

> Enumerate AWS IAM permissions reachable with a given access key/secret pair (brute-force allowed actions)

<!-- tags: aws, iam, enumeration, recon, cloud -->

---

## Clone the Repo
Pull the enumerate-iam tool from GitHub.

```bash
git clone https://github.com/andresriancho/enumerate-iam.git {{OUTDIR:dir:./enumerate-iam}}
```

<!-- meta: risk=safe | phase=misc | tags=git,install -->

---

## Install Dependencies
Install required Python packages inside the cloned repo.

```bash
cd {{REPO:dir:./enumerate-iam}} && pip3 install -r requirements.txt
```

<!-- meta: risk=safe | phase=misc | tags=pip,install -->

---

## Run Against Stolen Keys
Discover IAM permissions accessible with a captured access/secret key pair.

```bash
./enumerate-iam.py --access-key "{{ACCESS_KEY:str}}" --secret-key "{{SECRET_KEY:str}}"
```

<!-- meta: risk=low | phase=enum | tags=iam,bruteforce,permissions -->

---

## Run with Session Token (STS)
Add an STS session token when working with temporary credentials.

```bash
./enumerate-iam.py --access-key "{{ACCESS_KEY:str}}" --secret-key "{{SECRET_KEY:str}}" --session-token "{{SESSION_TOKEN:str}}"
```

<!-- meta: risk=low | phase=enum | tags=sts,session,temporary -->
