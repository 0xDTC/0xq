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
# Perl-regex-capable grep. GNU grep has -P; BSD/macOS grep does not, but
# `brew install grep` provides ggrep. Discovery patterns (q promote) use -P;
# they are all `|| true`-guarded so a plain-grep fallback degrades gracefully.
# ===========================================================================
if printf 'x' | grep -qP 'x' 2>/dev/null; then
    Q_GREP_P="grep"
elif command -v ggrep >/dev/null 2>&1 && printf 'x' | ggrep -qP 'x' 2>/dev/null; then
    Q_GREP_P="ggrep"
else
    Q_GREP_P="grep"
fi
export Q_GREP_P

# ===========================================================================
# Portable hash command — first whitespace field is the digest. Linux has
# md5sum; macOS has md5 (bare hash on stdin); fall back to shasum, then cksum.
# ===========================================================================
if command -v md5sum >/dev/null 2>&1; then Q_HASH="md5sum"
elif command -v md5 >/dev/null 2>&1; then Q_HASH="md5"
elif command -v shasum >/dev/null 2>&1; then Q_HASH="shasum"
else Q_HASH="cksum"; fi
export Q_HASH

# Portable file mtime in epoch seconds. GNU stat uses -c '%Y'; BSD/macOS stat
# uses -f '%m'. GNU stat has --version; BSD does not.
if stat --version >/dev/null 2>&1; then
    q_mtime() { stat -c '%Y' "$1" 2>/dev/null || echo 0; }
else
    q_mtime() { stat -f '%m' "$1" 2>/dev/null || echo 0; }
fi

