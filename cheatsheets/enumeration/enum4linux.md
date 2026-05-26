# Enum4linux
> SMB/NetBIOS enumeration — users, shares, groups, and OS info from Windows/Samba hosts.

<!-- tags: smb, enum4linux, netbios, users, shares, enumeration, windows -->

---

## enumerate all enum4linux
Run broad enum4linux enumeration (users, shares, groups, OS, policy).

```bash
enum4linux -a {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=enum4linux,all,comprehensive -->

---

## verbose enum enum4linux
Run verbose enum4linux enumeration for extra detail.

```bash
enum4linux -v {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=enum4linux,verbose -->

---

## null session enum4linux
Run enum4linux with null credentials (anonymous session).

```bash
enum4linux -u "" -p "" {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=enum4linux,null,anonymous -->

---

## guest access enum4linux
Run enum4linux as the guest account with an empty password.

```bash
enum4linux -u "guest" -p "" {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=enum4linux,guest -->

---

## authenticated enum enum4linux
Run enum4linux with a valid username and password.

```bash
enum4linux -u {{USERNAME}} -p {{PASSWORD}} {{TARGET:ip}}
```

<!-- meta: risk=low | phase=enum | tags=enum4linux,authenticated,creds -->

---

## list users enum4linux
List user accounts via enum4linux and filter to the user entries.

```bash
enum4linux -U {{TARGET:ip}} | grep 'user:'
```

<!-- meta: risk=low | phase=enum | tags=enum4linux,users -->
