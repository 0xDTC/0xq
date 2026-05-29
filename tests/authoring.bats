#!/usr/bin/env bats
# Tests for lib/authoring.sh — create / edit / delete cheatsheet entries.
# Only the pure (non-tty) helpers are exercised here; they do the actual file
# mutation, so they carry the real risk. The fzf/read orchestrators are glue.

load test_helper

setup() {
    Q_TEST_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    export Q_TEST_ROOT Q_ROOT="$Q_TEST_ROOT" Q_VERSION="test"
    export XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
    export Q_DATA_DIR="$XDG_DATA_HOME/q"
    export Q_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
    export Q_SESSION_DIR="$Q_DATA_DIR/sessions"
    export Q_VAR_HISTORY_DIR="$Q_DATA_DIR/var_history"
    export Q_SESSION_NAME="test_$$"
    export Q_RED='' Q_GREEN='' Q_YELLOW='' Q_BLUE='' Q_CYAN='' Q_MAGENTA='' Q_DIM='' Q_BOLD='' Q_RESET=''
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/core.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/parser.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/authoring.sh"
    # core.sh hard-sets Q_SHEETS_DIR=$Q_ROOT/cheatsheets, so override it AFTER
    # sourcing — tests must write to a throwaway dir, never the repo's sheets.
    export Q_SHEETS_DIR="$BATS_TEST_TMPDIR/sheets"
    mkdir -p "$Q_DATA_DIR" "$Q_CACHE_DIR" "$Q_SESSION_DIR" "$Q_VAR_HISTORY_DIR" "$Q_SHEETS_DIR/test"
    SHEET="$Q_SHEETS_DIR/test/tool.md"
    printf '# tool\n' > "$SHEET"
}

@test "build_entry emits well-formed markdown" {
    run q_author_build_entry "scan full nmap" "Aggressive scan" "nmap -A {{TARGET:ip}}" "high" "recon" "nmap,scan"
    [ "$status" -eq 0 ]
    [[ "$output" == *"## scan full nmap"* ]]
    [[ "$output" == *"Aggressive scan"* ]]
    [[ "$output" == *'```bash'* ]]
    [[ "$output" == *"nmap -A {{TARGET:ip}}"* ]]
    [[ "$output" == *"<!-- meta: risk=high | phase=recon | tags=nmap,scan -->"* ]]
}

@test "build_entry omits tags when empty and desc when empty" {
    run q_author_build_entry "t" "" "echo hi" "low" "misc" ""
    [[ "$output" == *"<!-- meta: risk=low | phase=misc -->"* ]]
    [[ "$output" != *"tags="* ]]
}

@test "append_entry: first entry has no separator, second gets ---" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "first cmd" "d1" "echo 1" "low" "misc" "")"
    run grep -c '^---$' "$SHEET"; [ "$output" -eq 0 ]
    q_author_append_entry "$SHEET" "$(q_author_build_entry "second cmd" "d2" "echo 2" "low" "misc" "")"
    run grep -c '^---$' "$SHEET"; [ "$output" -eq 1 ]
    run grep -c '^## ' "$SHEET"; [ "$output" -eq 2 ]
}

@test "append + parser indexes the new command with correct fields" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "list shares smb" "enum shares" "smbmap -H {{TARGET:ip}}" "low" "enum" "smb")"
    q_build_index
    run grep -F "smbmap -H {{TARGET:ip}}" "$Q_CACHE_DIR/index.tsv"
    [ "$status" -eq 0 ]
    [[ "$output" == *"list shares smb"* ]]
    [[ "$output" == *"enum"* ]]
}

@test "delete_entry removes the entry; missing title returns 1" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "keep me" "d" "echo keep" "low" "misc" "")"
    q_author_append_entry "$SHEET" "$(q_author_build_entry "drop me" "d" "echo drop" "low" "misc" "")"
    run q_author_delete_entry "$SHEET" "drop me"; [ "$status" -eq 0 ]
    run grep -c '^## ' "$SHEET"; [ "$output" -eq 1 ]
    run grep -F "echo drop" "$SHEET"; [ "$status" -ne 0 ]
    run grep -F "echo keep" "$SHEET"; [ "$status" -eq 0 ]
    run q_author_delete_entry "$SHEET" "does not exist"; [ "$status" -eq 1 ]
}

