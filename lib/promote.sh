#!/usr/bin/env bash
# promote.sh — Discovery -> target bridge + extended output parsers.
#
# Depends on lib/core.sh and lib/session.sh being sourced first
# (provides q_session_dir, q_target_add, q_discover_add, q_discover_get,
#  q_classify_target, q_parse_output, q_info/q_warn/q_success).
#
# DO NOT set -euo pipefail here — this file is sourced into the user's
# shell context and aggressive flags would break callers.

# ===========================================================================
# _q_targets_file — internal helper, prints path to active session targets file
# ===========================================================================
_q_targets_file() {
    printf '%s/targets' "$(q_session_dir)"
}

# ===========================================================================
# _q_target_exists VALUE
# ===========================================================================
# Returns 0 if VALUE already exists in the targets file (matched on the
# value side of "TYPE:VALUE"), 1 otherwise.
_q_target_exists() {
    local value="$1"
    local tfile
    tfile="$(_q_targets_file)"
    [[ -f "$tfile" ]] || return 1
    # Strip "TYPE:" prefix from each line and compare exact.
    awk -F: -v v="$value" '
        {
            line = $0
            sub(/^[^:]*:/, "", line)
            if (line == v) { found = 1; exit }
        }
        END { exit !found }
    ' "$tfile" 2>/dev/null
}

# ===========================================================================
# q_promote_discoveries
# ===========================================================================
# Walk ips / domains / urls discovery files and promote each unseen value to
# a session target via q_target_add (source="promoted"). Skips entries that
# are already targets. Emits a single "Promoted N targets" info line.
q_promote_discoveries() {
    local -a types=(ips domains urls)
    local dtype value count=0

    for dtype in "${types[@]}"; do
        # q_discover_get returns nothing (and a non-zero exit when empty
        # via the [[ -s ]] guard) — capture safely.
        local content=""
        content="$(q_discover_get "$dtype" 2>/dev/null || true)"
        [[ -z "$content" ]] && continue

        while IFS= read -r value; do
            [[ -z "$value" ]] && continue
            if _q_target_exists "$value"; then
                continue
            fi
            # q_target_add classifies + dedupes + writes; suppress its
            # success line to keep promotion noise low. The function's
            # caller still sees the aggregate "Promoted N" message.
            q_target_add "$value" "promoted" >/dev/null 2>&1
            count=$((count + 1))
        done <<< "$content"
    done

    if [[ "${count:-0}" -gt 0 ]]; then
        q_info "Promoted ${count} target(s)"
    fi
}

