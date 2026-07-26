#!/usr/bin/env bash
# session.sh — Session management, targets, clipboard, variable history
# Sourced by the main `q` script; not meant to be executed directly.

# ===========================================================================
# Session directory helpers
# ===========================================================================

# Returns the path to the current session directory, creating it if needed.
# Caches the result in _Q_SESSION_DIR_CACHE to avoid repeated subshell forks.
# The cache is invalidated when Q_SESSION_NAME changes (e.g., q session use).
q_session_dir() {
    if [[ "${_Q_SESSION_DIR_CACHE_KEY:-}" == "$Q_SESSION_NAME" ]] && [[ -n "${_Q_SESSION_DIR_CACHE:-}" ]]; then
        printf '%s' "$_Q_SESSION_DIR_CACHE"
        return 0
    fi
    local dir="${Q_SESSION_DIR}/${Q_SESSION_NAME}"
    [[ -d "$dir" ]] || mkdir -p "$dir"
    _Q_SESSION_DIR_CACHE="$dir"
    _Q_SESSION_DIR_CACHE_KEY="$Q_SESSION_NAME"
    printf '%s' "$dir"
}

# ===========================================================================
# _q_file_prepend — atomically prepend a line to a file, removing duplicates
# ===========================================================================
# Usage: _q_file_prepend FILE LINE [MAX_LINES]
# Removes exact duplicates of LINE, prepends it, and caps at MAX_LINES.
_q_file_prepend() {
    local file="$1" line="$2" max_lines="${3:-0}"
    local tmp="${file}.tmp"
    touch "$file"

    grep -vxF "$line" "$file" > "$tmp" 2>/dev/null || true
    if [[ "$max_lines" -gt 0 ]]; then
        { printf '%s\n' "$line"; head -"$((max_lines - 1))" "$tmp"; } > "$file"
    else
        { printf '%s\n' "$line"; cat "$tmp"; } > "$file"
    fi
    rm -f "$tmp"
}

# ===========================================================================
# Session variable management (KEY=VALUE plain text)
# ===========================================================================

# Save a KEY=VALUE pair to the session vars file.
# Updates in place if the key already exists; appends otherwise.
q_session_set() {
    local var="$1" value="$2"
    local vars_file
    vars_file="$(q_session_dir)/vars"
    touch "$vars_file"

    # Use awk for exact key match (avoids regex injection from var names)
    if awk -F= -v k="$var" '$1 == k { found=1; exit } END { exit !found }' "$vars_file" 2>/dev/null; then
        local tmp="${vars_file}.tmp"
        awk -F= -v k="$var" '$1 != k' "$vars_file" > "$tmp" 2>/dev/null || true
        printf '%s=%s\n' "$var" "$value" >> "$tmp"
        mv "$tmp" "$vars_file"
    else
        printf '%s=%s\n' "$var" "$value" >> "$vars_file"
    fi
    q_success "Session [${Q_SESSION_NAME}]: ${var}=${value}"
}

# Print all session vars formatted (for `q ls`).
q_session_list_vars() {
    local vars_file
    vars_file="$(q_session_dir)/vars"
    [[ -f "$vars_file" ]] && [[ -s "$vars_file" ]] || return 0
    printf '%s%sVars [%s]:%s\n' "$Q_BOLD" "$Q_CYAN" "$Q_SESSION_NAME" "$Q_RESET" >&2
    local line key val
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        key="${line%%=*}"
        val="${line#*=}"
        printf '  %s%-12s%s %s\n' "$Q_DIM" "$key" "$Q_RESET" "$val" >&2
    done < "$vars_file"
}

# Read a value for the given key from the session vars file.
# Outputs the value to stdout. Returns empty string if not found.
q_session_get() {
    local var="$1"
    local vars_file
    vars_file="$(q_session_dir)/vars"

    if [[ -f "$vars_file" ]]; then
        # Use awk for exact key match (avoids regex injection)
        local val
        val="$(awk -F= -v k="$var" '$1 == k { sub(/^[^=]*=/, ""); print; exit }' "$vars_file")"
        if [[ -n "$val" ]]; then
            printf '%s' "$val"
            return 0
        fi
    fi
    return 1
}

