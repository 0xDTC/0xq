# Cron

> Schedule recurring tasks via crontab on Linux/Unix systems

<!-- tags: cron, crontab, schedule, automation, system -->

---

## edit current user crontab
Open the current user's crontab in $EDITOR for editing.

```bash
crontab -e
```

<!-- meta: risk=safe | phase=misc | tags=edit,crontab -->

---

## list current user jobs
Show the current user's scheduled jobs.

```bash
crontab -l
```

<!-- meta: risk=safe | phase=enum | tags=list,jobs -->

---

## list another user crontab root
View another user's crontab (requires root).

```bash
sudo crontab -u {{USER:str}} -l
```

<!-- meta: risk=safe | phase=enum | tags=root,user,crontab -->

---

## list system jobs crontab
Inspect system-wide cron files for scheduled tasks.

```bash
ls -la /etc/cron.* /etc/crontab && cat /etc/crontab
```

<!-- meta: risk=safe | phase=enum | tags=system,cron.d,crontab -->

---

## find writable scripts privesc
Hunt for scripts called by cron that any user can modify.

```bash
find /etc/cron* /var/spool/cron 2>/dev/null -type f -perm -o+w -ls
```

<!-- meta: risk=low | phase=post | tags=privesc,writable,cron -->

---

## add job persistence crontab
Append a job to the current user's crontab without overwriting existing entries.

```bash
( crontab -l 2>/dev/null; echo "{{SCHEDULE:str:*/5 * * * *}} {{COMMAND:str:/path/to/script.sh}}" ) | crontab -
```

<!-- meta: risk=med | phase=post | tags=add,job,persistence -->

---

## tail log syslog
Follow the cron daemon log for execution debugging.

```bash
sudo tail -f /var/log/syslog | grep -i cron
```

<!-- meta: risk=safe | phase=enum | tags=log,debug,syslog -->
