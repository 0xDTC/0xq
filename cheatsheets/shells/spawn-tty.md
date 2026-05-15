# Spawn / Stabilize TTY

> Upgrade a dumb reverse shell to a full interactive PTY

<!-- tags: tty, pty, shell, upgrade, stabilize -->

---

## Set TERM to xterm
Make the remote shell render colors and clear screen properly.

```bash
export TERM=xterm
```

<!-- meta: risk=safe | phase=post | tags=term,xterm,environment -->

---

## Stty Raw + Foreground (Local)
Disable echo locally and bring the backgrounded shell back. Run after Ctrl+Z.

```bash
stty raw -echo && fg
```

<!-- meta: risk=safe | phase=post | tags=stty,raw,fg -->

---

## Python3 PTY Spawn
Spawn /bin/bash via Python's pty module on the target.

```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'
```

<!-- meta: risk=safe | phase=post | tags=python,pty,spawn -->

---

## Python2 PTY Spawn
Same upgrade using Python 2 when 3 is unavailable.

```bash
python -c 'import pty;pty.spawn("/bin/bash")'
```

<!-- meta: risk=safe | phase=post | tags=python2,pty,spawn -->

---

## Perl PTY Spawn
Drop into bash via Perl's exec.

```bash
perl -e 'exec "/bin/bash";'
```

<!-- meta: risk=safe | phase=post | tags=perl,exec,bash -->

---

## Ruby PTY Spawn
Drop into bash via Ruby's exec.

```bash
ruby -e 'exec "/bin/bash"'
```

<!-- meta: risk=safe | phase=post | tags=ruby,exec,bash -->

---

## Lua os.execute Spawn
Spawn /bin/sh via Lua interpreters.

```bash
lua -e 'os.execute("/bin/sh")'
```

<!-- meta: risk=safe | phase=post | tags=lua,osexecute,shell -->

---

## Vi/Vim Shell Escape
Escape into a shell from inside vi/vim.

```bash
vi -c ':!bash'
```

<!-- meta: risk=safe | phase=post | tags=vi,escape,shell -->

---

## Script Trick (util-linux)
Drop the dumb shell into `script` to allocate a real PTY.

```bash
script -qc /bin/bash /dev/null
```

<!-- meta: risk=safe | phase=post | tags=script,pty,util-linux -->

---

## Set Window Size After Upgrade
After stty raw, set rows and cols to match local terminal.

```bash
stty rows {{ROWS:int:40}} cols {{COLS:int:160}}
```

<!-- meta: risk=safe | phase=post | tags=stty,rows,cols -->
