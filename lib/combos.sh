#!/usr/bin/env bash
# combos.sh — Personal per-tool "combo" library.
# Sourced by the main `q` script; not meant to be executed directly.
#
# Every command the user picks through q gets captured — the placeholder-
# preserving TEMPLATE (not the filled command) is recorded under a per-tool
# TSV so the picker can surface "your own most-used combos" alongside
# cheatsheet entries. Zero authoring: just use the tool, combos accumulate.
#
# Storage layout:  $Q_DATA_DIR/combos/<tool>.tsv
#   <count>\t<template>
# Sorted by count desc after each bump; unique on template.

# ===========================================================================
# _q_combos_dir — ensure and print the combos directory
# ===========================================================================
_q_combos_dir() {
    local d="${Q_DATA_DIR}/combos"
    [[ -d "$d" ]] || mkdir -p "$d"
    printf '%s' "$d"
}

# ===========================================================================
# _q_combo_tool_for TEMPLATE — extract the tool binary name from a template
# ===========================================================================
# Mirrors q_log_extract_tool (logger.sh) — but that lib might not be sourced
# in every path, so we duplicate the tiny bit of logic here.
_q_combo_tool_for() {
    local cmd="$1"
    local -a words
    read -ra words <<< "$cmd"
    local w tool=""
    for w in "${words[@]}"; do
        # skip env assignments
        [[ "$w" == *=* && "$w" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] && continue
        # skip sudo
        [[ "$w" == "sudo" ]] && continue
        # skip short flags
        [[ "$w" == -* ]] && continue
        tool="$w"
        break
    done
    tool="${tool##*/}"
    tool="${tool%.exe}"
    tool="${tool%.py}"
    printf '%s' "$tool"
}

# ===========================================================================
# q_combo_bump TEMPLATE — increment hit count for TEMPLATE under its tool
# ===========================================================================
# Called from q_main after each successful pick (both inline widget path
# and interactive confirm path). Silent on failure so nothing about the
# combo file can break a normal q invocation.
q_combo_bump() {
    local template="$1"
    [[ -z "$template" ]] && return 0

    local tool; tool="$(_q_combo_tool_for "$template")"
    [[ -z "$tool" ]] && return 0

    # Skip q's own utility commands ("q rebuild", "q set", etc.) — those
    # aren't the kind of thing anyone wants back-suggested. Also skip
    # single-word bare-tool "commands" (nothing to combo).
    case "$tool" in
        q|"") return 0 ;;
    esac
    [[ "$template" != *" "* ]] && return 0

    local dir file
    dir="$(_q_combos_dir)"
    file="${dir}/${tool}.tsv"
    touch "$file"

    # Normalise whitespace so cosmetic differences don't create duplicate
    # rows. Tabs → spaces, newlines → semicolons, runs of spaces → one.
    template="${template//$'\t'/ }"
    template="${template//$'\n'/ ; }"
    template="$(printf '%s' "$template" | awk '{$1=$1;print}')"

    local tmp="${file}.tmp.$$"
    # Merge: bump matching row's count by 1, or append a new row with count 1.
    # awk keeps everything and writes updated rows sorted by count desc.
    awk -F'\t' -v t="$template" '
        {
            key = $2
            if (key == t) { c[key] = $1 + 1; seen[key] = 1 }
            else if (!(key in c))            { c[key] = $1;     seen[key] = 1 }
        }
        END {
            if (!(t in c)) c[t] = 1
            for (k in c) print c[k] "\t" k
        }
    ' "$file" | sort -k1,1nr -k2,2 > "$tmp" && mv "$tmp" "$file"
}

# ===========================================================================
# q_combo_emit_index_rows — emit combo rows in cache/index.tsv column layout
# ===========================================================================
# Called from q_search's display pipeline so combos slot into the same fzf
# list as cheatsheet entries. Columns match parser.sh output exactly:
#
#   1 CATEGORY  = "combo"
#   2 TOOL      = the tool binary name
#   3 TITLE     = "combo (used N×)"
#   4 DESC      = "" (the command itself is field 5)
#   5 COMMAND   = the template
#   6 RISK      = "low"
#   7 PHASE     = "combo"
#   8 TAGS      = "combo,<tool>"
#   9 SOURCE    = "combo:<tool>.tsv"
#  10 PLATFORM  = "any"
#
# Empty stdout if no combos exist.
q_combo_emit_index_rows() {
    local dir; dir="$(_q_combos_dir)"
    [[ -d "$dir" ]] || return 0
    shopt -s nullglob
    local f
    for f in "$dir"/*.tsv; do
        [[ -s "$f" ]] || continue
        local tool="${f##*/}"; tool="${tool%.tsv}"
        awk -F'\t' -v tool="$tool" '
            $1 != "" && $2 != "" {
                printf "combo\t%s\tcombo (used %d\xC3\x97)\t\t%s\tlow\tcombo\tcombo,%s\tcombo:%s.tsv\tany\n", \
                    tool, $1, $2, tool, tool
            }
        ' "$f"
    done
    shopt -u nullglob
}

# ===========================================================================
# q_combo_list [TOOL] — human-readable dump for the CLI
# ===========================================================================
# Used by `q combos` (dispatch added in the main script).
q_combo_list() {
    local filter="${1:-}"
    local dir; dir="$(_q_combos_dir)"
    if [[ ! -d "$dir" ]]; then
        q_info "No combos captured yet."
        return 0
    fi
    shopt -s nullglob
    local f any=0
    for f in "$dir"/*.tsv; do
        [[ -s "$f" ]] || continue
        local tool="${f##*/}"; tool="${tool%.tsv}"
        [[ -n "$filter" ]] && [[ "$tool" != "$filter" ]] && continue
        any=1
        printf '%s%s%s%s\n' "$Q_BOLD" "$Q_CYAN" "$tool" "$Q_RESET" >&2
        local count cmd
        while IFS=$'\t' read -r count cmd; do
            [[ -z "$count" ]] && continue
            printf '  %s%4d\xC3\x97%s  %s\n' "$Q_DIM" "$count" "$Q_RESET" "$cmd" >&2
        done < "$f"
    done
    shopt -u nullglob
    [[ "$any" -eq 0 ]] && q_info "No combos${filter:+ for '$filter'} yet."
}

# ===========================================================================
# q_combo_forget TOOL [TEMPLATE] — remove one combo or all for a tool
# ===========================================================================
q_combo_forget() {
    local tool="$1" template="${2:-}"
    [[ -z "$tool" ]] && { q_error "Usage: q combos forget TOOL [TEMPLATE]"; return 1; }
    local file; file="$(_q_combos_dir)/${tool}.tsv"
    if [[ ! -f "$file" ]]; then
        q_warn "No combos for '${tool}'."
        return 0
    fi
    if [[ -z "$template" ]]; then
        rm -f "$file"
        q_success "Forgot all combos for ${tool}."
        return 0
    fi
    local tmp="${file}.tmp.$$"
    awk -F'\t' -v t="$template" '$2 != t' "$file" > "$tmp" && mv "$tmp" "$file"
    q_success "Forgot: ${tool}: ${template}"
}
