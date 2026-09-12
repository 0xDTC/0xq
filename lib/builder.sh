#!/usr/bin/env bash
# builder.sh — Interactive flag composer for well-known tools.
# Sourced by the main `q` script; not meant to be executed directly.
#
# Each tool with a catalog file under builders/<tool>.yaml gets one virtual
# "[+] compose fresh" row in the Ctrl+Q picker. Selecting it opens a
# multi-select fzf over the tool's flags; picked flags with a `value:`
# block become {{PLACEHOLDER:type:default}} tokens in the assembled
# template. That template then flows through the normal fill picker —
# so the same file/dir/choice UI (with size hints, absolute paths,
# choice descriptions, and multi-select) all work for a freshly-built
# command too. The template also gets bumped in the combo library, so
# frequently-composed shapes surface as `⚙ combo` rows next time.

# ===========================================================================
# _q_builder_dirs — echo user + repo builder dirs, one per line
# ===========================================================================
_q_builder_dirs() {
    printf '%s\n' "${Q_USER_BUILDERS_DIR:-${Q_DATA_DIR}/builders}"
    printf '%s\n' "${Q_ROOT}/builders"
}

# ===========================================================================
# _q_builder_path TOOL — resolve TOOL to its yaml path
# ===========================================================================
_q_builder_path() {
    local name="$1" d
    while IFS= read -r d; do
        [[ -f "$d/${name}.yaml" ]] && { printf '%s' "$d/${name}.yaml"; return 0; }
        [[ -f "$d/${name}.yml"  ]] && { printf '%s' "$d/${name}.yml";  return 0; }
    done < <(_q_builder_dirs)
    return 1
}

# ===========================================================================
# _q_builder_config_file — path to the user's enabled-tools list
# ===========================================================================
_q_builder_config_file() {
    printf '%s/builder-tools' "${HOME}/.config/q"
}

# ===========================================================================
# _q_builder_auto_dir / _q_builder_auto_cache TOOL
# ===========================================================================
# Auto-parsed help catalogs land under here as flag-per-line TSVs. Format
# matches the yq-extracted table used by q_builder_run:
#   flag<TAB>desc<TAB>vname<TAB>vtype<TAB>vdefault
_q_builder_auto_dir() {
    local d="${Q_DATA_DIR}/builders/auto"
    [[ -d "$d" ]] || mkdir -p "$d"
    printf '%s' "$d"
}
_q_builder_auto_cache() {
    printf '%s/%s.tsv' "$(_q_builder_auto_dir)" "$1"
}

