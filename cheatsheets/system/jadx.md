# Jadx

> Dex to Java decompiler for Android APK and JAR analysis

<!-- tags: jadx,android,decompile,reverse -->

---

## decompile apk to java
Decompile an APK file to Java sources.

```bash
jadx {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=apk,decompile -->

---

## decompile jar to java
Decompile a JAR file.

```bash
jadx {{INFILE:file:app.jar}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=jar -->

---

## gui code browser
Interactive GUI for code browsing.

```bash
jadx-gui {{INFILE:file:app.apk}}
```

<!-- meta: risk=safe | phase=misc | tags=gui -->

---

## multi-threaded decompile fast
Speed up with N threads.

```bash
jadx -j {{THREADS:int:4}} {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=threads,fast -->

---

## decompile skip resources
Decompile only code, skip resources.

```bash
jadx --no-res {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=no-res -->

---

## decompile raw no deobfuscation
Disable auto-deobfuscation for raw decompiled code.

```bash
jadx --no-deobf {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=raw -->

---

## decompile single class filter
Only decompile a specific class.

```bash
jadx --class-filter={{CLASS:str:com.example.Foo}} {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=filter,class -->

---

## increase heap memory large apk
Use a larger heap for big apps.

```bash
jadx --max-memory-size={{MEM:str:4G}} {{INFILE:file:app.apk}} -d {{OUTDIR:dir:./out}}
```

<!-- meta: risk=safe | phase=misc | tags=memory -->