# ===========================================================================
# Session lifecycle
# ===========================================================================

# Create a new named session directory and switch to it.
q_session_create() {
    local name="$1"
    if [[ -z "$name" ]]; then
        q_error "Session name cannot be empty."
        return 1
    fi

    local dir="${Q_SESSION_DIR}/${name}"
    if [[ -d "$dir" ]]; then
        q_warn "Session '${name}' already exists."
    else
        mkdir -p "$dir"
        q_success "Created session '${name}'."
    fi

    q_session_use "$name"
}

# Switch the active session by writing the name to a marker file.
q_session_use() {
    local name="$1"
    local dir="${Q_SESSION_DIR}/${name}"

    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        q_info "Created new session '${name}'."
    fi

    printf '%s' "$name" > "${Q_DATA_DIR}/.active_session"
    Q_SESSION_NAME="$name"
    # Invalidate session dir cache
    _Q_SESSION_DIR_CACHE_KEY=""
    export Q_SESSION_NAME
    q_success "Switched to session '${name}'."

    # Show a quick tail of what was last running so the user recalls where they
    # were. Opt out with Q_SESSION_USE_TAIL=0 in ~/.config/q/config.sh.
    if [[ "${Q_SESSION_USE_TAIL:-1}" != "0" ]]; then
        if _q_history_tail 5; then
            printf '  %sRun `q session replay` to step through them.%s\n' \
                "$Q_DIM" "$Q_RESET" >&2
        fi
    fi
}

# List all session directories.
q_session_list() {
    if [[ ! -d "$Q_SESSION_DIR" ]]; then
        q_info "No sessions found."
        return 0
    fi

    local active
    active="$(<"${Q_DATA_DIR}/.active_session" 2>/dev/null)" || active="default"

    printf '%s%sSessions:%s\n' "$Q_BOLD" "$Q_CYAN" "$Q_RESET" >&2
    local name dir
    for dir in "${Q_SESSION_DIR}"/*/; do
        [[ -d "$dir" ]] || continue
        # Use parameter expansion instead of $(basename ...) subshell
        name="${dir%/}"
        name="${name##*/}"
        if [[ "$name" == "$active" ]]; then
            printf '  %s* %-20s%s (active)\n' "$Q_GREEN" "$name" "$Q_RESET" >&2
        else
            printf '    %-20s\n' "$name" >&2
        fi
    done
}

# Remove the current session's data (targets, vars, history).
q_session_purge() {
    local name="${1:-$Q_SESSION_NAME}"
    local dir="${Q_SESSION_DIR}/${name}"

    if [[ ! -d "$dir" ]]; then
        q_error "Session '${name}' does not exist."
        return 1
    fi

    rm -rf "$dir"
    q_success "Purged session '${name}'."

    # If we purged the active session, fall back to default
    if [[ "$name" == "$Q_SESSION_NAME" ]]; then
        Q_SESSION_NAME="default"
        printf '%s' "default" > "${Q_DATA_DIR}/.active_session"
        q_info "Active session reset to 'default'."
    fi
}

# ===========================================================================
# Target classification and management
# ===========================================================================

