# q (Go port) — WIP

Staged rewrite of the bash `q` in Go. Not yet feature-complete — the
bash tree at repo root is still authoritative during transition. When
this port reaches parity, the bash tree can be moved to `bash/` or
removed.

## Layout

```
go/
├── cmd/q/            # main dispatch — one subcommand per file
├── internal/
│   ├── index/        # TSV index read/write (cache/index.tsv)
│   ├── parser/       # .md → index rows
│   ├── tool/         # canonical tool-name extraction
│   ├── session/      # sessions, vars, targets, MRU (planned)
│   ├── combos/       # captured personal templates (planned)
│   └── config/       # ~/.config/q/config.sh loader (planned)
└── go.mod
```

## Current status

**Done:**
- `internal/tool` — tool-name extraction (canonical `TrimSudoEnv`).
  Ports the fixed `q_extract_tool_binary` from `lib/core.sh`.
- `internal/index` — read/write the 10-column TSV cache.
- `internal/parser` — walk `cheatsheets/**/*.md`, emit index rows.
  Ports `lib/parser.sh`. Handles H1/H2/```bash/meta/tags/platform
  and the choice-value keyword extraction.
- `cmd/q` — dispatch for `rebuild`, `lint`.

**Not yet:**
- `cmd/q` main flow (fzf integration + fill + confirm+run)
- combo capture / picker rows
- builder + Ctrl+B/M/X keybind helpers
- placeholder syntax (choice, optional blocks)
- session mgmt / targets / MRU
- q config / q history

## Building

```
cd go
go build -o q ./cmd/q
./q rebuild
./q lint
```

The compiled binary shares the same `Q_ROOT` (the parent directory
holding `cheatsheets/`), `Q_DATA_DIR` (`~/.local/share/q`), and
`Q_CACHE_DIR` (`Q_ROOT/cache`) as the bash version. During transition
both can co-exist and read the same cache.

## Why Go

The bash tree hit ~9k lines and started showing structural fatigue —
in particular the "helper sourced the wrong set of libs" class of
bugs. Go gives typed function signatures, real error handling, unit
tests, and a single-binary distribution. Costs an initial rewrite;
saves every future refactor.

## Deliberately not ported

- `q sync …` — already removed (dead)
- `q chain …` — audit flagged as never-triggered in recent use
- `q tmux …` — audit flagged as bolted-on; the Ctrl+Q widget popup
  stays as `install.sh` tmux config

If any of these are missed, they live in git history and can be
restored (either back to bash or as a new Go module).
