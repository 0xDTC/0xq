# q — fast command launcher for pentesters

Single-binary picker for pentester / DFIR cheatsheets. `Ctrl+Q` at any shell prompt → fuzzy-search 2,000+ curated commands → fill placeholders interactively → run (or copy, or save-as, or edit).

- **One binary**, ~3.7 MB stripped. No runtime dependency on `fzf`, Python, or anything else.
- **Native TUI** on `charmbracelet/bubbletea`. Startup is instant — no subprocess forks per keystroke.
- **150 cheatsheet files, 15 combined "chain" workflows, 2,000+ commands** across recon, enumeration, exploit, post-exploit, AD, cloud, web, forensics, wireless, cracking, networking, system.
- **Session-scoped state** — vars, targets, MRU, history all live per-session so HTB boxes don't bleed into client engagements.
- **Live browser User-Agent** via bundled `q-ua` helper — every web command sends a current Chrome/Firefox/Safari string (fetched daily, 24 h cached), so WAFs don't flag `nuclei/x.y.z` and `nikto/2.5.0` as bot signatures.
- **Snippet library** — reverse shells, PTY upgrades, hash-cracking one-liners live in one place and get referenced from any cheatsheet.
- **Output auto-promote** — every command's stdout is parsed for IPs, URLs, open ports, NTLM hashes, UPNs. Novel findings are offered as session targets after the run.

## Install

```bash
git clone https://github.com/0xDTC/0xq ~/repos/q
cd ~/repos/q
./install.sh          # needs go >= 1.22 (build-time only)
```

The installer:
1. Builds `./q` from source, strips it (~3.7 MB).
2. Copies to `~/.local/bin/q`.
3. Installs `q-ua` (live-UA helper) alongside.
4. Wires the `Ctrl+Q` widget into `~/.zshrc` / `~/.bashrc`.
5. Frees `Ctrl+Q` from the terminal's XON/XOFF flow control.
6. Installs bash + zsh tab-completion (`q edit <TAB>`, `q session <TAB>`, etc.).

Open a new terminal (or `source ~/.zshrc`), then hit `Ctrl+Q`.

## Usage

```bash
q                            # interactive picker
q nmap                       # picker pre-filtered to 'nmap'
q chain full smb null        # jump straight to a specific chain
q --phase attack --tag ad    # metadata narrowing before fuzzy search
q --inline                   # picker; final command → stdout (widget-mode)

q edit [query]               # fuzzy-find and open a cheatsheet in $EDITOR (auto-rebuild)
q session [list|new|use|rm]  # per-engagement session (own vars/targets/history)
q var [list|get|set|rm]      # session-var CRUD
q target [list|add|rm|clear] # session-target CRUD
q update                     # git pull + rebuild index
q rebuild                    # rebuild cheatsheet index cache
q lint                       # dedupe + UA-missing + no-timeout + deprecated-flag checks
q config get NAME            # read a Q_* config knob
q history                    # dump this session's history.log
q log [-f|clear]             # show / tail / clear the debug log

Ctrl+Q                       # from any shell prompt (installed by install.sh)
```

## Keybinds

**Inside the picker**

| Key | Action |
|---|---|
| `Enter` | Run — Auto-fills from session vars silently (fastest path) |
| `Ctrl+F` / `F4` / `Alt+↵` | Run BUT prompt for every placeholder (change IP / path / creds) |
| `Ctrl+E` / `F3` | Open highlighted cheatsheet in `$EDITOR` → auto-rebuild → back to picker |
| `↑ ↓` / `Ctrl+K` / `Ctrl+J` | Move highlight |
| `Home` `End` / `Ctrl+A` `Ctrl+B` | Query cursor start / end |
| `Backspace` / `Ctrl+H` / `Alt+↤` | Delete char (word) at cursor |
| `Ctrl+U` | Clear query |
| `Esc` | Quit |
| *(type)* | Fuzzy filter across title, tool, tags, category |

**Confirm dialog** (after fill, before exec)

| Key | Action |
|---|---|
| `Enter` | Run the assembled command |
| `v` | Change values — loop back through fill for the same template |
| `e` | Edit the assembled text in `$EDITOR` |
| `c` | Copy to system clipboard (xclip / wl-copy / pbcopy / clip.exe / OSC52) |
| `s` | Save-as — write to `cheatsheets/saved/user-saved.md` for reuse |
| `q` | Cancel |

## Cheatsheet format

Plain markdown under `cheatsheets/<category>/<tool>.md`:

````markdown
# nmap                                       ← H1: tool name
> Network scanner + service enumerator       ← blockquote (optional)

<!-- tags: nmap,recon,scan -->               ← file-level tags

## fast top-1k then deep on open ports       ← H2: entry title
Quick SYN scan first, then -sV -sC only on found ports.

