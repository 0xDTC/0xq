#!/usr/bin/env bash
# variables.sh — Variable extraction, interactive fill, and substitution
# Sourced by the main `q` script; not meant to be executed directly.

# ===========================================================================
# q_fill_state_path — transient interactive-fill state file (KEY=value/line)
# ===========================================================================
q_fill_state_path() { printf '%s/.fill_state' "${Q_CACHE_DIR}"; }

# ===========================================================================
# q_extract_vars — parse {{VAR:type:default}} placeholders from a command
# ===========================================================================
# Outputs one line per placeholder: NAME<TAB>TYPE<TAB>DEFAULT
# TYPE defaults to "str", DEFAULT defaults to "". Tab-delimited to handle colons in defaults.
q_extract_vars() {
    local cmd="$1"

    # Extract all {{...}} tokens
    grep -oP '\{\{[^}]+\}\}' <<< "$cmd" | while IFS= read -r placeholder; do
        # Strip the {{ and }}
        local inner="${placeholder#\{\{}"
        inner="${inner%\}\}}"

        # Split on : with care — only the first two colons are delimiters.
        # Everything after the second colon is the default value (which may contain colons).
        local name vtype vdefault
        name="${inner%%:*}"

        local rest="${inner#"$name"}"
        rest="${rest#:}"  # remove leading colon if present

        if [[ -n "$rest" ]]; then
            vtype="${rest%%:*}"
            local rest2="${rest#"$vtype"}"
            rest2="${rest2#:}"
            vdefault="$rest2"
        else
            vtype="str"
            vdefault=""
        fi

        vtype="${vtype:-str}"

        # Use tab as delimiter to avoid conflicts with colons in default values
        printf '%s\t%s\t%s\n' "$name" "$vtype" "$vdefault"
    done
}

# ===========================================================================
# _q_subst_var COMMAND NAME VALUE — replace every {{NAME}}, {{NAME:type}} or
# {{NAME:type:default}} with VALUE, inserted LITERALLY (pure bash string ops,
# no awk/sed/regex) so backslashes and & in Windows paths survive intact.
# ===========================================================================
_q_subst_var() {
    local rest="$1" name="$2" value="$3"
    local open="{{${name}" close="}}" out=""
    while [[ "$rest" == *"$open"* ]]; do
        out+="${rest%%"$open"*}"          # text before {{NAME
        rest="${rest#*"$open"}"           # text after {{NAME
        case "${rest:0:1}" in
            '}'|':')                      # {{NAME}} or {{NAME:...}} -> our var
                rest="${rest#*"$close"}"  # drop through the closing }}
                out+="$value"
                ;;
            *)                            # {{NAMExyz -> a longer name; keep as-is
                out+="$open"
                ;;
        esac
    done
    printf '%s' "${out}${rest}"
}

# ===========================================================================
# q_fill_vars — main entry point: fill all placeholders in a command string
# ===========================================================================
q_fill_vars() {
    local cmd="$1"
    local -A filled_vars    # associative array: VAR_NAME -> value

    # Extract unique variable names (preserve order of first occurrence)
    local vars_raw
    vars_raw="$(q_extract_vars "$cmd")"

    if [[ -z "$vars_raw" ]]; then
        printf '%s' "$cmd"
        return 0
    fi

    local seen_names=""
    local name vtype vdefault
    while IFS=$'\t' read -r name vtype vdefault; do
        [[ -z "$name" ]] && continue

        # Skip duplicates — only process each variable name once
        if [[ " $seen_names " == *" $name "* ]]; then
            continue
        fi
        seen_names="$seen_names $name"

        # 1. Special handling for LHOST — auto-detect
        if [[ "${name^^}" == "LHOST" ]]; then
            local auto_lhost=""
            auto_lhost="$(_q_detect_lhost)"
            if [[ -n "$auto_lhost" ]] && [[ -z "$vdefault" ]]; then
                vdefault="$auto_lhost"
            fi
        fi

        # 2. If there's a session value, pass it as the default (shown as top
        #    candidate in fzf) instead of silently auto-filling
        local session_val=""
        session_val="$(q_session_get "$name" 2>/dev/null)" || true
        if [[ -n "$session_val" ]]; then
            vdefault="$session_val"
        fi

        # 3. Interactive fill — always prompt via fzf
        local value=""
        value="$(q_fill_single_var "$name" "$vtype" "$vdefault")"

        if [[ -z "$value" ]] && [[ -n "$vdefault" ]]; then
            value="$vdefault"
        fi

        filled_vars["$name"]="$value"

        # 4. Persist: add to var history and targets if applicable
        if [[ -n "$value" ]]; then
            local upper_type="${vtype^^}"
            q_var_history_add "$upper_type" "$value"

            # Auto-add to targets if it looks like a target
            case "$upper_type" in
                IP|URL|DOMAIN|TARGET|HOST|RHOST)
                    q_target_add "$value" "fill" 2>/dev/null || true
                    ;;
            esac
            # Also save to session var so it's the top suggestion next time
            q_session_set "$name" "$value" >/dev/null 2>&1 || true
        fi
    done <<< "$vars_raw"

    # Substitute all placeholders with their resolved values
    local result="$cmd"
    for name in "${!filled_vars[@]}"; do
        local value="${filled_vars[$name]}"
        # Replace all variations: {{NAME}}, {{NAME:type}}, {{NAME:type:default}}
        # Use a loop to handle all patterns for this variable name
        # Single-pass replacement via awk to avoid re-scanning substituted text
        result="$(_q_subst_var "$result" "$name" "$value")"
    done

    printf '%s' "$result"
}

