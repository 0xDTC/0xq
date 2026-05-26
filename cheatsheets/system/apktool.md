# Apktool

> Decompile, modify, and rebuild Android APK files

<!-- tags: apktool, android, apk, mobile, reverse-engineering -->

---

## decompile apk smali
Decode an APK into smali, resources, and AndroidManifest.

```bash
apktool d {{APK:file:app.apk}}
```

<!-- meta: risk=safe | phase=recon | tags=decompile,apk,smali -->

---

## decompile apk output directory
Choose a custom output directory for the decoded APK contents.

```bash
apktool d {{APK:file:app.apk}} -o {{OUTDIR:dir:./decoded}}
```

<!-- meta: risk=safe | phase=recon | tags=decompile,output -->

---

## decompile apk skip resources
Keep the binary resources intact (faster, useful when only reading code).

```bash
apktool d {{APK:file:app.apk}} --no-res
```

<!-- meta: risk=safe | phase=recon | tags=decompile,fast,no-res -->

---

## force decompile apk overwrite
Overwrite an existing decoded directory and ignore errors.

```bash
apktool d {{APK:file:app.apk}} --force
```

<!-- meta: risk=safe | phase=recon | tags=decompile,force -->

---

## rebuild apk
Recompile a previously decoded APK directory.

```bash
apktool b {{DECODED_DIR:dir:./decoded}}
```

<!-- meta: risk=safe | phase=misc | tags=rebuild,build -->

---

## rebuild apk output path
Rebuild and emit the APK to a chosen path.

```bash
apktool b {{DECODED_DIR:dir:./decoded}} -o {{OUTAPK:file:./new_app.apk}}
```

<!-- meta: risk=safe | phase=misc | tags=rebuild,output -->

---

## install framework resource rom
Add a vendor framework (e.g., for Samsung/Xiaomi ROMs).

```bash
apktool if {{FRAMEWORK:file:framework-res.apk}}
```

<!-- meta: risk=safe | phase=misc | tags=framework,install,rom -->

---

## decompile apk api level
Decode using a target API level for version-sensitive resources.

```bash
apktool d {{APK:file:app.apk}} --api-level {{API:int:28}}
```

<!-- meta: risk=safe | phase=recon | tags=decompile,api-level -->

---

## rebuild apk aapt2
Use AAPT2 during the rebuild for newer Android resource handling.

```bash
apktool b {{DECODED_DIR:dir:./decoded}} --use-aapt2
```

<!-- meta: risk=safe | phase=misc | tags=rebuild,aapt2 -->

---

## clear framework directory
Clear all installed frameworks.

```bash
apktool empty-framework-dir
```

<!-- meta: risk=safe | phase=misc | tags=cleanup,framework -->
