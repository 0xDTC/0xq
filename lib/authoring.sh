#!/usr/bin/env bash
# authoring.sh — interactively create / edit / delete cheatsheet command entries.
#
# Sourced by q. Expects Q_ROOT, Q_SHEETS_DIR, Q_CACHE_DIR and the helpers from
# core.sh (q_info/q_warn/q_error/q_success — all write to stderr) plus parser.sh
# (q_ensure_index, q_rebuild_index). The pure helpers (build/append/delete/
# replace) take no terminal input so they can be unit-tested; the q_author_add /
# q_author_edit orchestrators drive fzf + /dev/tty prompts around them.

# Vocab offered in the pickers (kept in sync with the cheatsheet conventions).
_Q_AUTHOR_TYPES="str ip url domain port file dir wordlist int cidr iface"
_Q_AUTHOR_RISKS="safe low med high critical"
_Q_AUTHOR_PHASES="recon enum exploit post privesc passwords vuln misc"

# ===========================================================================
# Terminal helpers — q may run inside a pipe, so prompt + read on /dev/tty.
# All /dev/tty access is guarded so a missing controlling terminal degrades to
# "empty answer" rather than aborting q under set -euo pipefail.
# ===========================================================================

# _q_author_read PROMPT [DEFAULT] — echo the typed answer (or DEFAULT if empty).
_q_author_read() {
    local prompt="$1" def="${2:-}" ans=""
    printf '%s' "$prompt" 2>/dev/null > /dev/tty || true
    IFS= read -r ans 2>/dev/null < /dev/tty || ans=""
    printf '%s' "${ans:-$def}"
}

# _q_author_confirm PROMPT [DEFAULT(y|n)] — return 0 on yes.
_q_author_confirm() {
    local prompt="$1" def="${2:-y}" ans=""
    printf '%s' "$prompt" 2>/dev/null > /dev/tty || true
    IFS= read -r ans 2>/dev/null < /dev/tty || ans=""
    ans="${ans:-$def}"
    [[ "$ans" =~ ^[Yy] ]]
}

# _q_author_fzf PROMPT [EXTRA...] — pick one line from stdin via fzf; echo it
# ("" on cancel). Extra args are passed through (e.g. --query).
_q_author_fzf() {
    local prompt="$1"; shift
    local out=""
    out="$(fzf --height=40% --reverse --no-multi --prompt "$prompt" "$@" 2>/dev/null)" || out=""
    printf '%s' "$out"
}

# _q_author_edit_in_editor CONTENT — open CONTENT in $EDITOR (used for editing
# multi-line commands); echo the edited result (or CONTENT unchanged if the
# editor can't run, e.g. no tty).
_q_author_edit_in_editor() {
    local content="$1" tmpf out
    local ed="${EDITOR:-${VISUAL:-nano}}"
    tmpf="$(mktemp "${TMPDIR:-/tmp}/q_cmd_XXXXXX.sh")"
    printf '%s\n' "$content" > "$tmpf"
    "$ed" "$tmpf" < /dev/tty > /dev/tty 2>&1 || true
    out="$(cat "$tmpf" 2>/dev/null)" || out="$content"
    rm -f "$tmpf"
    printf '%s' "$out"
}

