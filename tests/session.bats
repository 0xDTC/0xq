#!/usr/bin/env bats
# Tests for lib/session.sh — enriched history.log format, tail, and replay.
# Only the pure paths are exercised; the interactive replay branch is stubbed.

load 'test_helper'

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
    source "$Q_TEST_ROOT/lib/session.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/executor.sh"
    # core.sh hard-sets Q_SHEETS_DIR; override AFTER sourcing.
    export Q_SHEETS_DIR="$BATS_TEST_TMPDIR/sheets"
    mkdir -p "$Q_DATA_DIR" "$Q_CACHE_DIR" "$Q_SESSION_DIR" "$Q_VAR_HISTORY_DIR"
}

@test "history_log writes the new 4-tab TSV with rc and duration" {
    q_history_log "nmap -sV 10.10.10.1" "0" "12"
    run cat "$(q_session_dir)/history.log"
    [[ "$output" == *$'\t0\t12\tnmap -sV 10.10.10.1' ]]
}

@test "history_log defaults rc + duration to '-' when legacy callers omit them" {
    q_history_log "smbclient -L //10.10.10.1"
    run cat "$(q_session_dir)/history.log"
    [[ "$output" == *$'\t-\t-\tsmbclient -L //10.10.10.1' ]]
}

@test "history_log preserves tabs in the command by writing them verbatim" {
    # Only the last of the 4 tabs separates fields; embedded tabs in the command
    # remain — this test just guards against a future 'sanitise input' regression.
    q_history_log "grep -P '\t'" "0" "1"
    run cat "$(q_session_dir)/history.log"
    [[ "$output" == *"grep -P"* ]]
}

@test "show_history reads legacy 2-field entries and new 4-field ones together" {
    local hf; hf="$(q_session_dir)/history.log"
    mkdir -p "$(dirname "$hf")"
    {
        printf '%s\t%s\n'         "2026-01-01 10:00:00"            "legacy-cmd --raw"
        printf '%s\t%s\t%s\t%s\n' "2026-01-01 10:01:00" "0" "3"    "new-cmd --ok"
        printf '%s\t%s\t%s\t%s\n' "2026-01-01 10:02:00" "1" "5"    "new-cmd --fail"
    } > "$hf"
    run q_show_history
    [[ "$output" == *"legacy-cmd --raw"* ]]
    [[ "$output" == *"new-cmd --ok"* ]]
    [[ "$output" == *"new-cmd --fail"* ]]
    [[ "$output" == *"3 commands total"* ]]
}

@test "history_tail prints last N entries with tail semantics" {
    for i in 1 2 3 4 5 6 7; do q_history_log "cmd-$i" "0" "$i"; done
    run _q_history_tail 3
    [ "$status" -eq 0 ]
    [[ "$output" == *"cmd-5"* ]]
    [[ "$output" == *"cmd-6"* ]]
    [[ "$output" == *"cmd-7"* ]]
    [[ "$output" != *"cmd-4"* ]]
}

@test "history_tail returns 1 (no output) when the log is missing" {
    run _q_history_tail 5
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "session_replay --yes walks the last N and invokes _q_execute per entry" {
    # Stub _q_execute so we don't actually run anything; just record calls.
    _q_execute() { printf 'RAN: %s\n' "$1"; }
    q_history_log "echo one"   "0" "1"
    q_history_log "echo two"   "0" "1"
    q_history_log "echo three" "0" "1"
    run q_session_replay --yes 2
    [[ "$output" == *"RAN: echo two"* ]]
    [[ "$output" == *"RAN: echo three"* ]]
    [[ "$output" != *"RAN: echo one"* ]]
}

@test "session_replay is quiet + succeeds on empty history" {
    run q_session_replay --yes 5
    [ "$status" -eq 0 ]
    [[ "$output" == *"No history"* ]]
}

@test "session_replay without --yes refuses when there is no TTY" {
    # bats runs without a controlling TTY, so the guard should trigger and
    # protect against silent auto-run in cron/CI/pipes.
    q_history_log "echo hi" "0" "1"
    run q_session_replay 5
    [ "$status" -eq 1 ]
    [[ "$output" == *"TTY"* ]]
}

@test "session_replay rejects non-numeric N" {
    run q_session_replay --yes 10abc
    [ "$status" -eq 1 ]
    [[ "$output" == *"positive integer"* ]]
}

@test "history_log strips embedded tabs (would corrupt TSV fields otherwise)" {
    q_history_log $'grep -P \tfoo' "0" "1"
    run cat "$(q_session_dir)/history.log"
    # The literal tab in the command should be replaced with a space.
    [[ "$output" != *$'grep -P \tfoo'* ]]
    [[ "$output" == *"grep -P  foo"* ]]
}

@test "history_log collapses embedded newlines with '; ' so records stay 1-line" {
    q_history_log $'echo one\necho two' "0" "1"
    local hf; hf="$(q_session_dir)/history.log"
    # Written entry becomes a single physical line in the log file.
    run wc -l "$hf"
    [[ "$output" == "1 "* ]]
    run cat "$hf"
    [[ "$output" == *"echo one ; echo two"* ]]
}

@test "history_split recovers a legacy row that carried an embedded tab in cmd" {
    # Simulate a pre-sanitiser row with an embedded tab in the command field.
    local hf; hf="$(q_session_dir)/history.log"
    mkdir -p "$(dirname "$hf")"
    printf '%s\t%s\t%s\t%s\n' "2026-01-01 10:00:00" "0" "1" $'a\tb\tc' > "$hf"
    ts=""; rc=""; dur=""; cmd=""
    _q_history_split "$(head -n1 "$hf")"
    [ "$rc" = "0" ]
    [ "$dur" = "1" ]
    [ "$cmd" = $'a\tb\tc' ]
}

@test "pre_exec_check auto-skips missing binaries when Q_REPLAY=1" {
    # A binary that definitely does not exist on the test host. Export the
    # env var (bats `run` uses a bash function, so inline `env VAR=` would
    # fail — env is an external and can't see shell functions).
    export Q_REPLAY=1
    run q_pre_exec_check "definitely-not-a-real-tool-xyz-foo --flag"
    unset Q_REPLAY
    [ "$status" -eq 1 ]
    [[ "$output" == *"Skipping in replay"* ]]
}
