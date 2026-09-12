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
wevtutil gl "{{LOGNAME:choice:Security=security audit log,System=system events,Application=application events,Setup=setup/install events,Microsoft-Windows-PowerShell/Operational=PS script blocks,Microsoft-Windows-Sysmon/Operational=Sysmon telemetry,Microsoft-Windows-TaskScheduler/Operational=scheduled task events,ForwardedEvents=WEF collector target}}"
```

<!-- meta: risk=low | phase=enum | tags=wevtutil,config,retention -->

---

## query events wevtutil
Query the most recent events from a log in reverse order as readable text.

```bash
wevtutil qe {{LOGNAME:choice:Security=security audit log,System=system events,Application=application events,Setup=setup/install events,Microsoft-Windows-PowerShell/Operational=PS script blocks,Microsoft-Windows-Sysmon/Operational=Sysmon telemetry,Microsoft-Windows-TaskScheduler/Operational=scheduled task events,ForwardedEvents=WEF collector target}} /c:{{COUNT:int:5}} /rd:true /f:text
```

<!-- meta: risk=low | phase=enum | tags=wevtutil,query,events -->

---

## export log wevtutil
Export a complete event log to an .evtx file for offline analysis.

```bash
wevtutil epl {{LOGNAME:choice:Security=security audit log,System=system events,Application=application events,Setup=setup/install events,Microsoft-Windows-PowerShell/Operational=PS script blocks,Microsoft-Windows-Sysmon/Operational=Sysmon telemetry,Microsoft-Windows-TaskScheduler/Operational=scheduled task events,ForwardedEvents=WEF collector target}} {{OUTFILE:file:C:\Windows\Temp\export.evtx}}
```

<!-- meta: risk=low | phase=post | tags=wevtutil,export,evtx -->

---

## clear event log wevtutil
Clear all entries from a log to destroy audit trails (anti-forensics).

```bash
wevtutil cl {{LOGNAME:choice:Security=security audit log,System=system events,Application=application events,Setup=setup/install events,Microsoft-Windows-PowerShell/Operational=PS script blocks,Microsoft-Windows-Sysmon/Operational=Sysmon telemetry,Microsoft-Windows-TaskScheduler/Operational=scheduled task events,ForwardedEvents=WEF collector target}}
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
Get-WinEvent -LogName '{{LOGNAME:choice:Security=security audit log,System=system events,Application=application events,Setup=setup/install events,Microsoft-Windows-PowerShell/Operational=PS script blocks,Microsoft-Windows-Sysmon/Operational=Sysmon telemetry,Microsoft-Windows-TaskScheduler/Operational=scheduled task events,ForwardedEvents=WEF collector target}}' -MaxEvents {{COUNT:int:5}} | Select-Object -ExpandProperty Message
```

<!-- meta: risk=low | phase=enum | tags=powershell,getwinevent,messages -->

---

## query failed logons eventid
Filter the Security log for failed logon events by event ID 4625.

```bash
Get-WinEvent -FilterHashTable @{LogName='Security';ID='{{EVENTID:choice:4625=logon failure,4624=logon success,4634=logoff,4648=explicit-cred logon,4672=admin privs granted,4688=process create,4697=service installed,4720=account created,4732=added to sec group,5140=share accessed,5145=share access check,7045=new service (System),1102=audit log cleared,4104=PS script block}}'}
```

<!-- meta: risk=low | phase=enum | tags=powershell,logon,4625 -->

---

## query successful logons eventid
Filter the Security log for successful logon events by event ID 4624.

```bash
Get-WinEvent -FilterHashTable @{LogName='Security';ID='{{EVENTID:choice:4624=logon success,4625=logon failure,4634=logoff,4648=explicit-cred logon,4672=admin privs granted,4688=process create,4697=service installed,4720=account created,4732=added to sec group,5140=share accessed,5145=share access check,7045=new service (System),1102=audit log cleared,4104=PS script block}}'}
```

<!-- meta: risk=low | phase=enum | tags=powershell,logon,4624 -->

---