# _q_author_trim_title TITLE — collapse tabs/CR to spaces and trim the ends so
# the written "## title" matches the parser's trimmed, tab-free index title.
_q_author_trim_title() {
    printf '%s' "$1" | tr '\t\r' '  ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# ===========================================================================
# Pure builders / file mutators (no tty — unit-testable).
# ===========================================================================

# q_author_build_entry TITLE DESC COMMAND RISK PHASE TAGS — print the entry block.
# Returns 1 (printing nothing) if the title is empty after trimming.
q_author_build_entry() {
    local title desc="$2" command="$3" risk="$4" phase="$5" tags="$6"
    title="$(_q_author_trim_title "$1")"
    if [[ -z "$title" ]]; then
        q_error "Entry title cannot be empty."
        return 1
    fi
    local meta="<!-- meta: risk=${risk} | phase=${phase}"
    [[ -n "$tags" ]] && meta="${meta} | tags=${tags}"
    meta="${meta} -->"
    printf '## %s\n' "$title"
    [[ -n "$desc" ]] && printf '%s\n' "$desc"
    printf '\n```bash\n%s\n```\n\n%s\n' "$command" "$meta"
}

# q_author_append_entry FILE BLOCK — append, with a --- separator if FILE already
# holds an entry. FILE is expected to exist (with at least an H1).
q_author_append_entry() {
    local file="$1" block="$2"
    # Guarantee a trailing newline so we never glue onto the previous line.
    if [[ -s "$file" ]] && [[ -n "$(tail -c1 "$file" 2>/dev/null)" ]]; then
        printf '\n' >> "$file"
    fi
    if grep -q '^## ' "$file" 2>/dev/null; then
        printf '\n---\n\n' >> "$file"
    else
        printf '\n' >> "$file"
    fi
    printf '%s\n' "$block" >> "$file"
}

# _q_author_strip_trailing_sep FILE — drop trailing blank/--- lines (cleanup
# after deleting the last entry, whose preceding separator would dangle).
_q_author_strip_trailing_sep() {
    local file="$1" tmp; tmp="$(mktemp)"
    if awk '
        { a[NR] = $0 }
        $0 !~ /^[[:space:]]*$/ && $0 !~ /^---+[[:space:]]*$/ { last = NR }
        END { for (i = 1; i <= last; i++) print a[i] }
    ' "$file" > "$tmp"; then
        mv "$tmp" "$file"
    else
        rm -f "$tmp"
    fi
}

# q_author_delete_entry FILE TITLE — remove the FIRST entry whose heading matches
# "## TITLE" (and its trailing ---). Returns 0 if removed, 1 if not found.
# The title is passed via the environment (ENVIRON) so awk does not apply C
# escape processing to it; matching tolerates trailing whitespace and CR.
q_author_delete_entry() {
    local file="$1" title="$2" tmp rc
    tmp="$(mktemp)"
    if _qa_t="## ${title}" awk '
        BEGIN { t = ENVIRON["_qa_t"] }
        { m = $0; sub(/\r$/, "", m); sub(/[[:space:]]+$/, "", m) }
        m == t && !seen        { skip = 1; seen = 1; found = 1; next }
        skip && (m ~ /^---+$/)  { skip = 0; next }
        skip && (m ~ /^## /)    { skip = 0 }
        !skip                   { print }
        END { exit (found ? 0 : 1) }
    ' "$file" > "$tmp"; then
        mv "$tmp" "$file"; rc=0
        _q_author_strip_trailing_sep "$file"
    else
        rc=$?; rm -f "$tmp"
    fi
    return "$rc"
}

# q_author_replace_entry FILE TITLE NEWBLOCK — swap the FIRST matching entry in
# place, keeping its position and trailing separator. Returns 0/1 as above.
q_author_replace_entry() {
    local file="$1" title="$2" newblock="$3" tmp nf rc
    nf="$(mktemp)"
    if ! printf '%s\n' "$newblock" > "$nf"; then rm -f "$nf"; return 1; fi
    tmp="$(mktemp)"
    if _qa_t="## ${title}" awk -v nf="$nf" '
        BEGIN { t = ENVIRON["_qa_t"] }
        { m = $0; sub(/\r$/, "", m); sub(/[[:space:]]+$/, "", m) }
        m == t && !seen {
            while ((getline line < nf) > 0) print line
            print ""
            close(nf); skip = 1; seen = 1; found = 1; next
        }
        skip && (m ~ /^---+$/ || m ~ /^## /) { skip = 0 }
        !skip { print }
        END { exit (found ? 0 : 1) }
    ' "$file" > "$tmp"; then
        mv "$tmp" "$file"; rc=0
    else
        rc=$?; rm -f "$tmp"
    fi
    rm -f "$nf"
    return "$rc"
}

# q_author_extract_command FILE TITLE — print the raw (possibly multi-line)
# command from inside the matching entry's ```bash block. Empty if not found.
# The index flattens multi-line commands to one space-joined line, so editing
# must read the real command from the source file instead.
q_author_extract_command() {
    local file="$1" title="$2"
    _qa_t="## ${title}" awk '
        BEGIN { t = ENVIRON["_qa_t"] }
        { m = $0; sub(/\r$/, "", m); sub(/[[:space:]]+$/, "", m) }
        !inentry && m == t                    { inentry = 1; next }
        inentry && m ~ /^## /                 { exit }
        inentry && !incode && m ~ /^```bash/  { incode = 1; next }
        inentry && incode && m ~ /^```/       { exit }
        inentry && incode                     { print }
    ' "$file"
}

# ===========================================================================
# Interactive pickers.
# ===========================================================================

# _q_author_pick_file — echo a target .md path (creating a new file if asked),
# return non-zero on cancel. Prompts/errors go to the tty/stderr, never stdout.
_q_author_pick_file() {
    local choice
    choice="$( { printf '%s\n' '[+ new file]';
                 find "$Q_SHEETS_DIR" -name '*.md' -not -path '*/external/*' 2>/dev/null \
                     | sed "s|^${Q_SHEETS_DIR}/||; s|\.md\$||" | sort;
               } | _q_author_fzf 'Cheatsheet (file)> ' )" || choice=""
    [[ -z "$choice" ]] && return 1
    if [[ "$choice" != '[+ new file]' ]]; then
        printf '%s' "${Q_SHEETS_DIR}/${choice}.md"
        return 0
    fi

    # New file: choose/create a category, then a tool/file name.
    local cat
    cat="$( { printf '%s\n' '[+ new category]';
              find "$Q_SHEETS_DIR" -mindepth 1 -maxdepth 1 -type d -not -name external 2>/dev/null \
                  | sed "s|^${Q_SHEETS_DIR}/||" | sort;
            } | _q_author_fzf 'Category> ' )" || cat=""
    [[ -z "$cat" ]] && return 1
    [[ "$cat" == '[+ new category]' ]] && cat="$(_q_author_read 'New category name: ')"
    local tool; tool="$(_q_author_read 'Tool name (the file, e.g. mytool): ')"

    local cat_s file_s
    cat_s="$(printf '%s' "$cat"  | tr ' ' '-' | tr -cd 'A-Za-z0-9._-')"
    file_s="$(printf '%s' "$tool" | tr ' ' '-' | tr -cd 'A-Za-z0-9._-')"
    if [[ -z "$cat_s" || -z "$file_s" ]]; then
        q_error "Category and tool name are required."
        return 1
    fi
    local dir="${Q_SHEETS_DIR}/${cat_s}" file="${Q_SHEETS_DIR}/${cat_s}/${file_s}.md"
    mkdir -p "$dir"
    if [[ ! -f "$file" ]]; then
        local h1; h1="$(_q_author_read "H1 / tool title [${tool}]: " "$tool")"
        [[ -z "$h1" ]] && h1="$file_s"
        printf '# %s\n' "$h1" > "$file"
    fi
    printf '%s' "$file"
}

