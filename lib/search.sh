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
# When the user hits Enter and every placeholder resolves from the current
# session, q_main's call to q_fill_vars_auto succeeds and the secondary
# per-variable fzf prompts are skipped entirely. If the user hits Ctrl+F
# instead, a sideband file (${Q_CACHE_DIR}/.force_interactive) is created
# so q_main can be told to skip the autofill attempt.
#
# Keybindings in the main fzf:
#   Enter     run (autofill if session has everything, else old fill flow)
#   Ctrl+F    force interactive variable fill (old flow)
#   Ctrl+E    force interactive fill then open in $EDITOR before exec
#   Ctrl+T    cycle TARGET through session targets; preview updates live
#   Ctrl+Y    copy the session-filled command to the clipboard
#   Tab       toggle preview
#   Esc       quit

# ===========================================================================
# q_search — main fzf search interface
# ===========================================================================
# Arguments: optional initial query string (all args joined)
# Stdout:    TSV line  CATEGORY/TOOL \t TITLE \t COMMAND  (for the selection)
# Exit 1 if no selection (Escape / Ctrl+C).
#
# Sideband flag files (consumed by q_main, run in a command substitution so
# env exports don't propagate):
#   ${Q_CACHE_DIR}/.force_interactive  exists  -> skip q_fill_vars_auto
#   ${Q_CACHE_DIR}/.force_edit         exists  -> after fill, open in editor
q_search() {
    local index_file="${Q_CACHE_DIR}/index.tsv"
    local initial_query="${*}"

    # -----------------------------------------------------------------------
    # Reset sideband flags for this invocation
    # -----------------------------------------------------------------------
    rm -f "${Q_CACHE_DIR}/.force_interactive" "${Q_CACHE_DIR}/.force_edit"

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

        # Strip ANSI so field parsing is clean
        line="\$(printf '%s' "\$line" | sed 's/\x1b\[[0-9;]*m//g')"
        # Layout: DISPLAY \t title \t cmd \t src
        IFS=\$'\t' read -r _display _title _cmd _src <<< "\$line"

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
                if (name in cycle && cycle[name] != "") {
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

        # Risk color
        case "\$_risk" in
            safe|low)       risk_color="\${green}" ;;
            med|medium)     risk_color="\${yellow}" ;;
            high|critical)  risk_color="\${red}" ;;
            *)              risk_color="\${dim}" ;;
        esac

        printf '%s\n'     "\${bold}\${cyan}TEMPLATE\${reset}"
        printf '  %s\n\n' "\${dim}\${highlighted_cmd}\${reset}"

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

    _q_write_copy_helper "$copy_script"
    _q_write_cycle_helper "$cycle_script"
    _q_write_setvar_helper "$setvar_script"

    # -----------------------------------------------------------------------
    # Build the display list and run fzf.
    # Display columns 1..3: CATEGORY/TOOL, TITLE, DESCRIPTION
    # Hidden columns 4..8:  COMMAND, RISK, PHASE, TAGS, SOURCE_FILE
    # Search matches against visible cols (title + description + tool),
    # NOT the bash command — so users type "find windows users" not nxc flags.
    # --expect captures Ctrl+F / Ctrl+E so the shell layer can set sideband
    # flags before returning.
    # -----------------------------------------------------------------------
    local q_bin="${Q_ROOT}/q"
    local mru_file="${Q_DATA_DIR}/mru"
    local selected
    selected="$(
        awk -F'\t' \
            -v cyan=$'\033[36m' \
            -v bold=$'\033[1m' \
            -v dim=$'\033[2m' \
            -v magenta=$'\033[35m' \
            -v reset=$'\033[0m' \
            -v sep=$'\033[2m│\033[0m' \
            -v mru_file="$mru_file" \
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
            tool  = $2
            title = $3
            desc  = ($4 != "") ? $4 : "(no description)"
            cmd   = $5
            src   = $9

            mark = (title in mru_rank) ? (magenta "★" reset " ") : "  "
            rank = (title in mru_rank) ? mru_rank[title] : 999999

            # Build colored, padded display: TOOL | TITLE | DESCRIPTION
            tool_col  = mark cyan pad(tool, tool_w - 2) reset
            title_col = bold pad(title, title_w) reset
            desc_col  = dim desc reset
            display   = tool_col " " sep " " title_col " " sep " " desc_col

            # Emit:  rank \t row_no \t display \t title \t cmd \t src
            # Sort prefix gets stripped after sort.
            printf "%010d\t%010d\t%s\t%s\t%s\t%s\n", \
                rank, NR, display, title, cmd, src
        }
        ' "$index_file" \
        | sort -k1,1n -k2,2n \
        | cut -f3- \
        | fzf \
            --ansi \
            --prompt='q> ' \
            --header='★ = recent | Enter: run | Ctrl+S: set var | Ctrl+F: fill | Ctrl+T: cycle | Ctrl+Y: copy | Ctrl+E: edit | Esc: quit' \
            --preview="$preview_cmd" \
            --preview-window="${Q_PREVIEW_POS:-down:30%:wrap}" \
            --query="$initial_query" \
            --expect="ctrl-f,ctrl-e" \
            --bind="ctrl-y:execute-silent('${copy_script}' {3} '${vars_file}')+abort" \
            --bind="ctrl-t:execute-silent('${cycle_script}' '${targets_file}' '${cycle_file}')+refresh-preview" \
            --bind="ctrl-s:execute('${setvar_script}' {3} '${vars_file}' '${q_bin}')+refresh-preview" \
            --bind='tab:toggle-preview' \
            --delimiter=$'\t' \
            --with-nth=1 \
            --nth=1 \
            --tabstop=4 \
            --color='pointer:cyan,prompt:cyan,hl:yellow,hl+:yellow:bold' \
            --no-multi \
            --exit-0 \
            ${Q_FZF_OPTS:-}
    )" || true

    if [[ -z "$selected" ]]; then
        return 1
    fi

    # -----------------------------------------------------------------------
    # --expect output layout:
    #   line 1 — pressed key (empty when Enter was used)
    #   line 2 — selected row
    # -----------------------------------------------------------------------
    local expect_key selection_line
    IFS=$'\n' read -r expect_key <<< "$selected" || true
    selection_line="${selected#*$'\n'}"
    if [[ "$selection_line" == "$selected" ]]; then
        # No newline present — treat the whole blob as the selection
        selection_line="$selected"
        expect_key=""
    fi

    # Ctrl+F: force interactive fill (skip autofill attempt).
    # Ctrl+E: force interactive fill + edit the filled command before exec.
    case "$expect_key" in
        ctrl-f) touch "${Q_CACHE_DIR}/.force_interactive" ;;
        ctrl-e) touch "${Q_CACHE_DIR}/.force_interactive" "${Q_CACHE_DIR}/.force_edit" ;;
    esac

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
stripped=$(printf '%s' "$raw" | sed 's/\x1b\[[0-9;]*m//g')
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

if command -v xclip >/dev/null 2>&1; then
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
mapfile -t all < <(awk -F: 'NF>1 { $1=""; sub(/^ /, ""); print }' "$targets_file")
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
cmd=$(printf '%s' "$raw_cmd" | sed 's/\x1b\[[0-9;]*m//g')

# Extract unique variable names from {{NAME[:type[:default]]}} placeholders
mapfile -t allvars < <(grep -oP '\{\{[^}]+\}\}' <<< "$cmd" \
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
