# GPG

> GnuPG encryption, signing, and key management

<!-- tags: gpg,pgp,encryption,keys -->

---

## Generate Full Key (Interactive)
Walk through full key generation.

```bash
gpg --full-generate-key
```

<!-- meta: risk=safe | phase=misc | tags=keygen -->

---

## Generate Quick Key
Simplified PGP key creation.

```bash
gpg --gen-key
```

<!-- meta: risk=safe | phase=misc | tags=quick-keygen -->

---

## List Public Keys
List all stored public keys.

```bash
gpg --list-keys
```

<!-- meta: risk=safe | phase=misc | tags=list -->

---

## List Secret Keys
List private keys in the keyring.

```bash
gpg --list-secret-keys
```

<!-- meta: risk=safe | phase=misc | tags=list,secret -->

---

## Delete Secret Key
Remove a private key by fingerprint.

```bash
gpg --delete-secret-keys {{FINGERPRINT:str}}
```

<!-- meta: risk=med | phase=misc | tags=delete,secret -->

---

## Delete Public Key
Remove a public key by fingerprint.

```bash
gpg --delete-keys {{FINGERPRINT:str}}
```

<!-- meta: risk=med | phase=misc | tags=delete,public -->

---

## Encrypt File for Recipient
Encrypt a file with a recipient's public key.

```bash
gpg -e -r {{RECIPIENT:str}} {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=encrypt -->

---

## Symmetric Encrypt
Encrypt with a passphrase only.

```bash
gpg -c {{INFILE:file}}
```

<!-- meta: risk=safe | phase=misc | tags=symmetric -->

---

## Decrypt File
Decrypt a .gpg file.

```bash
gpg -d {{INFILE:file:secret.gpg}} > {{OUTFILE:file:plain.txt}}
```

<!-- meta: risk=safe | phase=misc | tags=decrypt -->

---

## Export Public Key
Export a public key in ASCII armor.

```bash
gpg --armor --export {{KEY_ID:str}} > {{OUTFILE:file:public.asc}}
```

<!-- meta: risk=safe | phase=misc | tags=export -->
