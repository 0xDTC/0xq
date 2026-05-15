# LDAP Enumeration

> Querying LDAP directory services with ldapsearch

<!-- tags: ldap,enum,ad,directory -->

---

## Basic Anonymous Bind
Anonymously query an LDAP server for the base DN.

```bash
ldapsearch -x -h {{TARGET:ip}} -b "DC={{DOMAIN_DC:str:corp}},DC={{DC_TLD:str:local}}"
```

<!-- meta: risk=safe | phase=enum | tags=anon,bind -->

---

## LDAPS Bind
Query LDAP over SSL on port 636.

```bash
ldapsearch -x -h {{TARGET:ip}}:636 -b "DC={{DOMAIN_DC:str:corp}},DC={{DC_TLD:str:local}}"
```

<!-- meta: risk=safe | phase=enum | tags=ldaps,ssl -->

---

## Null Bind Check
Test for null bind enumeration with empty credentials.

```bash
ldapsearch -x -h {{TARGET:ip}} -D '' -w '' -b "DC={{DOMAIN_DC:str}},DC={{DC_TLD:str:local}}"
```

<!-- meta: risk=safe | phase=enum | tags=null-bind -->

---

## Authenticated Search
Authenticated LDAP query with bind DN and password.

```bash
ldapsearch -D '{{BINDDN:str:cn=admin,dc=corp,dc=local}}' -w '{{PASSWORD:str}}' -h {{TARGET:ip}} -b "{{BASE_OU:str:dc=corp,dc=local}}" '({{FILTER:str:objectClass=user}})'
```

<!-- meta: risk=low | phase=enum | tags=auth,search -->

---

## Search by Group Membership
Return objects that are members of a target group.

```bash
ldapsearch -D '{{BINDDN:str}}' -w '{{PASSWORD:str}}' -h {{TARGET:ip}} -b "{{BASE_OU:str}}" '(memberOf={{GROUP_DN:str}})' displayName
```

<!-- meta: risk=low | phase=enum | tags=group,member -->

---

## Inverted Group Filter
Return objects that are NOT in a particular group.

```bash
ldapsearch -D '{{BINDDN:str}}' -w '{{PASSWORD:str}}' -h {{TARGET:ip}} -b "{{BASE_OU:str}}" '(!(memberOf={{GROUP_DN:str}}))' displayName
```

<!-- meta: risk=low | phase=enum | tags=invert,filter -->

---

## Multiple Group Membership AND
Return only objects in all specified groups.

```bash
ldapsearch -D '{{BINDDN:str}}' -w '{{PASSWORD:str}}' -h {{TARGET:ip}} '(&(memberOf={{G1:str}})(memberOf={{G2:str}}))' displayName
```

<!-- meta: risk=low | phase=enum | tags=and,multi-group -->

---

## SPN Search (Kerberoasting Targets)
Find accounts with Service Principal Names set.

```bash
ldapsearch -x -h {{TARGET:ip}} -D '{{USER:str}}@{{DOMAIN:domain}}' -W -b "DC={{DC1:str:corp}},DC={{DC2:str:local}}" "(servicePrincipalName=*)"
```

<!-- meta: risk=low | phase=enum | tags=spn,kerberoast -->

---

## Limit Result Size
Return at most N matching entries.

```bash
ldapsearch -D '{{BINDDN:str}}' -w '{{PASSWORD:str}}' -h {{TARGET:ip}} -b "{{BASE_OU:str}}" '{{FILTER:str:objectClass=*}}' -z {{LIMIT:int:5}} displayName
```

<!-- meta: risk=safe | phase=enum | tags=limit,size -->
