#!/usr/bin/env bash
# search.sh — fzf-powered interactive command search with session-aware preview
# Sourced by q; expects Q_ROOT, Q_CACHE_DIR, Q_SHEETS_DIR, Q_PREVIEWER,
# Q_FZF_OPTS, Q_PREVIEW_SIZE, Q_DATA_DIR, Q_SESSION_NAME,
# and ANSI color vars from lib/core.sh.
#
# ---------------------------------------------------------------------------
# Design
# ---------------------------------------------------------------------------
# The preview pane shows both the raw template and a session-filled version
# of the selected command so the user can see exactly what will execute.
# Unresolved placeholders are rendered as <?NAME?> in red.
#
# Variables are filled on-screen: Ctrl+F (and Enter, when placeholders are
# still missing) open a candidate popup per variable and update the FILLED
# preview live, so the per-variable picker never leaves this screen.
#
# Keybindings in the main fzf:
#   Enter     fill any missing vars on-screen, then (next Enter) run
#   Ctrl+F    fill / change variables via the candidate popup
#   Ctrl+E    open the RAW command (with {{VAR}} placeholders intact) in
#             $EDITOR — no fill prompt, so you can rewrite anything (fill in
#             values manually, change flags, add pipes). (.force_edit sideband)
#   Ctrl+T    cycle TARGET through session targets; preview updates live
#   Ctrl+Y    copy the session-filled command to the clipboard
#   Ctrl+N    add a new cheatsheet command (runs q new), then quits
#   Tab       toggle preview
#   Esc       quit