# ===========================================================================
# q_fill_vars_auto — non-interactive fill using session values only
# ===========================================================================
# Returns the command with all {{VAR}} placeholders substituted from session
# values (plus LHOST auto-detect and declared defaults). If ANY variable cannot
# be resolved, returns exit code 1 so the caller can fall back to interactive
# q_fill_vars. No fzf prompts are ever shown.
q_fill_vars_auto() {
    local cmd="$1"
    local result="$cmd"

    local vars_raw
    vars_raw="$(q_extract_vars "$cmd")"

    if [[ -z "$vars_raw" ]]; then
        printf '%s' "$cmd"
        return 0
    fi

    # Load transient state files into assoc arrays (highest priority first):
    # .fill_state (on-screen interactive picks) then .target_cycle (Ctrl+T).
    local -A fstate=() cyc=()
    local _sf; _sf="$(q_fill_state_path)"
    if [[ -f "$_sf" ]]; then
        local _l
        while IFS= read -r _l; do
            [[ "$_l" == *=* ]] || continue
            fstate["${_l%%=*}"]="${_l#*=}"
        done < "$_sf"
    fi
    local _cf="${Q_CACHE_DIR}/.target_cycle"
    if [[ -f "$_cf" ]]; then
        local _l
        while IFS= read -r _l; do
            [[ "$_l" == *=* ]] || continue
            cyc["${_l%%=*}"]="${_l#*=}"
        done < "$_cf"
    fi

    local seen_names=""
    local name vtype vdefault
    while IFS=$'\t' read -r name vtype vdefault; do
        [[ -z "$name" ]] && continue

        # Skip duplicates — only process each variable name once
        if [[ " $seen_names " == *" $name "* ]]; then
            continue
        fi
        seen_names="$seen_names $name"

        # Resolution order: fill_state > cycle > session > LHOST auto > default
        local value=""
        if [[ -n "${fstate[$name]:-}" ]]; then
            value="${fstate[$name]}"
        elif [[ -n "${cyc[$name]:-}" ]]; then
            value="${cyc[$name]}"
        else
            value="$(q_session_get "$name" 2>/dev/null)" || value=""
            if [[ -z "$value" ]] && [[ "${name^^}" == "LHOST" ]]; then
                value="$(_q_detect_lhost 2>/dev/null)" || value=""
            fi
            if [[ -z "$value" ]] && [[ -n "$vdefault" ]]; then
                value="$vdefault"
            fi
        fi

        # Still empty — signal the caller to go interactive
        [[ -z "$value" ]] && return 1

        # Substitute all occurrences of this variable via awk
        result="$(_q_subst_var "$result" "$name" "$value")"
    done <<< "$vars_raw"

    printf '%s' "$result"
}