# ===========================================================================
# _q_builder_yaml_tools — every tool with a YAML catalog on disk
# ===========================================================================
_q_builder_yaml_tools() {
    command -v yq >/dev/null 2>&1 || return 0
    shopt -s nullglob
    local d f name
    local -A seen=()
    while IFS= read -r d; do
        [[ -d "$d" ]] || continue
        for f in "$d"/*.yaml "$d"/*.yml; do
            [[ -f "$f" ]] || continue
            name="$(yq -r '.tool // ""' "$f" 2>/dev/null)"
            [[ -z "$name" ]] && continue
            [[ -n "${seen[$name]:-}" ]] && continue
            seen["$name"]=1
            printf '%s\n' "$name"
        done
    done < <(_q_builder_dirs)
    shopt -u nullglob
}

# ===========================================================================
# _q_builder_enabled_tools — union of user config + YAML catalogs
# ===========================================================================
# YAML-shipped tools (nmap today) are auto-enabled; the config file adds
# more tools that don't have a YAML but should get help-parsed. Comments
# (# ...) and blank lines are ignored.
_q_builder_enabled_tools() {
    local cfg; cfg="$(_q_builder_config_file)"
    {
        _q_builder_yaml_tools
        if [[ -f "$cfg" ]]; then
            grep -vE '^[[:space:]]*(#|$)' "$cfg"
        fi
    } | awk 'NF && !seen[$0]++'
}

# ===========================================================================
# _q_builder_run_help TOOL — capture --help / -h output, best-effort
# ===========================================================================
_q_builder_run_help() {
    local tool="$1"
    command -v "$tool" >/dev/null 2>&1 || return 1
    local out
    # Try in order: --help → -h → bare invocation (some tools like dirb
    # print their help when given no args and treat --help as a bad URL).
    for probe in --help -h ""; do
        if [[ -z "$probe" ]]; then
            out="$(timeout 3 "$tool"        2>&1 </dev/null || true)"
        else
            out="$(timeout 3 "$tool" "$probe" 2>&1 </dev/null || true)"
        fi
        # Accept anything that has multiple lines and at least one flag-like
        # token — bare invocations that just fail with a one-liner error
        # get skipped.
        if [[ -n "$out" ]] && [[ "$(printf '%s\n' "$out" | wc -l)" -gt 3 ]] \
           && printf '%s\n' "$out" | grep -qE '^[[:space:]]+-' ; then
            printf '%s' "$out"
            return 0
        fi
    done
    printf '%s' "$out"
}

# ===========================================================================
# _q_builder_parse_help TOOL — turn `tool --help` into flag TSV
# ===========================================================================
# Best-effort extractor. Recognises lines like:
#   "  -sV               service version detection"
#   "  -p <ports>        port list"
#   "  --output=FILE     write to FILE"
#   "  -l, --long <arg>  desc"
# Value markers (<...> / [...] / =NAME / trailing UPPERCASE-word) become
# a generic {{ARG:str}} placeholder in the built template — help output
# doesn't carry semantic type info.
_q_builder_parse_help() {
    local tool="$1"
    local raw; raw="$(_q_builder_run_help "$tool")"
    [[ -z "$raw" ]] && return 1

    printf '%s\n' "$raw" | awk '
        # Lines with 1+ leading space(s) then a dash-prefixed token.
        # (dirb uses single-space indent; nmap uses two; both should parse.)
        /^[[:space:]]+-/ {
            line = $0
            sub(/^[[:space:]]+/, "", line)
            # Comma-separated aliases: -h, --help
            if (match(line, /^-{1,2}[A-Za-z0-9?][-A-Za-z0-9_]*([,[:space:]]+-{1,2}[A-Za-z0-9][-A-Za-z0-9_]*)*/)) {
                flag_group = substr(line, 1, RLENGTH)
                rest = substr(line, RLENGTH + 1)
                # Pick the LONGEST alias as canonical (usually --long).
                n = split(flag_group, aliases, /[,[:space:]]+/)
                canonical = aliases[1]
                for (i = 2; i <= n; i++) if (length(aliases[i]) > length(canonical)) canonical = aliases[i]
                if (canonical !~ /^-/) next
                if (length(canonical) > 40) next
                if (canonical == "-" || canonical == "--") next
                # Value marker detection — check the first non-whitespace
                # chunk. Any of <arg>, [arg], =VAL, or a leading UPPERCASE
                # placeholder word means the flag takes an argument.
                has_value = 0
                lead = rest
                sub(/^[[:space:]]+/, "", lead)
                if (lead ~ /^</) {
                    has_value = 1
                    sub(/^<[^>]*>[[:space:]]*/, "", lead)
                } else if (lead ~ /^\[/) {
                    has_value = 1
                    sub(/^\[[^]]*\][[:space:]]*/, "", lead)
                } else if (lead ~ /^=/) {
                    has_value = 1
                    sub(/^=[^[:space:]]+[[:space:]]*/, "", lead)
                } else if (lead ~ /^[A-Z_][A-Z_0-9]+[[:space:]]/) {
                    has_value = 1
                    sub(/^[A-Z_][A-Z_0-9]+[[:space:]]+/, "", lead)
                }
                rest = lead
                # Description: everything remaining, truncated.
                desc = rest
                if (length(desc) > 70) desc = substr(desc, 1, 70) "..."
                # Skip lines whose canonical "flag" looks like a bare hyphen
                # or something else weird.
                if (canonical ~ /^-{3,}/) next
                printf "%s\t%s\t%s\t%s\t\n", canonical, desc, (has_value ? "ARG" : ""), (has_value ? "str" : "")
            }
        }
    ' | awk -F'\t' '!seen[$1]++'
}

