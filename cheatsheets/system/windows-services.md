# Windows Services

> Enumerate and control Windows services and scheduled tasks via CMD and PowerShell

<!-- tags: windows,services,schtasks,powershell -->

---

## list services sc query
List all running services with their state via the Service Control manager.

```bash
sc query
```

<!-- meta: risk=low | phase=enum | tags=services,sc,cmd -->

---

## query service sc
Show configuration and current state for a single named service.

```bash
sc query {{SERVICE:str:Spooler}}
```

<!-- meta: risk=low | phase=enum | tags=services,sc,cmd -->

---

## start service sc
Start a service by name using the Service Control manager.

```bash
sc start {{SERVICE:str:Spooler}}
```

<!-- meta: risk=med | phase=post | tags=services,sc,start -->

---

## stop service sc
Stop a running service by name using the Service Control manager.

```bash
sc stop {{SERVICE:str:Spooler}}
```

<!-- meta: risk=med | phase=post | tags=services,sc,stop -->

---

## disable service sc config
Set a service start type to disabled so it will not launch at boot.

```bash
sc config {{SERVICE:str:Spooler}} start= disabled
```

<!-- meta: risk=med | phase=post | tags=services,sc,config,disable -->

---

## map services to processes tasklist
List running processes alongside the services hosted in each one.

```bash
tasklist /svc
```

<!-- meta: risk=low | phase=enum | tags=services,tasklist,pid -->

---

## list started services net start
Show the currently started services using the net command.

```bash
net start
```

<!-- meta: risk=low | phase=enum | tags=services,net,cmd -->

---

## list services wmic
Enumerate all services in brief form via WMI.

```bash
wmic service list brief
```

<!-- meta: risk=low | phase=enum | tags=services,wmic,enum -->

---

## list services powershell
List all services on the local host with PowerShell.

```bash
Get-Service
```

<!-- meta: risk=low | phase=enum | tags=services,powershell,enum -->

---

## list services table powershell
List services as a table of display name and status.

```bash
Get-Service | ft DisplayName,Status
```

<!-- meta: risk=low | phase=enum | tags=services,powershell,format -->

---

## find service by name powershell
Filter services whose display name matches a pattern and show name and status.

```bash
Get-Service | where DisplayName -like '*{{PATTERN:str:defender}}*' | ft DisplayName,ServiceName,Status
```

<!-- meta: risk=low | phase=enum | tags=services,powershell,filter -->

---

## start service powershell
Start a named service using PowerShell.

```bash
Start-Service {{SERVICE:str:Spooler}}
```

<!-- meta: risk=med | phase=post | tags=services,powershell,start -->

---

## stop service powershell
Stop a named service using PowerShell.

```bash
Stop-Service {{SERVICE:str:Spooler}}
```

<!-- meta: risk=med | phase=post | tags=services,powershell,stop -->

---

## disable service powershell
Set a service start type to disabled using PowerShell.

```bash
Set-Service -Name {{SERVICE:str:Spooler}} -StartType Disabled
```

<!-- meta: risk=med | phase=post | tags=services,powershell,disable -->

---

## remote list services powershell
List all services on a remote host via PowerShell.

```bash
Get-Service -ComputerName {{COMPUTER:str:DC01}}
```

<!-- meta: risk=low | phase=enum | tags=services,powershell,remote -->

---

## remote query services powershell
List only the running services on a remote host.

```bash
Get-Service -ComputerName {{COMPUTER:str:DC01}} | Where-Object {$_.Status -eq "Running"}
```

<!-- meta: risk=low | phase=enum | tags=services,powershell,remote -->

---

## remote check service invoke-command powershell
Query a specific service across remote hosts via PowerShell remoting.

```bash
Invoke-Command -ComputerName {{COMPUTER:str:DC01}} -ScriptBlock {Get-Service -Name 'windefend'}
```

<!-- meta: risk=med | phase=enum | tags=services,powershell,remote,invoke -->

---

## query scheduled tasks verbose
Dump all scheduled tasks in verbose list format.

```bash
schtasks /query /V /FO list
```

<!-- meta: risk=low | phase=enum | tags=schtasks,tasks,enum -->

---

## create scheduled task
Register a new scheduled task that runs a program on a given schedule.

```bash
schtasks /create /sc {{SCHEDULE:str:ONLOGON}} /tn {{TASK:str:Updater}} /tr {{PROGRAM:str:C:\Windows\Temp\payload.exe}}
```

<!-- meta: risk=med | phase=post | tags=schtasks,tasks,create -->

---

## change scheduled task user
Change the run-as user and password for an existing scheduled task.

```bash
schtasks /change /tn {{TASK:str:Updater}} /ru {{USERNAME:str}} /rp {{PASSWORD:str}}
```

<!-- meta: risk=med | phase=post | tags=schtasks,tasks,change -->

---

## delete scheduled task
Delete a scheduled task by name without prompting.

```bash
schtasks /delete /tn {{TASK:str:Updater}} /f
```

<!-- meta: risk=med | phase=post | tags=schtasks,tasks,delete -->
