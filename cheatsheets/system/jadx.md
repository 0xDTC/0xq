# Jadx

> Dex to Java decompiler for Android APK and JAR analysis

<!-- tags: jadx,android,decompile,reverse -->

---

## Decompile APK
Decompile an APK file to Java sources.

```bash
jadx {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=apk,decompile -->

---

## Decompile JAR
Decompile a JAR file.

```bash
jadx {{INFILE:file:app.jar}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=jar -->

---

## GUI Mode
Interactive GUI for code browsing.

```bash
jadx-gui {{INFILE:file:app.apk}}
```

<!-- meta: risk=safe | phase=misc | tags=gui -->

---

## Multi-Threaded Decompile
Speed up with N threads.

```bash
jadx -j {{THREADS:int:4}} {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=threads,fast -->

---

## Skip Resources
Decompile only code, skip resources.

```bash
jadx --no-res {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=no-res -->

---

## No Deobfuscation (Raw Code)
Disable auto-deobfuscation for raw decompiled code.

```bash
jadx --no-deobf {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=raw -->

---

## Filter Class
Only decompile a specific class.

```bash
jadx --class-filter={{CLASS:str:com.example.Foo}} {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=filter,class -->

---

## Increase Memory for Large APKs
Use a larger heap for big apps.

```bash
jadx --max-memory-size={{MEM:str:4G}} {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=memory -->
