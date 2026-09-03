# Linux Kernel Crash Dump Analysis (kdump + crash)

> Analyze Linux kernel crash dumps (`.kdump`, vmcore) with the `crash` utility. Handles panic root-cause, loaded modules, running processes, network sockets, filesystem state at the moment of panic. Needs the matching kernel's debug-info vmlinux (dbgsym).

<!-- tags: dfir,linux,kernel,crash,kdump,makedumpfile,vmcore,rootkit -->

## identify kdump file
Check the format and target kernel version (matches which vmlinux-dbgsym to use).

```bash
file {{DUMP:file:./vmcore.kdump}}
```

<!-- meta: risk=safe | phase=dfir | tags=kdump,identify -->

---

## makedumpfile convert flattened kdump to vmcore
`crash` needs an ELF vmcore. Flattened kdump v4+ must be converted first.

```bash
makedumpfile -R {{OUT:file:./vmcore}} < {{DUMP:file:./vmcore.kdump}}
```

<!-- meta: risk=safe | phase=dfir | tags=makedumpfile,convert -->

---

## crash: open dump with symbols
Point `crash` at both the vmlinux with debug info and the vmcore. Symbol path (-s) is the folder containing kernel symbol files.

```bash
crash {{VMLINUX:file:./vmlinux-dbgsym}} {{VMCORE:file:./vmcore}}
```

<!-- meta: risk=safe | phase=dfir | tags=crash,open,gdb -->

---

## crash single command mode
Run one command and exit (scriptable / non-interactive).

```bash
echo "{{CMD:str:sys}}" | crash {{VMLINUX:file:./vmlinux-dbgsym}} {{VMCORE:file:./vmcore}}
```

<!-- meta: risk=safe | phase=dfir | tags=crash,batch -->

---

## crash: sys - system info + panic reason
Kernel version, node name, uptime, CPU count, memory, PANIC line, and panic task (PID + COMMAND).

```bash
echo -e "sys\nquit" | crash {{VMLINUX:file:./vmlinux-dbgsym}} {{VMCORE:file:./vmcore}}
```

<!-- meta: risk=safe | phase=dfir | tags=crash,sys,panic -->

---

## crash: bt - backtrace of the panic task
Full call stack at the moment of panic. Top frame after the exception is where the crash happened.

```bash
echo -e "bt\nquit" | crash {{VMLINUX:file:./vmlinux-dbgsym}} {{VMCORE:file:./vmcore}}
```

<!-- meta: risk=safe | phase=dfir | tags=crash,bt,backtrace -->

---

## crash: log - kernel dmesg buffer
Full dmesg at time of dump. Contains the actual BUG/Oops lines with call trace + loaded modules.

```bash
echo -e "log\nquit" | crash {{VMLINUX:file:./vmlinux-dbgsym}} {{VMCORE:file:./vmcore}}
```

<!-- meta: risk=safe | phase=dfir | tags=crash,dmesg,log -->

---

## crash: ps - running processes
Every task with PID, PPID, state, COMMAND, TASK address. Panic task marked with >.

```bash
echo -e "ps\nquit" | crash {{VMLINUX:file:./vmlinux-dbgsym}} {{VMCORE:file:./vmcore}}
```

<!-- meta: risk=safe | phase=dfir | tags=crash,ps,process -->

---

## crash: mod - loaded modules
Base address, size, and name of every loaded kernel module. Attacker's LKM rootkit lives here (compare against a known-good baseline).

```bash
echo -e "mod\nquit" | crash {{VMLINUX:file:./vmlinux-dbgsym}} {{VMCORE:file:./vmcore}}
```

<!-- meta: risk=safe | phase=dfir | tags=crash,mod,rootkit -->

---

## crash: sym -m module - dump one module's symbols
Function names and addresses inside a specific module. Great for identifying the entry/exit points of a rootkit.

```bash
echo -e "sym -m {{MOD:str:core_helper}}\nquit" | crash {{VMLINUX:file:./vmlinux-dbgsym}} {{VMCORE:file:./vmcore}}
```

<!-- meta: risk=safe | phase=dfir | tags=crash,sym,module -->

---

## crash: net - network interfaces
Every net_device with assigned IPv4/IPv6 (and ARP cache with -a).

```bash
echo -e "net -a\nquit" | crash {{VMLINUX:file:./vmlinux-dbgsym}} {{VMCORE:file:./vmcore}}
```

<!-- meta: risk=safe | phase=dfir | tags=crash,net,interfaces -->

---

## crash: files PID - open file descriptors
List every FD held by a specific process (path, dentry, inode).

```bash
echo -e "files {{PID:int:9236}}\nquit" | crash {{VMLINUX:file:./vmlinux-dbgsym}} {{VMCORE:file:./vmcore}}
```

<!-- meta: risk=safe | phase=dfir | tags=crash,files,fd -->

---

## install crash + makedumpfile without root
Grab the .deb from apt archives, unpack locally, run from the extracted tree.

```bash
apt-get download crash makedumpfile
for d in *.deb; do dpkg -x "$d" {{DEST:path:./ext}}; done
{{DEST:path:./ext}}/usr/bin/makedumpfile -R vmcore < {{DUMP:file:./vmcore.kdump}}
{{DEST:path:./ext}}/usr/bin/crash {{VMLINUX:file:./vmlinux-dbgsym}} vmcore
```

<!-- meta: risk=safe | phase=util | tags=crash,install,no-root -->
