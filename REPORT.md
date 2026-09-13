# Code audit — findings and cleanup plan

Aggregated from three fresh reads across the tree. Total: **8883 lines** of bash across `q`, `install.sh`, 15 lib files, 2 completion scripts, 1 builder yaml.

Estimated cleanup gain before any Go work: **~1450 lines removable** and one whole class of sourcing regression eliminated.

---

## Root-cause of "so many things broken"

Not a random set of bugs. Three structural patterns produce most of them:

1. **Sourcing inconsistency.** The picker's `q_search` emits 10 helper scripts (`.q_*.sh`) into `cache/`. Each one hand-picks which libs to source. The Ctrl+M "Could not detect tool" bug two days ago happened because the modify helper sourced `builder.sh` but not `combos.sh` — where `_q_combo_tool_for` lives. Every helper is a fresh sourcing minefield. No shared preamble exists.
2. **Tool-name extraction, three copies.** `_q_combo_tool_for` (combos.sh), `q_log_extract_tool` (logger.sh), and inline in `q_pre_exec_check` (executor.sh). Same job, three implementations. The comment in `combos.sh` even flags it: *"Mirrors q_log_extract_tool — but that lib might not be sourced in every path, so we duplicate."* That admission IS the bug pattern.
3. **`2>/dev/null` everywhere.** ~40 occurrences across the tree. Legitimate for `command -v` probes, but scattered on function calls where a "command not found" from missing sourcing looks identical to a normal empty result. Hides bugs.

Fix all three and the class of "silent breakage on modify/build/…" regressions ends.

---

## Dead code — delete outright

| Item | Location | Why dead |
| --- | --- | --- |
| `lib/sync.sh` (325 lines) | whole file | `Q_SYNC_BUILTINS=()`; no callers add sources; help still documents 6 lines of `q sync …` |
| `q sync …` dispatch in `q` | main | dead-end after `sync.sh` goes |
| `CHEATSHEET SYNC` section | `q_help` in `core.sh` | documents removed subsystem |
| `q_builder_emit_index_rows` | `builder.sh` (~30 lines) | zero callers after Ctrl+B rewrote the `[+]` rows out |
| `__BUILDER__:<tool>` sentinel handling | `q` main | left over from the same rewrite; nothing writes this sentinel anymore |
| `.builder_tool` sideband `rm` | `search.sh` | nothing writes it |
| `_q_compatible_target_types` | `variables.sh` (12 lines) | one reference in the tree — inside a code comment that says "inlined to avoid subshell forks" |
| Dead defensive fallbacks | `executor.sh` (2 places) | `q_promote_after_run` / `q_log_start` unreachable branches (always sourced) |

**~400 lines deletable with zero behavioural change.**

## Real bugs — fix

1. `q` main uses `local _built` and `local _filled` inside `case )` bodies (lines 392, 398). `local` is only valid inside functions; some bash builds error under `set -euo pipefail`.
2. `q config get NAME` reads `${!key:-}` — the current shell env, not `~/.config/q/config.sh`. If the shell hasn't sourced the config, `q config get` returns empty. Must source config first or grep the file.
3. `q_search`'s ANSI-strip check `[[ -f X ]] && [[ -s X ]]` used 7+ places. `-s` already implies existence; redundant `-f` masks intent.

## Consolidation — same job, N implementations

| Duplicate | Locations | Consolidation |
| --- | --- | --- |
| Tool-name extraction | combos.sh, logger.sh, executor.sh | One `q_extract_tool_binary` in `core.sh` (always sourced). Delete the other two. |
| Target type-check + substitution | runner.sh, tmux.sh | Shared `_q_target_fill` helper |
| Output parsing | promote.sh + `q_parse_output` in session.sh | One `output-parse` module (or file) |
| Placeholder walk | `q_fill_vars`, `q_fill_vars_auto`, `q_unresolved_vars` | One walk taking an ordered `resolvers[]` list |
| ANSI strip | inlined in 5 helpers | Every helper sources `core.sh`; use `q_strip_ansi` |
| KV-file loading (`while IFS== read`) | 4 places in variables.sh | `_q_load_kv_file PATH ARRAY` |
| `q_author_add` + `q_author_add_from_template` | authoring.sh | Merge — 90% identical, only interactive command entry differs |
| Subcommand dispatch preamble | `q` main (24 places) | `_q_bootstrap LIB…` |
| Helper preamble | 10 emitted `.q_*.sh` in search.sh | Standard preamble emitter — this alone would have prevented the Ctrl+M regression |

**~600 lines saveable through consolidation.**

## Bolted-on subsystems — candidates for removal

Not dead (they work), but not core to the Ctrl+Q workflow and never mentioned in recent iterations:

| Subsystem | Size | Status |
| --- | --- | --- |
| `lib/chains.sh` + `chains/*.yaml` + `q chain …` | ~350 + 12 files | YAML chain runner. `when:` gates on session vars. Never triggered in recent testing. |
| `lib/tmux.sh` + `q tmux …` | ~430 lines | Q-managed tmux session with 3-pane layout + custom bindings. Distinct from the widget popup in `install.sh` (which stays). |
| External sync sources | already deleted — see above | — |

Both duplicate a small function with runner.sh (`_q_runner_fill_target` / `_q_tmux_runner_fill` — verbatim copies).

**Recommendation**: drop both from the bash tree. The Go port ignores them. If either is missed, they can be recovered from git history (`git show pre-modify-delete-chain:lib/tmux.sh`). Combined: **~800 lines removed.**

---

## Cleanup order — what I'm doing now

Safe, non-destructive:

1. `q_extract_tool_binary` → core.sh. Delete the two duplicates. Update the modify helper to use it.
2. Standard helper preamble in search.sh — every emitted `.q_*.sh` sources the same 6 libs.
3. Delete `_q_compatible_target_types`, `q_builder_emit_index_rows`, `__BUILDER__:*` handling, `.builder_tool` rm, dead `q_promote_after_run` / `q_log_start` fallbacks.
4. Fix `local` inside case bodies in `q` main.
5. Fix `q config get` to source config file first.
6. Merge `q_author_add` + `q_author_add_from_template`.
7. Delete `lib/sync.sh` + `q sync` dispatch + sync help section.

Held for user call:

- `lib/chains.sh` and `lib/tmux.sh` removal — significant subsystems, both work today. Say the word if you want them gone; otherwise they stay in the bash tree but aren't in the Go port scope.

---

## Go port scope

**Port:** parser, index, search (with fzf as subprocess), variables/fill, builder, combos, executor, config, path-check.

**Skip:** sync (dropped), chains (unless user asks), tmux subsystem (widget popup stays as install.sh's tmux config).

**New in Go:** the two-function split — `q_pick_existing` and `q_compose_new` as clean, separate entry points; both feed the same fill → confirm → run pipeline.

**Delivery model:** the Go port lands in a `go/` subdirectory in this same repo. Bash version stays working during transition. When Go reaches parity, the bash tree can be removed (or kept as `bash/` for the "hackable" audience). Standalone binary — no runtime deps except `fzf`.

**Realistic timeline:** 1–2 weeks focused, or 3–4 weeks incremental. Not one session. Tonight: scaffold + parser + index in Go, staged as WIP.