# Classify a value into a target type using pure bash regex.
# Outputs one of: url, ip, cidr, domain, file, str
q_classify_target() {
    local value="$1"

    # URL: starts with http:// or https://
    if [[ "$value" =~ ^https?:// ]]; then
        printf 'url'
        return 0
    fi

    # CIDR: IP/prefix notation
    if [[ "$value" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]+$ ]]; then
        printf 'cidr'
        return 0
    fi

    # IP: four octets
    if [[ "$value" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        printf 'ip'
        return 0
    fi

    # Domain: contains dots and looks like a hostname
    if [[ "$value" =~ ^[a-zA-Z0-9]([a-zA-Z0-9._-]*[a-zA-Z0-9])?\.[a-zA-Z]{2,}$ ]]; then
        printf 'domain'
        return 0
    fi

    # File path: starts with /, ./, or ~/
    if [[ "$value" =~ ^(/|\.\/|~/) ]]; then
        printf 'file'
        return 0
    fi

    printf 'str'
}

# Add a target to the session's targets file. Deduplicates.
# Usage: q_target_add VALUE SOURCE
q_target_add() {
    local value="$1" source="${2:-manual}"
    local ttype
    ttype="$(q_classify_target "$value")"

    local targets_file
    targets_file="$(q_session_dir)/targets"
    local entry="${ttype}:${value}"

    local existed=false
    [[ -f "$targets_file" ]] && grep -qxF "$entry" "$targets_file" 2>/dev/null && existed=true

    _q_file_prepend "$targets_file" "$entry"

    if [[ "$existed" == true ]]; then
        q_info "Target updated (moved to top): ${ttype}:${value}"
    else
        q_success "Target added [${source}]: ${ttype}:${value}"
    fi
}

# Remove a target by value. If value is empty, open an fzf multi-select picker.
q_target_remove() {
    local value="$1"
    local targets_file
    targets_file="$(q_session_dir)/targets"
    [[ -f "$targets_file" ]] || { q_warn "No targets."; return 0; }

    # Helper: remove an exact "type:value" entry. Splits on first colon only.
    _q_remove_by_value() {
        local v="$1"
        local tmp="${targets_file}.tmp"
        # Match value after first colon exactly (not substring)
        awk -F: -v v="$v" '{
            line = $0
            sub(/^[^:]*:/, "", line)
            if (line != v) print $0
        }' "$targets_file" > "$tmp" 2>/dev/null || true
        mv "$tmp" "$targets_file"
    }

    if [[ -z "$value" ]]; then
        # Interactive multi-select — show full entries so user knows type
        local selected
        selected="$(fzf --multi --prompt="Remove targets> " \
            --header="TAB: multi-select, Enter: confirm" < "$targets_file")" || return 0
        [[ -z "$selected" ]] && return 0
        while IFS= read -r entry; do
            [[ -z "$entry" ]] && continue
            local v="${entry#*:}"
            _q_remove_by_value "$v"
            q_success "Removed: $entry"
        done <<< "$selected"
    else
        # Exact match on value after first colon
        if awk -F: -v v="$value" '{ l=$0; sub(/^[^:]*:/,"",l); if (l==v) { found=1; exit } } END { exit !found }' "$targets_file"; then
            _q_remove_by_value "$value"
            q_success "Removed: $value"
        else
            q_warn "Target not found: $value"
        fi
    fi
}

# Clear all targets in the current session (truncates the targets file).
q_session_clear_targets() {
    local targets_file
    targets_file="$(q_session_dir)/targets"
    if [[ -f "$targets_file" ]]; then
        : > "$targets_file"
        q_success "Cleared all targets in session '${Q_SESSION_NAME}'."
    fi
}

# List targets, optionally filtered by type. MRU order (most recent at top).
q_target_list() {
    local filter_type="${1:-}"
    local targets_file
    targets_file="$(q_session_dir)/targets"

    if [[ ! -f "$targets_file" ]] || [[ ! -s "$targets_file" ]]; then
        q_info "No targets in session '${Q_SESSION_NAME}'."
        return 0
    fi

    printf '%s%sTargets [%s]:%s\n' "$Q_BOLD" "$Q_CYAN" "$Q_SESSION_NAME" "$Q_RESET" >&2
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local ttype="${line%%:*}"
        local tvalue="${line#*:}"
        if [[ -n "$filter_type" ]] && [[ "$ttype" != "$filter_type" ]]; then
            continue
        fi
        printf '  %s%-8s%s %s\n' "$Q_DIM" "$ttype" "$Q_RESET" "$tvalue" >&2
    done < "$targets_file"
}

# ===========================================================================
# Clipboard helpers
# ===========================================================================

# Detect the available clipboard backend.
# Prints one of: pb, xclip, xsel, wl, tmux, or returns 1 if none available.
_q_clip_backend() {
    if command -v pbcopy &>/dev/null; then
        printf 'pb'
    elif [[ -n "${DISPLAY:-}" ]] && command -v xclip &>/dev/null; then
        printf 'xclip'
    elif [[ -n "${DISPLAY:-}" ]] && command -v xsel &>/dev/null; then
        printf 'xsel'
    elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-paste &>/dev/null; then
        printf 'wl'
    elif [[ -n "${TMUX:-}" ]]; then
        printf 'tmux'
    else
        return 1
    fi
}

# Returns 0 if clipboard can be accessed, 1 otherwise.
q_clipboard_available() {
    _q_clip_backend &>/dev/null
}

# Read clipboard content. Returns 1 if no clipboard tool is available.
q_clipboard_read() {
    local backend
    backend="$(_q_clip_backend)" || return 1

    local content=""
    case "$backend" in
        pb)    content="$(pbpaste 2>/dev/null)" || true ;;
        xclip) content="$(xclip -selection clipboard -o 2>/dev/null)" || true ;;
        xsel)  content="$(xsel --clipboard --output 2>/dev/null)" || true ;;
        wl)    content="$(wl-paste --no-newline 2>/dev/null)" || true ;;
        tmux)  content="$(tmux show-buffer 2>/dev/null)" || true ;;
    esac

    # Trim leading/trailing whitespace
    content="${content#"${content%%[![:space:]]*}"}"
    content="${content%"${content##*[![:space:]]}"}"

    if [[ -z "$content" ]]; then
        return 1
    fi

    printf '%s' "$content"
}

