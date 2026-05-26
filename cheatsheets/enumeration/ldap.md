# LDAP Enumeration

> Querying LDAP directory services with ldapsearch

<!-- tags: ldap,enum,ad,directory -->

---

## bind ldap anonymous
Anonymously query an LDAP server for the base DN.

```bash
ldapsearch -x -h {{TARGET:ip}} -b "DC={{DOMAIN_DC:str:corp}},DC={{DC_TLD:str:local}}"
```

<!-- meta: risk=safe | phase=enum | tags=anon,bind -->

---

## bind ldaps ssl
Query LDAP over SSL on port 636.

```bash
ldapsearch -x -h {{TARGET:ip}}:636 -b "DC={{DOMAIN_DC:str:corp}},DC={{DC_TLD:str:local}}"
```

<!-- meta: risk=safe | phase=enum | tags=ldaps,ssl -->

---

## check null bind
Test for null bind enumeration with empty credentials.

```bash
ldapsearch -x -h {{TARGET:ip}} -D '' -w '' -b "DC={{DOMAIN_DC:str}},DC={{DC_TLD:str:local}}"
```

<!-- meta: risk=safe | phase=enum | tags=null-bind -->

---

## search ldap authenticated
Authenticated LDAP query with bind DN and password.

```bash
ldapsearch -D '{{BINDDN:str:cn=admin,dc=corp,dc=local}}' -w '{{PASSWORD:str}}' -h {{TARGET:ip}} -b "{{BASE_OU:str:dc=corp,dc=local}}" '({{FILTER:str:objectClass=user}})'
```

<!-- meta: risk=low | phase=enum | tags=auth,search -->

---

## search group membership
Return objects that are members of a target group.

```bash
ldapsearch -D '{{BINDDN:str}}' -w '{{PASSWORD:str}}' -h {{TARGET:ip}} -b "{{BASE_OU:str}}" '(memberOf={{GROUP_DN:str}})' displayName
```

<!-- meta: risk=low | phase=enum | tags=group,member -->

---

## search not in group
Return objects that are NOT in a particular group.

```bash
ldapsearch -D '{{BINDDN:str}}' -w '{{PASSWORD:str}}' -h {{TARGET:ip}} -b "{{BASE_OU:str}}" '(!(memberOf={{GROUP_DN:str}}))' displayName
```

<!-- meta: risk=low | phase=enum | tags=invert,filter -->

---

## search multiple groups AND
Return only objects in all specified groups.

```bash
ldapsearch -D '{{BINDDN:str}}' -w '{{PASSWORD:str}}' -h {{TARGET:ip}} '(&(memberOf={{G1:str}})(memberOf={{G2:str}}))' displayName
```

<!-- meta: risk=low | phase=enum | tags=and,multi-group -->

---

## find SPN kerberoast targets
Find accounts with Service Principal Names set.

```bash
ldapsearch -x -h {{TARGET:ip}} -D '{{USER:str}}@{{DOMAIN:domain}}' -W -b "DC={{DC1:str:corp}},DC={{DC2:str:local}}" "(servicePrincipalName=*)"
```

<!-- meta: risk=low | phase=enum | tags=spn,kerberoast -->

---

## search limit result size
Return at most N matching entries.

```bash
ldapsearch -D '{{BINDDN:str}}' -w '{{PASSWORD:str}}' -h {{TARGET:ip}} -b "{{BASE_OU:str}}" '{{FILTER:str:objectClass=*}}' -z {{LIMIT:int:5}} displayName
```

<!-- meta: risk=safe | phase=enum | tags=limit,size -->