# ===========================================================================
# q_builder_add TOOL... — enable one or more tools
# ===========================================================================
# For each tool: if it already has a YAML catalog, just record it in the
# config (it was implicitly enabled anyway — this makes it explicit); else
# run --help now, parse, and cache the flag list. Missing binaries and
# unparseable output are reported per-tool but never fail the whole call.
q_builder_add() {
    (( $# > 0 )) || { q_error "Usage: q build add TOOL [TOOL...]"; return 1; }
    local cfg; cfg="$(_q_builder_config_file)"
    mkdir -p "$(dirname "$cfg")"; touch "$cfg"
    local tool cache flags_count yaml_ok
    for tool in "$@"; do
        # Ignore obvious sub-word noise.
        [[ "$tool" =~ ^[A-Za-z0-9._-]+$ ]] || { q_warn "Skipping bad tool name: $tool"; continue; }
        yaml_ok=""
        _q_builder_path "$tool" >/dev/null 2>&1 && yaml_ok="yes"
        if [[ -z "$yaml_ok" ]]; then
            if ! command -v "$tool" >/dev/null 2>&1; then
                q_warn "$tool: not installed — skipping"
                continue
            fi
            cache="$(_q_builder_auto_cache "$tool")"
            if ! _q_builder_parse_help "$tool" > "${cache}.tmp"; then
                q_warn "$tool: --help returned nothing usable"
                rm -f "${cache}.tmp"
                continue
            fi
            flags_count="$(wc -l < "${cache}.tmp" 2>/dev/null || echo 0)"
            if [[ "${flags_count:-0}" -eq 0 ]]; then
                q_warn "$tool: parser extracted 0 flags from --help — skipping"
                rm -f "${cache}.tmp"
                continue
            fi
            mv "${cache}.tmp" "$cache"
            q_success "$tool: cached ${flags_count} flags from --help (auto)"
        else
            q_info "$tool: has YAML catalog — using rich UX"
        fi
        # Append to config if not already present.
        if ! grep -qxF "$tool" "$cfg" 2>/dev/null; then
            printf '%s\n' "$tool" >> "$cfg"
        fi
    done
    q_info "enabled tools: $(_q_builder_enabled_tools | tr '\n' ' ')"
}

# ===========================================================================
# q_builder_rm TOOL — disable a tool
# ===========================================================================
q_builder_rm() {
    local tool="$1"
    [[ -z "$tool" ]] && { q_error "Usage: q build rm TOOL"; return 1; }
    local cfg; cfg="$(_q_builder_config_file)"
    if [[ -f "$cfg" ]]; then
        local tmp="${cfg}.tmp.$$"
        grep -vxF "$tool" "$cfg" > "$tmp" 2>/dev/null || true
        mv "$tmp" "$cfg"
    fi
    local cache; cache="$(_q_builder_auto_cache "$tool")"
    [[ -f "$cache" ]] && rm -f "$cache"
    q_success "disabled: $tool"
    # Warn if the tool still has a YAML catalog (auto-enabled — user can't
    # disable a shipped catalog via config alone; they'd have to move the
    # yaml file out of the builders dir).
    if _q_builder_path "$tool" >/dev/null 2>&1; then
        q_warn "$tool has a YAML catalog and stays auto-enabled. Move ${Q_ROOT}/builders/${tool}.yaml to disable fully."
    fi
}

# ===========================================================================
# q_builder_emit_index_rows — one virtual index row per ENABLED tool
# ===========================================================================
# Columns match parser.sh output exactly (see combos.sh emit for the
# schema). Sentinel command `__BUILDER__:<tool>` is detected by q_main
# after selection.
q_builder_emit_index_rows() {
    local tool src desc source_marker
    while IFS= read -r tool; do
        [[ -z "$tool" ]] && continue
        if _q_builder_path "$tool" >/dev/null 2>&1; then
            src="yaml"
            desc="$(yq -r '.description // ""' "$(_q_builder_path "$tool")" 2>/dev/null)"
            source_marker="builder:${tool}.yaml"
        else
            src="auto"
            desc="parsed from ${tool} --help"
            source_marker="builder:auto/${tool}.tsv"
        fi
        printf "builder\t%s\t[+] compose fresh command\t%s\t__BUILDER__:%s\tlow\tbuilder\tbuilder,%s,build,compose,%s\t%s\tany\n" \
            "$tool" "$desc" "$tool" "$tool" "$src" "$source_marker"
    done < <(_q_builder_enabled_tools)
}

# ===========================================================================
# q_builder_run TOOL — interactive multi-select flag composer
# ===========================================================================
# Returns the assembled TEMPLATE on stdout (placeholders intact). Empty
# stdout means user cancelled or picked nothing. All fzf UI writes to
# /dev/tty so this can be captured via $(…).
q_builder_run() {
    local tool="$1"
    local path auto_cache src
    if path="$(_q_builder_path "$tool" 2>/dev/null)"; then
        command -v yq >/dev/null 2>&1 || {
            q_error "yq is required for YAML builder catalogs (sudo apt install yq)"
            return 1
        }
        src="yaml"
    else
        auto_cache="$(_q_builder_auto_cache "$tool")"
        if [[ ! -s "$auto_cache" ]]; then
            q_error "No builder catalog for '${tool}'."
            q_error "Enable it with:  q build add ${tool}"
            q_error "(will parse ${tool} --help and cache the flags)"
            return 1
        fi
        src="auto"
    fi

    # Slurp all flags in ONE call. YAML path uses yq; auto path just reads
    # the cached TSV directly. Both produce the same 5-column layout:
    #   flag<TAB>desc<TAB>vname<TAB>vtype<TAB>vdefault
    local -a flags=() descs=() vnames=() vtypes=() vdefaults=()
    local _f _d _vn _vt _vd
    local _flag_src
    if [[ "$src" == "yaml" ]]; then
        _flag_src=$(yq -r '.flags[] | [.flag // "", .desc // "", .value.name // "", .value.type // "", .value.default // ""] | @tsv' "$path" 2>/dev/null)
    else
        _flag_src=$(cat "$auto_cache")
    fi
    while IFS=$'\t' read -r _f _d _vn _vt _vd; do
        [[ -z "$_f" ]] && continue
        flags+=("$_f")
        descs+=("$_d")
        vnames+=("$_vn")
        vtypes+=("$_vt")
        vdefaults+=("$_vd")
    done <<< "$_flag_src"

    if [[ ${#flags[@]} -eq 0 ]]; then
        q_error "No flags defined in ${path}"
        return 1
    fi

    # Build fzf candidate list: `flag\tdesc` — tabstop 20 aligns descriptions
    local cands=""
    local _i
    for _i in "${!flags[@]}"; do
        cands="${cands}${flags[$_i]}"$'\t'"${descs[$_i]}"$'\n'
    done

    # Multi-select fzf. Header spells out the keys since this picker only
    # opens deliberately (from the [+] row) so users need the hint.
    local raw
    raw="$(printf '%s' "$cands" | fzf --multi --print-query --reverse \
            --border --no-info \
            --prompt="build ${tool}> " \
            --header="Tab: mark flag  |  Ctrl-A: all  |  Ctrl-D: clear  |  Enter: build  |  Esc: cancel" \
            --bind='ctrl-a:select-all,ctrl-d:deselect-all' \
            --tabstop=20 2>/dev/tty)" || return 0
    [[ -z "$raw" ]] && return 0

    # Parse: line 1 = typed query (ignored here — the builder catalog is the
    # source of truth); line 2+ = each picked row as "flag\tdesc".
    local -a picked=()
    local _line
    while IFS= read -r _line; do
        [[ -z "$_line" ]] && continue
        picked+=("${_line%%$'\t'*}")
    done < <(printf '%s\n' "$raw" | tail -n +2)
    [[ ${#picked[@]} -eq 0 ]] && return 0

    # Assemble template: tool + selected flags + value placeholders where
    # declared. Values are LEFT as {{PLACEHOLDER}} — the normal fill flow
    # in q_main handles prompting, so file/dir/choice pickers (with size
    # hints, absolute paths, multi-select) apply to a built command too.
    local assembled="$tool"
    local pflag idx placeholder
    for pflag in "${picked[@]}"; do
        # Locate flag index (linear scan — a builder catalog has 20-40
        # flags so this is negligible).
        idx=""
        for _i in "${!flags[@]}"; do
            if [[ "${flags[$_i]}" == "$pflag" ]]; then idx="$_i"; break; fi
        done
        [[ -z "$idx" ]] && continue
        assembled="$assembled $pflag"
        if [[ -n "${vnames[$idx]}" ]]; then
            placeholder="{{${vnames[$idx]}"
            [[ -n "${vtypes[$idx]}" ]]    && placeholder="${placeholder}:${vtypes[$idx]}"
            [[ -n "${vdefaults[$idx]}" ]] && placeholder="${placeholder}:${vdefaults[$idx]}"
            placeholder="${placeholder}}}"
            assembled="$assembled $placeholder"
        fi
    done

    # Positional arguments — YAML only (auto-parsed --help doesn't tell us
    # what positionals a tool takes). Always appended after flags, in
    # declared order. Auto tools get a generic {{TARGET:str}} tail so the
    # user always has somewhere to put an IP / host / URL.
    if [[ "$src" == "yaml" ]]; then
        local n_pos _pn _pt _pd
        n_pos="$(yq -r '.positional | length // 0' "$path" 2>/dev/null)"
        if [[ -n "$n_pos" && "$n_pos" != "0" && "$n_pos" != "null" ]]; then
            while IFS=$'\t' read -r _pn _pt _pd; do
                [[ -z "$_pn" ]] && continue
                placeholder="{{${_pn}"
                [[ -n "$_pt" ]] && placeholder="${placeholder}:${_pt}"
                [[ -n "$_pd" ]] && placeholder="${placeholder}:${_pd}"
                placeholder="${placeholder}}}"
                assembled="$assembled $placeholder"
            done < <(yq -r '.positional[] | [.name // "", .type // "str", .default // ""] | @tsv' "$path" 2>/dev/null)
        fi
    else
        assembled="$assembled {{TARGET:str}}"
    fi

    printf '%s' "$assembled"
}

# ===========================================================================
# q_builder_list — CLI helper: list all tools that have a builder catalog
# ===========================================================================
q_builder_list() {
    printf '%s%sEnabled builders:%s\n' "$Q_BOLD" "$Q_CYAN" "$Q_RESET" >&2
    local tool src desc flags count=0
    while IFS= read -r tool; do
        [[ -z "$tool" ]] && continue
        if _q_builder_path "$tool" >/dev/null 2>&1; then
            src="yaml"
            desc="$(yq -r '.description // ""' "$(_q_builder_path "$tool")" 2>/dev/null)"
            flags="$(yq -r '.flags | length' "$(_q_builder_path "$tool")" 2>/dev/null)"
        else
            src="auto"
            local cache; cache="$(_q_builder_auto_cache "$tool")"
            flags="$(wc -l < "$cache" 2>/dev/null | tr -d ' ')"
            desc="parsed from ${tool} --help"
        fi
        printf '  %s%-12s%s  %s(%s, %s flags)%s  %s%s%s\n' \
            "$Q_BOLD" "$tool" "$Q_RESET" \
            "$Q_DIM" "$src" "${flags:-0}" "$Q_RESET" \
            "$Q_DIM" "$desc" "$Q_RESET" >&2
        count=$((count + 1))
    done < <(_q_builder_enabled_tools)
    if [[ "$count" -eq 0 ]]; then
        q_info "No builders enabled."
        q_info "Enable with:  q build add TOOL [TOOL...]"
    else
        printf '\n%s%d enabled%s — add more with %sq build add TOOL%s\n' \
            "$Q_DIM" "$count" "$Q_RESET" "$Q_BOLD" "$Q_RESET" >&2
    fi
}
