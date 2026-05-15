# Locate

> Fast filename search using a prebuilt database

<!-- tags: locate,search,filesystem -->

---

## Find by Name
Search for files by name in the locate DB.

```bash
locate {{NAME:str}}
```

<!-- meta: risk=safe | phase=misc | tags=name -->

---

## Update Database
Refresh the locate database (may need sudo).

```bash
sudo updatedb
```

<!-- meta: risk=safe | phase=misc | tags=update -->

---

## Case-Insensitive Match
Ignore case while searching.

```bash
locate -i {{NAME:str}}
```

<!-- meta: risk=safe | phase=misc | tags=ignore-case -->

---

## Limit Results
Cap the number of returned matches.

```bash
locate -l {{LIMIT:int:20}} {{NAME:str}}
```

<!-- meta: risk=safe | phase=misc | tags=limit -->