# ===========================================================================
# q_parse_output_extra OUTPUT CMD
# ===========================================================================
# Supplements q_parse_output (in session.sh) with parsers for types not
# covered there. Conservative regexes — false positives matter more than
# misses. Stores via q_discover_add under: shares, hashes, jwts, ldap_dns,
# titles.
q_parse_output_extra() {
    local output="$1"
    local cmd="${2:-}"

    # Identify the tool (first non-env, non-sudo word).
    local -a _words=()
    read -ra _words <<< "$cmd"
    local tool="" _w
    for _w in "${_words[@]}"; do
        [[ "$_w" == *=* ]] && continue
        [[ "$_w" == "sudo" ]] && continue
        tool="$_w"
        break
    done
    tool="${tool##*/}"

    # ---------------------------------------------------------------------
    # SMB shares (crackmapexec / nxc / smbclient)
    # ---------------------------------------------------------------------
    # Typical crackmapexec/nxc share enumeration line:
    #   SMB   10.0.0.1  445  HOST   ShareName    READ,WRITE    Disk
    #   SMB   10.0.0.1  445  HOST   IPC$         READ          Remote IPC
    # smbclient -L:
    #   Sharename       Type      Comment
    #   IPC$            IPC       Remote IPC
    #   Reports         Disk      Reports share
    #
    # Heuristic: line containing "Disk" or "IPC" as a whole word, with a
    # share-name token. Extract the share-name field.
    case "$tool" in
        crackmapexec|cme|nxc|smbclient|netexec)
            local shares
            shares="$(printf '%s' "$output" | awk '
                # crackmapexec/nxc layout: SMB <ip> <port> <host> <share> <perm> <type>
                /^SMB[[:space:]]/ && ($0 ~ /[[:space:]]Disk([[:space:]]|$)/ || $0 ~ /[[:space:]]IPC([[:space:]]|$)/) {
                    # field 5 is share name on that layout
                    if (NF >= 5) print $5
                    next
                }
                # smbclient layout: <share>    <type>    <comment>
                # match a leading non-space token followed by Disk/IPC.
                /^[^[:space:]]+[[:space:]]+(Disk|IPC)([[:space:]]|$)/ {
                    print $1
                    next
                }
            ' | sed 's/\$$//' | sort -u)" || true
            if [[ -n "$shares" ]]; then
                local -a sh_arr=()
                mapfile -t sh_arr <<< "$shares"
                q_discover_add "shares" "${sh_arr[@]}"
            fi
            ;;
    esac

    # ---------------------------------------------------------------------
    # NTLM / Kerberos hashes
    # ---------------------------------------------------------------------
    # Capture three common formats:
    #   pwdump:  user:rid:lmhash:nthash:::
    #   asreproast / kerberoast: $krb5asrep$..., $krb5tgs$...
    #   raw NT hash with $NT$ prefix (rare but seen)
    local hashes
    # shellcheck disable=SC2016  # literal $krb5 / $NT$ — grep patterns, not shell vars
    hashes="$(printf '%s' "$output" | grep -E \
        -e '^[^[:space:]:]+:[0-9]+:[a-fA-F0-9]{32}:[a-fA-F0-9]{32}:::' \
        -e '\$krb5(asrep|tgs)\$[^[:space:]]+' \
        -e '\$NT\$[a-fA-F0-9]{32}' 2>/dev/null \
        | sort -u | head -50)" || true
    if [[ -n "$hashes" ]]; then
        local -a h_arr=()
        mapfile -t h_arr <<< "$hashes"
        q_discover_add "hashes" "${h_arr[@]}"
    fi

    # ---------------------------------------------------------------------
    # JWT tokens
    # ---------------------------------------------------------------------
    # Three base64url segments joined by dots. Total length >100 to dodge
    # short look-alike strings. Header must start with "ey" (base64url of
    # '{"') — this is the de-facto JWT signature.
    local jwts
    jwts="$(printf '%s' "$output" | grep -oE 'ey[A-Za-z0-9_-]+\.ey[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+' 2>/dev/null \
        | awk 'length($0) > 100' | sort -u | head -20)" || true
    if [[ -n "$jwts" ]]; then
        local -a j_arr=()
        mapfile -t j_arr <<< "$jwts"
        q_discover_add "jwts" "${j_arr[@]}"
    fi

    # ---------------------------------------------------------------------
    # LDAP base DNs
    # ---------------------------------------------------------------------
    # One or more DC= components, optionally preceded by CN= / OU= / etc.
    # We only keep the trailing DC= chain (the base DN) per match.
    local ldap_dns
    ldap_dns="$(printf '%s' "$output" | grep -oE '(DC=[A-Za-z0-9_-]+,?)+(DC=[A-Za-z0-9_-]+)' 2>/dev/null \
        | sed -E 's/,$//' | sort -u | head -20)" || true
    if [[ -n "$ldap_dns" ]]; then
        local -a l_arr=()
        mapfile -t l_arr <<< "$ldap_dns"
        q_discover_add "ldap_dns" "${l_arr[@]}"
    fi

    # ---------------------------------------------------------------------
    # HTML <title> tags
    # ---------------------------------------------------------------------
    # Non-greedy match for content between <title> and </title>, case
    # insensitive on the tag. Trim whitespace per match.
    local titles
    titles="$(printf '%s' "$output" \
        | tr '\n' ' ' \
        | grep -oiE '<title[^>]*>[^<]+</title>' 2>/dev/null \
        | sed -E 's|<[Tt][Ii][Tt][Ll][Ee][^>]*>||; s|</[Tt][Ii][Tt][Ll][Ee]>||; s/^[[:space:]]+//; s/[[:space:]]+$//' \
        | sort -u | head -20)" || true
    if [[ -n "$titles" ]]; then
        local -a t_arr=()
        mapfile -t t_arr <<< "$titles"
        q_discover_add "titles" "${t_arr[@]}"
    fi
}

# ===========================================================================
# q_promote_after_run OUTPUT CMD
# ===========================================================================
# Convenience wrapper meant to be called from the executor after a command
# completes. Runs the base parser (q_parse_output, from session.sh), the
# extended parsers, then promotes discoveries to targets.
#
# The integrator is responsible for wiring this into _q_execute; this lib
# does not modify executor.sh.
q_promote_after_run() {
    local output="$1"
    local cmd="${2:-}"

    q_parse_output "$output" "$cmd" 2>/dev/null || true
    q_parse_output_extra "$output" "$cmd" 2>/dev/null || true
    q_promote_discoveries
}
