# GPG

> GnuPG encryption, signing, and key management

<!-- tags: gpg,pgp,encryption,keys -->

---

## generate full key interactive
Walk through full key generation.

```bash
gpg --full-generate-key
```

<!-- meta: risk=safe | phase=misc | tags=keygen -->

---

## generate quick key
Simplified PGP key creation.

```bash
gpg --gen-key
```

<!-- meta: risk=safe | phase=misc | tags=quick-keygen -->

---

## list public keys
List all stored public keys.

```bash
gpg --list-keys
```

<!-- meta: risk=safe | phase=misc | tags=list -->

---

## list secret keys
List private keys in the keyring.

```bash
gpg --list-secret-keys
```

<!-- meta: risk=safe | phase=misc | tags=list,secret -->

---

## delete secret key
Remove a private key by fingerprint.

```bash
gpg --delete-secret-keys {{FINGERPRINT:str}}
```

<!-- meta: risk=med | phase=misc | tags=delete,secret -->

---

## delete public key
Remove a public key by fingerprint.

```bash
gpg --delete-keys {{FINGERPRINT:str}}
```

<!-- meta: risk=med | phase=misc | tags=delete,public -->

---

## encrypt file for recipient
Encrypt a file with a recipient's public key.

```bash
gpg -e -r {{RECIPIENT:str}} {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=encrypt -->

---

## symmetric encrypt passphrase
Encrypt with a passphrase only.

```bash
gpg -c {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=symmetric -->

---

## decrypt file
Decrypt a .gpg file.

```bash
gpg -d {{INFILE:file:secret.gpg}} > {{OUTFILE:file:plain.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=decrypt -->

---

## export public key armor
Export a public key in ASCII armor.

```bash
gpg --armor --export {{KEY_ID:str}} > {{OUTFILE:file:public.asc}}
```

<!-- meta: risk=safe | phase=misc | tags=export -->