# List files newest-first — portable replacement for GNU `find -printf '%T@ %p'`.
# Usage: q_ls_newest DIR MAXDEPTH NAMEGLOB   (MAXDEPTH may be empty for no limit)
q_ls_newest() {
    local dir="$1" depth="$2" glob="$3" f
    find "$dir" ${depth:+-maxdepth "$depth"} -type f -name "$glob" 2>/dev/null \
        | while IFS= read -r f; do printf '%s\t%s\n' "$(q_mtime "$f")" "$f"; done \
        | sort -k1,1nr | cut -f2-
}

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
    # Literal ESC byte, not \x1b — the latter is a GNU-sed extension that BSD/
    # macOS sed treats literally (leaving the escape codes in place).
    local esc; esc="$(printf '\033')"
    if [[ $# -gt 0 ]]; then
        printf '%s' "$1" | sed "s/${esc}\[[0-9;]*m//g"
    else
        sed "s/${esc}\[[0-9;]*m//g"
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

    local os; os="$(uname)"
    local missing_hard=()
    local missing_opt=()
    local cmd

    for cmd in "${!hard_deps[@]}"; do
        command -v "$cmd" &>/dev/null || missing_hard+=("${hard_deps[$cmd]}")
    done

    for cmd in "${!opt_deps[@]}"; do
        # macOS: `bat` satisfies `batcat`, and pbcopy (built in) satisfies xclip.
        [[ "$cmd" == batcat ]] && command -v bat &>/dev/null && continue
        [[ "$cmd" == xclip && "$os" == Darwin ]] && command -v pbcopy &>/dev/null && continue
        command -v "$cmd" &>/dev/null || missing_opt+=("${opt_deps[$cmd]}")
    done

    # Combine everything that needs installing
    local all_missing=("${missing_hard[@]}" "${missing_opt[@]}")

    if [[ ${#all_missing[@]} -gt 0 ]]; then
        # macOS: don't run a package manager on every invocation — guide via brew.
        if [[ "$os" == Darwin ]]; then
            if [[ ${#missing_hard[@]} -gt 0 ]]; then
                q_error "Missing required dependencies: ${missing_hard[*]}"
                q_error "Install them with:  brew install ${missing_hard[*]}"
                exit 1
            fi
            if [[ ${#missing_opt[@]} -gt 0 ]]; then
                q_warn "Optional packages not installed: ${missing_opt[*]}"
                q_warn "For full features:  brew install ${missing_opt[*]}"
            fi
            if command -v batcat &>/dev/null; then Q_PREVIEWER="batcat"
            elif command -v bat &>/dev/null; then Q_PREVIEWER="bat"
            else Q_PREVIEWER="cat"; fi
            export Q_PREVIEWER
            return 0
        fi

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
# q_config_keys — canonical list of user-settable Q_* knobs
# ===========================================================================
# Ordered for readability; used by `q config list/get/set`. Anything not on
# this list can still be set manually in ~/.config/q/config.sh — the list
# just controls what the CLI surfaces.
_q_config_keys() {
    printf '%s\n' \
        Q_CONFIRM_EXEC \
        Q_FZF_OPTS \
        Q_PREVIEW_SIZE \
        Q_PREVIEW_POS \
        Q_SESSION_NAME \
        Q_SESSION_USE_TAIL \
        Q_OS_FILTER \
        Q_CLIPBOARD_CANDIDATE \
        Q_FILE_MAXDEPTH \
        Q_FILE_MAXCOUNT \
        Q_HOME_MAXDEPTH \
        Q_HOME_MAXCOUNT
}

# ===========================================================================
# q_config — list / get / set knobs in ~/.config/q/config.sh
# ===========================================================================
q_config() {
    local sub="${1:-list}"
    local cfg="${HOME}/.config/q/config.sh"
    mkdir -p "$(dirname "$cfg")"; touch "$cfg"

    case "$sub" in
        list)
            printf '%s%sConfig%s  %s\n' "$Q_BOLD" "$Q_CYAN" "$Q_RESET" "$cfg" >&2
            local k v src
            while IFS= read -r k; do
                v="${!k:-}"
                if grep -qE "^[[:space:]]*(export[[:space:]]+)?${k}=" "$cfg" 2>/dev/null; then
                    src="user"
                else
                    src="default"
                fi
                printf '  %s%-20s%s %s%s%s  %s(%s)%s\n' \
                    "$Q_BOLD" "$k" "$Q_RESET" \
                    "$Q_GREEN" "${v:-<unset>}" "$Q_RESET" \
                    "$Q_DIM" "$src" "$Q_RESET"
            done < <(_q_config_keys)
            ;;
        get)
            [[ -z "${2:-}" ]] && { q_error "Usage: q config get NAME"; return 1; }
            local key="${2^^}"
            [[ "$key" == Q_* ]] || key="Q_${key}"
            printf '%s\n' "${!key:-}"
            ;;
        set)
            [[ $# -lt 3 ]] && { q_error "Usage: q config set NAME VALUE"; return 1; }
            local key="${2^^}" val="$3"
            [[ "$key" == Q_* ]] || key="Q_${key}"
            # Strip existing line for this key, append new one. Portable
            # in-place edit (BSD/GNU sed differ on -i argument shape).
            local tmp="${cfg}.tmp.$$"
            grep -vE "^[[:space:]]*(export[[:space:]]+)?${key}=" "$cfg" > "$tmp" 2>/dev/null || true
            printf '%s=%q\n' "$key" "$val" >> "$tmp"
            mv "$tmp" "$cfg"
            q_success "${key}=${val}  →  ${cfg}"
            ;;
        unset)
            [[ -z "${2:-}" ]] && { q_error "Usage: q config unset NAME"; return 1; }
            local key="${2^^}"
            [[ "$key" == Q_* ]] || key="Q_${key}"
            local tmp="${cfg}.tmp.$$"
            grep -vE "^[[:space:]]*(export[[:space:]]+)?${key}=" "$cfg" > "$tmp" 2>/dev/null || true
            mv "$tmp" "$cfg"
            q_success "unset ${key} in ${cfg}"
            ;;
        path)
            printf '%s\n' "$cfg"
            ;;
        *)
            q_error "Unknown config subcommand: ${sub}"
            q_error "Valid: list, get NAME, set NAME VALUE, unset NAME, path"
            return 1
            ;;
    esac
}

# ===========================================================================
# q_lint — cross-file duplicate command detection
# ===========================================================================
# Normalises each command (collapse whitespace, drop {{VAR:type:default}}
# metadata leaving just VAR) and groups by that key. Any group with >1
# source file is reported. Useful after a big content sweep to catch the
# "same command in multiple cheatsheets" the user flagged.
q_lint() {
    local index_file="${Q_CACHE_DIR}/index.tsv"
    if [[ ! -s "$index_file" ]]; then
        q_error "Index empty. Run: q rebuild"
        return 1
    fi
    local dupes
    dupes="$(awk -F'\t' '
        {
            cmd = $5
            # Strip placeholder metadata so {{FOO:str:bar}} and {{FOO:file:baz}}
            # collide. IMPORTANT: replace with a sentinel that does NOT match
            # the {{...}} pattern (otherwise the loop rematches the replacement
            # forever). [[NAME]] fits the bill.
            while (match(cmd, /\{\{[A-Za-z_][A-Za-z0-9_]*[^}]*\}\}/)) {
                token = substr(cmd, RSTART, RLENGTH)
                inner = substr(token, 3, length(token) - 4)
                colon = index(inner, ":")
                name  = (colon > 0) ? substr(inner, 1, colon - 1) : inner
                cmd = substr(cmd, 1, RSTART - 1) "[[" name "]]" substr(cmd, RSTART + RLENGTH)
            }
            gsub(/[[:space:]]+/, " ", cmd)
            sub(/^[[:space:]]+/, "", cmd); sub(/[[:space:]]+$/, "", cmd)
            key = cmd
            count[key]++
            if (files[key] == "") files[key] = $9 ":" $3
            else                  files[key] = files[key] "\n    " $9 ":" $3
            keep[key] = cmd
        }
        END {
            for (k in count) if (count[k] > 1) {
                printf "─── x%d ───\n  cmd:  %s\n  seen: %s\n\n", count[k], keep[k], files[k]
            }
        }
    ' "$index_file")"
    if [[ -z "$dupes" ]]; then
        q_success "No cross-file duplicate commands found."
        return 0
    fi
    printf '%s%sDuplicate commands (same normalized template in >1 file):%s\n\n' \
        "$Q_BOLD" "$Q_YELLOW" "$Q_RESET" >&2
    printf '%s' "$dupes"
    local groups
    groups="$(printf '%s' "$dupes" | grep -c '^─── ')"
    printf '\n%s%d duplicate group(s).%s\n' "$Q_DIM" "$groups" "$Q_RESET" >&2
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
    q config [list|get|set]     Manage config knobs (~/.config/q/config.sh)
    q lint                      Report cross-file duplicate commands
    q --os {windows|linux|any}  Filter cheatsheets by target OS (once)
    q --version, -v             Print version
    q --help, -h                Show this help

${Q_BOLD}KEYBINDING${Q_RESET}
    Ctrl+Q                      Launch q inline (after install.sh sets up widget)

${Q_BOLD}CONFIGURATION${Q_RESET}
    ${Q_DIM}~/.config/q/config.sh${Q_RESET}      User overrides (Q_CONFIRM_EXEC, Q_FZF_OPTS, etc.)
    ${Q_DIM}OXQ_SESSION=name${Q_RESET}            Environment variable to auto-select session

HELP
}
