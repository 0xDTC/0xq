# Mount
> Mount remote and local filesystems for access and pivoting
<!-- tags: mount,filesystem,nfs,smb,sshfs -->

---

## mount nfs share
Mount NFS export to local mount point.

```bash
sudo mount -t nfs {{TARGET:ip}}:{{REMOTE_PATH:str:/share}} {{MOUNT_POINT:dir:/mnt/nfs}}
```

<!-- meta: risk=low | phase=enum | tags=mount,nfs -->

---

## mount smb cifs share
Mount Windows SMB share with credentials.

```bash
sudo mount -t cifs //{{TARGET:ip}}/{{SHARE:str:share}} {{MOUNT_POINT:dir:/mnt/smb}} -o username={{USERNAME:str}},password={{PASSWORD:str}},vers=3.0
```

<!-- meta: risk=low | phase=enum | tags=mount,cifs,smb -->

---

## mount ext4 partition
Mount local EXT4 disk partition.

```bash
sudo mount /dev/{{DEVICE:str:sda1}} {{MOUNT_POINT:dir:/mnt/disk}}
```

<!-- meta: risk=safe | phase=misc | tags=mount,ext4,local -->

---

## mount fat32 usb
Mount USB drive with FAT32 filesystem.

```bash
sudo mount /dev/{{DEVICE:str:sdb1}} {{MOUNT_POINT:dir:/mnt/usb}} -t vfat
```

<!-- meta: risk=safe | phase=misc | tags=mount,fat32,usb -->

---

## mount iso image
Mount ISO file via loop device.

```bash
sudo mount -o loop {{ISO:file:image.iso}} {{MOUNT_POINT:dir:/mnt/iso}}
```

<!-- meta: risk=safe | phase=misc | tags=mount,iso,loop -->

---

## mount tmpfs
Create in-memory tmpfs mount.

```bash
sudo mount -t tmpfs tmpfs {{MOUNT_POINT:dir:/mnt/tmp}}
```

<!-- meta: risk=safe | phase=misc | tags=mount,tmpfs,memory -->

---

## mount sshfs remote
Mount remote directory over SSH using sshfs.

```bash
sshfs {{USERNAME:str}}@{{TARGET:ip}}:{{REMOTE_PATH:str:/home/user}} {{MOUNT_POINT:dir:/mnt/ssh}}
```

<!-- meta: risk=low | phase=post | tags=mount,sshfs -->

---

## mount bind
Bind one directory to another mount point.

```bash
sudo mount --bind {{SOURCE:dir:/source}} {{TARGET_DIR:dir:/mnt/bind}}
```

<!-- meta: risk=safe | phase=misc | tags=mount,bind -->

---

## activate swap
Enable a swap partition for use.

```bash
sudo swapon /dev/{{DEVICE:str:sda5}}
```

<!-- meta: risk=safe | phase=misc | tags=mount,swap -->
