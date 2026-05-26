# BloodHound

> Active Directory attack-path graphing using bloodhound-python and Neo4j (see sharphound.md for SharpHound)

<!-- tags: bloodhound, bloodhound-python, neo4j, ad, attack-path, graph -->

---

## start neo4j service
Start the Neo4j database service that backs BloodHound.

```bash
sudo systemctl start neo4j && sudo systemctl status neo4j --no-pager
```

<!-- meta: risk=safe | phase=misc | tags=neo4j,service,start -->

---

## reset neo4j password
Open the Neo4j browser to set the initial password (default neo4j:neo4j).

```bash
xdg-open http://localhost:7474
```

<!-- meta: risk=safe | phase=misc | tags=neo4j,password,reset -->

---

## collect AD authenticated linux
Run remote AD collection from Linux against a domain controller.

```bash
bloodhound-python -u {{USERNAME:str}} -p '{{PASSWORD:str}}' -d {{DOMAIN:domain}} -c All -dc {{DC_HOST:domain}} -ns {{DC_IP:ip}} --zip
```

<!-- meta: risk=low | phase=enum | tags=bloodhound-python,collection,linux -->

---

## collect AD disable autogc
Skip global catalog autodiscovery when DNS resolution fails.

```bash
bloodhound-python -u {{USERNAME:str}} -p '{{PASSWORD:str}}' -d {{DOMAIN:domain}} -c ALL --disable-autogc -dc {{DC_HOST:domain}} -ns {{DC_IP:ip}} --zip
```

<!-- meta: risk=low | phase=enum | tags=bloodhound-python,no-autogc -->

---

## collect AD pass-the-hash
Authenticate to AD using an NT hash instead of a password.

```bash
bloodhound-python -u {{USERNAME:str}} --hashes :{{NTHASH:str}} -d {{DOMAIN:domain}} -c All -dc {{DC_HOST:domain}} -ns {{DC_IP:ip}} --zip
```

<!-- meta: risk=low | phase=enum | tags=bloodhound-python,pth,hash -->

---

## collect AD kerberos ticket
Authenticate using a cached Kerberos ticket (KRB5CCNAME env var).

```bash
KRB5CCNAME={{CCACHE:file:/tmp/krb5cc}} bloodhound-python -u {{USERNAME:str}} -d {{DOMAIN:domain}} -c All -k --no-pass -dc {{DC_HOST:domain}} -ns {{DC_IP:ip}} --zip
```

<!-- meta: risk=low | phase=enum | tags=bloodhound-python,kerberos,ccache -->