@test "delete_entry then reindex drops it from the index" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "alpha cmd" "d" "echo a" "low" "misc" "")"
    q_author_append_entry "$SHEET" "$(q_author_build_entry "beta cmd" "d" "echo b" "low" "misc" "")"
    q_author_delete_entry "$SHEET" "alpha cmd"
    q_build_index
    run grep -F "alpha cmd" "$Q_CACHE_DIR/index.tsv"; [ "$status" -ne 0 ]
    run grep -F "beta cmd" "$Q_CACHE_DIR/index.tsv";  [ "$status" -eq 0 ]
}

@test "replace_entry swaps command in place, preserving order" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "one" "d" "echo one" "low" "misc" "")"
    q_author_append_entry "$SHEET" "$(q_author_build_entry "two" "d" "echo two" "low" "misc" "")"
    q_author_append_entry "$SHEET" "$(q_author_build_entry "three" "d" "echo three" "low" "misc" "")"
    run q_author_replace_entry "$SHEET" "two" "$(q_author_build_entry "two" "edited" "echo TWO_EDITED" "high" "exploit" "x")"
    [ "$status" -eq 0 ]
    run grep -c '^## ' "$SHEET"; [ "$output" -eq 3 ]
    # 'two' is still the 2nd heading (position preserved)
    run bash -c "grep -n '^## ' '$SHEET' | sed -n 2p"; [[ "$output" == *"## two"* ]]
    run grep -F "echo TWO_EDITED" "$SHEET"; [ "$status" -eq 0 ]
    run grep -F "echo two"        "$SHEET"; [ "$status" -ne 0 ]
    q_build_index
    run grep -F "echo TWO_EDITED" "$Q_CACHE_DIR/index.tsv"; [ "$status" -eq 0 ]
}

@test "replace_entry can change the title (key) of an entry" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "old title" "d" "echo x" "low" "misc" "")"
    run q_author_replace_entry "$SHEET" "old title" "$(q_author_build_entry "new title" "d" "echo x" "low" "misc" "")"
    [ "$status" -eq 0 ]
    run grep -F "## new title" "$SHEET"; [ "$status" -eq 0 ]
    run grep -F "## old title" "$SHEET"; [ "$status" -ne 0 ]
}

@test "replace_entry on missing title returns 1" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "only" "d" "echo only" "low" "misc" "")"
    run q_author_replace_entry "$SHEET" "nope" "$(q_author_build_entry "x" "" "echo x" "low" "misc" "")"
    [ "$status" -eq 1 ]
}

@test "type_vars expands bare vars and leaves already-typed ones" {
    # Stub the interactive pickers: always choose type 'ip', no default.
    _q_author_fzf() { printf 'ip'; }
    _q_author_read() { printf ''; }
    result="$(_q_author_type_vars "nmap {{TARGET}} -p {{PORTS:port:80}} {{TARGET}}")"
    [[ "$result" == *"{{TARGET:ip}}"* ]]
    [[ "$result" == *"{{PORTS:port:80}}"* ]]
    # both occurrences of {{TARGET}} expanded, none left bare
    [[ "$result" != *"{{TARGET}}"* ]]
}

@test "build_entry rejects an empty / whitespace-only title" {
    run q_author_build_entry "   " "d" "echo x" "low" "misc" ""; [ "$status" -eq 1 ]
    run q_author_build_entry ""    "d" "echo x" "low" "misc" ""; [ "$status" -eq 1 ]
}

@test "build_entry trims and de-tabs the title (matches parser index)" {
    block="$(q_author_build_entry "  spaced title  " "d" "echo x" "low" "misc" "")"
    [[ "$block" == *"## spaced title"* ]]
    [[ "$block" != *"##   spaced"* ]]
    q_author_append_entry "$SHEET" "$block"
    run q_author_delete_entry "$SHEET" "spaced title"; [ "$status" -eq 0 ]
    run grep -c '^## ' "$SHEET"; [ "$output" -eq 0 ]
}