# Write text to the system clipboard. Returns 1 if no clipboard tool is available.
q_clipboard_write() {
    local text="$1"
    local backend
    backend="$(_q_clip_backend)" || return 1

    case "$backend" in
        pb)    printf '%s' "$text" | pbcopy 2>/dev/null ;;
        xclip) printf '%s' "$text" | xclip -selection clipboard 2>/dev/null ;;
        xsel)  printf '%s' "$text" | xsel --clipboard --input 2>/dev/null ;;
        wl)    printf '%s' "$text" | wl-copy 2>/dev/null ;;
        tmux)  tmux set-buffer "$text" 2>/dev/null ;;
    esac
}

# ===========================================================================
# Variable history (per-type, deduplicated, max 20 entries)
# ===========================================================================

# Add a value to the history file for the given type.
# Keeps max 20 entries, most recent first, deduplicated.
q_var_history_add() {
    local vtype="$1" value="$2"
    local hist_file="${Q_VAR_HISTORY_DIR}/${vtype}"
    mkdir -p "$Q_VAR_HISTORY_DIR"
    _q_file_prepend "$hist_file" "$value" 20
}

# ===========================================================================
# MRU — most-recently-used command titles (cross-session, global)
# ===========================================================================
# Stored as plain text in ${Q_DATA_DIR}/mru. One title per line, MRU first.
# Capped at 50 entries. Used by search.sh to float recent commands to top.

q_mru_file() {
    printf '%s/mru' "$Q_DATA_DIR"
}

q_mru_add() {
    local title="$1"
    [[ -z "$title" ]] && return 0
    local mru_file
    mru_file="$(q_mru_file)"
    mkdir -p "$(dirname "$mru_file")"
    _q_file_prepend "$mru_file" "$title" 50
}

# ===========================================================================
# Discovery store — data extracted from command output
# ===========================================================================
# Stores discovered data per type (ports, domains, urls, ips, users, etc.)
# in session-scoped files so it feeds into future variable suggestions.
#
# File layout: sessions/<name>/discovered/<type>  (one value per line)

_q_discovery_dir() {
    local dir
    dir="$(q_session_dir)/discovered"
    [[ -d "$dir" ]] || mkdir -p "$dir"
    printf '%s' "$dir"
}