# ===========================================================================
# q_unresolved_vars — print names (one per line) of placeholders in CMD that
# cannot be resolved from .fill_state / .target_cycle / session / LHOST /
# default. Empty output means the command is fully resolvable. Used to gate
# the Enter action (run vs. open the fill picker).
# ===========================================================================
q_unresolved_vars() {
    local cmd="$1"
    local vars_raw; vars_raw="$(q_extract_vars "$cmd")"
    [[ -z "$vars_raw" ]] && return 0

    local -A fstate=() cyc=()
    local _sf; _sf="$(q_fill_state_path)"
    if [[ -f "$_sf" ]]; then
        local _l; while IFS= read -r _l; do [[ "$_l" == *=* ]] && fstate["${_l%%=*}"]="${_l#*=}"; done < "$_sf"
    fi
    local _cf="${Q_CACHE_DIR}/.target_cycle"
    if [[ -f "$_cf" ]]; then
        local _l; while IFS= read -r _l; do [[ "$_l" == *=* ]] && cyc["${_l%%=*}"]="${_l#*=}"; done < "$_cf"
    fi

    local seen="" name vtype vdefault
    while IFS=$'\t' read -r name vtype vdefault; do
        [[ -z "$name" ]] && continue
        if [[ " $seen " == *" $name "* ]]; then continue; fi
        seen="$seen $name"

        [[ -n "${fstate[$name]:-}" ]] && continue
        [[ -n "${cyc[$name]:-}" ]] && continue
        local sv; sv="$(q_session_get "$name" 2>/dev/null)" || sv=""
        [[ -n "$sv" ]] && continue
        [[ "${name^^}" == "LHOST" ]] && _q_detect_lhost &>/dev/null && continue
        [[ -n "$vdefault" ]] && continue
        printf '%s\n' "$name"
    done <<< "$vars_raw"
}

# ===========================================================================
# _q_detect_lhost — auto-detect local IP (prefer tun0, then eth0, fallback)
# ===========================================================================
_q_detect_lhost() {
    local ip=""
    ip="$(ip -4 addr show tun0 2>/dev/null | grep -oP 'inet \K[0-9.]+' | head -1)" && [[ -n "$ip" ]] && { printf '%s' "$ip"; return 0; }
    ip="$(ip -4 addr show eth0 2>/dev/null | grep -oP 'inet \K[0-9.]+' | head -1)" && [[ -n "$ip" ]] && { printf '%s' "$ip"; return 0; }
    ip="$(ip -4 route get 1 2>/dev/null | grep -oP 'src \K[0-9.]+' | head -1)" && [[ -n "$ip" ]] && { printf '%s' "$ip"; return 0; }
    return 1
}

# ===========================================================================
# _q_compatible_target_types — map variable type to compatible target types
# ===========================================================================
_q_compatible_target_types() {
    local vtype="$1"
    case "${vtype^^}" in
        URL)                    echo "url" ;;
        IP)                     echo "ip" ;;
        DOMAIN)                 echo "url domain" ;;
        TARGET|HOST|RHOST)      echo "ip url domain" ;;
        SUBNET|CIDR)            echo "cidr" ;;
        FILE|OUTFILE|OUTPUT_FILE) echo "file" ;;
        *)                      echo "" ;;
    esac
}

