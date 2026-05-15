# ADB - Android Debug Bridge

> Interact with Android devices and emulators for installation, debugging, and forensic capture

<!-- tags: adb, android, mobile, debug, forensics -->

---

## List Connected Devices
Show all attached Android devices/emulators and their state.

```bash
adb devices -l
```

<!-- meta: risk=safe | phase=recon | tags=devices,list -->

---

## Get Shell on Device
Open an interactive shell on the target Android device.

```bash
adb shell
```

<!-- meta: risk=safe | phase=enum | tags=shell,interactive -->

---

## Install APK
Push and install an APK onto the device.

```bash
adb install {{APK:file:app.apk}}
```

<!-- meta: risk=med | phase=exploit | tags=install,apk -->

---

## Pull File from Device
Copy a file off the device to the local filesystem.

```bash
adb pull {{REMOTE:str:/sdcard/Download/file.txt}} {{LOCAL:dir:./}}
```

<!-- meta: risk=safe | phase=enum | tags=pull,exfil,file -->

---

## Push File to Device
Copy a local file onto the device.

```bash
adb push {{LOCAL:file:./payload.apk}} {{REMOTE:str:/sdcard/Download/}}
```

<!-- meta: risk=low | phase=exploit | tags=push,upload -->

---

## Watch Audio/Media Recorder Activity (logcat)
Filter logcat for media recorder activity (e.g., live mic/camera triggers).

```bash
adb logcat | grep -i "AudioRecord\|MediaRecorder"
```

<!-- meta: risk=safe | phase=enum | tags=logcat,audio,recorder -->

---

## List Installed Packages
Enumerate all installed packages on the device.

```bash
adb shell pm list packages -f
```

<!-- meta: risk=safe | phase=enum | tags=packages,pm,list -->

---

## Get APK Path of a Package
Find the APK path for a specific package (e.g., for pulling).

```bash
adb shell pm path {{PACKAGE:str:com.example.app}}
```

<!-- meta: risk=safe | phase=enum | tags=pm,path,package -->