# Add one or more values to a discovery type. Deduplicates, keeps max 100.
q_discover_add() {
    local dtype="$1"
    shift
    local dfile
    dfile="$(_q_discovery_dir)/${dtype}"
    touch "$dfile"

    local value
    for value in "$@"; do
        [[ -z "$value" ]] && continue
        # Deduplicate: skip if already exists
        grep -qxF "$value" "$dfile" 2>/dev/null && continue
        printf '%s\n' "$value" >> "$dfile"
    done

    # Cap at 100 entries — use mapfile to count lines without a subshell
    local -a _lines
    mapfile -t _lines < "$dfile"
    if [[ ${#_lines[@]} -gt 100 ]]; then
        printf '%s\n' "${_lines[@]: -100}" > "$dfile"
    fi
}

# Read discovered values for a type. Returns one per line.
q_discover_get() {
    local dtype="$1"
    local dfile
    dfile="$(_q_discovery_dir)/${dtype}"
    [[ -f "$dfile" ]] && [[ -s "$dfile" ]] && cat "$dfile"
}

# ===========================================================================
# Output parser — extract useful data from command output
# ===========================================================================
# Called after every command execution. Parses stdout for IPs, ports,
# domains, URLs, and stores them in the discovery store.

q_parse_output() {
    local output="$1"
    local cmd="$2"

    # Determine which tool ran (first word, skip sudo/env)
    # Use bash word splitting + parameter expansion instead of awk + basename
    local -a _words
    read -ra _words <<< "$cmd"
    local tool="" _w
    for _w in "${_words[@]}"; do
        [[ "$_w" == *=* ]] && continue
        [[ "$_w" == "sudo" ]] && continue
        tool="$_w"
        break
    done
    tool="${tool##*/}"

    # --- Extract open ports (nmap, masscan, naabu output) ---
    # Matches patterns like: 80/tcp, 443/open, 22/tcp open
    local ports
    ports="$(printf '%s' "$output" | "${Q_GREP_P:-grep}" -oP '\b(\d{1,5})/(?:tcp|udp)' | cut -d/ -f1 | sort -un)" || true
    if [[ -n "$ports" ]]; then
        local -a port_arr
        mapfile -t port_arr <<< "$ports"
        q_discover_add "ports" "${port_arr[@]}"
        # Also save a comma-joined port list for convenience
        local joined
        joined="$(printf '%s,' "${port_arr[@]}")"
        joined="${joined%,}"
        q_discover_add "port_lists" "$joined"
    fi

    # --- Extract IPs ---
    local ips
    ips="$(printf '%s' "$output" | "${Q_GREP_P:-grep}" -oP '\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d?\d)\b' | sort -un)" || true
    if [[ -n "$ips" ]]; then
        local -a ip_arr
        mapfile -t ip_arr <<< "$ips"
        # Filter out common noise: 0.0.0.0, 127.0.0.1, 255.255.255.255
        local -a clean_ips=()
        local ip
        for ip in "${ip_arr[@]}"; do
            case "$ip" in
                0.0.0.0|127.0.0.1|255.255.255.255) continue ;;
                *) clean_ips+=("$ip") ;;
            esac
        done
        [[ ${#clean_ips[@]} -gt 0 ]] && q_discover_add "ips" "${clean_ips[@]}"
    fi

    # --- Extract URLs ---
    local urls
    urls="$(printf '%s' "$output" | "${Q_GREP_P:-grep}" -oP 'https?://[^\s"'"'"'<>\\]+' | sort -u | head -50)" || true
    if [[ -n "$urls" ]]; then
        local -a url_arr
        mapfile -t url_arr <<< "$urls"
        q_discover_add "urls" "${url_arr[@]}"
    fi

    # --- Extract domains/subdomains ---
    # Match FQDN patterns but exclude common noise
    local domains
    domains="$(printf '%s' "$output" | "${Q_GREP_P:-grep}" -oP '\b[a-zA-Z0-9]([a-zA-Z0-9-]*\.)+[a-zA-Z]{2,}\b' | \
        grep -v -E '^\d+\.\d+\.\d+\.\d+$' | \
        grep -v -E '\.(txt|md|sh|py|js|json|xml|html|css|jpg|png|gif|pdf|zip|gz|tar)$' | \
        sort -u | head -50)" || true
    if [[ -n "$domains" ]]; then
        local -a dom_arr
        mapfile -t dom_arr <<< "$domains"
        q_discover_add "domains" "${dom_arr[@]}"
    fi

    # --- Tool-specific parsing ---
    case "$tool" in
        nmap)
            # Extract hostnames from nmap output (e.g., "Nmap scan report for hostname (ip)")
            local nmap_hosts
            nmap_hosts="$(printf '%s' "$output" | "${Q_GREP_P:-grep}" -oP 'scan report for \K[^\s(]+' | sort -u)" || true
            [[ -n "$nmap_hosts" ]] && {
                local -a nh_arr; mapfile -t nh_arr <<< "$nmap_hosts"
                q_discover_add "domains" "${nh_arr[@]}"
            }
            # Extract service info
            local services
            services="$(printf '%s' "$output" | "${Q_GREP_P:-grep}" -oP '^\d+/tcp\s+open\s+\S+' | sort -u)" || true
            [[ -n "$services" ]] && {
                local -a svc_arr; mapfile -t svc_arr <<< "$services"
                q_discover_add "services" "${svc_arr[@]}"
            }
            ;;
        subfinder|amass|assetfinder|findomain)
            # These tools output one subdomain per line
            local subs
            subs="$(printf '%s' "$output" | "${Q_GREP_P:-grep}" -oP '^[a-zA-Z0-9]([a-zA-Z0-9.-]*\.[a-zA-Z]{2,})$' | sort -u)" || true
            [[ -n "$subs" ]] && {
                local -a sub_arr; mapfile -t sub_arr <<< "$subs"
                q_discover_add "domains" "${sub_arr[@]}"
            }
            ;;
        httpx)
            # httpx outputs URLs, often with status codes
            local httpx_urls
            httpx_urls="$(printf '%s' "$output" | "${Q_GREP_P:-grep}" -oP 'https?://[^\s\[\]]+' | sort -u)" || true
            [[ -n "$httpx_urls" ]] && {
                local -a hu_arr; mapfile -t hu_arr <<< "$httpx_urls"
                q_discover_add "urls" "${hu_arr[@]}"
            }
            ;;
        ffuf|gobuster|feroxbuster|dirsearch)
            # Directory discovery — extract found paths/URLs
            local found_paths
            found_paths="$(printf '%s' "$output" | "${Q_GREP_P:-grep}" -oP 'https?://[^\s\[\]]+' | sort -u)" || true
            [[ -n "$found_paths" ]] && {
                local -a fp_arr; mapfile -t fp_arr <<< "$found_paths"
                q_discover_add "urls" "${fp_arr[@]}"
            }
            ;;
        crackmapexec|cme|nxc)
            # Extract usernames from CME output (pattern: domain\username or [+] username)
            local cme_users
            cme_users="$(printf '%s' "$output" | "${Q_GREP_P:-grep}" -oP '(?<=\\\\)\S+(?=\s)' | sort -u)" || true
            [[ -n "$cme_users" ]] && {
                local -a cu_arr; mapfile -t cu_arr <<< "$cme_users"
                q_discover_add "users" "${cu_arr[@]}"
            }
            ;;
        hydra|john|hashcat)
            # Extract cracked credentials
            local creds
            creds="$(printf '%s' "$output" | "${Q_GREP_P:-grep}" -oP '(?<=password: )\S+|(?<=\$\S{1,20}\$\S+ )\S+' | sort -u)" || true
            [[ -n "$creds" ]] && {
                local -a cr_arr; mapfile -t cr_arr <<< "$creds"
                q_discover_add "passwords" "${cr_arr[@]}"
            }
            ;;
    esac
}

