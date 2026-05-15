#!/usr/bin/env bash
# sync.sh — Sync external cheatsheet repos into cheatsheets/external/<name>/.
# Sourced by the main `q` script; not meant to be executed directly.
# Relies on q_info/q_warn/q_error/q_success and Q_SHEETS_DIR / Q_DATA_DIR from core.sh.

# ===========================================================================
# Built-in sources (name -> url[#subpath])
# Kept intentionally small. Users add their own via $Q_DATA_DIR/sync_sources.
# ===========================================================================
declare -gA Q_SYNC_BUILTINS=(
    [hacktricks]="https://github.com/HackTricks-wiki/hacktricks.git#src"
    [payloads]="https://github.com/swisskyrepo/PayloadsAllTheThings.git"
)

# ===========================================================================
# Internal helpers
# ===========================================================================
_q_sync_user_file() {
    printf '%s/sync_sources' "$Q_DATA_DIR"
}

_q_sync_external_root() {
    printf '%s/external' "$Q_SHEETS_DIR"
}

# Print merged sources, one "name=url" per line.
# User entries override built-ins on name collision.
# Disabled entries (leading '#disabled ') are omitted unless $1=all.
_q_sync_merged() {
    local mode="${1:-active}"
    local user_file
    user_file="$(_q_sync_user_file)"
    declare -A seen=()

    # User entries first — they take precedence.
    if [[ -f "$user_file" ]]; then
        local line
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            if [[ "$line" == \#disabled\ * ]]; then
                if [[ "$mode" == "all" ]]; then
                    local rest="${line#\#disabled }"
                    local name="${rest%%=*}"
                    seen[$name]=1
                    printf '%s\t%s\tdisabled\n' "$name" "${rest#*=}"
                else
                    # remember name so built-in fallback doesn't re-add it
                    local rest="${line#\#disabled }"
                    seen["${rest%%=*}"]=1
                fi
                continue
            fi
            [[ "$line" == \#* ]] && continue
            local name="${line%%=*}"
            local url="${line#*=}"
            [[ -z "$name" || -z "$url" ]] && continue
            seen[$name]=1
            printf '%s\t%s\tactive\n' "$name" "$url"
        done < "$user_file"
    fi

    # Built-ins second, skipping anything the user already defined/disabled.
    local k
    for k in "${!Q_SYNC_BUILTINS[@]}"; do
        [[ -n "${seen[$k]:-}" ]] && continue
        printf '%s\t%s\tactive\n' "$k" "${Q_SYNC_BUILTINS[$k]}"
    done
}

# Split a source value into URL and subpath.
# Sets globals _Q_SYNC_URL and _Q_SYNC_SUB.
_q_sync_split() {
    local value="$1"
    if [[ "$value" == *"#"* ]]; then
        _Q_SYNC_URL="${value%%#*}"
        _Q_SYNC_SUB="${value#*#}"
    else
        _Q_SYNC_URL="$value"
        _Q_SYNC_SUB=""
    fi
}

# Look up a source by name. Echoes "url[#sub]\tactive|disabled" or returns 1.
_q_sync_lookup() {
    local want="$1" name url state
    while IFS=$'\t' read -r name url state; do
        if [[ "$name" == "$want" ]]; then
            printf '%s\t%s\n' "$url" "$state"
            return 0
        fi
    done < <(_q_sync_merged all)
    return 1
}

_q_sync_write_meta() {
    local dest="$1" sha="$2"
    local meta="$dest/.sync_meta"
    {
        printf 'timestamp=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf 'commit=%s\n'    "$sha"
    } > "$meta"
}

# ===========================================================================
# q_sync_list — show all known sources with sync status
# ===========================================================================
q_sync_list() {
    local ext_root
    ext_root="$(_q_sync_external_root)"
    local name url state status_str ts
    printf '%-20s %-10s %-25s %s\n' "NAME" "STATUS" "LAST-SYNC" "URL"
    while IFS=$'\t' read -r name url state; do
        if [[ -d "$ext_root/$name" ]]; then
            status_str="synced"
            if [[ -f "$ext_root/$name/.sync_meta" ]]; then
                ts="$(grep -E '^timestamp=' "$ext_root/$name/.sync_meta" | head -n1 | cut -d= -f2-)"
            else
                ts="-"
            fi
        else
            status_str="not synced"
            ts="-"
        fi
        [[ "$state" == "disabled" ]] && status_str="disabled"
        printf '%-20s %-10s %-25s %s\n' "$name" "$status_str" "$ts" "$url"
    done < <(_q_sync_merged all)
}

# ===========================================================================
# q_sync_add NAME URL
# ===========================================================================
q_sync_add() {
    local name="$1" url="$2"
    if [[ -z "$name" || -z "$url" ]]; then
        q_error "usage: q_sync_add NAME URL"
        return 1
    fi
    mkdir -p "$Q_DATA_DIR"
    local file
    file="$(_q_sync_user_file)"
    # Strip any existing entry (active or disabled) for this name.
    if [[ -f "$file" ]]; then
        local tmp="${file}.tmp.$$"
        grep -v -E "^(#disabled )?${name}=" "$file" > "$tmp" || true
        mv "$tmp" "$file"
    fi
    printf '%s=%s\n' "$name" "$url" >> "$file"
    q_success "Added sync source: $name"
}

# ===========================================================================
# q_sync_disable NAME — mark source disabled so no-arg sync_run skips it
# ===========================================================================
q_sync_disable() {
    local name="$1"
    if [[ -z "$name" ]]; then
        q_error "usage: q_sync_disable NAME"
        return 1
    fi
    mkdir -p "$Q_DATA_DIR"
    local file
    file="$(_q_sync_user_file)"

    # Resolve the URL (user or built-in) so the disabled line preserves it.
    local url=""
    if [[ -f "$file" ]]; then
        local existing
        existing="$(grep -E "^${name}=" "$file" | head -n1)"
        [[ -n "$existing" ]] && url="${existing#*=}"
    fi
    [[ -z "$url" && -n "${Q_SYNC_BUILTINS[$name]:-}" ]] && url="${Q_SYNC_BUILTINS[$name]}"
    if [[ -z "$url" ]]; then
        q_error "Unknown source: $name"
        return 1
    fi

    touch "$file"
    local tmp="${file}.tmp.$$"
    grep -v -E "^(#disabled )?${name}=" "$file" > "$tmp" || true
    mv "$tmp" "$file"
    printf '#disabled %s=%s\n' "$name" "$url" >> "$file"
    q_info "Disabled sync source: $name"
}

# ===========================================================================
# q_sync_remove NAME [--force]
# ===========================================================================
q_sync_remove() {
    local name="" force=false
    local arg
    for arg in "$@"; do
        case "$arg" in
            --force) force=true ;;
            -*)      q_error "unknown flag: $arg"; return 1 ;;
            *)       name="$arg" ;;
        esac
    done
    if [[ -z "$name" ]]; then
        q_error "usage: q_sync_remove NAME [--force]"
        return 1
    fi
    local target
    target="$(_q_sync_external_root)/$name"
    if [[ ! -d "$target" ]]; then
        q_warn "Not synced: $name"
        return 0
    fi
    if [[ "$force" != true ]]; then
        printf 'Remove %s? [y/N] ' "$target" >&2
        local reply
        read -r reply
        [[ "$reply" =~ ^[Yy]$ ]] || { q_info "Aborted"; return 0; }
    fi
    rm -rf "$target"
    q_success "Removed: $name"
}

# ===========================================================================
# q_sync_run [NAME] — clone or pull. No NAME = all active sources.
# ===========================================================================
q_sync_run() {
    if ! command -v git &>/dev/null; then
        q_error "git not found in PATH — required for sync"
        return 1
    fi

    if [[ $# -gt 0 ]]; then
        local target="$1"
        local lookup
        if ! lookup="$(_q_sync_lookup "$target")"; then
            q_error "Unknown source: $target"
            return 1
        fi
        local url state
        IFS=$'\t' read -r url state <<<"$lookup"
        if [[ "$state" == "disabled" ]]; then
            q_warn "Source $target is disabled — re-enable by removing the '#disabled ' line in $(_q_sync_user_file)"
            return 0
        fi
        _q_sync_one "$target" "$url"
        return $?
    fi

    # No arg — iterate active sources only.
    local rc=0 name url state
    while IFS=$'\t' read -r name url state; do
        [[ "$state" == "active" ]] || continue
        _q_sync_one "$name" "$url" || rc=$?
    done < <(_q_sync_merged active)
    return $rc
}

# Internal: sync a single named source.
_q_sync_one() {
    local name="$1" value="$2"
    _q_sync_split "$value"
    local url="$_Q_SYNC_URL" sub="$_Q_SYNC_SUB"
    local ext_root dest
    ext_root="$(_q_sync_external_root)"
    dest="$ext_root/$name"
    mkdir -p "$ext_root"

    if [[ -n "$sub" ]]; then
        # Subpath mode: clone to temp, rsync subpath into dest.
        local tmp="${dest}.tmp.$$"
        rm -rf "$tmp"
        if ! git clone --depth=1 --quiet "$url" "$tmp" 2>/dev/null; then
            rm -rf "$tmp"
            q_error "Failed to clone $url"
            return 1
        fi
        if [[ ! -d "$tmp/$sub" ]]; then
            rm -rf "$tmp"
            q_error "Subpath '$sub' missing in $url"
            return 1
        fi
        local sha
        sha="$(git -C "$tmp" rev-parse HEAD 2>/dev/null || printf 'unknown')"
        mkdir -p "$dest"
        if command -v rsync &>/dev/null; then
            rsync -a --delete \
                --exclude='.sync_meta' \
                "$tmp/$sub/" "$dest/"
        else
            # Fallback: nuke + cp -R.
            find "$dest" -mindepth 1 ! -name '.sync_meta' -exec rm -rf {} + 2>/dev/null
            cp -R "$tmp/$sub/." "$dest/"
        fi
        rm -rf "$tmp"
        _q_sync_write_meta "$dest" "$sha"
        q_success "Synced $name (subpath: $sub)"
        return 0
    fi

    # Full-repo mode.
    if [[ -d "$dest/.git" ]]; then
        if ! git -C "$dest" pull --ff-only --quiet 2>/dev/null; then
            q_error "git pull failed for $name"
            return 1
        fi
    elif [[ -d "$dest" ]]; then
        # Directory exists but isn't a git checkout — reclone cleanly.
        rm -rf "$dest"
        if ! git clone --depth=1 --quiet "$url" "$dest" 2>/dev/null; then
            q_error "Failed to clone $url"
            return 1
        fi
    else
        if ! git clone --depth=1 --quiet "$url" "$dest" 2>/dev/null; then
            q_error "Failed to clone $url"
            return 1
        fi
    fi
    local sha
    sha="$(git -C "$dest" rev-parse HEAD 2>/dev/null || printf 'unknown')"
    _q_sync_write_meta "$dest" "$sha"
    q_success "Synced $name"
}