# ===========================================================================
# q_search — main fzf search interface
# ===========================================================================
# Arguments: optional initial query string (all args joined)
# Stdout:    TSV line  CATEGORY/TOOL \t TITLE \t COMMAND  (for the selection)
# Exit 1 if no selection (Escape / Ctrl+C).
#
# Sideband flag file (consumed by q_main, run in a command substitution so
# env exports don't propagate):
#   ${Q_CACHE_DIR}/.force_edit  exists  -> open the raw command in $EDITOR
#                                          (skips fill so you edit as a whole)
q_search() {
    local index_file="${Q_CACHE_DIR}/index.tsv"
    local initial_query="${*}"

    # -----------------------------------------------------------------------
    # Reset the .force_edit sideband flag for this invocation
    # -----------------------------------------------------------------------
    rm -f "${Q_CACHE_DIR}/.force_edit"

    # -----------------------------------------------------------------------
    # Guard: index must exist and have content
    # -----------------------------------------------------------------------
    if [[ ! -s "$index_file" ]]; then
        q_error "Index is empty or missing. Run: q rebuild"
        return 1
    fi

    # -----------------------------------------------------------------------
    # Resolve session paths (may not exist yet — preview tolerates missing)
    # -----------------------------------------------------------------------
    local vars_file="${Q_DATA_DIR}/sessions/${Q_SESSION_NAME}/vars"
    local targets_file="${Q_DATA_DIR}/sessions/${Q_SESSION_NAME}/targets"

    # Transient state for Ctrl+T target cycling. Cleared each search.
    local cycle_file="${Q_CACHE_DIR}/.target_cycle"
    : > "$cycle_file"

    # Transient on-screen fill state + current-command stash. Reset per search.
    local fill_state="${Q_CACHE_DIR}/.fill_state"
    local cur_cmd_file="${Q_CACHE_DIR}/.cur_cmd"
    : > "$fill_state"
    : > "$cur_cmd_file"
    local varhint_script="${Q_CACHE_DIR}/.q_varhint.sh"

    # -----------------------------------------------------------------------
    # Preview script — runs under fzf for every highlighted row. Reads the
    # session vars file directly and produces a filled-command rendering.
    # Heredoc is NOT quoted so Q_CACHE_DIR / vars_file paths are baked in.
    # -----------------------------------------------------------------------
    local preview_cmd
    read -r -d '' preview_cmd <<PREVIEW_EOF || true
        line={}
        vars_file='${vars_file}'
        cycle_file='${cycle_file}'
        fill_file='${fill_state}'
        varhint='${varhint_script}'

        # Strip ANSI so field parsing is clean
        line="\$(printf '%s' "\$line" | sed "s/$(printf '\033')\[[0-9;]*m//g")"
        # Layout: DISPLAY \t title \t cmd \t src \t keywords
        IFS=\$'\t' read -r _display _title _cmd _src _kw <<< "\$line"

        bold=\$'\033[1m'
        dim=\$'\033[2m'
        cyan=\$'\033[36m'
        yellow=\$'\033[33m'
        green=\$'\033[32m'
        red=\$'\033[31m'
        magenta=\$'\033[35m'
        reset=\$'\033[0m'

        # Raw template: highlight {{VAR}} placeholders in yellow
        highlighted_cmd=\$(printf '%s' "\$_cmd" | \
            sed "s/{{\\\\([^}]*\\\\)}}/\${yellow}{{\\1}}\${reset}\${dim}/g")

        # Filled command: walk placeholders, substitute from session/default.
        # Missing resolutions render as <?NAME?> in red. A trailing line holds
        # the missing count so the shell layer can switch the status badge.
        awk_out=\$(printf '%s' "\$_cmd" | awk \\
            -v vars_file="\$vars_file" \\
            -v cycle_file="\$cycle_file" \\
            -v fill_file="\$fill_file" \\
            -v green="\$green" \\
            -v red="\$red" \\
            -v bold="\$bold" \\
            -v reset="\$reset" '
        BEGIN {
            while ((getline ln < vars_file) > 0) {
                eq = index(ln, "=")
                if (eq > 0) session[substr(ln, 1, eq-1)] = substr(ln, eq+1)
            }
            close(vars_file)
            while ((getline ln < cycle_file) > 0) {
                eq = index(ln, "=")
                if (eq > 0) cycle[substr(ln, 1, eq-1)] = substr(ln, eq+1)
            }
            close(cycle_file)
            while ((getline ln < fill_file) > 0) {
                eq = index(ln, "=")
                if (eq > 0) fill[substr(ln, 1, eq-1)] = substr(ln, eq+1)
            }
            close(fill_file)
            missing = 0
        }
        {
            line = \$0; out = ""
            while (match(line, /\\{\\{[^}]+\\}\\}/)) {
                pre = substr(line, 1, RSTART - 1)
                tok = substr(line, RSTART, RLENGTH)
                line = substr(line, RSTART + RLENGTH)
                inner = substr(tok, 3, length(tok) - 4)
                colon = index(inner, ":")
                name  = (colon > 0) ? substr(inner, 1, colon - 1) : inner
                dflt  = ""
                if (colon > 0) {
                    rest = substr(inner, colon + 1)
                    c2   = index(rest, ":")
                    dflt = (c2 > 0) ? substr(rest, c2 + 1) : ""
                }
                if (name in fill && fill[name] != "") {
                    out = out pre green fill[name] reset
                } else if (name in cycle && cycle[name] != "") {
                    out = out pre green cycle[name] reset
                } else if (name in session && session[name] != "") {
                    out = out pre green session[name] reset
                } else if (dflt != "") {
                    out = out pre green dflt reset
                } else {
                    out = out pre red bold "<?" name "?>" reset
                    missing++
                }
            }
            printf "%s%s\n", out, line
        }
        END { printf "__MISSING__=%d\n", missing }
        ')

        # Split awk output: all lines except last are the filled command;
        # last line is __MISSING__=N.
        filled_cmd="\${awk_out%\$'\n'*}"
        missing_line="\${awk_out##*\$'\n'}"
        missing_count="\${missing_line#__MISSING__=}"

        printf '%s\n'     "\${bold}\${cyan}TEMPLATE\${reset}"
        printf '  %s\n\n' "\${dim}\${highlighted_cmd}\${reset}"

        # Variable legend — what each {{placeholder}} is for
        vars_legend="\$("\$varhint" "\$_cmd" 2>/dev/null)"
        if [[ -n "\$vars_legend" ]]; then
            printf '%s\n'   "\${bold}\${cyan}VARIABLES\${reset}"
            printf '%s\n\n' "\${dim}\${vars_legend}\${reset}"
        fi

        if [[ "\$missing_count" -eq 0 ]]; then
            printf '%s %s\n' "\${bold}\${cyan}FILLED\${reset}" "\${green}[ready — Enter to run]\${reset}"
        else
            printf '%s %s\n' "\${bold}\${cyan}FILLED\${reset}" "\${yellow}[\${missing_count} missing — Ctrl+S to set]\${reset}"
        fi
        printf '  %s\n\n' "\${bold}\${filled_cmd}\${reset}"

        # Session summary
        if [[ -s "\$vars_file" ]]; then
            printf '%s ' "\${bold}\${cyan}SESSION\${reset}"
            head -6 "\$vars_file" | tr '\n' ' ' | sed 's/ \$//'
            total=\$(wc -l < "\$vars_file" 2>/dev/null || echo 0)
            [[ "\$total" -gt 6 ]] && printf ' \${dim}(+%d)\${reset}' "\$((total - 6))"
            printf '\n'
        fi

        printf '%s  %s\n' "\${dim}file:\${reset}" "\${dim}\${_src}\${reset}"
PREVIEW_EOF

    # -----------------------------------------------------------------------
    # Helper scripts for Ctrl+Y / Ctrl+T. Written to cache dir so fzf binds
    # can reference them by path without worrying about shell escaping.
    # -----------------------------------------------------------------------
    local copy_script="${Q_CACHE_DIR}/.q_copy_filled.sh"
    local cycle_script="${Q_CACHE_DIR}/.q_cycle_target.sh"
    local setvar_script="${Q_CACHE_DIR}/.q_set_var.sh"

    # Emit helper scripts only when missing or older than search.sh itself
    # (which contains their source heredocs). Skips ~6 file writes on every
    # `q` invocation once the cache is warm.
    local _helpers_src="${Q_ROOT}/lib/search.sh"
    _q_helper_stale() {
        local p="$1"
        [[ ! -f "$p" ]] && return 0
        local hm sm
        hm="$(q_mtime "$p")"; sm="$(q_mtime "$_helpers_src")"
        [[ "${hm:-0}" -lt "${sm:-0}" ]]
    }
    _q_helper_stale "$copy_script"    && _q_write_copy_helper    "$copy_script"
    _q_helper_stale "$cycle_script"   && _q_write_cycle_helper   "$cycle_script"
    _q_helper_stale "$setvar_script"  && _q_write_setvar_helper  "$setvar_script"

    local fill_script="${Q_CACHE_DIR}/.q_fill_var.sh"
    local decide_script="${Q_CACHE_DIR}/.q_decide.sh"
    local builder_script="${Q_CACHE_DIR}/.q_builder_pick.sh"
    local modify_script="${Q_CACHE_DIR}/.q_modify.sh"
    local delete_script="${Q_CACHE_DIR}/.q_delete.sh"
    local chain_script="${Q_CACHE_DIR}/.q_chain_pick.sh"
    _q_helper_stale "$fill_script"    && _q_write_fill_helper    "$fill_script"
    _q_helper_stale "$decide_script"  && _q_write_decide_helper  "$decide_script"
    _q_helper_stale "$varhint_script" && _q_write_varhint_helper "$varhint_script"
    _q_helper_stale "$builder_script" && _q_write_builder_pick_helper "$builder_script"
    _q_helper_stale "$modify_script"  && _q_write_modify_helper       "$modify_script"
    _q_helper_stale "$delete_script"  && _q_write_delete_helper       "$delete_script"
    _q_helper_stale "$chain_script"   && _q_write_chain_pick_helper   "$chain_script"
    unset -f _q_helper_stale

    # Reset sidebands so stale values don't leak between invocations.
    rm -f "${Q_CACHE_DIR}/.built_cmd"

    # Save the full picker feed (combos + index) so keybind helpers can
    # read the exact rows fzf is showing without re-generating them.
    local feed_file="${Q_CACHE_DIR}/.picker_feed"
    { declare -f q_combo_emit_index_rows >/dev/null 2>&1 && \
        q_combo_emit_index_rows 2>/dev/null; \
      cat "$index_file"; } > "$feed_file"

    # -----------------------------------------------------------------------
    # Build the display list and run fzf.
    # fzf line (after cut): DISPLAY \t title \t cmd \t src \t keywords
    # --with-nth=1 shows DISPLAY only (tool│title│desc); --nth=1,5 also searches
    # the hidden keywords field (category + phase + tags), so users can type
    # intent like "post creds windows" — but never the raw bash command.
    # --expect captures Ctrl+F / Ctrl+E so the shell layer can set sideband
    # flags before returning.
    # -----------------------------------------------------------------------
    local q_bin="${Q_ROOT}/q"
    local mru_file="${Q_DATA_DIR}/mru"
    local selected
    # Optional OS filter — Q_OS_FILTER (or --os flag captured earlier) drops
    # rows whose platform column doesn't match. "any" always passes.
    local _os_filter="${Q_OS_FILTER:-}"
    selected="$(
        awk -F'\t' \
            -v cyan=$'\033[36m' \
            -v bold=$'\033[1m' \
            -v dim=$'\033[2m' \
            -v magenta=$'\033[35m' \
            -v reset=$'\033[0m' \
            -v sep=$'\033[2m│\033[0m' \
            -v mru_file="$mru_file" \
            -v os_filter="$_os_filter" \
        '
        BEGIN {
            # Load MRU titles into rank map (lower rank = more recent)
            r = 0
            while ((getline ln < mru_file) > 0) {
                if (ln != "" && !(ln in mru_rank)) {
                    mru_rank[ln] = ++r
                }
            }
            close(mru_file)

            tool_w  = 22
            title_w = 38
        }
        function pad(s, w,    ls) {
            ls = length(s)
            if (ls >= w) return substr(s, 1, w)
            return s sprintf("%*s", w - ls, "")
        }
        {
            cat      = $1
            tool     = $2
            title    = $3
            desc     = ($4 != "") ? $4 : "(no description)"
            cmd      = $5
            phase    = $7
            tags     = $8
            src      = $9
            platform = ($10 != "") ? tolower($10) : "any"

            # OS filter: keep rows tagged "any" always, or matching the filter.
            if (os_filter != "" && platform != "any" && platform != os_filter) next

            # Combos always sort above MRU cheatsheets. Their display gets
            # a distinct wrench marker instead of the MRU star. Since combo
            # rows are emitted before the index, their NR is already small
            # and already sorted by hit count desc — so rank=0 + NR
            # tiebreak gives top combo first.
            if (cat == "combo") {
                mark = magenta "\xE2\x9A\x99" reset " "   # ⚙ combo
                rank = 0
            } else if (cat == "builder") {
                mark = magenta "+" reset " "              # +  build fresh
                rank = 1
            } else {
                mark = (title in mru_rank) ? (magenta "\xE2\x98\x85" reset " ") : "  "
                rank = (title in mru_rank) ? mru_rank[title] : 999999
            }

            # Build colored, padded display: TOOL | TITLE | DESCRIPTION
            tool_col  = mark cyan pad(tool, tool_w - 2) reset
            title_col = bold pad(title, title_w) reset
            desc_col  = dim desc reset
            display   = tool_col " " sep " " title_col " " sep " " desc_col

            # Hidden keyword field (category + phase + tags) so the search can
            # match on intent: recon/enum/post/privesc, persistence, creds, ...
            gsub(/,/, " ", tags)
            keywords = cat " " phase " " tags

            # Emit:  rank \t row_no \t display \t title \t cmd \t src \t keywords
            # Sort prefix gets stripped after sort.
            printf "%010d\t%010d\t%s\t%s\t%s\t%s\t%s\n", \
                rank, NR, display, title, cmd, src, keywords
        }
        ' "$feed_file" \
        | sort -k1,1n -k2,2n \
        | cut -f3- \
        | fzf \
            --ansi \
            --print-query \
            --prompt='q> ' \
            --header='★ recent  ⚙ combo  ^F fill  ^S set  ^T cycle  ^Y copy  ^E edit  ^B build  ^M modify  ^X chain  ^D delete  ^N new  Esc quit' \
            --preview="$preview_cmd" \
            --preview-window="${Q_PREVIEW_POS:-down:50%:wrap}" \
            --query="$initial_query" \
            --bind="ctrl-f:execute('${fill_script}' {3} '${fill_state}' '${vars_file}' '${q_bin}' '${Q_ROOT}' all)+refresh-preview" \
            --bind="enter:transform('${decide_script}' {3} '${fill_state}' '${vars_file}' '${cur_cmd_file}' '${fill_script}' '${q_bin}' '${Q_ROOT}')" \
            --bind="ctrl-e:execute-silent(touch '${Q_CACHE_DIR}/.force_edit')+accept" \
            --bind="ctrl-y:execute-silent('${copy_script}' {3} '${vars_file}')+abort" \
            --bind="ctrl-t:execute-silent('${cycle_script}' '${targets_file}' '${cycle_file}')+refresh-preview" \
            --bind="ctrl-s:execute('${setvar_script}' {3} '${vars_file}' '${q_bin}')+refresh-preview" \
            --bind="ctrl-n:execute('${q_bin}' new)+abort" \
            --bind="ctrl-b:execute('${builder_script}' '${Q_ROOT}' '${Q_CACHE_DIR}/.built_cmd')+abort" \
            --bind="ctrl-m:execute('${modify_script}' '${Q_ROOT}' '${Q_CACHE_DIR}/.built_cmd' {3})+abort" \
            --bind="ctrl-x:execute('${chain_script}' '${Q_ROOT}' '${Q_CACHE_DIR}/.built_cmd' '${feed_file}')+abort" \
            --bind="ctrl-d:execute('${delete_script}' '${Q_ROOT}' {2} {3} {4})+abort" \
            --bind='tab:toggle-preview' \
            --delimiter=$'\t' \
            --with-nth=1 \
            --nth=1,5 \
            --tabstop=4 \
            --color='pointer:cyan,prompt:cyan,hl:yellow,hl+:yellow:bold' \
            --no-multi \
            --exit-0 \
            ${Q_FZF_OPTS:-}
    )" || true

    if [[ -z "$selected" ]]; then
        return 1
    fi

    # --print-query prepends the final typed query on its own line. Split
    # it off and stash it so q_main can auto-pre-fill any {{X:choice:...}}
    # values the user mentioned (e.g. `q regripper userassist` → PLUGIN
    # gets pre-filled without opening the picker).
    local user_query="${selected%%$'\n'*}"
    local selection_line="${selected#*$'\n'}"
    if [[ "$selection_line" == "$selected" ]]; then
        # No newline in output means fzf printed only the query (no pick).
        selection_line=""
    fi
    if [[ -z "$selection_line" ]]; then
        return 1
    fi
    printf '%s' "$user_query" > "${Q_CACHE_DIR}/.last_query"

    # -----------------------------------------------------------------------
    # Emit 3-field TSV expected by q_main: DISPLAY, TITLE, COMMAND.
    # Layout coming in: DISPLAY \t title \t cmd \t src — drop src.
    # -----------------------------------------------------------------------
    printf '%s\n' "$selection_line" \
        | q_strip_ansi \
        | awk -F'\t' '{ printf "%s\t%s\t%s\n", $1, $2, $3 }'
}

