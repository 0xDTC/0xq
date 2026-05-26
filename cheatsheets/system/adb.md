# ADB - Android Debug Bridge

> Interact with Android devices and emulators for installation, debugging, and forensic capture

<!-- tags: adb, android, mobile, debug, forensics -->

---

## list connected devices android
Show all attached Android devices/emulators and their state.

```bash
adb devices -l
```

<!-- meta: risk=safe | phase=recon | tags=devices,list -->

---

## shell on android device
Open an interactive shell on the target Android device.

```bash
adb shell
```

<!-- meta: risk=safe | phase=enum | tags=shell,interactive -->

---

## install apk android
Push and install an APK onto the device.

```bash
adb install {{APK:file:app.apk}}
```

<!-- meta: risk=med | phase=exploit | tags=install,apk -->

---

## pull file from android device
Copy a file off the device to the local filesystem.

```bash
adb pull {{REMOTE:str:/sdcard/Download/file.txt}} {{LOCAL:dir:./}}
```

<!-- meta: risk=safe | phase=enum | tags=pull,exfil,file -->

---

## push file to android device
Copy a local file onto the device.

```bash
adb push {{LOCAL:file:./payload.apk}} {{REMOTE:str:/sdcard/Download/}}
```

<!-- meta: risk=low | phase=exploit | tags=push,upload -->

---

## watch media recorder logcat
Filter logcat for media recorder activity (e.g., live mic/camera triggers).

```bash
adb logcat | grep -i "AudioRecord\|MediaRecorder"
```

<!-- meta: risk=safe | phase=enum | tags=logcat,audio,recorder -->

---

## list installed packages android
Enumerate all installed packages on the device.

```bash
adb shell pm list packages -f
```

<!-- meta: risk=safe | phase=enum | tags=packages,pm,list -->

---

## find apk path package
Find the APK path for a specific package (e.g., for pulling).

```bash
adb shell pm path {{PACKAGE:str:com.example.app}}
```

<!-- meta: risk=safe | phase=enum | tags=pm,path,package -->