# ===========================================================================
# _q_build_candidates — assemble the candidate list for fzf selection
# ===========================================================================
_q_build_candidates() {
    local name="$1" vtype="$2" vdefault="$3"
    local upper_type="${vtype^^}"
    local upper_name="${name^^}"
    local candidates=""

    # --- Pre-compute paths once to avoid repeated subshell forks ---
    # Each $(q_session_dir) call forks a subshell (~2ms). Computing paths
    # inline once and reading files directly saves ~30ms total.
    local sdir
    sdir="$(q_session_dir)"
    local vars_file="${sdir}/vars"
    local targets_file="${sdir}/targets"
    local disc_dir="${sdir}/discovered"

    # --- Session value (top priority — first in list) ---
    # Inline q_session_get to avoid a subshell fork
    local session_val=""
    if [[ -f "$vars_file" ]]; then
        local _sline
        _sline="$(awk -F= -v k="$name" '$1 == k { sub(/^[^=]*=/, ""); print; exit }' "$vars_file")" || true
        [[ -n "$_sline" ]] && session_val="$_sline"
    fi
    if [[ -n "$session_val" ]]; then
        candidates="[session] ${session_val}"$'\n'
    fi

    # --- Clipboard entry (if available and type-compatible) ---
    if q_clipboard_available; then
        local clip=""
        clip="$(q_clipboard_read 2>/dev/null)" || true
        if [[ -n "$clip" ]] && [[ "$clip" != "$session_val" ]]; then
            local clip_compatible=0
            case "$upper_type" in
                STR|TARGET|HOST|RHOST) clip_compatible=1 ;;
                IP)     [[ "$clip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && clip_compatible=1 ;;
                URL)    [[ "$clip" =~ ^https?:// ]] && clip_compatible=1 ;;
                DOMAIN) [[ "$clip" =~ ^[a-zA-Z0-9] ]] && clip_compatible=1 ;;
                PORT|RPORT|LPORT) [[ "$clip" =~ ^[0-9]+$ ]] && clip_compatible=1 ;;
                *)      clip_compatible=1 ;;
            esac
            if [[ "$clip_compatible" -eq 1 ]]; then
                candidates="${candidates}[clipboard] ${clip}"$'\n'
            fi
        fi
    fi

    # --- Default value entry (only if different from session) ---
    if [[ -n "$vdefault" ]] && [[ "$vdefault" != "$session_val" ]]; then
        candidates="${candidates}[default] ${vdefault}"$'\n'
    fi

    # --- Session targets filtered by compatible types ---
    # Inline _q_compatible_target_types to avoid 2 subshell forks
    local compat_types=""
    case "${vtype^^}" in
        URL)                        compat_types="url" ;;
        IP)                         compat_types="ip" ;;
        DOMAIN)                     compat_types="url domain" ;;
        TARGET|HOST|RHOST)          compat_types="ip url domain" ;;
        SUBNET|CIDR)                compat_types="cidr" ;;
        FILE|OUTFILE|OUTPUT_FILE)   compat_types="file" ;;
    esac
    case "$upper_name" in
        URL)                        compat_types="${compat_types} url" ;;
        IP)                         compat_types="${compat_types} ip" ;;
        DOMAIN)                     compat_types="${compat_types} url domain" ;;
        TARGET|HOST|RHOST)          compat_types="${compat_types} ip url domain" ;;
        SUBNET|CIDR)                compat_types="${compat_types} cidr" ;;
        FILE|OUTFILE|OUTPUT_FILE)   compat_types="${compat_types} file" ;;
    esac

    if [[ -n "$compat_types" ]]; then
        if [[ -f "$targets_file" ]] && [[ -s "$targets_file" ]]; then
            while IFS= read -r _tline; do
                [[ -z "$_tline" ]] && continue
                local ttype="${_tline%%:*}"
                local tvalue="${_tline#*:}"
                local ct
                for ct in $compat_types; do
                    if [[ "$ttype" == "$ct" ]]; then
                        candidates="${candidates}[used] ${tvalue}"$'\n'
                        break
                    fi
                done
            done < "$targets_file"
        fi
    fi

    # --- Discovered data from previous command outputs ---
    # Read discovery files directly instead of calling q_discover_get per type.
    # Each q_discover_get call forks 2 nested subshells (_q_discovery_dir ->
    # q_session_dir). Reading files inline saves ~4ms per discovery type.

    # Collect discovery types needed based on variable type AND name
    local -a disc_types=()
    case "$upper_type" in
        PORT)   disc_types+=(ports) ;;
        IP)     disc_types+=(ips) ;;
        URL)    disc_types+=(urls) ;;
        DOMAIN) disc_types+=(domains) ;;
    esac
    case "$upper_name" in
        *PORT*)                                   disc_types+=(ports port_lists) ;;
        *URL*|*ENDPOINT*)                          disc_types+=(urls) ;;
        *DOMAIN*|*HOST*|TARGET)                   disc_types+=(domains ips) ;;
        *USER*)                                   disc_types+=(users) ;;
        *PASS*)                                   disc_types+=(passwords) ;;
    esac

    # Read all needed discovery files directly, tag each line with [new]
    if [[ ${#disc_types[@]} -gt 0 ]]; then
        local dtype dfile
        for dtype in "${disc_types[@]}"; do
            dfile="${disc_dir}/${dtype}"
            if [[ -f "$dfile" ]] && [[ -s "$dfile" ]]; then
                while IFS= read -r _dline; do
                    [[ -n "$_dline" ]] && candidates="${candidates}[new] ${_dline}"$'\n'
                done < "$dfile"
            fi
        done
    fi

    # --- Variable history (tagged [recent]) ---
    # Read the var-history files directly (tagged [recent])
    local hist_file_type="${Q_VAR_HISTORY_DIR}/${upper_type}"
    local hist_file_name="${Q_VAR_HISTORY_DIR}/${upper_name}"

    if [[ -f "$hist_file_type" ]] && [[ -s "$hist_file_type" ]]; then
        while IFS= read -r _hline; do
            [[ -z "$_hline" ]] && continue
            candidates="${candidates}[recent] ${_hline}"$'\n'
        done < "$hist_file_type"
    fi
    if [[ "$upper_name" != "$upper_type" ]] && [[ -f "$hist_file_name" ]] && [[ -s "$hist_file_name" ]]; then
        while IFS= read -r _hline; do
            [[ -z "$_hline" ]] && continue
            candidates="${candidates}[recent] ${_hline}"$'\n'
        done < "$hist_file_name"
    fi

    # --- Type-specific additions ---
    # Wordlist candidates — curated favourites first, then live discovery so
    # the rest of the installed lists surface as real candidates (not just a
    # handful of hardcoded pins).
    if [[ "$upper_type" == "WORDLIST" ]] || [[ "$upper_name" == *WORDLIST* ]]; then
        local -a wordlist_paths=(
            "/usr/share/wordlists/rockyou.txt"
            "/usr/share/seclists/Discovery/Web-Content/common.txt"
            "/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt"
            "/usr/share/seclists/Discovery/Web-Content/raft-medium-words.txt"
            "/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt"
            "/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt"
            "/usr/share/seclists/Usernames/top-usernames-shortlist.txt"
            "/usr/share/wordlists/dirb/common.txt"
            "/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"
        )
        local wp
        for wp in "${wordlist_paths[@]}"; do
            [[ -f "$wp" ]] && candidates="${candidates}${wp}"$'\n'
        done
        # Discover the rest of the common seclists dirs (deduped by the trailing
        # awk). Bounded by -maxdepth 1 so it stays fast.
        local _wl_dir _wl
        for _wl_dir in \
            /usr/share/seclists/Usernames \
            /usr/share/seclists/Passwords/Common-Credentials \
            /usr/share/seclists/Passwords/Leaked-Databases \
            /usr/share/seclists/Discovery/Web-Content \
            /usr/share/seclists/Discovery/DNS; do
            [[ -d "$_wl_dir" ]] || continue
            while IFS= read -r _wl; do
                [[ -n "$_wl" ]] && candidates="${candidates}${_wl}"$'\n'
            done < <(find "$_wl_dir" -maxdepth 1 -type f -name '*.txt' 2>/dev/null | sort)
        done
    fi

    # Network interface candidates
    if [[ "$upper_type" == "IFACE" ]] || [[ "$upper_name" == *IFACE* ]] || [[ "$upper_name" == *INTERFACE* ]]; then
        local ifaces
        ifaces="$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | tr -d ' ')" || true
        if [[ -n "$ifaces" ]]; then
            candidates="${candidates}${ifaces}"$'\n'
        fi
    fi

    # Reverse/bind callback presets — LPORT specifically, ranked before the
    # generic service-port list below so listener ports come first.
    if [[ "$upper_type" == "LPORT" ]] || [[ "$upper_name" == *LPORT* ]]; then
        local _cb
        for _cb in 4444 9001 443 80 8080 1234 4443 1080; do
            candidates="${candidates}${_cb}"$'\n'
        done
    fi

    # Port candidates
    if [[ "$upper_type" == "PORT" ]] || [[ "$upper_name" == *PORT* ]]; then
        local -a common_ports=(
            "80" "443" "8080" "8443"
            "21" "22" "23" "25" "53"
            "135" "139" "445" "3389"
            "3306" "5432" "1433" "27017"
            "6379" "11211" "1-1000"
        )
        local p
        for p in "${common_ports[@]}"; do
            candidates="${candidates}${p}"$'\n'
        done
    fi

    # msfvenom payload candidates (-p). Curated; bare strings match -p usage.
    if [[ "$upper_type" == "PAYLOAD" ]] || [[ "$upper_name" == *PAYLOAD* ]]; then
        if command -v msfvenom >/dev/null 2>&1; then
            local _pl
            for _pl in \
                windows/x64/meterpreter/reverse_tcp \
                windows/x64/meterpreter/reverse_https \
                windows/meterpreter/reverse_tcp \
                windows/x64/shell_reverse_tcp \
                linux/x64/meterpreter/reverse_tcp \
                linux/x64/shell_reverse_tcp \
                java/jsp_shell_reverse_tcp \
                php/meterpreter/reverse_tcp \
                cmd/unix/reverse_python \
                windows/x64/meterpreter/bind_tcp; do
                candidates="${candidates}${_pl}"$'\n'
            done
        fi
    fi

    # Also handle LHOST auto-detection in candidates
    if [[ "$upper_name" == "LHOST" ]]; then
        local auto_ip
        auto_ip="$(_q_detect_lhost 2>/dev/null)" || true
        if [[ -n "$auto_ip" ]]; then
            candidates="[auto] ${auto_ip}"$'\n'"${candidates}"
        fi
    fi

    # Live system entities (docker) for container / image / network vars.
    # docker uses Go-template --format here; this is q's own code, not a
    # cheatsheet command, so the {{...}} is never seen by the placeholder parser.
    if command -v docker >/dev/null 2>&1; then
        local _de
        case "$upper_name" in
            *CONTAINER*)
                while IFS= read -r _de; do
                    [[ -n "$_de" ]] && candidates="${candidates}[docker] ${_de}"$'\n'
                done < <(docker ps -a --format '{{.Names}}' 2>/dev/null)
                ;;
            *IMAGE*)
                while IFS= read -r _de; do
                    [[ -n "$_de" && "$_de" != *'<none>'* ]] && candidates="${candidates}[docker] ${_de}"$'\n'
                done < <(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null)
                ;;
            *NETWORK*)
                while IFS= read -r _de; do
                    [[ -n "$_de" ]] && candidates="${candidates}[docker] ${_de}"$'\n'
                done < <(docker network ls --format '{{.Name}}' 2>/dev/null)
                ;;
        esac
    fi

    # Live network hosts — ARP neighbours + /etc/hosts (target/host/ip/domain vars)
    case "$upper_name" in
        TARGET|RHOST|RHOSTS|RHOST_NAME|IP|HOST|HOSTNAME|DC_IP|DC_HOST|DOMAIN)
            local _h
            while IFS= read -r _h; do
                [[ -n "$_h" ]] && candidates="${candidates}[arp] ${_h}"$'\n'
            done < <(ip neigh 2>/dev/null | awk '$1 ~ /^[0-9]+(\.[0-9]+){3}$/ && $0 !~ /FAILED|INCOMPLETE/ {print $1}' | sort -u)
            while IFS= read -r _h; do
                [[ -n "$_h" ]] && candidates="${candidates}[hosts] ${_h}"$'\n'
            done < <(awk 'NF>=2 && $1 !~ /^#/ && $1 !~ /^(127\.|255\.|0\.0\.0\.0|::1|ff0|fe00)/ { for (i=1;i<=NF;i++) { if ($i ~ /^#/) break; print $i } }' /etc/hosts 2>/dev/null | sort -u)
            ;;
    esac

    # Local login users (user/username vars)
    case "$upper_name" in
        USER|USERNAME)
            local _u
            while IFS= read -r _u; do
                [[ -n "$_u" ]] && candidates="${candidates}[user] ${_u}"$'\n'
            done < <(awk -F: '$3>=1000 && $3<65534 {print $1}' /etc/passwd 2>/dev/null)
            ;;
    esac

    # Live local listening ports (port vars) — augments the common-ports list
    if [[ "$upper_name" == *PORT* ]] && command -v ss >/dev/null 2>&1; then
        local _lp
        while IFS= read -r _lp; do
            [[ -n "$_lp" ]] && candidates="${candidates}[listen] ${_lp}"$'\n'
        done < <(ss -H -tln 2>/dev/null | awk '{n=split($4,a,":"); if (a[n] ~ /^[0-9]+$/) print a[n]}' | sort -un)
    fi

    # Deduplicate while preserving order
    if [[ -n "$candidates" ]]; then
        printf '%s' "$candidates" | awk '!seen[$0]++ && NF'
    fi
}

