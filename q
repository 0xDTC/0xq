#!/usr/bin/env bash
# q — Fast, keyboard-driven command launcher for Kali Linux pentesters
# Usage: q [query], q --inline [query], q set/get/session/add/targets/history/rebuild
set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve Q_ROOT to the directory containing this script (follows symlinks)
# ---------------------------------------------------------------------------
Q_ROOT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
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

    # 1. Ensure the cheatsheet index is built and current
    q_ensure_index

    # 2. Run interactive search (fzf) — returns a TSV line for the selection
    local selected
    selected="$(q_search "$@")" || true
    if [[ -z "$selected" ]]; then
        q_info "No command selected."
        return 0
    fi

    # 3. Extract the raw command template + title from the selection
    local command title
    title="$(printf '%s' "$selected" | cut -f2)"
    command="$(printf '%s' "$selected" | cut -f3)"

    # Track this title in the MRU so it floats to top next time
    q_mru_add "$title" 2>/dev/null || true

    # 4. Try auto-fill from session first; fall back to interactive if
    #    any variable can't be resolved, or if the user pressed Ctrl+F /
    #    Ctrl+E in the main fzf (sideband flags written by q_search).
    local filled_command
    local force_interactive="${Q_CACHE_DIR}/.force_interactive"
    local force_edit="${Q_CACHE_DIR}/.force_edit"

    if [[ -f "$force_interactive" ]] || ! filled_command="$(q_fill_vars_auto "$command" 2>/dev/null)"; then
        filled_command="$(q_fill_vars "$command")"
    fi

    # 5a. Inline mode: print the filled command for shell widget consumption
    if [[ "$inline" == "yes" ]]; then
        printf '%s' "$filled_command"
        rm -f "$force_interactive" "$force_edit"
        return 0
    fi

    # 5b. Ctrl+E requested edit-before-run: pop the command into $EDITOR
    if [[ -f "$force_edit" ]]; then
        local tmpfile
        tmpfile="$(mktemp /tmp/q_edit_XXXXXX.sh)"
        printf '%s\n' "$filled_command" > "$tmpfile"
        "${EDITOR:-${VISUAL:-nano}}" "$tmpfile" < /dev/tty > /dev/tty 2>&1 || true
        filled_command="$(<"$tmpfile")"
        rm -f "$tmpfile"
    fi

    # Clear sideband flags so they don't leak into the next invocation
    rm -f "$force_interactive" "$force_edit"

    # 5c. Normal mode: confirm and execute
    q_confirm_and_run "$filled_command"
}

# ---------------------------------------------------------------------------
# Source all library files needed for the full pipeline
# ---------------------------------------------------------------------------
q_source_all_libs() {
    local lib
    for lib in parser.sh search.sh variables.sh executor.sh session.sh \
               logger.sh promote.sh chains.sh runner.sh sync.sh; do
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

    # -- Session management -----------------------------------------------
    session)
        if [[ $# -lt 2 ]]; then
            q_error "Usage: q session create|use|list|purge NAME"
            exit 1
        fi
        source "${Q_ROOT}/lib/session.sh"
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
            *)
                q_error "Unknown session command: ${subcmd}"
                q_error "Valid: create, use, list, purge"
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

    # -- Cheatsheet sync from upstream repos ------------------------------
    sync)
        source "${Q_ROOT}/lib/session.sh"
        source "${Q_ROOT}/lib/sync.sh"
        q_ensure_dirs
        q_config_load
        case "${2:-run}" in
            list)
                q_sync_list
                ;;
            add)
                [[ $# -lt 4 ]] && { q_error "Usage: q sync add NAME URL"; exit 1; }
                q_sync_add "$3" "$4"
                ;;
            disable)
                [[ $# -lt 3 ]] && { q_error "Usage: q sync disable NAME"; exit 1; }
                q_sync_disable "$3"
                ;;
            remove|rm)
                [[ $# -lt 3 ]] && { q_error "Usage: q sync remove NAME [--force]"; exit 1; }
                q_sync_remove "$3" "${4:-}"
                ;;
            run|"")
                q_sync_run "${3:-}"
                ;;
            *)
                # If second arg looks like a source name, treat it as `q sync run NAME`
                q_sync_run "$2"
                ;;
        esac
        # After a successful sync, drop the index checksum so the next `q`
        # invocation re-indexes including new external sheets.
        rm -f "${Q_CACHE_DIR}/checksum"
        exit $?
        ;;

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