```bash
ports=$(sudo nmap -sS --top-ports 1000 -Pn {{TARGET:ip}} 2>/dev/null | \
  awk '/^[0-9]+\/tcp.*open/{split($1,a,"/"); print a[1]}' | paste -sd,); \
  sudo nmap -sV -sC -O -p "$ports" -Pn -oN {{OUT:file:nmap.txt}} {{TARGET:ip}}
```

<!-- meta: risk=low | phase=recon | tags=nmap,chain,fast -->
````

**Placeholder syntax**

| Form | Meaning |
|---|---|
| `{{NAME}}` | freeform string, no default |
| `{{NAME:type:default}}` | typed (str, ip, url, port, file, dir, domain, …) with default |
| `{{NAME:choice:v1=hint1,v2=hint2}}` | enum with per-option descriptions |
| `{{NAME:helpflags:tool}}` | picker of every flag from `tool --help` (auto-scraped, 2s timeout) |
| `{{NAME:wordlist:default}}` | picker of curated SecLists / wordlists files that exist on disk |
| `{{NAME:snippet:key}}` | expand a named snippet from `builders/snippets/*.yaml` |
| `{{?TAG}}...{{/TAG}}` | optional block — fill flow asks *include TAG?* at run time |

## Chains

`cheatsheets/chains/chains.md` bundles 15 multi-tool workflows — each replaces 3-8 separate invocations with one focused command, output-filtered to only high-signal lines:

- `chain full nmap fast-then-deep` — top-1k → -sV/-sC/-O on found ports
- `chain quick web recon` — whatweb + nikto + nuclei critical/high (all fast tools)
- `chain full domain recon passive` — subfinder + amass passive + httpx alive/title/tech
- `chain full smb null session` — nxc + smbmap + enum4linux-ng + smbclient (null)
- `chain full smb authenticated` — same + spider-plus + rpcclient enumdomusers + --computers
- `chain full rpc nfs mount-and-list` — rpcinfo → showmount → auto-mount ro + ls
- `chain ad external recon kerbrute plus asrep`
- `chain ad kerberoast get-hashes`
- `chain ad bloodhound collect and quick-triage`
- `chain ad cert attack certipy find` (ESC1-ESC15 + -oids for ESC13)
- `chain ad writable objects bloodyAD`
- `chain ad hosts file from ad` (nxc --generate-hosts-file)
- `chain ad gmsa dump and validate` (bloodyAD → nxc pass-the-hash)
- `chain web nuclei full automated` (-as + -dast)
- `chain ad delegation s4u save ticket` (nxc --delegate → KRB5CCNAME hint)

## Live browser User-Agent (`q-ua`)

`bin/q-ua` fetches jnrbsn's maintained UA list (updated when browsers ship new majors), caches at `~/.cache/q/latest-ua.json` for 24 h, falls back to a hard-coded baseline offline. Every cheatsheet's `{{UA:str:$(q-ua)}}` placeholder default resolves at run time — no stale WAF-baiting Chrome/131 strings six months from now.

```bash
q-ua              # latest Chrome (default)
q-ua firefox      # latest Firefox
q-ua safari       # latest Safari
q-ua --refresh    # bust the cache and re-fetch
q-ua --list       # dump every UA in cache
```

## Snippets (`builders/snippets/`)

Shared payload library. Cheatsheets reference snippets by key:

```markdown
```bash
echo "{{PAYLOAD:snippet:rshell-bash-linux}}"
```
```

At fill time, the snippet payload is substituted; any placeholders inside it (e.g. `{{LHOST}}`, `{{LPORT}}`) then get resolved on the next pass. User overrides live in `~/.config/q/snippets/*.yaml` — same YAML shape, loaded after the shipped set so they shadow.

Shipped:
- `builders/snippets/reverse-shells.yaml` — bash TCP, bash+b64, python3, nc+mkfifo, PowerShell TCP, perl, php, ruby.
- `builders/snippets/upgrade-shell.yaml` — python3 pty, python2 pty, script -qc, full-stty rows.

## Output auto-promote

Every executed command's stdout is teed into a 10 MB buffer, then parsed for:
- **IPs** (validated octets, loopback rejected)
- **URLs** (http / https)
- **Domains** (real TLD-shaped, versions filtered out)
- **Open ports** (nmap-style `N/tcp open service`)
- **NTLM hash pairs** (32:32 hex)
- **User principals** (`user@realm`)

Novel findings (deduped against current session targets) get a summary + `[y/N]` prompt to add URL/IP/domain rows as session targets. Hashes → `sessions/<name>/hashes.txt`, UPNs → `sessions/<name>/users.txt`.

Disable per run: `Q_PROMOTE=off q ...`.

## Session management

Sessions isolate `vars`, `targets`, `history.log`, `hashes.txt`, `users.txt`, `mru`. Everything defaults to a session called `default`; create per-engagement sessions with:

