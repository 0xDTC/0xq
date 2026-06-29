# dislocker

> Read/write BitLocker-encrypted drives on Linux by decrypting to a virtual mount point. Needs a known password or recovery key — this is access, not cracking.

<!-- tags: dislocker, bitlocker, mount, vhd, forensics -->

---

## mount bitlocker vhd dislocker
One-shot BitLocker VHD mount: create the mount points, set up the loop device with partition mapping, decrypt with dislocker (adjust /dev/loop0p2 if losetup grabbed a different loop number), then mount the virtual file. Lands at /media/bitlockermount.

```bash
sudo mkdir -p /media/bitlocker /media/bitlockermount && sudo losetup -f -P {{VHD:file:Backup.vhd}} && sudo dislocker /dev/loop0p2 -u{{PASSWORD:str}} -- /media/bitlocker && sudo mount -o loop /media/bitlocker/dislocker-file /media/bitlockermount && echo "Mounted at /media/bitlockermount"
```

<!-- meta: risk=low | phase=post | tags=bitlocker,mount,dislocker,losetup,vhd -->

---

## unmount bitlocker dislocker
Clean up the dislocker mount: unmount the virtual file, unmount dislocker itself, detach all loop devices.

```bash
sudo umount /media/bitlockermount && sudo umount /media/bitlocker && sudo losetup -D
```

<!-- meta: risk=safe | phase=post | tags=bitlocker,unmount,dislocker,cleanup -->