# ===========================================================================
# Command history log
# ===========================================================================
# history.log is a TSV: <YYYY-mm-dd HH:MM:SS>\t<rc>\t<duration_sec>\t<command>
# Legacy files (2-field: ts + command) are still readable — every reader in
# executor.sh / session.sh treats a 2-field row as "unknown rc, unknown dur".
# Callers should pass rc + duration when they have them (the executor and the
# chain runner do) so `q session replay` can filter and colour-code entries.

# q_history_log CMD [EXIT_CODE] [DURATION_SEC] — append one entry to
# ${session_dir}/history.log. Missing rc/duration become "-".
q_history_log() {
    local command="$1"
    local exit_code="${2:--}"
    local duration="${3:--}"
    local log_file
    log_file="$(q_session_dir)/history.log"
    # Sanitise: tabs would split fields, newlines would break the record. Both
    # can arrive via Ctrl+E multi-line edits or pasted commands. Replace them
    # so history.log stays strictly single-line-per-entry.
    command="${command//$'\t'/ }"
    command="${command//$'\n'/ ; }"
    # printf %(...)T builtin avoids a $(date ...) fork.
    local ts
    printf -v ts '%(%Y-%m-%d %H:%M:%S)T' -1
    printf '%s\t%s\t%s\t%s\n' "$ts" "$exit_code" "$duration" "$command" >> "$log_file"
}