```bash
q session new htb-blazorized
q session use htb-blazorized
q session list                       # ▸ marks active, shows cmd/var/target counts
q session current                    # print active name (scriptable)
q session rm old-engagement          # confirms; refuses to delete 'default'
```

On-disk state under `$XDG_DATA_HOME/q/sessions/<name>/`.

## `q lint`

Static checks over the whole index. Passes clean on a fresh clone; catches drift over time:

- **`[dup]`** — same normalised command in two files (intentional cross-lists remain; false-positive collisions on placeholder-default drift are filtered).
- **`[ua-missing]`** — web-request command missing a `{{UA}}` placeholder. Aware of curl in non-HTTP contexts (skipped when no URL); skips GitHub-raw / api.github.com; skips the curl-verbose demo.
- **`[no-timeout]`** — scanner (amass, masscan, nikto) missing a `timeout` prefix or native `--maxtime` / `-timeout`.
- **`[deprecated]`** — flags known bad ideas: `--random-agent`, `--random-user-agent`, `-irr`.
- **`[placeholder-mix]`** — same file uses both `{{TARGET}}` and `{{TARGET_IP}}` (breaks session-var sharing).

## Directory layout

```
q/                           ← this repo
├── install.sh
├── bin/
│   ├── q-ua                 ← live-UA helper (installed to ~/.local/bin/)
│   ├── q-completion.bash    ← shell tab-completion
│   └── q-completion.zsh
├── cmd/q/                   ← main dispatch
├── internal/
│   ├── clip/                ← xclip / wl-copy / pbcopy / clip.exe / OSC52
│   ├── config/              ← Q_* env, ~/.config/q/config.sh
│   ├── executor/            ← confirm/copy/save/edit + auto-promote tee
│   ├── fill/                ← placeholder parse, candidates, interactive fill
│   ├── helpscrape/          ← --help output parser (used by helpflags placeholder)
│   ├── index/               ← cache/index.tsv read/write
│   ├── nexthint/            ← post-run "what's next?" suggestion table
│   ├── parser/              ← .md → index rows
│   ├── promote/             ← output → IPs/URLs/hashes/UPNs parser
│   ├── qlog/                ← timestamped action log
│   ├── saveas/              ← [s] Save-as → cheatsheets/saved/user-saved.md
│   ├── session/             ← vars, targets, MRU, history
│   ├── snippets/            ← YAML snippet library loader
│   ├── tool/                ← canonical tool-name extraction
│   └── tui/                 ← reusable bubbletea picker + fuzzy matcher
├── cheatsheets/             ← content (150 files, 15 categories, 2,000+ commands)
│   └── chains/chains.md     ← 15 multi-tool workflows
└── builders/
    ├── nmap.yaml            ← curated flag catalog (fed to picker via helpflags)
    └── snippets/            ← shipped snippet library YAMLs
```

Runtime state:

```
~/.local/share/q/
├── sessions/<name>/
│   ├── vars                 ← session KEY=VAL variables
│   ├── targets              ← session targets (type:value, MRU order)
│   ├── history.log          ← ts \t rc \t dur \t cmd
│   ├── hashes.txt           ← promoted NTLM hashes
│   └── users.txt            ← promoted UPNs
├── var_history/<NAME>       ← per-variable value history (last 20, deduped)
├── mru                      ← recent command titles (cap 50)
└── debug.log                ← action log (1 MB rotate; Q_LOG=off disables)

~/.config/q/
├── config.sh                ← optional Q_* knobs
├── enabled.tsv              ← (reserved; from earlier tool-curator; unused today)
└── snippets/*.yaml          ← user snippet overrides

~/.cache/q/
└── latest-ua.json           ← q-ua UA list cache (24 h)
```

## Config knobs (`~/.config/q/config.sh`)

Optional. Plain `KEY=value` or `export KEY=value` grammar.

| Knob | Default | Purpose |
|---|---|---|
| `Q_OS_FILTER` | *(none)* | Restrict picker to entries with matching platform tag |
| `Q_SESSION_NAME` | `default` | Active session (also settable via `q session use`) |
| `Q_LOG` | *(on)* | Set to `off` to disable the debug log |
| `Q_LOG_FILE` | `~/.local/share/q/debug.log` | Override log path |
| `Q_PROMOTE` | *(on)* | Set to `off` to disable output auto-promote |
| `Q_CLIP` | *(auto)* | `osc52` forces OSC52 escape (tmux + SSH-friendly); or a specific tool name |

## Rollback

The full bash-tree implementation was retired at git tag `pre-go-cutover`. If the Go binary misbehaves, revert with `git reset --hard pre-go-cutover`; the previous `install.sh` reinstates the bash `~/.local/bin/q` symlink. The current installer also preserves any prior `~/.local/bin/q` as `~/.local/bin/q.pre-go` for a per-user rollback.
