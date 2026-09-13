# q — fast command launcher for pentesters

Native single-binary picker for pentester/DFIR cheatsheets. Type
`Ctrl+Q` at any prompt → fuzzy-search hundreds of curated commands →
fill placeholders interactively → run.

- **One binary**, ~3.5 MB stripped. No runtime dependency on `fzf`,
  Python, or anything else.
- **Native TUI**, built on `charmbracelet/bubbletea`. Startup is
  instant (no subprocess forks per keystroke).
- **Zero-config content authoring** — cheatsheets are plain markdown
  under `cheatsheets/<category>/<tool>.md`. See below for the format.
- **Auto-captured combos** — every command you pick gets stored as a
  template under `~/.local/share/q/combos/<tool>.tsv`; next run they
  float to the top of the picker with a `⚙ combo (used N×)` badge.
- **Choice placeholders** with per-option hints — the picker knows the
  20+ regripper plugins, hydra modules, hashcat modes, etc.
- **Optional-block syntax** `{{?TAG}}...{{/TAG}}` — one command, N
  variants; the fill flow asks *include TAG?* at run time and drops
  the block when you say no.

## Install

```bash
git clone https://github.com/0xDTC/0xq ~/repos/q
cd ~/repos/q
./install.sh          # requires: go >= 1.22 (build-time only)
```

The installer:
1. Builds `./q` from source
2. Copies it to `~/.local/bin/q`
3. Adds the `Ctrl+Q` widget to `~/.zshrc` or `~/.bashrc`
4. Frees `Ctrl+Q` from the terminal's XON/XOFF flow control

Then open a new terminal (or `source ~/.zshrc`) and hit `Ctrl+Q`.

## Usage

```
q                    # interactive picker (default)
q nmap               # picker pre-filtered to 'nmap'
q --inline           # picker; final command to stdout (for the widget)
q rebuild            # rebuild the cheatsheet index
q lint               # report cross-file duplicate commands
q combos list        # your captured personal combos
q combos forget TOOL [TEMPLATE]
q config get NAME    # read a Q_* knob from ~/.config/q/config.sh
q history            # dump this session's history.log
Ctrl+Q               # invoke from any shell prompt (installed by install.sh)
```

## Cheatsheet format

```markdown
# regripper                              ← H1: tool name
> One-liner description of the tool      ← blockquote (optional)

<!-- tags: dfir,registry,offline -->     ← file-level tags
<!-- platform: windows -->                ← platform filter

## single plugin                          ← H2: entry title
Run one named plugin against a hive.     ← description

```bash
regripper -r {{HIVE:file:./NTUSER.DAT}} -p {{PLUGIN:choice:userassist=executed GUI programs,recentdocs=recently opened files,shellbags=folders navigated in Explorer,...}}
```

<!-- meta: risk=safe | phase=dfir | tags=plugin,artifact -->
```

Placeholder syntax:

| Form | Meaning |
| --- | --- |
| `{{NAME}}` | freeform string, no default |
| `{{NAME:type}}` | typed (str, ip, url, domain, port, file, dir, wordlist, choice, …) |
| `{{NAME:type:default}}` | with a default value |
| `{{NAME:choice:v1=hint1,v2=hint2,...}}` | enum with per-option descriptions |
| `{{?TAG}}...{{/TAG}}` | optional block — fill flow asks `include TAG?` at run time |

## Directory layout

```
q/                       ← this repo
├── install.sh
├── cmd/q/               ← main dispatch
├── internal/
│   ├── config/          ← Q_ROOT, Q_DATA_DIR, Q_CACHE_DIR, ~/.config/q/config.sh
│   ├── parser/          ← .md → index rows
│   ├── index/           ← cache/index.tsv read/write
│   ├── session/         ← vars, targets, MRU, history
│   ├── combos/          ← captured personal templates
│   ├── fill/            ← placeholder parse, candidates, interactive fill
│   ├── tui/             ← reusable bubbletea picker + fuzzy matcher
│   ├── executor/        ← confirm+run + path sanity check
│   └── tool/            ← canonical tool-name extraction from a cmdline
├── cheatsheets/         ← content (170+ files, 15 categories, 2200+ commands)
└── builders/            ← per-tool flag catalogs (nmap.yaml today; more via `--help` parsing)
```

Runtime state lives under `$XDG_DATA_HOME/q` (typically `~/.local/share/q`):

```
~/.local/share/q/
├── sessions/<name>/
│   ├── vars                ← session KEY=VAL variables
│   ├── targets             ← session targets (type:value)
│   ├── history.log         ← executed commands (ts, rc, dur, cmd)
│   └── runs/               ← per-run output logs
├── combos/<tool>.tsv       ← captured personal command templates
├── var_history/<NAME>      ← per-variable value history
└── mru                     ← recent command titles
```

## Configuration

Optional `~/.config/q/config.sh` (plain `KEY=value` grammar):

| Knob | Default | Purpose |
| --- | --- | --- |
| `Q_OS_FILTER` | *(none)* | Only show cheatsheets matching this platform |
| `Q_PREVIEW_SIZE` | `80%` | Picker height |
| `Q_SESSION_NAME` | `default` | Named session |
| `Q_CLIPBOARD_CANDIDATE` | `off` | Include current clipboard as a fill candidate |
| `Q_FILE_MAXDEPTH` | `10` | PWD file sweep depth (fill picker) |
| `Q_FILE_MAXCOUNT` | `20000` | PWD file sweep cap |
| `Q_HOME_MAXDEPTH` | `3` | HOME file sweep depth |
| `Q_HOME_MAXCOUNT` | `500` | HOME file sweep cap |

## Roadmap

Still to port from the previous (now-retired) bash tree:

- Builder + Ctrl+B (interactive flag composer with YAML catalogs and
  `--help` parsing)
- Ctrl+M (modify current row's command with flags pre-marked)
- Ctrl+X (chain composer — sequential `&&`)
- Ctrl+D (delete current row with confirm)
- `[s] Save` — save a filled command as a new cheatsheet entry
- Native clipboard support (currently stubbed as `off`)

## Rollback

The full bash tree is preserved at git tag `pre-go-cutover`. If the Go
binary misbehaves, revert with `git reset --hard pre-go-cutover`; the
old `install.sh` reinstates the bash `~/.local/bin/q` symlink. The
installer also preserves any previous `~/.local/bin/q` as
`~/.local/bin/q.pre-go` for a per-user rollback.