# ===========================================================================
# _q_path_reload — dynamic filesystem completion helper for fzf
# ===========================================================================
# When the user types a path-like prefix (starts with /, ./, ~/, or contains
# /), emit matching filesystem entries for fzf to display. Otherwise echo the
# original candidate list (stashed in _Q_PATH_RELOAD_CANDIDATES) so fzf keeps
# filtering normal candidates.
_q_path_reload() {
    local q="$1"

    # Non-path query — restore the original candidate list
    if [[ "$q" != /* && "$q" != ./* && "$q" != \~/* && "$q" != */* ]]; then
        printf '%s' "${_Q_PATH_RELOAD_CANDIDATES-}"
        return 0
    fi

    # Expand leading ~ to $HOME
    local expanded="${q/#\~/$HOME}"

    local dir base
    if [[ "$expanded" == */ ]]; then
        dir="${expanded%/}"
        base=""
    else
        dir="$(dirname "$expanded")"
        base="$(basename "$expanded")"
    fi
    [[ -z "$dir" ]] && dir="."

    find "$dir" -maxdepth 1 -name "${base}*" 2>/dev/null | sort | head -50
}
export -f _q_path_reload

# ===========================================================================
# q_fill_single_var — interactive single variable fill via fzf
# ===========================================================================
q_fill_single_var() {
    local name="$1" vtype="$2" vdefault="$3"
    local upper_type="${vtype^^}"

    # Build candidate list
    local candidates
    candidates="$(_q_build_candidates "$name" "$vtype" "$vdefault")"

    # Determine if this is a file/path type (needs browse binding)
    local is_file_type=0
    case "$upper_type" in
        FILE|WORDLIST|DIR|OUTFILE|OUTPUT_FILE) is_file_type=1 ;;
    esac

    # Also check by variable name
    case "${name^^}" in
        *FILE*|*WORDLIST*|*PATH*|*DIR*) is_file_type=1 ;;
    esac

    # Build fzf command
    local fzf_args=()
    fzf_args+=(--prompt="  {{${name}}}> ")
    fzf_args+=(--print-query)
    fzf_args+=(--height=14)
    fzf_args+=(--layout=reverse)
    fzf_args+=(--border)
    fzf_args+=(--no-info)
    fzf_args+=(--no-multi)

    # Don't pre-fill query — let the user see all candidates and pick.
    # The session/default value is already the top item in the list.

    # Header: context-sensitive help text
    local header_text="Enter: select | Type: custom value"

    # Add file browse keybinding for file-like types
    if [[ "$is_file_type" -eq 1 ]]; then
        case "$upper_type" in
            WORDLIST)
                fzf_args+=(--bind "ctrl-f:become(find /usr/share/seclists /usr/share/wordlists -type f 2>/dev/null | fzf --prompt='Browse wordlists> ' --height=80% --layout=reverse --border)")
                ;;
            DIR)
                fzf_args+=(--bind "ctrl-f:become(find . -maxdepth 4 -type d 2>/dev/null | fzf --prompt='Browse dirs> ' --height=80% --layout=reverse --border)")
                ;;
            *)
                fzf_args+=(--bind "ctrl-f:become(find . -maxdepth 4 -type f 2>/dev/null | fzf --prompt='Browse files> ' --height=80% --layout=reverse --border)")
                ;;
        esac
        # Dynamic path completion: as the user types a path-like prefix
        # (/, ./, ~/, or anything containing /), reload the list with
        # matching filesystem entries. Non-path queries restore the original
        # candidate list so normal fuzzy filtering keeps working.
        export _Q_PATH_RELOAD_CANDIDATES="$candidates"
        fzf_args+=(--bind "change:reload:_q_path_reload {q} || true")
        header_text="${header_text} | Ctrl+F: browse | Type path for tab-completion"
    fi

    fzf_args+=(--header="$header_text")

    # Run fzf
    local fzf_output
    if [[ -n "$candidates" ]]; then
        fzf_output="$(printf '%s\n' "$candidates" | fzf "${fzf_args[@]}" 2>/dev/tty)" || true
    else
        fzf_output="$(printf '' | fzf "${fzf_args[@]}" 2>/dev/tty)" || true
    fi

    # Parse fzf output: --print-query gives query on line 1, selection on line 2
    # Use IFS+read instead of head/sed subshells to avoid 2 fork+exec (~4ms)
    local typed_query="" selected=""
    IFS=$'\n' read -r typed_query <<< "$fzf_output" || true
    selected="${fzf_output#*$'\n'}"
    # If no newline was present, selected == fzf_output — clear it
    [[ "$selected" == "$fzf_output" ]] && selected=""

    # Determine final value
    local value=""
    if [[ -n "$selected" ]]; then
        # User selected from the list — strip tag prefixes using parameter expansion
        value="${selected#\[*\] }"
    elif [[ -n "$typed_query" ]]; then
        # User typed a custom value
        value="$typed_query"
    elif [[ -n "$vdefault" ]]; then
        # User pressed Enter with nothing — use default
        value="$vdefault"
    fi

    printf '%s' "$value"
}
