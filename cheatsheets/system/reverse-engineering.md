# Reverse Engineering
> Static and dynamic binary analysis tools for ELF/PE inspection and exploit dev
<!-- tags: reverse-engineering,binary,elf,gdb,exploit-dev -->

---

## identify binary type
Identify file type, architecture, and linking type.

```bash
file {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,file,identify -->

---

## check binary mitigations checksec
Show NX, PIE, RELRO, ASLR status with checksec.

```bash
checksec --file={{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,checksec,mitigations -->

---

## extract printable strings
Pull printable strings from binary (look for hardcoded creds/cmds).

```bash
strings {{BINARY:file:./target}} | less
```

<!-- meta: risk=safe | phase=recon | tags=re,strings -->

---

## filter strings by length
Strings of minimum length to reduce noise.

```bash
strings -n {{MIN_LEN:int:10}} {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,strings,filter -->

---

## inspect elf headers
Display ELF headers, sections, and symbols.

```bash
readelf -a {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,readelf,elf -->

---

## disassemble binary objdump
Disassemble binary into x86/x64 assembly.

```bash
objdump -d {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,objdump,disassemble -->

---

## disassemble specific function
Disassemble a single function (e.g. main).

```bash
objdump -d {{BINARY:file:./target}} | awk '/<{{FUNCTION:str:main}}>:/,/^$/'
```

<!-- meta: risk=safe | phase=recon | tags=re,objdump,function -->

---

## trace library calls ltrace
Monitor dynamic library function calls (printf, strcpy, etc).

```bash
ltrace ./{{BINARY:file:target}}
```

<!-- meta: risk=low | phase=recon | tags=re,ltrace,dynamic -->

---

## trace system calls strace
Track all syscalls made by the binary.

```bash
strace ./{{BINARY:file:target}}
```

<!-- meta: risk=low | phase=recon | tags=re,strace,syscalls -->

---

## filter syscalls strace
Filter strace output to specific syscalls.

```bash
strace -e {{SYSCALL:str:open,read,write}} ./{{BINARY:file:target}}
```

<!-- meta: risk=low | phase=recon | tags=re,strace,filter -->

---

## debug binary gdb
Open binary in GNU Debugger for dynamic analysis.

```bash
gdb {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,gdb,debug -->

---

## debug binary gef plugin
Launch GDB with enhanced exploit dev plugins.

```bash
gdb-gef {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,gdb,gef,peda -->

---

## find ROP gadgets
Search binary for usable ROP gadgets.

```bash
ROPgadget --binary {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,ropgadget,rop -->

---

## filter ROP gadgets by pattern
Search for specific gadget pattern (e.g. pop rdi).

```bash
ROPgadget --binary {{BINARY:file:./target}} --only "pop|ret"
```

<!-- meta: risk=safe | phase=exploit | tags=re,ropgadget,filter -->

---

## find one_gadget libc offsets
Find one_gadget shell-spawning offsets in libc.

```bash
one_gadget {{LIBC:file:./libc.so.6}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,one_gadget,libc -->

---

## analyze binary radare2
Open binary in radare2 for static/dynamic analysis.

```bash
r2 -A {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,radare2 -->

---

## replace libc patchelf
Patch binary to use a custom libc version.

```bash
patchelf --replace-needed libc.so.6 {{NEW_LIBC:file:./libc-2.27.so}} {{BINARY:file:./target}}
```

<!-- meta: risk=med | phase=exploit | tags=re,patchelf,libc -->

---

## assemble shellcode nasm
Assemble shellcode for x86_64.

```bash
nasm -f elf64 {{ASM:file:shellcode.asm}} -o {{OBJ:file:shellcode.o}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,nasm,shellcode -->

---

## hex dump binary xxd
View binary contents in hex with offsets.

```bash
xxd {{BINARY:file:./target}} | less
```

<!-- meta: risk=safe | phase=recon | tags=re,xxd,hex -->

---

## edit binary hexedit
Open binary in interactive hex editor.

```bash
hexedit {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,hexedit -->

---

## install pwndbg plugin
Set up pwndbg for exploit development.

```bash
git clone https://github.com/pwndbg/pwndbg && cd pwndbg && ./setup.sh
```

<!-- meta: risk=safe | phase=misc | tags=re,setup,pwndbg -->

---

## install gef plugin
Set up GEF for GDB.

```bash
wget -O ~/.gdbinit-gef.py https://github.com/hugsy/gef/raw/main/gef.py
echo "source ~/.gdbinit-gef.py" >> ~/.gdbinit
```

<!-- meta: risk=safe | phase=misc | tags=re,setup,gef -->
