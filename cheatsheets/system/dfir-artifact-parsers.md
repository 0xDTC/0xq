# DFIR Artifact Parsers (MFT, USN, Prefetch, LNK)

> Parse Windows filesystem and execution artifacts pulled from a triage: `$MFT` (Master File Table), `$Extend/$J` (USN Journal), `.pf` (Prefetch), `.lnk` (Shell Link). Kali has analyzeMFT (Python) plus libraries `libscca-python` (prefetch) and `pylnk3` (shortcuts). USN parsing done via a small Python loop over the binary format.

<!-- tags: dfir,mft,usn,prefetch,lnk,shellbags,timeline,artifact -->

## install python-based parsers
One-shot install of analyzeMFT (MFT to CSV), libscca-python (prefetch), pylnk3 (shortcut files).

```bash
pip3 install --user --break-system-packages analyzeMFT libscca-python pylnk3
```

<!-- meta: risk=safe | phase=dfir | tags=install,pip,setup -->

---

## analyzemft dump MFT to csv
Convert $MFT to a CSV with every record: filename, parent ref, SI/FN timestamps, data attribute. Foundational for a filesystem timeline.

```bash
analyzemft -f {{MFT:file:./\$MFT}} -o {{OUT:file:./mft.csv}}
```

<!-- meta: risk=safe | phase=dfir | tags=analyzemft,mft,csv -->

---

## analyzemft body file for timeline tools
Body file (mactime format) suitable for `mactime` / Timesketch / log2timeline.

```bash
analyzemft --body -f {{MFT:file:./\$MFT}} -o {{OUT:file:./mft.body}}
```

<!-- meta: risk=safe | phase=dfir | tags=analyzemft,timeline,mactime -->

---

## rebuild file path from MFT record
Walk parent chain from a target record number to reconstruct the full path.

```bash
python3 -c "
import csv
mft={int(r['Record Number']): r for r in csv.DictReader(open('{{CSV:file:./mft.csv}}'))}
def path(rec):
    p=[]
    while rec in mft and rec!=5:
        p.append(mft[rec]['Filename'])
        rec=int(mft[rec]['Parent Record Number'])
    return 'C:\\\\' + '\\\\'.join(reversed(p))
print(path({{REC:int:97945}}))"
```

<!-- meta: risk=safe | phase=dfir | tags=analyzemft,path,walk -->

---

## raw MFT record parse (data attribute real-size)
analyzemft's CSV drops the $DATA.RealSize field. Pull it manually when you need the exact byte count of a deleted / dumped file.

```bash
python3 -c "
import struct
d=open('{{MFT:file:./\$MFT}}','rb').read()
rec=d[{{REC:int:663}}*1024:({{REC:int:663}}+1)*1024]
pos=struct.unpack('<H', rec[0x14:0x16])[0]
while pos<1024-16:
    t=struct.unpack('<I', rec[pos:pos+4])[0]
    if t==0xffffffff: break
    l=struct.unpack('<I', rec[pos+4:pos+8])[0]
    if t==0x80:
        real=struct.unpack('<Q', rec[pos+0x30:pos+0x38])[0]
        print(f'RealSize={real:,} bytes'); break
    pos+=l"
```

<!-- meta: risk=safe | phase=dfir | tags=mft,raw,size -->

---

## parse USN Journal $J
Extract create/delete/rename events with timestamps from the USN journal. Reveals attacker file activity even after files are deleted.

```bash
python3 -c "
import struct, datetime
d=open('{{J:file:./\$J}}','rb').read()
pos=0
while pos<len(d):
    while pos<len(d) and d[pos]==0: pos+=1
    if pos+60>=len(d): break
    l=struct.unpack('<I', d[pos:pos+4])[0]
    if l==0 or l>1024: pos+=1; continue
    ts=struct.unpack('<Q', d[pos+32:pos+40])[0]
    r=struct.unpack('<I', d[pos+40:pos+44])[0]
    fl=struct.unpack('<H', d[pos+56:pos+58])[0]
    fo=struct.unpack('<H', d[pos+58:pos+60])[0]
    fn=d[pos+fo:pos+fo+fl].decode('utf-16-le','replace')
    if any(k in fn.lower() for k in ['{{KW:str:mimikatz}}']):
        t=datetime.datetime.fromtimestamp(ts/1e7-11644473600, datetime.timezone.utc)
        print(f'{t} r=0x{r:x} {fn}')
    pos+=l"
```

<!-- meta: risk=safe | phase=dfir | tags=usn,journal,timeline -->

---

## prefetch last-run times (pyscca)
Read a .pf file to get executable name, run count, and up to 8 last-run timestamps.

```bash
python3 -c "
import pyscca
s=pyscca.file(); s.open('{{PF:file:./NOTEPAD.EXE-XXXXXXXX.pf}}')
print(f'exe={s.get_executable_filename()} runs={s.get_run_count()}')
for i in range(8):
    try:
        t=s.get_last_run_time(i)
        if t.year>1601: print(f'  Run[{i}] {t}')
    except: break"
```

<!-- meta: risk=safe | phase=dfir | tags=pyscca,prefetch,execution -->

---

## prefetch referenced files
List every file the executable touched (useful for spotting DLL side-loading / staged binaries).

```bash
python3 -c "
import pyscca
s=pyscca.file(); s.open('{{PF:file:./PS.pf}}')
for i in range(s.number_of_filenames):
    print(s.get_filename(i))"
```

<!-- meta: risk=safe | phase=dfir | tags=pyscca,prefetch,references -->

---

## batch-parse every prefetch in a folder
One-liner per .pf: last run + run count.

```bash
python3 -c "
import pyscca, os
for f in sorted(os.listdir('{{DIR:path:./prefetch}}')):
    if not f.endswith('.pf'): continue
    s=pyscca.file(); s.open(f'{{DIR:path:./prefetch}}/{f}')
    t=s.get_last_run_time(0)
    print(f'{t}  {s.get_run_count():4}  {f}')" | sort
```

<!-- meta: risk=safe | phase=dfir | tags=pyscca,batch,timeline -->

---

## parse a Windows shortcut (.lnk)
Full parse: target path, args, working dir, timestamps, volume info.

```bash
python3 -c "
import pylnk3
lnk=pylnk3.parse('{{LNK:file:./Recent/example.lnk}}')
print(lnk)"
```

<!-- meta: risk=safe | phase=dfir | tags=pylnk3,lnk,shortcut -->
