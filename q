#!/usr/bin/env bash
# q — Fast, keyboard-driven command launcher for Kali Linux pentesters
# Usage: q [query], q --inline [query], q set/get/session/add/targets/history/rebuild
set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve Q_ROOT to the directory containing this script (follows symlinks)
# ---------------------------------------------------------------------------
Q_ROOT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
Q_VERSION="1.0.0"
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
    for lib in parser.sh search.sh variables.sh executor.sh session.sh; do
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