@test "delete handles a title containing a backslash" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry 'back\slash here' "d" "echo bs" "low" "misc" "")"
    run q_author_delete_entry "$SHEET" 'back\slash here'; [ "$status" -eq 0 ]
    run grep -F 'echo bs' "$SHEET"; [ "$status" -ne 0 ]
}

@test "delete removes only the FIRST of duplicate titles" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "dupe" "d" "echo first" "low" "misc" "")"
    q_author_append_entry "$SHEET" "$(q_author_build_entry "dupe" "d" "echo second" "low" "misc" "")"
    run q_author_delete_entry "$SHEET" "dupe"; [ "$status" -eq 0 ]
    run grep -c '^## dupe' "$SHEET"; [ "$output" -eq 1 ]
    run grep -F 'echo second' "$SHEET"; [ "$status" -eq 0 ]
}

@test "delete of the last entry leaves no dangling separator" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "first" "d" "echo 1" "low" "misc" "")"
    q_author_append_entry "$SHEET" "$(q_author_build_entry "last" "d" "echo 2" "low" "misc" "")"
    q_author_delete_entry "$SHEET" "last"
    run grep -c '^## ' "$SHEET"; [ "$output" -eq 1 ]
    run bash -c "tail -n1 '$SHEET' | grep -c '^---'"; [ "$output" -eq 0 ]
}

@test "delete handles CRLF source files" {
    printf '# tool\r\n\r\n## winentry\r\necho win\r\n\r\n<!-- meta: risk=low | phase=misc -->\r\n' > "$SHEET"
    run q_author_delete_entry "$SHEET" "winentry"; [ "$status" -eq 0 ]
    run grep -F 'echo win' "$SHEET"; [ "$status" -ne 0 ]
}

@test "type_vars escapes & in a default value" {
    _q_author_fzf() { printf 'str'; }
    _q_author_read() { printf 'a&b'; }
    result="$(_q_author_type_vars "run {{TOK}}")"
    [[ "$result" == *"{{TOK:str:a&b}}"* ]]
}

@test "extract_command returns a single-line command verbatim" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "one liner" "d" "nmap -sV {{TARGET:ip}}" "low" "misc" "")"
    run q_author_extract_command "$SHEET" "one liner"
    [ "$status" -eq 0 ]
    [ "$output" = "nmap -sV {{TARGET:ip}}" ]
}

@test "extract_command returns a multi-line command intact (3 lines)" {
    ml=$'msfvenom -p win \\\n  LHOST={{LHOST:ip}} \\\n  -f exe -o {{OUTFILE:file}}'
    q_author_append_entry "$SHEET" "$(q_author_build_entry "build payload" "d" "$ml" "high" "exploit" "")"
    run q_author_extract_command "$SHEET" "build payload"
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]
    run grep -F 'msfvenom -p win' "$SHEET"; [ "$status" -eq 0 ]
    run grep -F 'exe -o {{OUTFILE:file}}' "$SHEET"; [ "$status" -eq 0 ]
}

@test "multi-line command survives an edit of another field (no flatten)" {
    ml=$'line one \\\nline two \\\nline three'
    q_author_append_entry "$SHEET" "$(q_author_build_entry "ml entry" "first" "$ml" "low" "misc" "")"
    cur="$(q_author_extract_command "$SHEET" "ml entry")"
    q_author_replace_entry "$SHEET" "ml entry" "$(q_author_build_entry "ml entry" "SECOND desc" "$cur" "low" "misc" "")"
    run q_author_extract_command "$SHEET" "ml entry"
    [ "${#lines[@]}" -eq 3 ]
    run grep -F 'line three' "$SHEET"; [ "$status" -eq 0 ]
    run grep -F 'SECOND desc' "$SHEET"; [ "$status" -eq 0 ]
    run grep -F 'first' "$SHEET"; [ "$status" -ne 0 ]
}