# ===========================================================================
# _q_write_copy_helper — emit the Ctrl+Y helper script
# ===========================================================================
# Fills placeholders from session vars, then writes the result to the system
# clipboard using whichever tool is available. Kept as a separate file so
# fzf's --bind doesn't need to embed multi-line awk.
_q_write_copy_helper() {
    local path="$1"
    cat > "$path" <<'COPYEOF'
#!/usr/bin/env bash
raw="$1"
vars_file="$2"
stripped=$(printf '%s' "$raw" | sed "s/$(printf '\033')\[[0-9;]*m//g")
filled=$(printf '%s' "$stripped" | awk -v vars_file="$vars_file" '
BEGIN {
    while ((getline ln < vars_file) > 0) {
        eq = index(ln, "=")
        if (eq > 0) session[substr(ln, 1, eq-1)] = substr(ln, eq+1)
    }
    close(vars_file)
}
{
    line = $0; out = ""
    while (match(line, /\{\{[^}]+\}\}/)) {
        pre = substr(line, 1, RSTART - 1)
        tok = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
        inner = substr(tok, 3, length(tok) - 4)
        colon = index(inner, ":")
        name  = (colon > 0) ? substr(inner, 1, colon - 1) : inner
        dflt  = ""
        if (colon > 0) {
            rest = substr(inner, colon + 1)
            c2   = index(rest, ":")
            dflt = (c2 > 0) ? substr(rest, c2 + 1) : ""
        }
        if (name in session && session[name] != "") {
            out = out pre session[name]
        } else if (dflt != "") {
            out = out pre dflt
        } else {
            out = out pre tok
        }
    }
    print out line
}')

if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$filled" | pbcopy
elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$filled" | xclip -selection clipboard
elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$filled" | xsel --clipboard --input
elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$filled" | wl-copy
fi
COPYEOF
    chmod +x "$path"
}