# _q_author_type_vars COMMAND — for each bare {{VAR}}, prompt a type + optional
# default, then expand it to {{VAR:type[:default]}}. Already-typed vars are left
# untouched. Echoes the rewritten command.
_q_author_type_vars() {
    local cmd="$1" v t d repl repl_esc
    local -a vars=()
    mapfile -t vars < <(grep -oE '\{\{[A-Za-z_][A-Za-z0-9_]*\}\}' <<< "$cmd" 2>/dev/null \
                        | sed 's/[{}]//g' | sort -u) || true
    for v in "${vars[@]}"; do
        [[ -z "$v" ]] && continue
        # shellcheck disable=SC2086
        t="$(printf '%s\n' $_Q_AUTHOR_TYPES | _q_author_fzf "Type for {{${v}}} [str]> ")"
        t="${t:-str}"
        d="$(_q_author_read "Default for {{${v}}} (optional): ")"
        if [[ -n "$d" ]]; then repl="{{${v}:${t}:${d}}}"; else repl="{{${v}:${t}}}"; fi
        # Escape \ and & — bash 5.2+ treats & in a ${//} replacement as the match.
        repl_esc="${repl//\\/\\\\}"
        repl_esc="${repl_esc//&/\\&}"
        cmd="${cmd//\{\{"${v}"\}\}/$repl_esc}"
    done
    printf '%s' "$cmd"
}

