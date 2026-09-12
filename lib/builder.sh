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
# q_builder_emit_index_rows — one virtual index row per builder catalog
# ===========================================================================
# Columns match parser.sh output exactly (see combos.sh emit for the
# schema). Sentinel command `__BUILDER__:<tool>` is detected by q_main
# after selection.
q_builder_emit_index_rows() {
    command -v yq >/dev/null 2>&1 || return 0
    local -A seen=()
    shopt -s nullglob
    local d f name desc
    while IFS= read -r d; do
        [[ -d "$d" ]] || continue
        for f in "$d"/*.yaml "$d"/*.yml; do
            [[ -f "$f" ]] || continue
            name="$(yq -r '.tool // ""' "$f" 2>/dev/null)"
            [[ -z "$name" ]] && continue
            [[ -n "${seen[$name]:-}" ]] && continue
            seen["$name"]=1
            desc="$(yq -r '.description // ""' "$f" 2>/dev/null)"
            printf "builder\t%s\t[+] compose fresh command\t%s\t__BUILDER__:%s\tlow\tbuilder\tbuilder,%s,build,compose\tbuilder:%s\tany\n" \
                "$name" "$desc" "$name" "$name" "${f##*/}"
        done
    done < <(_q_builder_dirs)
    shopt -u nullglob
}

# ===========================================================================
# q_builder_run TOOL — interactive multi-select flag composer
# ===========================================================================
# Returns the assembled TEMPLATE on stdout (placeholders intact). Empty
# stdout means user cancelled or picked nothing. All fzf UI writes to
# /dev/tty so this can be captured via $(…).
q_builder_run() {
    local tool="$1"
    command -v yq >/dev/null 2>&1 || {
        q_error "yq is required for q build (sudo apt install yq)"
        return 1
    }
    local path
    path="$(_q_builder_path "$tool")" || {
        q_error "No builder catalog for '${tool}'."
        q_error "Add one at: ${Q_DATA_DIR}/builders/${tool}.yaml (see ${Q_ROOT}/builders/nmap.yaml for the schema)"
        return 1
    }

    # Slurp all flags in ONE yq call — TSV: flag<TAB>desc<TAB>vname<TAB>vtype<TAB>vdefault
    local -a flags=() descs=() vnames=() vtypes=() vdefaults=()
    local _f _d _vn _vt _vd
    while IFS=$'\t' read -r _f _d _vn _vt _vd; do
        [[ -z "$_f" ]] && continue
        flags+=("$_f")
        descs+=("$_d")
        vnames+=("$_vn")
        vtypes+=("$_vt")
        vdefaults+=("$_vd")
    done < <(yq -r '.flags[] | [.flag // "", .desc // "", .value.name // "", .value.type // "", .value.default // ""] | @tsv' "$path" 2>/dev/null)

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

    # Positional arguments — always appended after flags, in declared order.
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

    printf '%s' "$assembled"
}

# ===========================================================================
# q_builder_list — CLI helper: list all tools that have a builder catalog
# ===========================================================================
q_builder_list() {
    command -v yq >/dev/null 2>&1 || { q_error "yq required"; return 1; }
    printf '%s%sBuilders available:%s\n' "$Q_BOLD" "$Q_CYAN" "$Q_RESET" >&2
    local d f name desc any=0
    shopt -s nullglob
    while IFS= read -r d; do
        [[ -d "$d" ]] || continue
        for f in "$d"/*.yaml "$d"/*.yml; do
            [[ -f "$f" ]] || continue
            name="$(yq -r '.tool // ""' "$f" 2>/dev/null)"
            [[ -z "$name" ]] && continue
            desc="$(yq -r '.description // ""' "$f" 2>/dev/null)"
            printf '  %s%-12s%s  %s%s%s\n' "$Q_BOLD" "$name" "$Q_RESET" "$Q_DIM" "$desc" "$Q_RESET" >&2
            any=1
        done
    done < <(_q_builder_dirs)
    shopt -u nullglob
    [[ "$any" -eq 0 ]] && q_info "No builder catalogs yet. Drop a yaml under ${Q_ROOT}/builders/ or ${Q_DATA_DIR}/builders/"
}