@test "q new composes a multi-line command in \$EDITOR when left blank" {
    _q_author_pick_file(){ printf '%s' "$SHEET"; }
    _q_author_read(){ case "$1" in *Title*) printf 'ml new';; *Description*) printf 'd';; *) printf '';; esac; }
    _q_author_edit_in_editor(){ printf 'cmd one {{TARGET}} \\\n  cmd two {{PORTS}}'; }
    _q_author_fzf(){ cat >/dev/null 2>&1 || true; case "$1" in *TARGET*) printf 'ip';; *PORTS*) printf 'port';; *) printf '';; esac; }
    _q_author_confirm(){ return 0; }
    run q_author_add
    [ "$status" -eq 0 ]
    run q_author_extract_command "$SHEET" "ml new"
    [ "${#lines[@]}" -eq 2 ]
    run grep -F '{{TARGET:ip}}' "$SHEET"; [ "$status" -eq 0 ]
    run grep -F '{{PORTS:port}}' "$SHEET"; [ "$status" -eq 0 ]
}

@test "known_vars lists used variable names, most-frequent first" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "a" "d" "x {{TARGET:ip}} {{TARGET:ip}} {{PORT:port}}" "low" "misc" "")"
    q_author_append_entry "$SHEET" "$(q_author_build_entry "b" "d" "y {{TARGET:ip}} {{USERNAME:str}}" "low" "misc" "")"
    q_build_index
    run _q_author_known_vars 10
    [ "$status" -eq 0 ]
    # TARGET appears most (3x) → first; PORT + USERNAME also present (once each).
    [ "${lines[0]}" = "TARGET" ]
    [[ "$output" == *"PORT"* ]]
    [[ "$output" == *"USERNAME"* ]]
}

@test "known_vars caps the count and is empty with no index" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "c" "d" "z {{A:str}} {{B:str}} {{C:str}}" "low" "misc" "")"
    q_build_index
    run _q_author_known_vars 2
    [ "${#lines[@]}" -eq 2 ]
    rm -f "$Q_CACHE_DIR/index.tsv"
    run _q_author_known_vars 10
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "pick_vars: no {{}} marker → command unchanged" {
    run _q_author_pick_vars 'kubectl get pods'
    [ "$status" -eq 0 ]
    [ "$output" = 'kubectl get pods' ]
}

@test "pick_vars: replaces {{}} markers in order with fzf-picked names" {
    _q_author_known_vars() { printf 'POD\nNAMESPACE\nTARGET\n'; }
    counter="$BATS_TEST_TMPDIR/pn"; echo 0 > "$counter"
    fzf() {
        cat >/dev/null
        local n; n="$(cat "$counter")"; echo "$((n+1))" > "$counter"
        case "$n" in
            0) printf '\nPOD\n' ;;
            *) printf '\nNAMESPACE\n' ;;
        esac
        return 0
    }
    export -f fzf _q_author_known_vars
    result="$(_q_author_pick_vars 'kubectl logs -f {{}} -n {{}}')"
    [ "$result" = 'kubectl logs -f {{POD}} -n {{NAMESPACE}}' ]
}

@test "pick_vars: accepts a new typed name (fzf rc=1, query echoed)" {
    _q_author_known_vars() { printf 'TARGET\n'; }
    fzf() { cat >/dev/null; printf 'NEWVAR\n'; return 1; }
    export -f fzf _q_author_known_vars
    result="$(_q_author_pick_vars 'echo {{}}')"
    [ "$result" = 'echo {{NEWVAR}}' ]
}

@test "pick_vars: cancel (rc=130) warns and leaves the marker" {
    _q_author_known_vars() { printf 'TARGET\n'; }
    fzf() { cat >/dev/null; return 130; }
    export -f fzf _q_author_known_vars
    result="$(_q_author_pick_vars 'a {{}} b {{}} c' 2>/dev/null)"
    [ "$result" = 'a {{}} b {{}} c' ]
}

@test "all_types unions canonical with index-derived types" {
    q_author_append_entry "$SHEET" "$(q_author_build_entry "a" "d" "x {{X:custom:y}}" "low" "misc" "")"
    q_build_index
    run _q_author_all_types
    [ "$status" -eq 0 ]
    [[ "$output" == *"str"* ]]
    [[ "$output" == *"ip"* ]]
    [[ "$output" == *"custom"* ]]
}
