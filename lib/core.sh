#!/usr/bin/env bash
# core.sh — Shared constants, colors, logging, dependency checks, and config
# Sourced by the main `q` script; not meant to be executed directly.

# ===========================================================================
# Directory constants
# ===========================================================================
Q_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/q"
# Honor a pre-set Q_CACHE_DIR (lets tests isolate the cache); default in-repo.
Q_CACHE_DIR="${Q_CACHE_DIR:-${Q_ROOT}/cache}"
Q_SHEETS_DIR="${Q_ROOT}/cheatsheets"
Q_SESSION_DIR="${Q_DATA_DIR}/sessions"
Q_VAR_HISTORY_DIR="${Q_DATA_DIR}/var_history"

export Q_DATA_DIR Q_CACHE_DIR Q_SHEETS_DIR Q_SESSION_DIR Q_VAR_HISTORY_DIR

# ===========================================================================
# ANSI color constants
# ===========================================================================
if [[ -t 2 ]]; then
    Q_RED=$'\033[0;31m'
    Q_GREEN=$'\033[0;32m'
    Q_YELLOW=$'\033[0;33m'
    Q_BLUE=$'\033[0;34m'
    Q_MAGENTA=$'\033[0;35m'
    Q_CYAN=$'\033[0;36m'
    Q_DIM=$'\033[2m'
    Q_BOLD=$'\033[1m'
    Q_RESET=$'\033[0m'
else
    Q_RED='' Q_GREEN='' Q_YELLOW='' Q_BLUE=''
    Q_CYAN='' Q_MAGENTA='' Q_DIM='' Q_BOLD='' Q_RESET=''
fi

export Q_RED Q_GREEN Q_YELLOW Q_BLUE Q_CYAN Q_MAGENTA Q_DIM Q_BOLD Q_RESET