# ===========================================================================
# q_author_add — interactive "add a new command" flow.
# ===========================================================================
q_author_add() {
    command -v fzf >/dev/null 2>&1 || { q_error "fzf is required for 'q new'."; return 1; }
    q_ensure_index >/dev/null 2>&1 || true

    local file; file="$(_q_author_pick_file)" || { q_info "Cancelled."; return 0; }
    [[ -z "$file" ]] && { q_info "Cancelled."; return 0; }

    # Type a one-liner inline, or leave it blank to compose a multi-line
    # command in $EDITOR (an empty editor cancels).
    local command; command="$(_q_author_read 'Command (use {{VAR}}; blank = compose multi-line in $EDITOR): ')"
    [[ -z "$command" ]] && command="$(_q_author_edit_in_editor "")"
    [[ -z "$command" ]] && { q_info "No command entered — cancelled."; return 0; }
    command="$(_q_author_type_vars "$command")"

    local title; title="$(_q_author_read 'Title (search-query style, lowercase): ')"
    [[ -z "$title" ]] && { q_info "No title entered — cancelled."; return 0; }

    local desc; desc="$(_q_author_read 'Description (one line): ')"
    local risk;  # shellcheck disable=SC2086
    risk="$(printf '%s\n' $_Q_AUTHOR_RISKS | _q_author_fzf 'Risk [low]> ')";   risk="${risk:-low}"
    local phase; # shellcheck disable=SC2086
    phase="$(printf '%s\n' $_Q_AUTHOR_PHASES | _q_author_fzf 'Phase [misc]> ')"; phase="${phase:-misc}"
    local tags; tags="$(_q_author_read 'Tags (comma-separated, optional): ')"
    tags="$(printf '%s' "$tags" | tr -d '[:space:]')"

    local block
    if ! block="$(q_author_build_entry "$title" "$desc" "$command" "$risk" "$phase" "$tags")"; then
        return 1
    fi
    {
        printf '\n%s───── new entry ─────%s\n' "${Q_DIM:-}" "${Q_RESET:-}"
        printf '%s\n' "$block"
        printf '%sfile:%s %s\n\n' "${Q_DIM:-}" "${Q_RESET:-}" "${file#"${Q_SHEETS_DIR}"/}"
    } 2>/dev/null > /dev/tty || true
    _q_author_confirm 'Add this entry? [Y/n] ' y || { q_info "Cancelled — nothing written."; return 0; }

    q_author_append_entry "$file" "$block"
    q_rebuild_index
    q_success "Added '${title}' → ${file#"${Q_SHEETS_DIR}"/}"
}

