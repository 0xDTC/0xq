# Process Management

> Inspect, control, and debug running processes and open files

<!-- tags: ps, kill, lsof, top, strace, pgrep, process, debug -->

---

## list all processes
Show all running processes with full details.

```bash
ps auxf
```

<!-- meta: risk=safe | phase=misc | tags=ps,list,processes,tree -->

---

## find process by name
Search for processes matching a pattern.

```bash
pgrep -af "{{PATTERN:str:python}}"
```

<!-- meta: risk=safe | phase=misc | tags=pgrep,search,find -->

---

## kill process by pid
Send a signal to a process by its PID.

```bash
kill -{{SIGNAL:int:9}} {{PID:int:1234}}
```

<!-- meta: risk=med | phase=misc | tags=kill,signal,terminate -->

---

## kill all by name
Kill all processes matching a name.

```bash
killall -{{SIGNAL:int:9}} {{NAME:str:python3}}
```

<!-- meta: risk=med | phase=misc | tags=killall,name,terminate -->

---

## snapshot top cpu usage
Capture a single snapshot of top processes sorted by CPU usage.

```bash
top -bn1 | head -n {{LINES:int:20}}
```

<!-- meta: risk=safe | phase=misc | tags=top,snapshot,cpu,memory -->

---

## find process by port
Find which process is listening on a specific port.

```bash
sudo lsof -i :{{PORT:port:80}}
```

<!-- meta: risk=safe | phase=misc | tags=lsof,port,listener -->

---

## list open files by pid
List all files opened by a specific process.

```bash
lsof -p {{PID:int:1234}}
```

<!-- meta: risk=safe | phase=misc | tags=lsof,pid,files,descriptors -->

---

## list open files by user
Show all files opened by a specific user.

```bash
lsof -u {{USER:str:www-data}}
```

<!-- meta: risk=safe | phase=misc | tags=lsof,user,files -->

---

## identify process using port
Identify and optionally kill the process using a specific port.

```bash
fuser -v {{PORT:port:80}}/tcp
```

<!-- meta: risk=safe | phase=misc | tags=fuser,port,identify -->

---

## run command in background nohup
Run a command that persists after logout with output logged.

```bash
nohup {{CMD:str:./long-running-script.sh}} > {{OUTFILE:file:nohup.out}} 2>&1 &
```

<!-- meta: risk=low | phase=misc | tags=nohup,background,persistent -->

---

## trace system calls strace
Trace system calls made by a running process.

```bash
sudo strace -f -p {{PID:int:1234}} -e {{CALLS:str:open,read,write}}
```

<!-- meta: risk=low | phase=misc | tags=strace,syscall,debug,trace -->

---

## trace library calls ltrace
Trace library function calls made by a process.

```bash
ltrace -p {{PID:int:1234}} -e {{FUNCS:str:malloc,free}}
```

<!-- meta: risk=low | phase=misc | tags=ltrace,library,debug,trace -->

---

## trace file syscalls strace
Filter strace output to file-related syscalls only.

```bash
sudo strace -f -e trace=file -p {{PID:int:1234}}
```

<!-- meta: risk=low | phase=misc | tags=strace,file,syscalls -->

---

## trace network syscalls strace
Trace network-related syscalls (connect, accept, recvfrom).

```bash
sudo strace -f -e trace=network -p {{PID:int:1234}}
```

<!-- meta: risk=low | phase=misc | tags=strace,network,syscalls -->

---

## summarize syscall stats strace
Print a summary of time, calls, and errors per syscall on exit.

```bash
strace -c -p {{PID:int:1234}}
```

<!-- meta: risk=low | phase=misc | tags=strace,summary,stats -->

---

## time syscalls strace
Show wall time spent inside each syscall.

```bash
strace -T -p {{PID:int:1234}}
```

<!-- meta: risk=low | phase=misc | tags=strace,timing,T -->

---

## trace program launch strace
Trace a program from start, logging to a file.

```bash
strace -f -o {{LOG:file:trace.log}} {{PROGRAM:str:./binary arg1}}
```

<!-- meta: risk=low | phase=misc | tags=strace,launch,log -->