# ===========================================================================
# _q_write_cycle_helper — emit the Ctrl+T target-cycle helper script
# ===========================================================================
# Advances TARGET= in cycle_file to the next value in targets_file. Preview
# reads cycle_file on every refresh, so the filled command updates live.
_q_write_cycle_helper() {
    local path="$1"
    cat > "$path" <<'CYCLEEOF'
#!/usr/bin/env bash
targets_file="$1"
cycle_file="$2"

[[ -s "$targets_file" ]] || exit 0

# Strip "type:" prefix from each target line to get bare values
mapfile -t all < <(cut -s -d: -f2- "$targets_file")
[[ ${#all[@]} -gt 0 ]] || exit 0

current=""
if [[ -s "$cycle_file" ]]; then
    current=$(awk -F= '$1 == "TARGET" { sub(/^[^=]*=/, ""); print; exit }' "$cycle_file")
fi

next="${all[0]}"
for i in "${!all[@]}"; do
    if [[ "${all[$i]}" == "$current" ]]; then
        next="${all[$(( (i + 1) % ${#all[@]} ))]}"
        break
    fi
done

printf 'TARGET=%s\n' "$next" > "$cycle_file"
CYCLEEOF
    chmod +x "$path"
}

# ===========================================================================
# _q_write_setvar_helper — emit the Ctrl+S inline variable setter
# ===========================================================================
# Reads the selected command, finds missing variables (those NOT in vars_file
# and without a default), and prompts the user to set one. Writes via `q set`
# so the change persists for next preview refresh.
_q_write_setvar_helper() {
    local path="$1"
    cat > "$path" <<'SETVAREOF'
#!/usr/bin/env bash
# Args: $1 = raw command (field 4 from fzf, ANSI-tainted), $2 = vars_file, $3 = q_bin
raw_cmd="$1"
vars_file="$2"
q_bin="$3"

# Strip ANSI
cmd=$(printf '%s' "$raw_cmd" | sed "s/$(printf '\033')\[[0-9;]*m//g")

# Extract unique variable names from {{NAME[:type[:default]]}} placeholders
mapfile -t allvars < <(grep -oE '\{\{[^}]+\}\}' <<< "$cmd" \
    | sed -E 's/^\{\{([^:}]+).*/\1/' \
    | awk '!seen[$0]++')

[[ ${#allvars[@]} -eq 0 ]] && {
    printf '\n[!] No variables in this command.\n' > /dev/tty
    sleep 1
    exit 0
}

# Split into missing (not in vars_file) and set (already in vars_file)
missing=()
already=()
for v in "${allvars[@]}"; do
    if [[ -f "$vars_file" ]] && awk -F= -v k="$v" '$1==k{f=1;exit}END{exit !f}' "$vars_file" 2>/dev/null; then
        already+=("$v")
    else
        missing+=("$v")
    fi
done

# Show summary
clear > /dev/tty 2>&1 || printf '\n\n' > /dev/tty
printf '\033[1;36m=== q: set session variable ===\033[0m\n\n' > /dev/tty
if [[ ${#missing[@]} -gt 0 ]]; then
    printf '\033[1;33mMissing:\033[0m  %s\n' "${missing[*]}" > /dev/tty
fi
if [[ ${#already[@]} -gt 0 ]]; then
    printf '\033[1;32mAlready set:\033[0m  %s\n' "${already[*]}" > /dev/tty
fi
printf '\nFormat:  \033[1mNAME=value\033[0m  or  \033[1mNAME\033[0m (asks for value)\n' > /dev/tty
printf 'Empty input cancels.\n\n' > /dev/tty

# Default name = first missing var if any
default_name=""
[[ ${#missing[@]} -gt 0 ]] && default_name="${missing[0]}"

prompt="\033[1;36mset> \033[0m"
[[ -n "$default_name" ]] && prompt="\033[1;36mset \033[0m[\033[1;33m${default_name}\033[0m]\033[1;36m> \033[0m"
printf "$prompt" > /dev/tty
read -r input < /dev/tty || exit 0
[[ -z "$input" ]] && exit 0

if [[ "$input" == *=* ]]; then
    name="${input%%=*}"
    value="${input#*=}"
else
    name="$input"
    printf '\033[1;36mvalue for %s> \033[0m' "$name" > /dev/tty
    read -r value < /dev/tty || exit 0
fi

[[ -z "$name" || -z "$value" ]] && {
    printf '\n[!] Empty name or value, cancelled.\n' > /dev/tty
    sleep 1
    exit 0
}

# Write via q set so logging + dedup are consistent
"$q_bin" set "$name" "$value" > /dev/tty 2>&1
sleep 0.3
SETVAREOF
    chmod +x "$path"
}

# ===========================================================================
# _q_write_fill_helper — emit the on-screen variable fill picker
# ===========================================================================
# Runtime args: ($1 cmd  | --file $2 path-to-cmd) then
#   fill_state vars_file q_bin q_root mode(all|missing)
# For each placeholder needing a value, builds candidates via _q_build_candidates
# and opens a picker: a tmux popup overlay when $TMUX is set, else a nested fzf.
# Writes NAME=value to fill_state and persists via `q set`.
_q_write_fill_helper() {
    local path="$1"
    cat > "$path" <<'FILLEOF'
#!/usr/bin/env bash
set -uo pipefail

if [[ "${1:-}" == "--file" ]]; then
    cmd="$(cat "$2" 2>/dev/null)"; shift 2
else
    cmd="${1:-}"; shift 1
fi
fill_state="$1"; vars_file="$2"; q_bin="$3"; q_root="$4"; mode="${5:-all}"

# Strip ANSI from the command field.
cmd="$(printf '%s' "$cmd" | sed "s/$(printf '\033')\[[0-9;]*m//g")"

# Source libs so we can reuse _q_build_candidates + extraction helpers.
export Q_ROOT="$q_root"
# shellcheck disable=SC1091
source "$q_root/lib/core.sh"
# shellcheck disable=SC1091
source "$q_root/lib/session.sh"
# shellcheck disable=SC1091
source "$q_root/lib/variables.sh"
q_config_load 2>/dev/null || true

tmpdir="$(mktemp -d /tmp/q_fill_XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

# In "missing" mode, skip vars already resolvable.
declare -A resolved=()
if [[ "$mode" == "missing" ]]; then
    while IFS= read -r n; do [[ -n "$n" ]] && resolved["$n"]=1; done \
        < <(comm -23 \
              <(q_extract_vars "$cmd" | cut -f1 | awk 'NF && !s[$0]++' | sort) \
              <(q_unresolved_vars "$cmd" | sort) 2>/dev/null)
fi

seen=""
while IFS=$'\t' read -r name vtype vdefault; do
    [[ -z "$name" ]] && continue
    case " $seen " in *" $name "*) continue ;; esac
    seen="$seen $name"
    [[ "$mode" == "missing" && -n "${resolved[$name]:-}" ]] && continue

    cands="$(_q_build_candidates "$name" "$vtype" "$vdefault")"
    prompt="  {{${name}}}> "
    header="Enter: select | Tab: multi | Ctrl-A: all | Type: custom | Esc: skip"
    out="$tmpdir/out"; : > "$out"

    if [[ -n "${TMUX:-}" && -z "${Q_NO_POPUP:-}" ]]; then
        printf '%s\n' "$cands" > "$tmpdir/cands"
        tmux display-popup -E -w '75%' -h '45%' \
          "fzf --print-query --reverse --border --no-info --multi --bind=ctrl-a:select-all,ctrl-d:deselect-all --prompt='$prompt' --header='$header' < '$tmpdir/cands' > '$out'" || true
    else
        printf '%s\n' "$cands" \
          | fzf --print-query --reverse --border --no-info --multi \
                --bind='ctrl-a:select-all,ctrl-d:deselect-all' \
                --height=14 --prompt="$prompt" --header="$header" > "$out" 2>/dev/tty || true
    fi

    # --print-query: line 1 = query, then one line per selected item
    # (0 or many with --multi).
    typed=""
    IFS= read -r typed < "$out" || true
    _sels=()
    while IFS= read -r _sl; do
        [[ -z "$_sl" ]] && continue
        _sels+=("$_sl")
    done < <(tail -n +2 "$out")

    # Multi-select join: file/dir/path types with space, everything else
    # with comma. Overridable via Q_MULTI_SEP_FILE / Q_MULTI_SEP_CHOICE.
    value=""
    if [[ ${#_sels[@]} -ge 2 ]]; then
        _upper="${vtype^^}"
        case "$_upper" in
            FILE|DIR|OUTFILE|OUTPUT_FILE|WORDLIST|PATH) _sep="${Q_MULTI_SEP_FILE:- }" ;;
            *) _sep="${Q_MULTI_SEP_CHOICE:-,}" ;;
        esac
        _clean=()
        for _v in "${_sels[@]}"; do
            _v="${_v#\[*\] }"; _v="${_v%%$'\t'*}"
            _clean+=("$_v")
        done
        _IFS_bak="$IFS"; IFS="$_sep"; value="${_clean[*]}"; IFS="$_IFS_bak"
    else
        # Single-select — original typed-vs-picked precedence.
        sel="${_sels[0]:-}"
        sel_val="${sel#\[*\] }"
        sel_val="${sel_val%%$'\t'*}"
        if [[ -n "$typed" && -n "$sel_val" ]]; then
            typed_lc="${typed,,}"; sel_lc="${sel_val,,}"
            if [[ "$sel_lc" == *"$typed_lc"* ]]; then value="$sel_val"; else value="$typed"; fi
        elif [[ -n "$typed" ]]; then
            value="$typed"
        elif [[ -n "$sel_val" ]]; then
            value="$sel_val"
        fi
    fi
    [[ -z "$value" ]] && continue   # Esc / empty → leave unfilled

    # Persist: fill_state (transient, top priority) + session (next-time hint).
    if [[ -f "$fill_state" ]]; then
        grep -v -E "^${name}=" "$fill_state" > "$fill_state.tmp" 2>/dev/null || true
        mv "$fill_state.tmp" "$fill_state"
    fi
    printf '%s=%s\n' "$name" "$value" >> "$fill_state"
    "$q_bin" set "$name" "$value" >/dev/null 2>&1 || true
done < <(q_extract_vars "$cmd")
FILLEOF
    chmod +x "$path"
}

# ===========================================================================
# _q_write_decide_helper — emit the Enter "decider" used by fzf transform
# ===========================================================================
# Args: $1 cmd  $2 fill_state  $3 vars_file  $4 cur_cmd_file  $5 fill_script
#       $6 q_bin  $7 q_root
# Prints fzf actions: "accept" when fully resolved, else stash the command in
# cur_cmd_file and print an execute() that runs the fill picker (missing mode).
_q_write_decide_helper() {
    local path="$1"
    cat > "$path" <<'DECEOF'
#!/usr/bin/env bash
set -uo pipefail
cmd="$1"; fill_state="$2"; vars_file="$3"; cur_cmd_file="$4"
fill_script="$5"; q_bin="$6"; q_root="$7"

cmd="$(printf '%s' "$cmd" | sed "s/$(printf '\033')\[[0-9;]*m//g")"

export Q_ROOT="$q_root"
# shellcheck disable=SC1091
source "$q_root/lib/core.sh"
# shellcheck disable=SC1091
source "$q_root/lib/session.sh"
# shellcheck disable=SC1091
source "$q_root/lib/variables.sh"
q_config_load 2>/dev/null || true

if [[ -z "$(q_unresolved_vars "$cmd")" ]]; then
    printf 'accept'
else
    printf '%s' "$cmd" > "$cur_cmd_file"
    printf "execute(%q --file %q %q %q %q %q missing)+refresh-preview" \
        "$fill_script" "$cur_cmd_file" "$fill_state" "$vars_file" "$q_bin" "$q_root"
fi
DECEOF
    chmod +x "$path"
}

# ===========================================================================
# _q_write_varhint_helper — emit the variable-legend helper
# ===========================================================================
# Given a command string ($1), prints "  NAME   purpose" for each unique
# {{placeholder}}, using a built-in glossary with an auto-humanize fallback
# (DC_HOST -> "dc host"). Non-identifier tokens (e.g. SSTI {{7*7}}) are skipped.
_q_write_varhint_helper() {
    local path="$1"
    cat > "$path" <<'VHEOF'
#!/usr/bin/env bash
cmd="$1"
cmd="$(printf '%s' "$cmd" | sed "s/$(printf '\033')\[[0-9;]*m//g")"
printf '%s' "$cmd" | grep -oE '\{\{[^}]+\}\}' | awk '
BEGIN {
  g["TARGET"]="target host or IP"; g["RHOST"]="target / remote host"
  g["IP"]="target IP"; g["HOST"]="target hostname"; g["HOSTNAME"]="target hostname"
  g["LHOST"]="your (attacker) IP"; g["LPORT"]="your listening port"
  g["RPORT"]="remote port"; g["PORT"]="port"; g["PORTS"]="port list or range"
  g["URL"]="target URL"; g["DOMAIN"]="AD / DNS domain"
  g["DC_IP"]="domain controller IP"; g["DC_HOST"]="domain controller hostname"
  g["SUBNET"]="network range (CIDR)"; g["CIDR"]="network range (CIDR)"
  g["USERNAME"]="username you authenticate as (actor)"; g["USER"]="username you authenticate as (actor)"; g["PASSWORD"]="password for the actor"
  g["TARGET_USER"]="account you attack / modify (subject)"; g["TARGET_PASSWORD"]="subject account password"; g["TARGET_NTHASH"]="subject account NT hash"
  g["RHOST_NAME"]="target hostname / FQDN (for Kerberos)"
  g["USERLIST"]="username wordlist file"; g["USERS_FILE"]="username wordlist file"
  g["PASSLIST"]="password wordlist file"; g["WORDLIST"]="wordlist file path"
  g["HASH"]="hash to crack"; g["HASHFILE"]="file of hashes"; g["NTHASH"]="NTLM hash"
  g["KEY"]="key (SSH / API / etc.)"; g["API_KEY"]="API key"
  g["FILE"]="file path"; g["INFILE"]="input file"; g["OUTFILE"]="output file"
  g["OUTDIR"]="output directory"; g["DIR"]="directory"; g["PATH"]="path"
  g["LFILE"]="target file to read/write"; g["MOUNT_POINT"]="mount point"
  g["SHARE"]="share name"; g["CMD"]="command to run"; g["COMMAND"]="command to run"
  g["THREADS"]="thread count"; g["RATE"]="packet / request rate"
  g["PARAM"]="parameter name"; g["PATTERN"]="search pattern / regex"
  g["QUERY"]="query string"; g["DATABASE"]="database name"; g["SERVICE"]="service name"
  g["PID"]="process ID"; g["NAME"]="name"; g["IMAGE"]="image (repo:tag)"
  g["CONTAINER"]="container name or ID"; g["TAG"]="tag"; g["PROFILE"]="profile name"
  g["IFACE"]="network interface"; g["INTERFACE"]="network interface"
  g["CCACHE"]="Kerberos ccache file"; g["SPN"]="service principal name"
  g["KEYPATH"]="registry key path"; g["VALUE"]="registry value name"
  g["DATA"]="data / value"; g["DISK"]="disk / partition (e.g. sda1)"
  g["SOCKET"]="unix socket path"; g["BUCKET"]="S3 bucket name"
  g["COOKIE"]="session cookie"; g["TOKEN"]="auth token"; g["JWT"]="JWT token"
  g["HOSTPATH"]="host directory to mount"; g["CONTPATH"]="path inside container"
  g["HPORT"]="host port"; g["CPORT"]="container port"; g["LOCAL_PORT"]="local port"
  g["REMOTE"]="remote host / path"; g["DEST"]="destination"; g["LOCAL"]="local path"
  g["BINARY"]="binary / executable"; g["MODE"]="mode"
  g["COMMUNITY"]="SNMP community string"; g["TEMPLATE"]="certificate template name"
  g["CA"]="certificate authority name"; g["CA_NAME"]="certificate authority name"
  g["URLLIST"]="file of URLs"; g["HOSTLIST"]="file of hosts"; g["SID"]="domain SID"
  g["GROUP"]="group name"; g["ENDPOINT"]="API endpoint"; g["PAYLOAD"]="payload"
  g["SSID"]="wireless network name"; g["BSSID"]="access point MAC"
  g["CHANNEL"]="wireless channel"; g["ATTACKER"]="attacker host / IP"
}
function purpose(n,   h) {
  if (n in g) return g[n]
  h = tolower(n); gsub(/_/, " ", h); return h
}
{
  tok=$0; inner=substr(tok, 3, length(tok)-4)
  ci=index(inner, ":"); name=(ci>0)?substr(inner,1,ci-1):inner
  uname=toupper(name)
  if (uname !~ /^[A-Z][A-Z0-9_]*$/) next
  if (uname in seen) next
  seen[uname]=1
  printf "  %-12s %s\n", name, purpose(uname)
}'
VHEOF
    chmod +x "$path"
}

# ===========================================================================
# _q_write_builder_pick_helper — emit the Ctrl+B tool-picker helper script
# ===========================================================================
# Ctrl+B on the main picker fires this via `execute(...)+abort`. It opens
# a small fzf popup listing the user's enabled builder tools (curated via
# `q build add`). The chosen tool name is written to the sideband file; the
# main fzf aborts, and q_main picks up the sideband to invoke q_builder_run.
_q_write_builder_pick_helper() {
    local path="$1"
    cat > "$path" <<'BUILDERPICKEOF'
#!/usr/bin/env bash
set -uo pipefail

Q_ROOT="$1"
sideband="$2"

# shellcheck disable=SC1091
source "$Q_ROOT/lib/core.sh"
# shellcheck disable=SC1091
source "$Q_ROOT/lib/builder.sh"
q_config_load 2>/dev/null || true

# Enumerate enabled tools (union of YAML catalogs + user's config).
tools_out="$(_q_builder_enabled_tools 2>/dev/null)"
if [[ -z "$tools_out" ]]; then
    {
        printf '\n\033[1;33m[!]\033[0m No builder tools enabled yet.\n'
        printf '    Add some from your shell:\n'
        printf '      \033[1mq build add TOOL [TOOL...]\033[0m\n'
        printf '    e.g.  \033[1mq build add smbclient smbmap dirb ffuf hydra\033[0m\n\n'
        printf '    Press any key to return to the picker...\n'
    } > /dev/tty
    read -rsn1 -t 5 _ < /dev/tty 2>/dev/null || true
    exit 0
fi

# Small fzf popup — one row per enabled tool, source annotated dim.
# The user picks ONE tool; writing to sideband triggers q_main dispatch.
lines=""
while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    if _q_builder_path "$t" >/dev/null 2>&1; then src="yaml"
    else                                          src="auto"; fi
    lines="${lines}${t}"$'\t'"${src}"$'\n'
done <<< "$tools_out"

sel="$(printf '%s' "$lines" | fzf \
        --reverse --border --height=50% --no-info \
        --prompt='build for tool > ' \
        --header='Enter: open flag composer  |  Esc: cancel' \
        --delimiter=$'\t' --with-nth=1 --nth=1 \
        --preview='printf "\033[1m%s\033[0m  (%s)\n\nAll flag data from this source loads into the multi-select composer next.\n" {1} {2}' \
        --preview-window='right:40%:wrap' \
        2>/dev/tty)" || exit 0

sel="${sel%%$'\t'*}"
[[ -z "$sel" ]] && exit 0

# Invoke the flag composer inline so we can write the FULL assembled
# template to the unified sideband (.built_cmd). q_main reads that.
built="$(q_builder_run "$sel" 2>/dev/tty)"
[[ -z "$built" ]] && exit 0
printf '%s' "$built" > "$sideband"
BUILDERPICKEOF
    chmod +x "$path"
}

# ===========================================================================
# _q_write_modify_helper — emit the Ctrl+M "modify current row" script
# ===========================================================================
# On Ctrl+M in the picker the highlighted row's command is passed in.
# Extract the tool and the flags actually present, then open the builder
# multi-select with those flags PRE-SELECTED. User Tabs to add/remove,
# hits Enter, and the assembled template lands in the shared .built_cmd
# sideband (same path Ctrl+B uses).
_q_write_modify_helper() {
    local path="$1"
    cat > "$path" <<'MODIFYEOF'
#!/usr/bin/env bash
set -uo pipefail

Q_ROOT="$1"
sideband="$2"
raw_cmd="$3"

# shellcheck disable=SC1091
source "$Q_ROOT/lib/core.sh"
# shellcheck disable=SC1091
source "$Q_ROOT/lib/combos.sh"      # provides _q_combo_tool_for
# shellcheck disable=SC1091
source "$Q_ROOT/lib/builder.sh"
q_config_load 2>/dev/null || true

# Strip ANSI + placeholder tokens so the flag extractor sees the actual
# shape of the command.
cmd="$(printf '%s' "$raw_cmd" | sed "s/$(printf '\033')\[[0-9;]*m//g")"
tool="$(_q_combo_tool_for "$cmd" 2>/dev/null)"
if [[ -z "$tool" ]]; then
    printf '\n\033[1;33m[!]\033[0m Could not detect tool from that row.\n' > /dev/tty
    printf '    Press any key...\n' > /dev/tty
    read -rsn1 -t 5 _ < /dev/tty 2>/dev/null || true
    exit 0
fi

# Ensure the tool has a builder catalog. If not, auto-parse --help on
# the fly and cache it — no reason to send the user back to a shell
# command for something we can do right now. Falls through to a Ctrl+E
# hint only if --help produces nothing usable (uninstalled tool /
# unparseable output).
have_catalog=0
if _q_builder_path "$tool" >/dev/null 2>&1; then
    have_catalog=1
elif [[ -s "$(_q_builder_auto_cache "$tool")" ]]; then
    have_catalog=1
fi
if [[ "$have_catalog" -eq 0 ]]; then
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf '\n\033[1;33m[!]\033[0m %s is not installed on this host.\n' "$tool" > /dev/tty
        printf '    Ctrl+E to edit the raw command instead.\n' > /dev/tty
        printf '    Press any key...\n' > /dev/tty
        read -rsn1 -t 5 _ < /dev/tty 2>/dev/null || true
        exit 0
    fi
    printf '  parsing %s --help ...' "$tool" > /dev/tty
    cache_file="$(_q_builder_auto_cache "$tool")"
    if _q_builder_parse_help "$tool" > "${cache_file}.tmp" 2>/dev/null \
       && [[ -s "${cache_file}.tmp" ]]; then
        mv "${cache_file}.tmp" "$cache_file"
        # Add to enabled tools list so it stays available in future picks.
        cfg="$(_q_builder_config_file)"
        mkdir -p "$(dirname "$cfg")"; touch "$cfg"
        if ! grep -qxF "$tool" "$cfg" 2>/dev/null; then
            printf '%s\n' "$tool" >> "$cfg"
        fi
        printf ' cached %s flags\n' "$(wc -l < "$cache_file" | tr -d ' ')" > /dev/tty
        have_catalog=1
    else
        rm -f "${cache_file}.tmp"
        printf '\n\033[1;33m[!]\033[0m %s: --help produced nothing the parser could use.\n' "$tool" > /dev/tty
        printf '    Ctrl+E to edit the raw command instead.\n' > /dev/tty
        printf '    Press any key...\n' > /dev/tty
        read -rsn1 -t 5 _ < /dev/tty 2>/dev/null || true
        exit 0
    fi
fi

# Collect the flags the current command already uses. Simple lexical scan:
# any token starting with '-' after the tool binary. Skip placeholders and
# redirect operators. Empty result is fine — user just picks fresh flags.
used=""
seen_tool=0
for tok in $cmd; do
    [[ "$tok" == "sudo" || "$tok" == "$tool" ]] && { seen_tool=1; continue; }
    [[ "$seen_tool" -eq 0 ]] && continue
    case "$tok" in
        -*) used="${used}${tok}"$'\n' ;;
    esac
done

# Load the catalog into arrays via the same yq/tsv path q_builder_run uses.
tmpdir="$(mktemp -d /tmp/q_modify_XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT
_flag_src=""
if _q_builder_path "$tool" >/dev/null 2>&1; then
    catalog_path="$(_q_builder_path "$tool")"
    _flag_src=$(yq -r '.flags[] | [.flag // "", .desc // "", .value.name // "", .value.type // "", .value.default // ""] | @tsv' "$catalog_path" 2>/dev/null)
else
    _flag_src=$(cat "$(_q_builder_auto_cache "$tool")")
fi

# Build the candidate list, and while at it record which row indices match
# a "used" flag so we can pre-select them via `load:pos(N)+select+...`.
cands_file="$tmpdir/cands"
: > "$cands_file"
pre_marks=""
idx=0
while IFS=$'\t' read -r f d vn vt vd; do
    [[ -z "$f" ]] && continue
    idx=$((idx + 1))
    printf '%s\t%s\n' "$f" "$d" >> "$cands_file"
    if grep -qxF "$f" <<< "$used"; then
        # fzf pos() is 1-indexed; chain pos(N)+select for each match.
        pre_marks="${pre_marks:+${pre_marks}+}pos(${idx})+select"
    fi
done <<< "$_flag_src"

if [[ -z "$pre_marks" ]]; then
    load_bind="pos(1)"
else
    load_bind="${pre_marks}+pos(1)"
fi

raw="$(fzf --multi --print-query --reverse --border --no-info \
        --prompt="modify ${tool}> " \
        --header="pre-marked = current flags  |  Tab: toggle  |  Ctrl-A: all  |  Enter: rebuild  |  Esc: cancel" \
        --bind='ctrl-a:select-all,ctrl-d:deselect-all' \
        --bind="load:${load_bind}" \
        --tabstop=20 \
        --delimiter=$'\t' --with-nth=1,2 \
        < "$cands_file" 2>/dev/tty)" || exit 0
[[ -z "$raw" ]] && exit 0

# Parse (line 1 = query, then each selected row as flag\tdesc).
picked=()
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    picked+=("${line%%$'\t'*}")
done < <(printf '%s\n' "$raw" | tail -n +2)
[[ ${#picked[@]} -eq 0 ]] && exit 0

# Follow-up: which of the picked flags should be OPTIONAL (asked at fill
# time via {{?tag}}...{{/tag}})? Same UX as the fresh builder — Enter
# with nothing marked = everything required. Pre-mark flags that were
# ALREADY inside optional blocks in the original command so a plain
# Enter preserves the shape.
opt_cands_file="$tmpdir/opt_cands"
: > "$opt_cands_file"
opt_pre=""
opt_idx=0
for pf in "${picked[@]}"; do
    # Look up description from the flag catalog TSV so the picker shows
    # what each flag does.
    _pd=""
    while IFS=$'\t' read -r f d vn vt vd; do
        [[ "$f" == "$pf" ]] && { _pd="$d"; break; }
    done <<< "$_flag_src"
    opt_idx=$((opt_idx + 1))
    printf '%s\t%s\n' "$pf" "$_pd" >> "$opt_cands_file"
    # Was this flag inside a {{?...}}...{{/...}} block in the ORIGINAL
    # command? Then pre-mark it as optional so plain Enter preserves shape.
    if [[ "$cmd" == *"{{?"* ]] && \
       [[ "$cmd" =~ \{\{\?[^}]+\}\}[^{]*"$pf" ]]; then
        opt_pre="${opt_pre:+${opt_pre}+}pos(${opt_idx})+select"
    fi
done
opt_load="${opt_pre:+${opt_pre}+}pos(1)"

opt_raw="$(fzf --multi --print-query --reverse --border --no-info \
            --prompt="which flags are OPTIONAL (ask at fill time)? " \
            --header="pre-marked = already optional  |  Tab: toggle  |  Enter: continue  |  Esc: all required" \
            --bind='ctrl-a:select-all,ctrl-d:deselect-all' \
            --bind="load:${opt_load}" \
            --tabstop=20 --delimiter=$'\t' --with-nth=1,2 \
            < "$opt_cands_file" 2>/dev/tty)" || opt_raw=""
declare -A is_optional=()
if [[ -n "$opt_raw" ]]; then
    while IFS= read -r ol; do
        [[ -z "$ol" ]] && continue
        is_optional["${ol%%$'\t'*}"]=1
    done < <(printf '%s\n' "$opt_raw" | tail -n +2)
fi

# Reassemble template. Optional flags get their whole flag+placeholder
# segment wrapped in {{?tag}}...{{/tag}}. Tag = flag stripped of dashes,
# non-word chars replaced with _.
declare -A vname vtype vdefault
while IFS=$'\t' read -r f d vn vt vd; do
    [[ -z "$f" ]] && continue
    vname["$f"]="$vn"; vtype["$f"]="$vt"; vdefault["$f"]="$vd"
done <<< "$_flag_src"

assembled="$tool"
for pf in "${picked[@]}"; do
    seg="$pf"
    _vn="${vname[$pf]:-}"; _vt="${vtype[$pf]:-}"; _vd="${vdefault[$pf]:-}"
    if [[ -n "$_vn" ]]; then
        ph="{{${_vn}"
        [[ -n "$_vt" ]] && ph="${ph}:${_vt}"
        [[ -n "$_vd" ]] && ph="${ph}:${_vd}"
        seg="${seg} ${ph}}}"
    fi
    if [[ -n "${is_optional[$pf]:-}" ]]; then
        tag="${pf##-}"; tag="${tag##-}"
        tag="${tag//[^A-Za-z0-9_]/_}"
        [[ -z "$tag" ]] && tag="opt"
        seg="{{?${tag}}}${seg}{{/${tag}}}"
    fi
    assembled="${assembled} ${seg}"
done

# Preserve any positional {{TARGET}} the original had (nmap etc.).
for tok in $cmd; do
    if [[ "$tok" == '{{'*'}}' ]]; then
        # Skip placeholder tokens the flag catalog already inserted.
        case "$assembled" in
            *"$tok"*) ;;
            *) assembled="$assembled $tok" ;;
        esac
    fi
done

printf '%s' "$assembled" > "$sideband"
MODIFYEOF
    chmod +x "$path"
}

# ===========================================================================
# _q_write_delete_helper — emit the Ctrl+D "delete current row" script
# ===========================================================================
# Dispatches by source of the highlighted row:
#   src starts with "combo:"     → q_combo_forget TOOL TEMPLATE
#   src ends with ".md"          → cheatsheet delete (uses q_author_delete_entry)
# Always confirms before deleting. After a cheatsheet edit, reindexes.
_q_write_delete_helper() {
    local path="$1"
    cat > "$path" <<'DELETEEOF'
#!/usr/bin/env bash
set -uo pipefail

Q_ROOT="$1"
title="$2"
raw_cmd="$3"
src="$4"

# shellcheck disable=SC1091
source "$Q_ROOT/lib/core.sh"
# shellcheck disable=SC1091
source "$Q_ROOT/lib/session.sh"
# shellcheck disable=SC1091
source "$Q_ROOT/lib/combos.sh"
# shellcheck disable=SC1091
source "$Q_ROOT/lib/parser.sh"
# shellcheck disable=SC1091
source "$Q_ROOT/lib/authoring.sh"
q_config_load 2>/dev/null || true

strip_ansi() { sed "s/$(printf '\033')\[[0-9;]*m//g"; }
title="$(printf '%s' "$title" | strip_ansi)"
cmd="$(printf '%s' "$raw_cmd" | strip_ansi)"
src="$(printf '%s' "$src" | strip_ansi)"

case "$src" in
    combo:*)
        # Extract tool from "combo:<tool>.tsv"
        rest="${src#combo:}"; tool="${rest%.tsv}"
        printf '\n\033[1;31m[?]\033[0m Delete combo:\n' > /dev/tty
        printf '      tool: \033[1m%s\033[0m\n' "$tool" > /dev/tty
        printf '      cmd:  %s\n' "$cmd" > /dev/tty
        printf '    [y] confirm  [any other key] cancel: ' > /dev/tty
        read -rsn1 reply < /dev/tty
        printf '\n' > /dev/tty
        if [[ "$reply" == "y" || "$reply" == "Y" ]]; then
            q_combo_forget "$tool" "$cmd"
        else
            printf '  (cancelled)\n' > /dev/tty
            sleep 0.5
        fi
        ;;
    *.md|*.md\ *)
        # Cheatsheet row — src is the source .md path relative to cheatsheets/
        rel="${src%% *}"
        file="${Q_SHEETS_DIR}/${rel}"
        if [[ ! -f "$file" ]]; then
            printf '\n\033[1;33m[!]\033[0m Source file not found: %s\n' "$rel" > /dev/tty
            sleep 1
            exit 0
        fi
        printf '\n\033[1;31m[?]\033[0m Delete cheatsheet entry:\n' > /dev/tty
        printf '      file:  %s\n' "$rel" > /dev/tty
        printf '      title: \033[1m%s\033[0m\n' "$title" > /dev/tty
        printf '      cmd:   %s\n' "$cmd" > /dev/tty
        printf '    [y] confirm  [any other key] cancel: ' > /dev/tty
        read -rsn1 reply < /dev/tty
        printf '\n' > /dev/tty
        if [[ "$reply" == "y" || "$reply" == "Y" ]]; then
            if q_author_delete_entry "$file" "$title"; then
                q_rebuild_index >/dev/null 2>&1 || true
                printf '  \033[1;32m[+]\033[0m Deleted "%s" from %s\n' "$title" "$rel" > /dev/tty
                sleep 1
            else
                printf '  \033[1;31m[-]\033[0m Could not find "%s" in %s\n' "$title" "$rel" > /dev/tty
                sleep 1
            fi
        else
            printf '  (cancelled)\n' > /dev/tty
            sleep 0.5
        fi
        ;;
    *)
        printf '\n\033[1;33m[!]\033[0m This row cannot be deleted (src="%s")\n' "$src" > /dev/tty
        sleep 1
        ;;
esac
DELETEEOF
    chmod +x "$path"
}

# ===========================================================================
# _q_write_chain_pick_helper — emit the Ctrl+X chain composer script
# ===========================================================================
# Multi-select from the same picker feed (combos + cheatsheets). Selected
# commands get joined with " && " into one template. Placeholders that
# appear in multiple commands only get prompted once by the fill flow.
_q_write_chain_pick_helper() {
    local path="$1"
    cat > "$path" <<'CHAINEOF'
#!/usr/bin/env bash
set -uo pipefail

Q_ROOT="$1"
sideband="$2"
feed_file="$3"

# shellcheck disable=SC1091
source "$Q_ROOT/lib/core.sh"
q_config_load 2>/dev/null || true

if [[ ! -s "$feed_file" ]]; then
    printf '\n\033[1;33m[!]\033[0m Picker feed missing. Reopen Ctrl+Q and try again.\n' > /dev/tty
    sleep 1
    exit 0
fi

# Feed rows are 10-column TSV (parser.sh layout):
#   1 CATEGORY 2 TOOL 3 TITLE 4 DESC 5 CMD 6 RISK 7 PHASE 8 TAGS 9 SRC 10 PLATFORM
# We display "TOOL │ TITLE" and let fzf multi-select. Selected rows come
# back as the full TSV so we can grab field 5 (CMD).
raw="$(awk -F'\t' '
    { printf "%s\t%s | %s\n", NR, $2 " │ " $3, $5 }
' "$feed_file" | fzf --multi --print-query --reverse --border --no-info \
        --prompt='chain (Tab: mark, Enter: build)> ' \
        --header='Selected commands get joined with && in the order you mark them' \
        --bind='ctrl-a:select-all,ctrl-d:deselect-all' \
        --delimiter=$'\t' --with-nth=2 \
        2>/dev/tty)" || exit 0
[[ -z "$raw" ]] && exit 0

# Skip the query (line 1); each remaining line is "NR\tdisplay\tcmd".
# But because our awk emitted "NR\tdisplay | cmd" we need to split on
# " | " to recover the cmd. Cleaner: re-read the feed by NR and grab
# column 5 directly.
nrs=()
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    nrs+=("${line%%$'\t'*}")
done < <(printf '%s\n' "$raw" | tail -n +2)
[[ ${#nrs[@]} -eq 0 ]] && exit 0

# Look up each picked NR in the feed file, extract command (field 5).
# Preserve the user's pick ORDER (nrs[] is in tab order which is the
# selection order from fzf --print-query --multi).
assembled=""
for nr in "${nrs[@]}"; do
    cmd="$(awk -F'\t' -v want="$nr" 'NR == want { print $5 }' "$feed_file")"
    [[ -z "$cmd" ]] && continue
    if [[ -z "$assembled" ]]; then
        assembled="$cmd"
    else
        assembled="${assembled} && ${cmd}"
    fi
done

[[ -z "$assembled" ]] && exit 0
printf '%s' "$assembled" > "$sideband"
CHAINEOF
    chmod +x "$path"
}