# _q_history_split LINE → sets shell vars ts / rc / dur / cmd from LINE.
# Handles both new (4-field) and legacy (2-field) rows. Missing fields → "-".
# Uses prefix-strip so the last field absorbs any residual tabs the writer
# didn't sanitise (defensive — old rows may pre-date the sanitiser).
_q_history_split() {
    local line="$1"
    # Count tabs to distinguish new (≥3 tabs, 4 fields) from legacy (1 tab).
    local only_tabs="${line//[^$'\t']/}"
    if [[ ${#only_tabs} -ge 3 ]]; then
        ts="${line%%$'\t'*}";  line="${line#*$'\t'}"
        rc="${line%%$'\t'*}";  line="${line#*$'\t'}"
        dur="${line%%$'\t'*}"; cmd="${line#*$'\t'}"
    else
        ts="${line%%$'\t'*}"; rc="-"; dur="-"; cmd="${line#*$'\t'}"
    fi
}

# _q_history_status_sym RC → sets `sym` and `color` shell vars for a bullet.
# ✓ green for rc=0, • dim for unknown, ✗ red for anything else.
_q_history_status_sym() {
    case "$1" in
        0) sym="✓"; color="$Q_GREEN" ;;
        -) sym="•"; color="$Q_DIM"   ;;
        *) sym="✗"; color="$Q_RED"   ;;
    esac
}

# _q_history_tail [N] — print the last N history rows with rc-colored bullets.
# Returns 1 (nothing printed) if the log doesn't exist or is empty so callers
# can gate a follow-up hint.
_q_history_tail() {
    local n="${1:-5}"
    local log_file
    log_file="$(q_session_dir)/history.log"
    [[ -f "$log_file" ]] && [[ -s "$log_file" ]] || return 1
    printf '%s%sLast %d in [%s]:%s\n' "$Q_BOLD" "$Q_CYAN" "$n" "$Q_SESSION_NAME" "$Q_RESET" >&2
    local line ts rc dur cmd sym color
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        _q_history_split "$line"
        _q_history_status_sym "$rc"
        printf '  %s%s%s  %s%s%s  %s\n' \
            "$color" "$sym" "$Q_RESET" \
            "$Q_DIM" "$ts" "$Q_RESET" \
            "$cmd" >&2
    done < <(tail -n "$n" "$log_file")
}

