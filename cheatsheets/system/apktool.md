# Apktool

> Decompile, modify, and rebuild Android APK files

<!-- tags: apktool, android, apk, mobile, reverse-engineering -->

---

## Decompile APK
Decode an APK into smali, resources, and AndroidManifest.

```bash
apktool d {{APK:file:app.apk}}
```

<!-- meta: risk=safe | phase=recon | tags=decompile,apk,smali -->

---

## Decompile to Specific Output Directory
Choose a custom output directory for the decoded APK contents.

```bash
apktool d {{APK:file:app.apk}} -o {{OUTDIR:dir:./decoded}}
```

<!-- meta: risk=safe | phase=recon | tags=decompile,output -->

---

## Decompile Without Decoding Resources
Keep the binary resources intact (faster, useful when only reading code).

```bash
apktool d {{APK:file:app.apk}} --no-res
```

<!-- meta: risk=safe | phase=recon | tags=decompile,fast,no-res -->

---

## Force Decompile (Overwrite Existing)
Overwrite an existing decoded directory and ignore errors.

```bash
apktool d {{APK:file:app.apk}} --force
```

<!-- meta: risk=safe | phase=recon | tags=decompile,force -->

---

## Rebuild APK
Recompile a previously decoded APK directory.

```bash
apktool b {{DECODED_DIR:dir:./decoded}}
```

<!-- meta: risk=safe | phase=misc | tags=rebuild,build -->

---

## Rebuild to Specific Output APK
Rebuild and emit the APK to a chosen path.

```bash
apktool b {{DECODED_DIR:dir:./decoded}} -o {{OUTAPK:file:./new_app.apk}}
```

<!-- meta: risk=safe | phase=misc | tags=rebuild,output -->

---

## Install Framework Resource
Add a vendor framework (e.g., for Samsung/Xiaomi ROMs).

```bash
apktool if {{FRAMEWORK:file:framework-res.apk}}
```

<!-- meta: risk=safe | phase=misc | tags=framework,install,rom -->

---

## Decompile with Specific API Level
Decode using a target API level for version-sensitive resources.

```bash
apktool d {{APK:file:app.apk}} --api-level {{API:int:28}}
```

<!-- meta: risk=safe | phase=recon | tags=decompile,api-level -->

---

## Rebuild with AAPT2
Use AAPT2 during the rebuild for newer Android resource handling.

```bash
apktool b {{DECODED_DIR:dir:./decoded}} --use-aapt2
```

<!-- meta: risk=safe | phase=misc | tags=rebuild,aapt2 -->

---

## Empty Framework Directory
Clear all installed frameworks.

```bash
apktool empty-framework-dir
```

<!-- meta: risk=safe | phase=misc | tags=cleanup,framework -->
