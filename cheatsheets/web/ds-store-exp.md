# DS_Store Exp

> Parse exposed .DS_Store files to recursively map and download web directory contents

<!-- tags: ds_store, macos, web, info-disclosure, recon -->

---

## Install Dependencies
Install the Python libraries required by ds_store_exp and ds_walk.

```bash
pip install ds-store requests
```

<!-- meta: risk=safe | phase=misc | tags=install,pip -->

---

## Run ds_store_exp Against URL
Recursively parse a remote .DS_Store and download referenced files.

```bash
python3 {{SCRIPT:file:ds_store_exp.py}} {{URL:url:http://target.com/.DS_Store}}
```

<!-- meta: risk=low | phase=enum | tags=ds_store,exfil,recursive -->

---

## Quick Probe for .DS_Store Files
Check if a server exposes .DS_Store at common paths before running the parser.

```bash
for p in "" "themes/" "static/" "assets/"; do curl -sI {{URL:url:http://target.com/}}${p}.DS_Store | head -1; done
```

<!-- meta: risk=safe | phase=recon | tags=probe,curl,manual -->
