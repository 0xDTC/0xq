# systemctl / Services

> Manage systemd services, units, and view system logs with journalctl

<!-- tags: systemctl, systemd, service, journalctl, logs -->
<!-- platform: linux -->

---

## start service
Start a stopped service immediately.

```bash
sudo systemctl start {{SERVICE:choice:apache2,nginx,sshd,ssh,mysql,postgresql,docker,cron,NetworkManager,systemd-resolved,firewalld}}
```

<!-- meta: risk=low | phase=misc | tags=start,service -->

---

## stop service
Stop a running service immediately.

```bash
sudo systemctl stop {{SERVICE:choice:apache2,nginx,sshd,ssh,mysql,postgresql,docker,cron,NetworkManager,systemd-resolved,firewalld}}
```

<!-- meta: risk=low | phase=misc | tags=stop,service -->

---

## restart service
Restart a service (stop then start).

```bash
sudo systemctl restart {{SERVICE:choice:apache2,nginx,sshd,ssh,mysql,postgresql,docker,cron,NetworkManager,systemd-resolved,firewalld}}
```

<!-- meta: risk=low | phase=misc | tags=restart,service -->

---

## enable service at boot
Enable a service to start automatically on boot.

```bash
sudo systemctl enable {{SERVICE:choice:ssh,sshd,apache2,nginx,mysql,postgresql,docker,cron,NetworkManager,systemd-resolved,firewalld}}
```

<!-- meta: risk=low | phase=misc | tags=enable,boot,autostart -->

---

## disable service at boot
Disable a service from starting on boot.

```bash
sudo systemctl disable {{SERVICE:choice:apache2,nginx,sshd,ssh,mysql,postgresql,docker,cron,NetworkManager,systemd-resolved,firewalld}}
```

<!-- meta: risk=low | phase=misc | tags=disable,boot -->

---

## check service status
Check the current status and recent logs of a service.

```bash
systemctl status {{SERVICE:choice:ssh,sshd,apache2,nginx,mysql,postgresql,docker,cron,NetworkManager,systemd-resolved,firewalld}}
```

<!-- meta: risk=safe | phase=misc | tags=status,check,health -->

---

## list active units
List all active systemd units.

```bash
systemctl list-units --type=service --state=running
```

<!-- meta: risk=safe | phase=misc | tags=list,units,running -->

---

## list failed services
Show all services that failed to start.

```bash
systemctl --failed
```

<!-- meta: risk=safe | phase=misc | tags=failed,errors,debug -->

---

## follow service logs journalctl
Follow real-time logs for a specific service.

```bash
sudo journalctl -u {{SERVICE:choice:ssh,sshd,apache2,nginx,mysql,postgresql,docker,cron,NetworkManager,systemd-resolved,firewalld}} -f
```

<!-- meta: risk=safe | phase=misc | tags=journalctl,follow,realtime,logs -->

---

## view logs since time journalctl
View logs since a specific time or date.

```bash
sudo journalctl -u {{SERVICE:choice:ssh,sshd,apache2,nginx,mysql,postgresql,docker,cron,NetworkManager,systemd-resolved,firewalld}} --since "{{SINCE:choice:1 hour ago,today,yesterday,1 day ago,1 week ago,boot}}" --no-pager
```

<!-- meta: risk=safe | phase=misc | tags=journalctl,since,time,filter -->

---

## filter logs by priority journalctl
View logs filtered by priority level (0=emerg through 7=debug).

```bash
sudo journalctl -p {{PRIORITY:choice:err,warning,info,debug,notice,crit,alert,emerg}} --no-pager -n {{LINES:int:50}}
```

<!-- meta: risk=safe | phase=misc | tags=journalctl,priority,severity -->