# ===========================================================================
# q_author_edit [QUERY...] — pick an existing command, then edit or delete it.
# Any QUERY args pre-filter the fzf picker.
# ===========================================================================
q_author_edit() {
    command -v fzf >/dev/null 2>&1 || { q_error "fzf is required for 'q edit'."; return 1; }
    q_ensure_index >/dev/null 2>&1 || true
    local index="${Q_CACHE_DIR}/index.tsv"
    [[ -s "$index" ]] || { q_error "Empty index — add commands first or run 'q rebuild'."; return 1; }

    local query="$*"
    # Pick an entry. Display "category/tool : title"; carry title + source file
    # in hidden tab-separated fields.
    local sel
    sel="$(awk -F'\t' '{printf "%s/%s : %s\t%s\t%s\n", $1, $2, $3, $3, $9}' "$index" \
            | fzf --height=60% --reverse --no-multi --delimiter='\t' --with-nth=1 \
                  --query "$query" --prompt 'Command to edit/delete> ' 2>/dev/null)" || sel=""
    [[ -z "$sel" ]] && { q_info "Cancelled."; return 0; }

    local title srcfile file
    title="$(printf '%s' "$sel" | cut -f2)"
    srcfile="$(printf '%s' "$sel" | cut -f3)"
    file="${Q_SHEETS_DIR}/${srcfile}"
    [[ -f "$file" ]] || { q_error "Source file not found: ${srcfile}"; return 1; }

    local action; action="$(printf '%s\n' 'edit' 'delete' | _q_author_fzf 'Action> ')"
    case "$action" in
        delete)
            _q_author_confirm "Delete '${title}' from ${srcfile}? [y/N] " n \
                || { q_info "Cancelled."; return 0; }
            if q_author_delete_entry "$file" "$title"; then
                q_rebuild_index; q_success "Deleted '${title}'."
            else
                q_error "Could not locate '${title}' in ${srcfile}."
                return 1
            fi
            ;;
        edit)
            local row
            row="$(awk -F'\t' -v t="$title" -v f="$srcfile" '$3==t && $9==f {print; exit}' "$index")"
            local cur_desc cur_cmd cur_risk cur_phase cur_tags
            cur_desc="$(printf '%s'  "$row" | cut -f4)"
            cur_risk="$(printf '%s'  "$row" | cut -f6)"
            cur_phase="$(printf '%s' "$row" | cut -f7)"
            cur_tags="$(printf '%s'  "$row" | cut -f8)"
            # Read the command from the SOURCE FILE — the index flattens
            # multi-line commands to one space-joined line. Fall back to index.
            cur_cmd="$(q_author_extract_command "$file" "$title")"
            [[ -z "$cur_cmd" ]] && cur_cmd="$(printf '%s' "$row" | cut -f5)"

            local new_title new_cmd new_desc new_risk new_phase new_tags
            new_title="$(_q_author_read "Title [${title}]: " "$title")"
            if [[ "$cur_cmd" == *$'\n'* ]]; then
                q_info "Multi-line command — opening \$EDITOR (${EDITOR:-${VISUAL:-nano}}); save & quit to apply."
                new_cmd="$(_q_author_edit_in_editor "$cur_cmd")"
            else
                new_cmd="$(_q_author_read "Command [${cur_cmd}]: " "$cur_cmd")"
            fi
            new_desc="$(_q_author_read  "Description [${cur_desc}]: " "$cur_desc")"
            # shellcheck disable=SC2086
            new_risk="$(printf '%s\n' $_Q_AUTHOR_RISKS | _q_author_fzf "Risk [${cur_risk}]> ")"
            new_risk="${new_risk:-$cur_risk}"
            # shellcheck disable=SC2086
            new_phase="$(printf '%s\n' $_Q_AUTHOR_PHASES | _q_author_fzf "Phase [${cur_phase}]> ")"
            new_phase="${new_phase:-$cur_phase}"
            new_tags="$(_q_author_read "Tags [${cur_tags}]: " "$cur_tags")"
            new_tags="$(printf '%s' "$new_tags" | tr -d '[:space:]')"

            local block
            if ! block="$(q_author_build_entry "$new_title" "$new_desc" "$new_cmd" "$new_risk" "$new_phase" "$new_tags")"; then
                return 1
            fi
            { printf '\n%s\n' "$block"; } 2>/dev/null > /dev/tty || true
            _q_author_confirm 'Save these changes? [Y/n] ' y || { q_info "Cancelled."; return 0; }
            if q_author_replace_entry "$file" "$title" "$block"; then
                q_rebuild_index; q_success "Updated '${new_title}'."
            else
                q_error "Could not locate '${title}' in ${srcfile}."
                return 1
            fi
            ;;
        *)
            q_info "Cancelled."
            ;;
    esac
}
