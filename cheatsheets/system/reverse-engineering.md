# Reverse Engineering
> Static and dynamic binary analysis tools for ELF/PE inspection and exploit dev
<!-- tags: reverse-engineering,binary,elf,gdb,exploit-dev -->

---

## Identify Binary Type
Identify file type, architecture, and linking type.

```bash
file {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,file,identify -->

---

## Check Binary Security Mitigations
Show NX, PIE, RELRO, ASLR status with checksec.

```bash
checksec --file={{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,checksec,mitigations -->

---

## Extract Printable Strings
Pull printable strings from binary (look for hardcoded creds/cmds).

```bash
strings {{BINARY:file:./target}} | less
```

<!-- meta: risk=safe | phase=recon | tags=re,strings -->

---

## Strings with Length Filter
Strings of minimum length to reduce noise.

```bash
strings -n {{MIN_LEN:int:10}} {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,strings,filter -->

---

## ELF Header Inspection
Display ELF headers, sections, and symbols.

```bash
readelf -a {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,readelf,elf -->

---

## Disassemble Binary
Disassemble binary into x86/x64 assembly.

```bash
objdump -d {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,objdump,disassemble -->

---

## Disassemble Specific Function
Disassemble a single function (e.g. main).

```bash
objdump -d {{BINARY:file:./target}} | awk '/<{{FUNCTION:str:main}}>:/,/^$/'
```

<!-- meta: risk=safe | phase=recon | tags=re,objdump,function -->

---

## Trace Library Calls
Monitor dynamic library function calls (printf, strcpy, etc).

```bash
ltrace ./{{BINARY:file:target}}
```

<!-- meta: risk=low | phase=recon | tags=re,ltrace,dynamic -->

---

## Trace System Calls
Track all syscalls made by the binary.

```bash
strace ./{{BINARY:file:target}}
```

<!-- meta: risk=low | phase=recon | tags=re,strace,syscalls -->

---

## Strace Filter Syscalls
Filter strace output to specific syscalls.

```bash
strace -e {{SYSCALL:str:open,read,write}} ./{{BINARY:file:target}}
```

<!-- meta: risk=low | phase=recon | tags=re,strace,filter -->

---

## GDB Interactive Debug
Open binary in GNU Debugger for dynamic analysis.

```bash
gdb {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,gdb,debug -->

---

## GDB with PEDA/GEF Plugin
Launch GDB with enhanced exploit dev plugins.

```bash
gdb-gef {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,gdb,gef,peda -->

---

## Find ROP Gadgets
Search binary for usable ROP gadgets.

```bash
ROPgadget --binary {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,ropgadget,rop -->

---

## Filter ROP Gadgets by Pattern
Search for specific gadget pattern (e.g. pop rdi).

```bash
ROPgadget --binary {{BINARY:file:./target}} --only "pop|ret"
```

<!-- meta: risk=safe | phase=exploit | tags=re,ropgadget,filter -->

---

## OneGadget RCE Search
Find one_gadget shell-spawning offsets in libc.

```bash
one_gadget {{LIBC:file:./libc.so.6}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,one_gadget,libc -->

---

## Radare2 Analysis
Open binary in radare2 for static/dynamic analysis.

```bash
r2 -A {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=recon | tags=re,radare2 -->

---

## Patchelf Replace Library
Patch binary to use a custom libc version.

```bash
patchelf --replace-needed libc.so.6 {{NEW_LIBC:file:./libc-2.27.so}} {{BINARY:file:./target}}
```

<!-- meta: risk=med | phase=exploit | tags=re,patchelf,libc -->

---

## NASM Assemble Shellcode
Assemble shellcode for x86_64.

```bash
nasm -f elf64 {{ASM:file:shellcode.asm}} -o {{OBJ:file:shellcode.o}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,nasm,shellcode -->

---

## Hex Dump with xxd
View binary contents in hex with offsets.

```bash
xxd {{BINARY:file:./target}} | less
```

<!-- meta: risk=safe | phase=recon | tags=re,xxd,hex -->

---

## Edit Binary in Hexedit
Open binary in interactive hex editor.

```bash
hexedit {{BINARY:file:./target}}
```

<!-- meta: risk=safe | phase=exploit | tags=re,hexedit -->

---

## Install pwndbg GDB Plugin
Set up pwndbg for exploit development.

```bash
git clone https://github.com/pwndbg/pwndbg && cd pwndbg && ./setup.sh
```

<!-- meta: risk=safe | phase=misc | tags=re,setup,pwndbg -->

---

## Install GEF GDB Plugin
Set up GEF for GDB.

```bash
wget -O ~/.gdbinit-gef.py https://github.com/hugsy/gef/raw/main/gef.py
echo "source ~/.gdbinit-gef.py" >> ~/.gdbinit
```

<!-- meta: risk=safe | phase=misc | tags=re,setup,gef -->
