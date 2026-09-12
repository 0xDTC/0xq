# Windows Event Log

> Enumerate, query, export, and clear Windows event logs with wevtutil and Get-WinEvent

<!-- tags: windows,eventlog,wevtutil,powershell,forensics -->
<!-- platform: windows -->

---

## list log sources wevtutil
Enumerate the names of all available event log sources on the host.

```bash
wevtutil el
```

<!-- meta: risk=low | phase=enum | tags=wevtutil,logs,sources -->

---

## show log config wevtutil
Display configuration info (path, retention, max size) for a named log.

```bash
wevtutil gl "{{LOGNAME:choice:Security,System,Application,Setup,Microsoft-Windows-PowerShell/Operational,Microsoft-Windows-Sysmon/Operational,Microsoft-Windows-TaskScheduler/Operational,ForwardedEvents}}"
```

<!-- meta: risk=low | phase=enum | tags=wevtutil,config,retention -->

---

## query events wevtutil
Query the most recent events from a log in reverse order as readable text.

```bash
wevtutil qe {{LOGNAME:choice:Security,System,Application,Setup,Microsoft-Windows-PowerShell/Operational,Microsoft-Windows-Sysmon/Operational,Microsoft-Windows-TaskScheduler/Operational,ForwardedEvents}} /c:{{COUNT:int:5}} /rd:true /f:text
```

<!-- meta: risk=low | phase=enum | tags=wevtutil,query,events -->

---

## export log wevtutil
Export a complete event log to an .evtx file for offline analysis.

```bash
wevtutil epl {{LOGNAME:choice:Security,System,Application,Setup,Microsoft-Windows-PowerShell/Operational,Microsoft-Windows-Sysmon/Operational,Microsoft-Windows-TaskScheduler/Operational,ForwardedEvents}} {{OUTFILE:file:C:\Windows\Temp\export.evtx}}
```

<!-- meta: risk=low | phase=post | tags=wevtutil,export,evtx -->

---

## clear event log wevtutil
Clear all entries from a log to destroy audit trails (anti-forensics).

```bash
wevtutil cl {{LOGNAME:choice:Security,System,Application,Setup,Microsoft-Windows-PowerShell/Operational,Microsoft-Windows-Sysmon/Operational,Microsoft-Windows-TaskScheduler/Operational,ForwardedEvents}}
```

<!-- meta: risk=high | phase=post | tags=wevtutil,clear,antiforensics -->

---

## list logs powershell
List all event logging facilities and their record counts via PowerShell.

```bash
Get-WinEvent -ListLog *
```

<!-- meta: risk=low | phase=enum | tags=powershell,getwinevent,logs -->

---

## read log messages powershell
Read the message body of the most recent events from a named log.

```bash
Get-WinEvent -LogName '{{LOGNAME:choice:Security,System,Application,Setup,Microsoft-Windows-PowerShell/Operational,Microsoft-Windows-Sysmon/Operational,Microsoft-Windows-TaskScheduler/Operational,ForwardedEvents}}' -MaxEvents {{COUNT:int:5}} | Select-Object -ExpandProperty Message
```

<!-- meta: risk=low | phase=enum | tags=powershell,getwinevent,messages -->

---

## query failed logons eventid
Filter the Security log for failed logon events by event ID 4625.

```bash
Get-WinEvent -FilterHashTable @{LogName='Security';ID='{{EVENTID:choice:4625,4624,4634,4648,4672,4688,4697,4720,4732,5140,5145,7045,1102,4104}}'}
```

<!-- meta: risk=low | phase=enum | tags=powershell,logon,4625 -->

---

## query successful logons eventid
Filter the Security log for successful logon events by event ID 4624.

```bash
Get-WinEvent -FilterHashTable @{LogName='Security';ID='{{EVENTID:choice:4624,4625,4634,4648,4672,4688,4697,4720,4732,5140,5145,7045,1102,4104}}'}
```

<!-- meta: risk=low | phase=enum | tags=powershell,logon,4624 -->

---
