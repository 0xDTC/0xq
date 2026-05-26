#!/usr/bin/env bash
# logger.sh — Per-target, per-tool, timestamped output logging for q.
# Depends on lib/core.sh + lib/session.sh (q_session_dir, q_classify_target).
# Sourced by the main `q` script; not meant to be executed directly.

# ===========================================================================
# q_log_target_slug — turn a target value into a filesystem-safe directory name
# ===========================================================================
# Rules:
#   url    → strip scheme, replace / : ? & = with _
#   ip     → return literally (dots OK on every modern filesystem)
#   domain → return literally
#   file   → md5 hash, file_<first8>
#   str    → md5 hash, file_<first8>
#   cidr   → return literally (slash → _ to keep it path-safe)
q_log_target_slug() {
    local value="$1"
    local ttype
    ttype="$(q_classify_target "$value")"

    case "$ttype" in
        url)
            # Strip leading scheme then sanitize structural chars
            local stripped="${value#http://}"
            stripped="${stripped#https://}"
            # Replace each of / : ? & = with underscore
            stripped="${stripped//\//_}"
            stripped="${stripped//:/_}"
            stripped="${stripped//\?/_}"
            stripped="${stripped//&/_}"
            stripped="${stripped//=/_}"
            # Strip any trailing underscores to keep dirs tidy
            stripped="${stripped%_}"
            printf '%s' "$stripped"
            ;;
        ip|domain)
            printf '%s' "$value"
            ;;
        cidr)
            printf '%s' "${value//\//_}"
            ;;
        file|str|*)
            local hash
            hash="$(printf '%s' "$value" | md5sum | cut -c1-8)"
            printf 'file_%s' "$hash"
            ;;
    esac
}

# ===========================================================================
# q_log_path TOOL [TARGET] — compute (and create) a timestamped log path
# ===========================================================================
# - TARGET is optional; missing/empty → _unscoped.
# - Creates the parent directory (mkdir -p).
# - Returns the full path on stdout. Does NOT create the file itself.
# - Timestamp regenerated fresh each call.
q_log_path() {
    local tool="$1" target="${2:-}"
    local slug
    if [[ -z "$target" ]]; then
        slug="_unscoped"
    else
        slug="$(q_log_target_slug "$target")"
    fi

    local sdir
    sdir="$(q_session_dir)"
    local dir="${sdir}/runs/${slug}"
    mkdir -p "$dir"

    local ts
    printf -v ts '%(%Y%m%d-%H%M%S)T' -1

    printf '%s/%s-%s.log' "$dir" "$tool" "$ts"
}

