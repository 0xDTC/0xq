#!/usr/bin/env bash
# q — Fast, keyboard-driven command launcher for pentesters (Linux + macOS)
# Usage: q [query], q --inline [query], q set/get/session/add/targets/history/rebuild

# Re-exec under bash >= 4 if launched with an older bash (macOS ships 3.2, which
# lacks the associative arrays q uses). Runs fine under 3.2 itself.
if [ -z "${_Q_BASH_REEXEC:-}" ] && [ "${BASH_VERSINFO:-0}" -lt 4 ]; then
    for _qb in /opt/homebrew/bin/bash /usr/local/bin/bash /usr/bin/bash bash; do
        command -v "$_qb" >/dev/null 2>&1 || continue
        _qv="$("$_qb" -c 'echo ${BASH_VERSINFO:-0}' 2>/dev/null || echo 0)"
        if [ "${_qv:-0}" -ge 4 ]; then _Q_BASH_REEXEC=1 exec "$_qb" "$0" "$@"; fi
    done
    printf 'q: needs bash >= 4 (macOS ships 3.2). Install with: brew install bash\n' >&2
    exit 1
fi

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve Q_ROOT to the directory containing this script (follows symlinks).
# Portable substitute for `readlink -f` (BSD/older-macOS readlink lacks -f).
# ---------------------------------------------------------------------------
_q_resolve() {
    local src="$1" dir
    while [ -h "$src" ]; do
        dir="$(cd -P "$(dirname "$src")" >/dev/null 2>&1 && pwd)"
        src="$(readlink "$src")"
        case "$src" in /*) ;; *) src="$dir/$src" ;; esac
    done
    cd -P "$(dirname "$src")" >/dev/null 2>&1 && pwd
}
Q_ROOT="$(_q_resolve "${BASH_SOURCE[0]}")"
Q_VERSION="1.1.0"
export Q_ROOT Q_VERSION

# ---------------------------------------------------------------------------
# Always source the core library (colors, logging, deps, dirs, config)
# ---------------------------------------------------------------------------
# shellcheck source=lib/core.sh
source "${Q_ROOT}/lib/core.sh"

# ---------------------------------------------------------------------------
# q_main — primary search-select-fill-execute flow
# ---------------------------------------------------------------------------
q_main() {
    local inline="${Q_INLINE_MODE:-no}"

    # Optional --os {windows,linux,macos,any} filter. Consumes the flag +
    # value before passing the rest through as the query. Also honors
    # Q_OS_FILTER from the environment / config.sh.
    if [[ "${1:-}" == "--os" ]] && [[ $# -ge 2 ]]; then
        export Q_OS_FILTER="$2"
        shift 2
    fi

    # 1. Ensure the cheatsheet index is built and current
    q_ensure_index

    # 2. Run interactive search (fzf) — returns a TSV line for the selection
    local selected
    selected="$(q_search "$@")" || true

    # 2a. Built-command sideband — Ctrl+B, Ctrl+M, Ctrl+X all write the
    #     ASSEMBLED template to .built_cmd and abort fzf. That template
    #     flows through the same fill path as any picked cheatsheet or
    #     combo. Delete (Ctrl+D) doesn't write here — it just deletes
    #     and returns to a "no selection" state; the user re-opens the
    #     picker to continue.
    local _built_sideband="${Q_CACHE_DIR}/.built_cmd"
    local command title
    if [[ -s "$_built_sideband" ]]; then
        command="$(<"$_built_sideband")"
        rm -f "$_built_sideband"
        title="[built]"
    elif [[ -z "$selected" ]]; then
        q_info "No command selected."
        return 0
    else
        # 3. Extract the raw command template + title from the selection
        title="$(printf '%s' "$selected" | cut -f2)"
        command="$(printf '%s' "$selected" | cut -f3)"
    fi

    # Track this title in the MRU so it floats to top next time
    q_mru_add "$title" 2>/dev/null || true

    # 3a. Auto-pre-fill any {{VAR:choice:...}} whose option value appears in
    #     the user's search query. Lets `q regripper userassist` land the
    #     right command WITH PLUGIN pre-filled and skip the fill picker.
    local _last_query_file="${Q_CACHE_DIR}/.last_query"
    if [[ -s "$_last_query_file" ]]; then
        q_prefill_choices_from_query "$command" "$(<"$_last_query_file")" 2>/dev/null || true
        rm -f "$_last_query_file"
    fi

    # 3b. Combo capture — bump the hit-count for this template under its
    #     tool so future picker sessions can surface "used 42×" combos
    #     alongside cheatsheet entries. Uses the template (with placeholders
    #     intact), NOT the filled command, so re-selection prompts for
    #     today's values instead of pinning yesterday's TARGET/OUT/etc.
    if declare -f q_combo_bump >/dev/null 2>&1; then
        q_combo_bump "$command" 2>/dev/null || true
    fi

    # 4. Ctrl+E requested "edit raw": drop the user straight into $EDITOR with
    #    the raw command (placeholders intact) so they can rewrite the whole
    #    selection — fill vars manually, change flags, add pipes, etc. No
    #    fill prompt runs. Otherwise, auto-fill from session / on-screen picks
    #    and fall back to the interactive fill flow only if a var stays unset.
    local filled_command
    local force_edit="${Q_CACHE_DIR}/.force_edit"

    if [[ -f "$force_edit" ]]; then
        local tmpfile
        tmpfile="$(mktemp /tmp/q_edit_XXXXXX.sh)"
        printf '%s\n' "$command" > "$tmpfile"
        "${EDITOR:-${VISUAL:-nano}}" "$tmpfile" < /dev/tty > /dev/tty 2>&1 || true
        filled_command="$(<"$tmpfile")"
        rm -f "$tmpfile"
        # Ctrl+E hands the raw command over — remind the user if they left any
        # {{VAR}} placeholders unfilled (eval would send them literally).
        if [[ "$filled_command" == *"{{"* ]]; then
            q_warn "Command still has {{...}} placeholders — running it will pass them literally."
        fi
    else
        if ! filled_command="$(q_fill_vars_auto "$command" 2>/dev/null)"; then
            filled_command="$(q_fill_vars "$command")"
        fi
    fi

    # 4b. Path sanity — warn about missing input paths / 0-byte input files
    #     BEFORE either inline output or the confirm-and-run flow so the
    #     Ctrl+Q widget users (whose widget does `2>/dev/null`) still see
    #     the warnings. Output goes to /dev/tty so widget stderr redirects
    #     can't swallow it.
    if declare -f _q_check_paths_in_cmd >/dev/null 2>&1; then
        local _pathchk_out
        _pathchk_out="$(_q_check_paths_in_cmd "$filled_command" 2>&1 || true)"
        if [[ -n "$_pathchk_out" ]] && [[ -w /dev/tty ]]; then
            printf '%s\n' "$_pathchk_out" > /dev/tty
        fi
    fi

    # 5a. Inline mode: print the (possibly edited) command for shell widgets
    if [[ "$inline" == "yes" ]]; then
        printf '%s' "$filled_command"
        rm -f "$force_edit"
        return 0
    fi

    # Clear the sideband flag so it doesn't leak into the next invocation
    rm -f "$force_edit"

    # 5c. Normal mode: confirm and execute.
    #     Pass the pre-fill TEMPLATE too so [s] Save persists the shape
    #     with {{PLACEHOLDERS}} intact (rather than today's concrete values).
    q_confirm_and_run "$filled_command" "$command"
}

# ---------------------------------------------------------------------------
# Source all library files needed for the full pipeline
# ---------------------------------------------------------------------------
q_source_all_libs() {
    local lib
    for lib in parser.sh search.sh variables.sh executor.sh session.sh \
               logger.sh promote.sh chains.sh runner.sh tmux.sh \
               authoring.sh combos.sh builder.sh; do
        if [[ -f "${Q_ROOT}/lib/${lib}" ]]; then
            # shellcheck source=/dev/null
            source "${Q_ROOT}/lib/${lib}"
        fi
    done
}

# ---------------------------------------------------------------------------
# Subcommand dispatch
# ---------------------------------------------------------------------------
case "${1:-}" in

    # -- Version ----------------------------------------------------------
    --version|-v)
        echo "q ${Q_VERSION}"
        exit 0
        ;;

    # -- Help -------------------------------------------------------------
    --help|-h)
        q_help
        exit 0
        ;;

    # -- Inline mode (for Ctrl+Q widget) ---------------------------------
    --inline)
        shift
        q_source_all_libs
        q_check_deps
        q_ensure_dirs
        q_config_load
        Q_INLINE_MODE="yes" q_main "$@"
        exit $?
        ;;

    # -- Session variable: set --------------------------------------------
    set)
        if [[ $# -lt 3 ]]; then
            q_error "Usage: q set VAR VALUE"
            exit 1
        fi
        source "${Q_ROOT}/lib/session.sh"
        q_ensure_dirs
        q_config_load
        q_session_set "$2" "$3"
        exit $?
        ;;

    # -- Session variable: get --------------------------------------------
    get)
        if [[ $# -lt 2 ]]; then
            q_error "Usage: q get VAR"
            exit 1
        fi
        source "${Q_ROOT}/lib/session.sh"
        q_ensure_dirs
        q_config_load
        q_session_get "$2"
        exit $?
        ;;

    # -- Author / edit cheatsheet commands --------------------------------
    new|author)
        q_source_all_libs
        q_check_deps
        q_ensure_dirs
        q_config_load
        q_author_add
        exit $?
        ;;

    edit)
        shift
        q_source_all_libs
        q_check_deps
        q_ensure_dirs
        q_config_load
        q_author_edit "$@"
        exit $?
        ;;

    # -- Session management -----------------------------------------------
    session)
        if [[ $# -lt 2 ]]; then
            q_error "Usage: q session create|use|list|purge|replay|history [args]"
            exit 1
        fi
        source "${Q_ROOT}/lib/session.sh"
        source "${Q_ROOT}/lib/executor.sh"
        q_ensure_dirs
        q_config_load
        subcmd="$2"
        case "$subcmd" in
            create)
                [[ $# -lt 3 ]] && { q_error "Usage: q session create NAME"; exit 1; }
                q_session_create "$3"
                ;;
            use)
                [[ $# -lt 3 ]] && { q_error "Usage: q session use NAME"; exit 1; }
                q_session_use "$3"
                ;;
            list)
                q_session_list
                ;;
            purge)
                [[ $# -lt 3 ]] && { q_error "Usage: q session purge NAME"; exit 1; }
                q_session_purge "$3"
                ;;
            replay)
                shift 2
                q_session_replay "$@"
                ;;
            history)
                q_show_history
                ;;
            *)
                q_error "Unknown session command: ${subcmd}"
                q_error "Valid: create, use, list, purge, replay, history"
                exit 1
                ;;
        esac
        exit $?
        ;;

    # -- Add target -------------------------------------------------------
    add)
        if [[ $# -lt 2 ]]; then
            q_error "Usage: q add TARGET"
            exit 1
        fi
        source "${Q_ROOT}/lib/session.sh"
        q_ensure_dirs
        q_config_load
        q_target_add "$2" "manual"
        exit $?
        ;;

    # -- List targets -----------------------------------------------------
    targets)
        source "${Q_ROOT}/lib/session.sh"
        q_ensure_dirs
        q_config_load
        q_target_list
        exit $?
        ;;

    # -- Command history --------------------------------------------------
    history)
        source "${Q_ROOT}/lib/session.sh"
        source "${Q_ROOT}/lib/executor.sh"
        q_ensure_dirs
        q_config_load
        q_show_history
        exit 0
        ;;

    # -- Rebuild index cache ----------------------------------------------
    rebuild)
        source "${Q_ROOT}/lib/parser.sh"
        q_ensure_dirs
        q_config_load
        q_info "Rebuilding cheatsheet index..."
        q_rebuild_index
        q_success "Index rebuilt."
        exit 0
        ;;

    # -- Config knobs -----------------------------------------------------
    config)
        q_ensure_dirs
        q_config_load
        shift
        q_config "$@"
        exit $?
        ;;

    # -- Cross-file duplicate detection -----------------------------------
    lint)
        source "${Q_ROOT}/lib/parser.sh"
        q_ensure_dirs
        q_config_load
        q_ensure_index >/dev/null 2>&1 || true
        q_lint
        exit $?
        ;;

    # -- Personal combo library (auto-captured on every pick) -------------
    combos|combo)
        source "${Q_ROOT}/lib/combos.sh"
        q_ensure_dirs
        q_config_load
        case "${2:-list}" in
            list)  q_combo_list "${3:-}" ;;
            forget) q_combo_forget "${3:-}" "${4:-}" ;;
            path)  _q_combos_dir; printf '\n' ;;
            *)     q_error "Unknown combos subcommand: ${2}"
                   q_error "Valid: list [TOOL], forget TOOL [TEMPLATE], path"
                   exit 1 ;;
        esac
        exit $?
        ;;

    # -- Interactive flag composer + curated per-user tool selection ------
    build|b)
        q_source_all_libs
        q_check_deps
        q_ensure_dirs
        q_config_load
        case "${2:-list}" in
            add)
                shift 2
                q_builder_add "$@"
                exit $?
                ;;
            rm|remove|disable)
                q_builder_rm "${3:-}"
                exit $?
                ;;
            list|"")
                q_builder_list
                exit 0
                ;;
            *)
                # Treat as a tool name: compose, fill, run.
                # (Plain assignments — `local` is a function-scope keyword
                # and errors under strict-mode bash when used inside a
                # top-level `case` body.)
                _built="$(q_builder_run "$2")"
                if [[ -z "$_built" ]]; then
                    q_info "Builder cancelled."
                    exit 0
                fi
                Q_INLINE_MODE="${Q_INLINE_MODE:-no}"
                if ! _filled="$(q_fill_vars_auto "$_built" 2>/dev/null)"; then
                    _filled="$(q_fill_vars "$_built")"
                fi
                q_combo_bump "$_built" 2>/dev/null || true
                q_confirm_and_run "$_filled"
                exit $?
                ;;
        esac
        ;;

    # -- List enabled builders (alias for `q build list`) -----------------
    builders)
        q_source_all_libs
        q_ensure_dirs
        q_config_load
        q_builder_list
        exit 0
        ;;

    # -- Fast target shortcuts ---------------------------------------------
    t|add-target)
        if [[ $# -lt 2 ]]; then
            q_error "Usage: q t TARGET [TARGET...]"
            exit 1
        fi
        source "${Q_ROOT}/lib/session.sh"
        q_ensure_dirs
        q_config_load
        shift
        for target in "$@"; do
            q_target_add "$target" "manual"
        done
        exit 0
        ;;

    rm|remove)
        source "${Q_ROOT}/lib/session.sh"
        q_ensure_dirs
        q_config_load
        q_target_remove "${2:-}"
        exit $?
        ;;

    c|clear)
        source "${Q_ROOT}/lib/session.sh"
        q_ensure_dirs
        q_config_load
        q_session_clear_targets
        exit 0
        ;;

    ls|list)
        source "${Q_ROOT}/lib/session.sh"
        q_ensure_dirs
        q_config_load
        q_session_list_vars || true
        q_target_list || true
        exit 0
        ;;

    # -- Promote discoveries to targets -----------------------------------
    promote)
        source "${Q_ROOT}/lib/session.sh"
        source "${Q_ROOT}/lib/promote.sh"
        q_ensure_dirs
        q_config_load
        q_promote_discoveries
        exit $?
        ;;

    # -- YAML command chains ----------------------------------------------
    chain)
        source "${Q_ROOT}/lib/session.sh"
        source "${Q_ROOT}/lib/variables.sh"
        source "${Q_ROOT}/lib/executor.sh"
        source "${Q_ROOT}/lib/chains.sh"
        q_ensure_dirs
        q_config_load
        case "${2:-}" in
            list|"")
                q_chain_list
                ;;
            show)
                [[ $# -lt 3 ]] && { q_error "Usage: q chain show NAME"; exit 1; }
                q_chain_show "$3"
                ;;
            run)
                [[ $# -lt 3 ]] && { q_error "Usage: q chain run NAME [--dry-run]"; exit 1; }
                shift 2
                q_chain_run "$@"
                ;;
            *)
                q_error "Unknown chain subcommand: ${2}"
                q_error "Valid: list, show, run"
                exit 1
                ;;
        esac
        exit $?
        ;;

    # -- Parallel multi-target execution ----------------------------------
    run)
        source "${Q_ROOT}/lib/session.sh"
        source "${Q_ROOT}/lib/variables.sh"
        source "${Q_ROOT}/lib/runner.sh"
        q_ensure_dirs
        q_config_load
        shift
        # --tmux backend: spawn one pane per target inside the q tmux session
        if [[ "${1:-}" == "--tmux" ]]; then
            shift
            source "${Q_ROOT}/lib/tmux.sh"
            q_tmux_run_parallel "$@"
            exit $?
        fi
        case "${1:-}" in
            show)
                [[ $# -lt 2 ]] && { q_error "Usage: q run show TARGET"; exit 1; }
                q_run_show "$2"
                ;;
            clean)
                q_run_clean "${2:-}"
                ;;
            *)
                q_run_parallel "$@"
                ;;
        esac
        exit $?
        ;;

    # -- Tmux integration --------------------------------------------------
    tmux)
        source "${Q_ROOT}/lib/session.sh"
        source "${Q_ROOT}/lib/tmux.sh"
        q_ensure_dirs
        q_config_load
        case "${2:-help}" in
            start)
                q_tmux_start "${3:-}"
                ;;
            attach|a)
                q_tmux_attach "${3:-}"
                ;;
            kill)
                q_tmux_kill "${3:-}"
                ;;
            list|ls)
                q_tmux_list
                ;;
            send)
                [[ $# -lt 3 ]] && { q_error "Usage: q tmux send CMD [PANE]"; exit 1; }
                q_tmux_send "$3" "${4:-}"
                ;;
            help|"")
                q_tmux_help
                ;;
            *)
                q_error "Unknown tmux subcommand: ${2}"
                q_error "Valid: start, attach, kill, list, send, help"
                exit 1
                ;;
        esac
        exit $?
        ;;

    # -- Per-target output logs -------------------------------------------
    logs)
        source "${Q_ROOT}/lib/session.sh"
        source "${Q_ROOT}/lib/logger.sh"
        q_ensure_dirs
        q_config_load
        case "${2:-ls}" in
            ls)
                shift 2 2>/dev/null || shift
                q_log_ls "$@"
                ;;
            show)
                [[ $# -lt 3 ]] && { q_error "Usage: q logs show TOOL [TARGET]"; exit 1; }
                q_log_show "$3" "${4:-}"
                ;;
            prune)
                shift 2
                q_log_prune "$@"
                ;;
            *)
                q_error "Unknown logs subcommand: ${2}"
                q_error "Valid: ls, show, prune"
                exit 1
                ;;
        esac
        exit $?
        ;;

    # (removed: `q sync` subsystem — Q_SYNC_BUILTINS was already empty
    #  and the two upstream sources didn't parse as q sheets. See git
    #  history if the mechanism is ever wanted back.)

    # -- Default: main search flow ----------------------------------------
    *)
        q_source_all_libs
        q_check_deps
        q_ensure_dirs
        q_config_load
        q_main "$@"
        exit $?
        ;;
esac