# ===========================================================================
# q_strip_ansi — remove ANSI escape codes from stdin or argument
# ===========================================================================
q_strip_ansi() {
    if [[ $# -gt 0 ]]; then
        printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g'
    else
        sed 's/\x1b\[[0-9;]*m//g'
    fi
}

# ===========================================================================
# Logging helpers (all output goes to stderr to keep stdout clean for data)
# ===========================================================================
q_info()    { printf '%s[*]%s %s\n' "$Q_BLUE"    "$Q_RESET" "$*" >&2; }
q_warn()    { printf '%s[!]%s %s\n' "$Q_YELLOW"  "$Q_RESET" "$*" >&2; }
q_error()   { printf '%s[-]%s %s\n' "$Q_RED"     "$Q_RESET" "$*" >&2; }
q_success() { printf '%s[+]%s %s\n' "$Q_GREEN"   "$Q_RESET" "$*" >&2; }

# ===========================================================================
# q_check_deps — verify required and optional external tools
# ===========================================================================
q_check_deps() {
    # --- Hard dependencies (command -> apt package name) ------------------
    local -A hard_deps=(
        [fzf]="fzf"
        [awk]="gawk"
        [sed]="sed"
        [grep]="grep"
    )

    # --- Optional dependencies (command -> apt package name) --------------
    local -A opt_deps=(
        [xclip]="xclip"
        [batcat]="bat"
    )

    local missing_hard=()
    local missing_opt=()
    local cmd

    for cmd in "${!hard_deps[@]}"; do
        command -v "$cmd" &>/dev/null || missing_hard+=("${hard_deps[$cmd]}")
    done

    for cmd in "${!opt_deps[@]}"; do
        command -v "$cmd" &>/dev/null || missing_opt+=("${opt_deps[$cmd]}")
    done

    # Combine everything that needs installing
    local all_missing=("${missing_hard[@]}" "${missing_opt[@]}")

    if [[ ${#all_missing[@]} -gt 0 ]]; then
        q_info "Missing packages: ${all_missing[*]}"
        q_info "Attempting auto-install..."

        # Skip apt-get update if it was run within the last hour
        local _apt_stamp="/var/lib/apt/lists/partial"
        local _apt_stale=true
        if [[ -d "$_apt_stamp" ]]; then
            local -i _now _mtime
            printf -v _now '%(%s)T' -1
            _mtime="$(stat -c '%Y' "$_apt_stamp" 2>/dev/null)" || _mtime=0
            (( _now - _mtime < 3600 )) && _apt_stale=false
        fi

        local installed=false
        if command -v sudo &>/dev/null; then
            if { [[ "$_apt_stale" == false ]] || sudo apt-get update -qq 2>/dev/null; } && \
               sudo apt-get install -y -qq "${all_missing[@]}" 2>/dev/null; then
                installed=true
                q_success "Installed: ${all_missing[*]}"
            fi
        elif [[ "$(id -u)" -eq 0 ]]; then
            if { [[ "$_apt_stale" == false ]] || apt-get update -qq 2>/dev/null; } && \
               apt-get install -y -qq "${all_missing[@]}" 2>/dev/null; then
                installed=true
                q_success "Installed: ${all_missing[*]}"
            fi
        fi

        if [[ "$installed" != true ]]; then
            # Auto-install failed — check if hard deps are still missing
            local still_missing=()
            for cmd in "${!hard_deps[@]}"; do
                command -v "$cmd" &>/dev/null || still_missing+=("${hard_deps[$cmd]}")
            done
            if [[ ${#still_missing[@]} -gt 0 ]]; then
                q_error "Missing required dependencies: ${still_missing[*]}"
                q_error "Install them with:  sudo apt install ${still_missing[*]}"
                exit 1
            fi
            # Optional deps missing is fine — just warn
            if [[ ${#missing_opt[@]} -gt 0 ]]; then
                q_warn "Optional packages not installed: ${missing_opt[*]}"
                q_warn "For full features:  sudo apt install ${missing_opt[*]}"
            fi
        fi
    fi

    # --- Detect previewer (re-check after install) ------------------------
    if command -v batcat &>/dev/null; then
        Q_PREVIEWER="batcat"
    elif command -v bat &>/dev/null; then
        Q_PREVIEWER="bat"
    else
        Q_PREVIEWER="cat"
    fi
    export Q_PREVIEWER
}

# ===========================================================================
# q_ensure_dirs — create data/cache directories if they don't exist
# ===========================================================================
q_ensure_dirs() {
    mkdir -p "$Q_DATA_DIR" "$Q_SESSION_DIR" "$Q_VAR_HISTORY_DIR" "$Q_CACHE_DIR"
}

# ===========================================================================
# q_config_load — load user config, then apply defaults for anything unset
# ===========================================================================
q_config_load() {
    local config_file="${HOME}/.config/q/config.sh"
    if [[ -f "$config_file" ]]; then
        # shellcheck source=/dev/null
        source "$config_file"
    fi

    # Defaults — user config can override any of these
    Q_CONFIRM_EXEC="${Q_CONFIRM_EXEC:-yes}"
    Q_FZF_OPTS="${Q_FZF_OPTS:---height=80% --border --reverse --cycle}"
    Q_PREVIEW_SIZE="${Q_PREVIEW_SIZE:-40%}"
    # Session priority: env var > already set > persisted file > default
    local _persisted=""
    if [[ -f "${Q_DATA_DIR}/.active_session" ]]; then
        _persisted="$(<"${Q_DATA_DIR}/.active_session")"
    fi
    Q_SESSION_NAME="${OXQ_SESSION:-${Q_SESSION_NAME:-${_persisted:-default}}}"

    export Q_CONFIRM_EXEC Q_FZF_OPTS Q_PREVIEW_SIZE Q_SESSION_NAME
}

# ===========================================================================
# q_help — print usage information
# ===========================================================================
q_help() {
    cat <<HELP
${Q_BOLD}q${Q_RESET} — Fast command launcher for pentesters  ${Q_DIM}v${Q_VERSION}${Q_RESET}

${Q_BOLD}USAGE${Q_RESET}
    q [query]                   Interactive search (default)
    q --inline [query]          Output command string (for shell widget)

${Q_BOLD}SESSION & VARIABLES${Q_RESET}
    q set VAR VALUE             Set a session variable (e.g. RHOST, LPORT)
    q get VAR                   Get a session variable
    q session create NAME       Create a new session
    q session use NAME          Switch — shows tail of last commands
    q session list              List all sessions
    q session purge NAME        Delete a session and its data
    q session history           Full command history for the active session
    q session replay [--yes] [N]   Walk last N history entries; prompt to re-run

${Q_BOLD}TARGETS${Q_RESET}
    q add TARGET                Add a target to the current session
    q targets                   List targets in the current session

${Q_BOLD}FAST SHORTCUTS${Q_RESET}
    q t IP [IP...]              Add target(s) quickly
    q rm [TARGET]               Remove target (fzf picker if no arg)
    q c                         Clear all targets in session
    q ls                        List everything (vars + targets)

${Q_BOLD}DISCOVERY & PROMOTION${Q_RESET}
    q promote                   Promote discovered IPs/domains/URLs to targets

${Q_BOLD}AUTHOR CHEATSHEETS${Q_RESET}
    q new                       Add a command (prompts for vars, description, file)
    q edit                      Edit or delete an existing command (fzf picker)

${Q_BOLD}CHAINS${Q_RESET}
    q chain list                List available command chains
    q chain show NAME           Show steps in a chain
    q chain run NAME [--dry-run] Run a chain (yaml under chains/)

${Q_BOLD}PARALLEL EXECUTION${Q_RESET}
    q run [-j N] CMD            Run CMD against every session target in parallel
    q run --tmux CMD            Same, but one tmux pane per target (live view)
    q run show TARGET           Show last output for TARGET
    q run clean                 Wipe parallel-run output dir

${Q_BOLD}TMUX WORKFLOW${Q_RESET}
    q tmux start [NAME]         Create a tmux session tied to a q session
    q tmux attach [NAME]        Attach (or switch-client if inside tmux)
    q tmux list                 List q-managed tmux sessions
    q tmux kill [NAME]          Kill the tmux session for q session NAME
    q tmux send CMD [PANE]      Paste CMD into the main pane
    q tmux help                 Show tmux key bindings

${Q_BOLD}OUTPUT LOGS${Q_RESET}
    q logs ls [--tool T] [--target V]   List per-target log files
    q logs show TOOL [TARGET]   Cat most recent log for tool/target
    q logs prune [--older-than DAYS] [--keep N]   Trim old logs

${Q_BOLD}CHEATSHEET SYNC${Q_RESET}
    q sync list                 List cheatsheet sources and status
    q sync run [NAME]           Pull cheatsheets from upstream
    q sync add NAME URL         Register a custom source
    q sync disable NAME         Skip a source on sync-all
    q sync remove NAME [--force] Remove a synced source

${Q_BOLD}UTILITY${Q_RESET}
    q history                   Show command execution history
    q rebuild                   Force-rebuild the cheatsheet index cache
    q --version, -v             Print version
    q --help, -h                Show this help

${Q_BOLD}KEYBINDING${Q_RESET}
    Ctrl+Q                      Launch q inline (after install.sh sets up widget)

${Q_BOLD}CONFIGURATION${Q_RESET}
    ${Q_DIM}~/.config/q/config.sh${Q_RESET}      User overrides (Q_CONFIRM_EXEC, Q_FZF_OPTS, etc.)
    ${Q_DIM}OXQ_SESSION=name${Q_RESET}            Environment variable to auto-select session

HELP
}
