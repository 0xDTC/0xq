# Locate

> Fast filename search using a prebuilt database

<!-- tags: locate,search,filesystem -->

---

## find file by name
Search for files by name in the locate DB.

```bash
locate {{NAME:str}}
```

<!-- meta: risk=safe | phase=misc | tags=name -->

---

## update locate database
Refresh the locate database (may need sudo).

```bash
sudo updatedb
```

<!-- meta: risk=safe | phase=misc | tags=update -->

---

## find file case insensitive
Ignore case while searching.

```bash
locate -i {{NAME:str}}
```

<!-- meta: risk=safe | phase=misc | tags=ignore-case -->

---

## find file limit results
Cap the number of returned matches.

```bash
locate -l {{LIMIT:int:20}} {{NAME:str}}
```

<!-- meta: risk=safe | phase=misc | tags=limit -->