# q_session_replay [--yes|-y] [N] — walk the last N history entries in
# chronological order and offer to re-run each. Default N=10. Per entry:
#   [y] run   [n] skip   [e] edit-then-run   [a] abort replay
# --yes runs them all without prompting (dangerous — use with care).
# Requires executor.sh sourced (uses _q_execute + _q_edit_command).
q_session_replay() {
    local auto=0 n=10
    while (( $# > 0 )); do
        case "$1" in
            --yes|-y) auto=1 ;;
            [0-9]*)   n="$1" ;;
            *)        q_error "Usage: q session replay [--yes] [N]"; return 1 ;;
        esac
        shift
    done
    # The [0-9]* glob accepts "10abc" — validate the digits strictly.
    if ! [[ "$n" =~ ^[0-9]+$ ]] || (( n < 1 )); then
        q_error "N must be a positive integer (got '$n')."
        return 1
    fi
    # Refuse to run interactively without a TTY (cron, CI, non-interactive
    # SSH, `< /dev/null`). Otherwise a failed read + empty case would silently
    # auto-run every entry — the opposite of a safe default. Explicit --yes
    # is still required to acknowledge auto-run.
    if [[ "$auto" -ne 1 ]]; then
        if ! { [[ -r /dev/tty ]] && [[ -w /dev/tty ]] && [[ -t 0 ]]; }; then
            q_error "q session replay needs a TTY — re-run with --yes to auto-run."
            return 1
        fi
    fi
    local log_file
    log_file="$(q_session_dir)/history.log"
    if [[ ! -f "$log_file" ]] || [[ ! -s "$log_file" ]]; then
        q_info "No history for session '${Q_SESSION_NAME}' — nothing to replay."
        return 0
    fi
    local -a lines
    mapfile -t lines < <(tail -n "$n" "$log_file")
    if [[ ${#lines[@]} -eq 0 ]]; then
        q_info "No history entries in the last $n rows."
        return 0
    fi
    printf '%s%sReplaying last %d in [%s]%s\n' \
        "$Q_BOLD" "$Q_CYAN" "${#lines[@]}" "$Q_SESSION_NAME" "$Q_RESET" >&2
    local i=0 line ts rc dur cmd sym color key extra
    for line in "${lines[@]}"; do
        [[ -z "$line" ]] && continue
        i=$((i+1))
        _q_history_split "$line"
        _q_history_status_sym "$rc"
        extra=""
        [[ "$dur" != "-" ]] && extra=" ${Q_DIM}(last ran in ${dur}s)${Q_RESET}"
        printf '\n%s[%d/%d]%s  %s%s%s  %s%s%s%s\n' \
            "$Q_BOLD" "$i" "${#lines[@]}" "$Q_RESET" \
            "$color" "$sym" "$Q_RESET" \
            "$Q_DIM" "$ts" "$Q_RESET" \
            "$extra" >&2
        printf '    %s%s%s\n' "$Q_GREEN" "$cmd" "$Q_RESET" >&2
        if [[ "$auto" -eq 1 ]]; then
            key="y"
        else
            # Drain any stale bytes left in the tty buffer.
            while read -rsn1 -t 0.05 _ < /dev/tty 2>/dev/null; do :; done
            # Enter defaults to SKIP (safe default when reviewing history —
            # re-firing scans/hydras on muscle-memory Enter is exactly what
            # we don't want). Explicit y required to run.
            printf '%s[Enter]%s Skip  %s[y]%s Run  %s[e]%s Edit  %s[a]%s Abort  \n' \
                "$Q_BOLD" "$Q_RESET" "$Q_BOLD" "$Q_RESET" \
                "$Q_BOLD" "$Q_RESET" "$Q_BOLD" "$Q_RESET" >&2
            read -rsn1 key < /dev/tty || key=""
            printf '\n' >&2
        fi
        case "$key" in
            y|Y)
                # Q_REPLAY hints q_pre_exec_check to auto-skip missing binaries
                # (a nested [y/N] between replay prompts is confusing UX).
                Q_REPLAY=1 _q_execute "$cmd" || true
                ;;
            e|E)
                if declare -f _q_edit_command >/dev/null 2>&1; then
                    local edited
                    edited="$(_q_edit_command "$cmd")"
                    if [[ -z "$edited" ]]; then
                        q_info "Empty after edit — skipped."
                    else
                        [[ "$edited" == *"{{"* ]] && \
                            q_warn "Edited command still has {{...}} placeholders — running literally."
                        Q_REPLAY=1 _q_execute "$edited" || true
                    fi
                else
                    q_warn "Edit helper not sourced — skipping."
                fi
                ;;
            a|A|q|Q) q_info "Aborted replay."; return 0 ;;
            n|N|"")  q_info "Skipped." ;;
            *)       q_info "Skipped." ;;
        esac
    done
    q_success "Replay finished."
}
