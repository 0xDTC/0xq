# systemctl / Services

> Manage systemd services, units, and view system logs with journalctl

<!-- tags: systemctl, systemd, service, journalctl, logs -->

---

## Start a Service
Start a stopped service immediately.

```bash
sudo systemctl start {{SERVICE:str:apache2}}
```

<!-- meta: risk=low | phase=misc | tags=start,service -->

---

## Stop a Service
Stop a running service immediately.

```bash
sudo systemctl stop {{SERVICE:str:apache2}}
```

<!-- meta: risk=low | phase=misc | tags=stop,service -->

---

## Restart a Service
Restart a service (stop then start).

```bash
sudo systemctl restart {{SERVICE:str:apache2}}
```

<!-- meta: risk=low | phase=misc | tags=restart,service -->

---

## Enable at Boot
Enable a service to start automatically on boot.

```bash
sudo systemctl enable {{SERVICE:str:ssh}}
```

<!-- meta: risk=low | phase=misc | tags=enable,boot,autostart -->

---

## Disable at Boot
Disable a service from starting on boot.

```bash
sudo systemctl disable {{SERVICE:str:apache2}}
```

<!-- meta: risk=low | phase=misc | tags=disable,boot -->

---

## Service Status
Check the current status and recent logs of a service.

```bash
systemctl status {{SERVICE:str:ssh}}
```

<!-- meta: risk=safe | phase=misc | tags=status,check,health -->

---

## List All Active Units
List all active systemd units.

```bash
systemctl list-units --type=service --state=running
```

<!-- meta: risk=safe | phase=misc | tags=list,units,running -->

---

## List Failed Services
Show all services that failed to start.

```bash
systemctl --failed
```

<!-- meta: risk=safe | phase=misc | tags=failed,errors,debug -->

---

## Journalctl Follow Logs
Follow real-time logs for a specific service.

```bash
sudo journalctl -u {{SERVICE:str:ssh}} -f
```

<!-- meta: risk=safe | phase=misc | tags=journalctl,follow,realtime,logs -->

---

## Journalctl Since Time
View logs since a specific time or date.

```bash
sudo journalctl -u {{SERVICE:str:ssh}} --since "{{SINCE:str:1 hour ago}}" --no-pager
```

<!-- meta: risk=safe | phase=misc | tags=journalctl,since,time,filter -->

---

## Journalctl by Priority
View logs filtered by priority level (0=emerg through 7=debug).

```bash
sudo journalctl -p {{PRIORITY:str:err}} --no-pager -n {{LINES:int:50}}
```

<!-- meta: risk=safe | phase=misc | tags=journalctl,priority,severity -->
