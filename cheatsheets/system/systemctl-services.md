# systemctl / Services

> Manage systemd services, units, and view system logs with journalctl

<!-- tags: systemctl, systemd, service, journalctl, logs -->
<!-- platform: linux -->

---

## start service
Start a stopped service immediately.

```bash
sudo systemctl start {{SERVICE:choice:apache2=Apache web server,nginx=Nginx web server,sshd=OpenSSH daemon,ssh=OpenSSH (Debian alias),mysql=MySQL DB,postgresql=PostgreSQL DB,docker=Docker daemon,cron=cron scheduler,NetworkManager=network manager,systemd-resolved=DNS resolver,firewalld=firewall daemon}}
```

<!-- meta: risk=low | phase=misc | tags=start,service -->

---

## stop service
Stop a running service immediately.

```bash
sudo systemctl stop {{SERVICE:choice:apache2=Apache web server,nginx=Nginx web server,sshd=OpenSSH daemon,ssh=OpenSSH (Debian alias),mysql=MySQL DB,postgresql=PostgreSQL DB,docker=Docker daemon,cron=cron scheduler,NetworkManager=network manager,systemd-resolved=DNS resolver,firewalld=firewall daemon}}
```

<!-- meta: risk=low | phase=misc | tags=stop,service -->

---

## restart service
Restart a service (stop then start).

```bash
sudo systemctl restart {{SERVICE:choice:apache2=Apache web server,nginx=Nginx web server,sshd=OpenSSH daemon,ssh=OpenSSH (Debian alias),mysql=MySQL DB,postgresql=PostgreSQL DB,docker=Docker daemon,cron=cron scheduler,NetworkManager=network manager,systemd-resolved=DNS resolver,firewalld=firewall daemon}}
```

<!-- meta: risk=low | phase=misc | tags=restart,service -->

---

## enable service at boot
Enable a service to start automatically on boot.

```bash
sudo systemctl enable {{SERVICE:choice:ssh=OpenSSH (Debian alias),sshd=OpenSSH daemon,apache2=Apache web server,nginx=Nginx web server,mysql=MySQL DB,postgresql=PostgreSQL DB,docker=Docker daemon,cron=cron scheduler,NetworkManager=network manager,systemd-resolved=DNS resolver,firewalld=firewall daemon}}
```

<!-- meta: risk=low | phase=misc | tags=enable,boot,autostart -->

---

## disable service at boot
Disable a service from starting on boot.

```bash
sudo systemctl disable {{SERVICE:choice:apache2=Apache web server,nginx=Nginx web server,sshd=OpenSSH daemon,ssh=OpenSSH (Debian alias),mysql=MySQL DB,postgresql=PostgreSQL DB,docker=Docker daemon,cron=cron scheduler,NetworkManager=network manager,systemd-resolved=DNS resolver,firewalld=firewall daemon}}
```

<!-- meta: risk=low | phase=misc | tags=disable,boot -->

---

## check service status
Check the current status and recent logs of a service.

```bash
systemctl status {{SERVICE:choice:ssh=OpenSSH (Debian alias),sshd=OpenSSH daemon,apache2=Apache web server,nginx=Nginx web server,mysql=MySQL DB,postgresql=PostgreSQL DB,docker=Docker daemon,cron=cron scheduler,NetworkManager=network manager,systemd-resolved=DNS resolver,firewalld=firewall daemon}}
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
sudo journalctl -u {{SERVICE:choice:ssh=OpenSSH (Debian alias),sshd=OpenSSH daemon,apache2=Apache web server,nginx=Nginx web server,mysql=MySQL DB,postgresql=PostgreSQL DB,docker=Docker daemon,cron=cron scheduler,NetworkManager=network manager,systemd-resolved=DNS resolver,firewalld=firewall daemon}} -f
```

<!-- meta: risk=safe | phase=misc | tags=journalctl,follow,realtime,logs -->

---

## view logs since time journalctl
View logs since a specific time or date.

```bash
sudo journalctl -u {{SERVICE:choice:ssh=OpenSSH (Debian alias),sshd=OpenSSH daemon,apache2=Apache web server,nginx=Nginx web server,mysql=MySQL DB,postgresql=PostgreSQL DB,docker=Docker daemon,cron=cron scheduler,NetworkManager=network manager,systemd-resolved=DNS resolver,firewalld=firewall daemon}} --since "{{SINCE:choice:1 hour ago=last hour,today=since midnight,yesterday=previous calendar day,1 day ago=last 24h,1 week ago=last 7d,boot=since last boot}}" --no-pager
```

<!-- meta: risk=safe | phase=misc | tags=journalctl,since,time,filter -->

---

## filter logs by priority journalctl
View logs filtered by priority level (0=emerg through 7=debug).

```bash
sudo journalctl -p {{PRIORITY:choice:err=error (3),warning=warn (4),info=info (6),debug=debug (7),notice=notice (5),crit=critical (2),alert=alert (1),emerg=emergency (0)}} --no-pager -n {{LINES:int:50}}
```

<!-- meta: risk=safe | phase=misc | tags=journalctl,priority,severity -->
