# Disk Image Mount and Extract (VHD/VHDX/VMDK/E01/AD1/Archives)

> Read triage disk images and archives without touching the host filesystem. Covers libguestfs (guestfish / guestmount / qemu-nbd), pyfsntfs (Python NTFS reader), Sleuth Kit (fls / icat / mmls), cabextract, and 7z on nested/AES archives.

<!-- tags: dfir,vhdx,vmdk,ntfs,guestfish,pyfsntfs,sleuthkit,cab,7z,triage -->

## guestfish inspect a VHDX/VMDK/qcow2
List partitions and filesystems inside a virtual disk without mounting it.

```bash
guestfish --ro -a {{IMG:file:./triage.vhdx}} <<'EOF'
run
list-partitions
list-filesystems
EOF
```

<!-- meta: risk=safe | phase=dfir | tags=guestfish,inspect,partitions -->

---

## guestfish download raw partition (bypasses ntfs3)
When Kali kernel lacks ntfs3 and `guestmount -i` refuses, download the raw partition to disk and read it with pyfsntfs or fls instead.

```bash
guestfish --ro -a {{IMG:file:./triage.vhdx}} <<EOF
run
download /dev/sda1 {{OUT:file:./fs.raw}}
EOF
```

<!-- meta: risk=safe | phase=dfir | tags=guestfish,raw,extract -->

---

## walk NTFS with pyfsntfs (no mount)
Enumerate top-level entries in a raw NTFS partition (e.g. the fs.raw from above).

```bash
python3 -c "
import pyfsntfs
v=pyfsntfs.volume(); v.open('{{RAW:file:./fs.raw}}')
for e in v.get_root_directory().sub_file_entries: print(' ', e.name)"
```

<!-- meta: risk=safe | phase=dfir | tags=pyfsntfs,ntfs,walk -->

---

## pyfsntfs extract a specific file by path
Copy one file out of the raw NTFS to a local file.

```bash
python3 -c "
import pyfsntfs
v=pyfsntfs.volume(); v.open('{{RAW:file:./fs.raw}}')
def fp(cur, parts):
    for p in parts:
        for e in cur.sub_file_entries:
            if e.name.lower()==p.lower(): cur=e; break
        else: return None
    return cur
e=fp(v.get_root_directory(), {{PATH:str:['C','Windows','AppCompat','Programs','Amcache.hve']}})
open('{{OUT:file:./out.hve}}','wb').write(e.read_buffer(e.get_size()))
print('bytes:', e.get_size())"
```

<!-- meta: risk=safe | phase=dfir | tags=pyfsntfs,extract,copy -->

---

## qemu-img convert VHDX to raw
Turn a Hyper-V VHDX into a flat raw file (needs disk space equal to virtual size).

```bash
qemu-img convert -O raw {{IMG:file:./triage.vhdx}} {{OUT:file:./triage.raw}}
```

<!-- meta: risk=low | phase=dfir | tags=qemu-img,convert,raw -->

---

## qemu-img inspect virtual disk
Format, virtual size, physical size, cluster size.

```bash
qemu-img info {{IMG:file:./triage.vhdx}}
```

<!-- meta: risk=safe | phase=dfir | tags=qemu-img,info -->

---

## mmls list partition table
Sleuth Kit's partition mapper. Gives sector offsets for each partition.

```bash
mmls {{IMG:file:./triage.raw}}
```

<!-- meta: risk=safe | phase=dfir | tags=sleuthkit,mmls,partitions -->

---

## fls list NTFS directory tree
List every filename in the NTFS partition at sector offset (from mmls) with allocated/deleted flag.

```bash
fls -f ntfs -o {{OFFSET:int:63}} -r {{IMG:file:./triage.raw}}
```

<!-- meta: risk=safe | phase=dfir | tags=sleuthkit,fls,ntfs -->

---

## icat extract file by inode
Recover a file's content by its MFT record number (get it from fls).

```bash
icat -f ntfs -o {{OFFSET:int:63}} {{IMG:file:./triage.raw}} {{INODE:int:97945}} > {{OUT:file:./recovered.bin}}
```

<!-- meta: risk=safe | phase=dfir | tags=sleuthkit,icat,recover -->

---

## qemu-nbd expose VHDX as block device (needs root)
Attach a VHDX to /dev/nbd0 so any tool that reads block devices can use it.

```bash
sudo modprobe nbd max_part=8
sudo qemu-nbd --read-only --connect=/dev/nbd0 {{IMG:file:./triage.vhdx}}
sudo mount -t ntfs-3g -o ro /dev/nbd0p1 {{MOUNT:path:/mnt/triage}}
```

<!-- meta: risk=low | phase=dfir | tags=qemu-nbd,nbd,mount -->

---

## disconnect nbd
Clean up after use.

```bash
sudo umount {{MOUNT:path:/mnt/triage}}
sudo qemu-nbd --disconnect /dev/nbd0
```

<!-- meta: risk=low | phase=dfir | tags=qemu-nbd,cleanup -->

---

## cabextract MS Cabinet archive
Extract a .cab (also files with fake extensions like .wp5 that are really CABs).

```bash
cabextract -d {{DEST:path:./out}} {{CAB:file:./Play.wp5}}
```

<!-- meta: risk=safe | phase=dfir | tags=cabextract,cab,extract -->

---

## cabextract list archive contents
Preview a CAB without extracting.

```bash
cabextract -l {{CAB:file:./Play.wp5}}
```

<!-- meta: risk=safe | phase=dfir | tags=cabextract,list -->

---

## 7z selective extract from a huge zip
Pull only specific paths out of a multi-GB zip (glob patterns supported).

```bash
7z x -y -aoa -p'{{PW:str:hackthebox}}' {{ZIP:file:./triage.zip}} -o{{OUT:path:./out}}/ {{PATTERN:str:'*/uploads/auto/C%3A/Windows/System32/winevt/Logs/Security.evtx'}}
```

<!-- meta: risk=safe | phase=dfir | tags=7z,selective,extract -->

---

## 7z list contents to a file
Full listing (needed for finding exact paths for selective extract on large archives).

```bash
7z l {{ZIP:file:./triage.zip}} > {{OUT:file:./listing.txt}}
```

<!-- meta: risk=safe | phase=dfir | tags=7z,list -->

---

## 7z AES-encrypted zip
`unzip` fails on AES-256 encrypted zips ("unsupported compression method 99"). 7z handles them.

```bash
7z x -y -p'{{PW:str:hackthebox}}' {{ZIP:file:./encrypted.zip}} -o{{OUT:path:./out}}/
```

<!-- meta: risk=safe | phase=dfir | tags=7z,aes,encrypted -->

---

## apt-get download a package without root
Grab a .deb and unpack in a local dir when you don't have sudo (used for pulling `crash` + `makedumpfile` when analyzing kdumps).

```bash
apt-get download {{PKG:str:crash}}
dpkg -x {{PKG:str:crash}}_*.deb {{DEST:path:./extracted}}
```

<!-- meta: risk=safe | phase=util | tags=apt,download,no-root -->