# ===========================================================================
# q_log_extract_tool CMD — pull the bare tool name from a full command string
# ===========================================================================
# Skips env-var assignments (FOO=bar) and `sudo`. Also skips short flags
# (tokens starting with `-`) that might appear after sudo. Strips dirname
# and trailing .py / .exe suffixes.
q_log_extract_tool() {
    local cmd="$1"
    # shellcheck disable=SC2206
    local -a words
    read -ra words <<< "$cmd"

    local w tool=""
    for w in "${words[@]}"; do
        # Skip env assignments like FOO=bar
        [[ "$w" == *=* && "$w" != *=*/* && "$w" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] && continue
        # Skip sudo
        [[ "$w" == "sudo" ]] && continue
        # Skip flags
        [[ "$w" == -* ]] && continue
        tool="$w"
        break
    done

    # Strip dirname
    tool="${tool##*/}"
    # Strip .exe / .py suffixes
    tool="${tool%.exe}"
    tool="${tool%.py}"

    printf '%s' "$tool"
}

# ===========================================================================
# q_log_extract_target CMD — best-effort target inference from a command line
# ===========================================================================
# Priority: IPv4 > URL > domain. Empty stdout + non-zero exit if nothing found.
q_log_extract_target() {
    local cmd="$1"

    # 1) IPv4 first
    local ip
    ip="$(printf '%s' "$cmd" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)"
    if [[ -n "$ip" ]]; then
        printf '%s' "$ip"
        return 0
    fi

    # 2) URL
    local url
    url="$(printf '%s' "$cmd" | grep -oE 'https?://[^[:space:]"'"'"'<>\\]+' | head -1)"
    if [[ -n "$url" ]]; then
        printf '%s' "$url"
        return 0
    fi

    # 3) Domain-looking token (has dot, no slash, not bare numeric)
    local tok
    local -a _toks=(); read -ra _toks <<< "$cmd"
    for tok in "${_toks[@]}"; do
        # Skip flags and assignments
        [[ "$tok" == -* ]] && continue
        [[ "$tok" == *=* ]] && continue
        # Must contain a dot, no slash, and at least one alpha char
        [[ "$tok" != *.* ]] && continue
        [[ "$tok" == */* ]] && continue
        [[ "$tok" =~ ^[0-9.]+$ ]] && continue
        # Must look domain-ish: ends in 2+ letter TLD
        if [[ "$tok" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\.[A-Za-z]{2,}$ ]]; then
            printf '%s' "$tok"
            return 0
        fi
    done

    # Nothing found — emit nothing, exit 0 (consumers branch on output, not status)
    return 0
}

# ===========================================================================
# q_log_start CMD — convenience wrapper: extract tool, extract target, path it
# ===========================================================================
q_log_start() {
    local cmd="$1"
    local tool target
    tool="$(q_log_extract_tool "$cmd")"
    target="$(q_log_extract_target "$cmd" 2>/dev/null || true)"

    if [[ -z "$tool" ]]; then
        tool="cmd"
    fi

    q_log_path "$tool" "$target"
}

# ===========================================================================
# q_log_ls [--tool TOOL] [--target VALUE] — list logs newest first
# ===========================================================================
# Output: "<mtime>  <relative_path>  <size>"
q_log_ls() {
    local filter_tool="" filter_target=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tool)   filter_tool="$2"; shift 2 ;;
            --target) filter_target="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local sdir runs_dir
    sdir="$(q_session_dir)"
    runs_dir="${sdir}/runs"

    [[ -d "$runs_dir" ]] || return 0

    # Build slug filter when --target is given
    local target_slug=""
    if [[ -n "$filter_target" ]]; then
        target_slug="$(q_log_target_slug "$filter_target")"
    fi

    # Find all .log files with mtime + size, sort newest first
    # Use find -printf "%T@\t%p\t%s\n" then sort -nr
    local entries
    entries="$(find "$runs_dir" -type f -name '*.log' \
        -printf '%T@\t%p\t%s\n' 2>/dev/null | sort -nr)" || true

    [[ -z "$entries" ]] && return 0

    local ts path size rel target_dir tool_name
    while IFS=$'\t' read -r ts path size; do
        [[ -z "$path" ]] && continue
        rel="${path#"$runs_dir"/}"
        # rel = <target_slug>/<tool>-<ts>.log
        target_dir="${rel%%/*}"
        tool_name="${rel##*/}"           # <tool>-<ts>.log
        tool_name="${tool_name%-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9].log}" # strip trailing -YYYYMMDD-HHMMSS.log
        # Edge case: <tool>.log (no timestamp) — fall back to stripping just .log
        if [[ "$tool_name" == "${rel##*/}" ]]; then
            tool_name="${tool_name%.log}"
        fi

        if [[ -n "$filter_tool" && "$tool_name" != "$filter_tool" ]]; then
            continue
        fi
        if [[ -n "$target_slug" && "$target_dir" != "$target_slug" ]]; then
            continue
        fi

        # Human-readable mtime: trim fractional seconds, format via printf %T
        local secs="${ts%.*}"
        local human
        printf -v human '%(%Y-%m-%d %H:%M:%S)T' "$secs"
        printf '%s\t%s\t%s\n' "$human" "$rel" "$size"
    done <<< "$entries"
}

# ===========================================================================
# q_log_show TOOL [TARGET] — show contents of most recent matching log
# ===========================================================================
q_log_show() {
    local tool="$1" target="${2:-}"
    local sdir runs_dir
    sdir="$(q_session_dir)"
    runs_dir="${sdir}/runs"

    [[ -d "$runs_dir" ]] || return 1

    local search_dir="$runs_dir"
    if [[ -n "$target" ]]; then
        local slug
        slug="$(q_log_target_slug "$target")"
        search_dir="${runs_dir}/${slug}"
        [[ -d "$search_dir" ]] || return 1
    fi

    # Find newest <tool>-*.log under search_dir
    local newest
    newest="$(find "$search_dir" -type f -name "${tool}-*.log" \
        -printf '%T@\t%p\n' 2>/dev/null | sort -nr | head -1 | cut -f2-)"

    [[ -z "$newest" || ! -f "$newest" ]] && return 1

    local previewer="${Q_PREVIEWER:-cat}"
    # bat/batcat take a filename
    if command -v "$previewer" &>/dev/null; then
        "$previewer" "$newest"
    else
        cat "$newest"
    fi
}

# ===========================================================================
# q_log_prune [--older-than DAYS] [--keep N] — clean up old logs
# ===========================================================================
# - With no flags: print stats only, delete nothing.
# - --older-than DAYS: delete files older than DAYS.
# - --keep N: keep only N most recent per <target>/<tool> combo.
# Both flags can be combined; both are applied.
q_log_prune() {
    local older_days="" keep_n=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --older-than) older_days="$2"; shift 2 ;;
            --keep)       keep_n="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local sdir runs_dir
    sdir="$(q_session_dir)"
    runs_dir="${sdir}/runs"
    [[ -d "$runs_dir" ]] || { q_info "No logs to prune."; return 0; }

    local total before_size
    total="$(find "$runs_dir" -type f -name '*.log' 2>/dev/null | wc -l)"
    before_size="$(du -sh "$runs_dir" 2>/dev/null | awk '{print $1}')"

    # No flags → stats only
    if [[ -z "$older_days" && -z "$keep_n" ]]; then
        q_info "Logs: ${total} files, ${before_size} total in ${runs_dir}"
        return 0
    fi

    local deleted=0

    # --older-than DAYS
    if [[ -n "$older_days" ]]; then
        local victim
        while IFS= read -r victim; do
            [[ -z "$victim" ]] && continue
            rm -f "$victim" && deleted=$((deleted + 1))
        done < <(find "$runs_dir" -type f -name '*.log' -mtime "+${older_days}" 2>/dev/null)
    fi

    # --keep N per <target>/<tool>
    if [[ -n "$keep_n" ]]; then
        local target_dir
        for target_dir in "$runs_dir"/*/; do
            [[ -d "$target_dir" ]] || continue

            # Collect unique tool names in this target dir
            local f tool_name
            declare -A _tools_seen=()
            for f in "$target_dir"*.log; do
                [[ -f "$f" ]] || continue
                tool_name="${f##*/}"
                tool_name="${tool_name%-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9].log}"
                _tools_seen[$tool_name]=1
            done

            for tool_name in "${!_tools_seen[@]}"; do
                # Newest-first list of matching logs
                local -a files=()
                mapfile -t files < <(
                    find "$target_dir" -maxdepth 1 -type f -name "${tool_name}-*.log" \
                        -printf '%T@\t%p\n' 2>/dev/null |
                        sort -nr | cut -f2-
                )

                if [[ ${#files[@]} -gt $keep_n ]]; then
                    local victim2
                    for victim2 in "${files[@]:$keep_n}"; do
                        rm -f "$victim2" && deleted=$((deleted + 1))
                    done
                fi
            done
            unset _tools_seen
        done
    fi

    local after_size
    after_size="$(du -sh "$runs_dir" 2>/dev/null | awk '{print $1}')"
    q_info "Pruned ${deleted} file(s). Size: ${before_size} → ${after_size}"
}
