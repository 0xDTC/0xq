#!/usr/bin/env bats
# Tests for lib/tmux.sh — tmux integration for q sessions.
#
# These tests use a PRIVATE tmux server socket per-test (Q_TMUX_SOCKET) so
# we never touch the user's running tmux server. The lib must honor that
# env var on every tmux invocation.

bats_require_minimum_version 1.5.0

load test_helper

setup() {
    # Inherit test_helper's XDG/session scaffolding but redeclare here so the
    # exports happen before we source any lib that reads them at source-time.
    export XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
    export Q_DATA_DIR="$XDG_DATA_HOME/q"
    export Q_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
    export Q_SHEETS_DIR="$Q_TEST_ROOT/cheatsheets"
    export Q_SESSION_DIR="$Q_DATA_DIR/sessions"
    export Q_VAR_HISTORY_DIR="$Q_DATA_DIR/var_history"
    export Q_SESSION_NAME="qtest$$"
    mkdir -p "$Q_DATA_DIR" "$Q_CACHE_DIR" "$Q_SESSION_DIR" "$Q_VAR_HISTORY_DIR"
    export Q_RED='' Q_GREEN='' Q_YELLOW='' Q_BLUE='' Q_CYAN=''
    export Q_MAGENTA='' Q_DIM='' Q_BOLD='' Q_RESET=''

    # Bail early if tmux is not installed on the build host.
    if ! command -v tmux >/dev/null 2>&1; then
        skip "tmux not available"
    fi

    # Private socket — every tmux call in lib/tmux.sh must route via this.
    # Bats sets BATS_TEST_NUMBER (1-based), so pair with $RANDOM for safety.
    export Q_TMUX_SOCKET="q_test_${BATS_TEST_NUMBER}_${RANDOM}_$$"

    # Keep tmux quiet during tests
    export TMUX_TMPDIR="$BATS_TEST_TMPDIR/tmuxtmp"
    mkdir -p "$TMUX_TMPDIR"

    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/core.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/session.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/tmux.sh"
}

teardown() {
    # Make sure no zombie tmux server lingers from this test.
    if [[ -n "${Q_TMUX_SOCKET:-}" ]] && command -v tmux >/dev/null 2>&1; then
        tmux -L "$Q_TMUX_SOCKET" kill-server 2>/dev/null || true
    fi
}

# Helper: write a raw targets file (skip q_target_add which logs).
_seed_targets() {
    local tfile
    tfile="$(q_session_dir)/targets"
    : > "$tfile"
    local entry
    for entry in "$@"; do
        printf '%s\n' "$entry" >> "$tfile"
    done
}

# Helper: wait until tmux has-session is true (or timeout).
_wait_for_session() {
    local target="$1" tries=0
    while (( tries < 50 )); do
        if tmux -L "$Q_TMUX_SOCKET" has-session -t "$target" 2>/dev/null; then
            return 0
        fi
        sleep 0.05
        tries=$((tries + 1))
    done
    return 1
}

# ---------------------------------------------------------------------------
# 1. tmux_session_name returns q:<session>
# ---------------------------------------------------------------------------
@test "tmux_session_name returns q:<session>" {
    run q_tmux_session_name
    [ "$status" -eq 0 ]
    [ "$output" = "q:${Q_SESSION_NAME}" ]
}

# ---------------------------------------------------------------------------
# 2. tmux_start creates a detached session with the q: prefix
# ---------------------------------------------------------------------------
@test "tmux_start creates a detached session with the q: prefix" {
    run q_tmux_start
    [ "$status" -eq 0 ]

    _wait_for_session "q_${Q_SESSION_NAME}"
    tmux -L "$Q_TMUX_SOCKET" has-session -t "q_${Q_SESSION_NAME}"
}

# ---------------------------------------------------------------------------
# 3. tmux_start is idempotent — second call does NOT spawn a duplicate
# ---------------------------------------------------------------------------
@test "tmux_start is idempotent — second call does NOT spawn a duplicate" {
    run q_tmux_start
    [ "$status" -eq 0 ]
    _wait_for_session "q_${Q_SESSION_NAME}"

    # Snapshot session list, then call again.
    local before
    before="$(tmux -L "$Q_TMUX_SOCKET" list-sessions -F '#{session_name}' 2>/dev/null | grep -c '^q_' || true)"

    run q_tmux_start
    [ "$status" -eq 0 ]
    [[ "$output" =~ exists ]] || [[ "$(printf '%s' "$stderr" 2>/dev/null)" =~ exists ]] || true

    local after
    after="$(tmux -L "$Q_TMUX_SOCKET" list-sessions -F '#{session_name}' 2>/dev/null | grep -c '^q_' || true)"
    [ "$before" -eq "$after" ]
    [ "$before" -eq 1 ]
}

# ---------------------------------------------------------------------------
# 4. tmux_start sets up 3 panes in the main window
# ---------------------------------------------------------------------------
@test "tmux_start sets up 3 panes in the main window" {
    run q_tmux_start
    [ "$status" -eq 0 ]
    _wait_for_session "q_${Q_SESSION_NAME}"

    local pane_count
    pane_count="$(tmux -L "$Q_TMUX_SOCKET" list-panes -t "q_${Q_SESSION_NAME}" 2>/dev/null | wc -l)"
    [ "$pane_count" -eq 3 ]
}

# ---------------------------------------------------------------------------
# 5. tmux_kill removes the session
# ---------------------------------------------------------------------------
@test "tmux_kill removes the session" {
    q_tmux_start >/dev/null 2>&1
    _wait_for_session "q_${Q_SESSION_NAME}"

    run q_tmux_kill
    [ "$status" -eq 0 ]

    run tmux -L "$Q_TMUX_SOCKET" has-session -t "q_${Q_SESSION_NAME}"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# 6. tmux_list prints only q: prefixed sessions, not unrelated ones
# ---------------------------------------------------------------------------
@test "tmux_list prints only q: prefixed sessions, not unrelated ones" {
    q_tmux_start >/dev/null 2>&1
    _wait_for_session "q_${Q_SESSION_NAME}"

    # Spin up an unrelated session on the same private socket.
    tmux -L "$Q_TMUX_SOCKET" new-session -d -s "unrelated_session" 2>/dev/null

    run q_tmux_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ q:${Q_SESSION_NAME} ]]
    ! [[ "$output" =~ unrelated_session ]]

    tmux -L "$Q_TMUX_SOCKET" kill-session -t unrelated_session 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# 7. tmux_send delivers a command to pane 0
# ---------------------------------------------------------------------------
@test "tmux_send delivers a command to pane 0" {
    q_tmux_start >/dev/null 2>&1
    _wait_for_session "q_${Q_SESSION_NAME}"

    # Send a sentinel that will appear in the pane contents.
    run q_tmux_send "echo TMUX_SEND_SENTINEL_777"
    [ "$status" -eq 0 ]

    # Let the keystrokes settle in the pane.
    sleep 0.3
    local pane_contents
    pane_contents="$(tmux -L "$Q_TMUX_SOCKET" capture-pane -t "q_${Q_SESSION_NAME}:0.0" -p 2>/dev/null || true)"
    [[ "$pane_contents" =~ TMUX_SEND_SENTINEL_777 ]]
}

# ---------------------------------------------------------------------------
# 8. tmux_run_parallel spawns one pane per target (3 ip targets)
# ---------------------------------------------------------------------------
@test "tmux_run_parallel spawns one pane per target" {
    _seed_targets "ip:10.0.0.1" "ip:10.0.0.2" "ip:10.0.0.3"
    q_tmux_start >/dev/null 2>&1
    _wait_for_session "q_${Q_SESSION_NAME}"

    run q_tmux_run_parallel "echo HELLO {{TARGET}}"
    [ "$status" -eq 0 ]

    # The new window's name pattern is run-<TS>
    local windows
    windows="$(tmux -L "$Q_TMUX_SOCKET" list-windows -t "q_${Q_SESSION_NAME}" -F '#{window_name}' 2>/dev/null)"
    local run_win
    run_win="$(printf '%s\n' "$windows" | grep -m1 '^run-' || true)"
    [ -n "$run_win" ]

    local panes
    panes="$(tmux -L "$Q_TMUX_SOCKET" list-panes -t "q_${Q_SESSION_NAME}:${run_win}" 2>/dev/null | wc -l)"
    [ "$panes" -eq 3 ]
}

# ---------------------------------------------------------------------------
# 9. tmux_run_parallel skips ip targets when template uses only {{URL}}
# ---------------------------------------------------------------------------
@test "tmux_run_parallel skips ip targets when template uses only {{URL}}" {
    _seed_targets "ip:10.0.0.1" "ip:10.0.0.2" "url:https://example.com" "url:https://demo.test"
    q_tmux_start >/dev/null 2>&1
    _wait_for_session "q_${Q_SESSION_NAME}"

    run q_tmux_run_parallel "echo URL={{URL}}"
    [ "$status" -eq 0 ]

    local windows run_win panes
    windows="$(tmux -L "$Q_TMUX_SOCKET" list-windows -t "q_${Q_SESSION_NAME}" -F '#{window_name}' 2>/dev/null)"
    run_win="$(printf '%s\n' "$windows" | grep -m1 '^run-' || true)"
    [ -n "$run_win" ]

    panes="$(tmux -L "$Q_TMUX_SOCKET" list-panes -t "q_${Q_SESSION_NAME}:${run_win}" 2>/dev/null | wc -l)"
    # Only the 2 URL targets should get panes — IPs skipped.
    [ "$panes" -eq 2 ]
}

# ---------------------------------------------------------------------------
# 10. tmux_run_parallel errors with <=1 target
# ---------------------------------------------------------------------------
@test "tmux_run_parallel errors with <=1 target" {
    _seed_targets "ip:10.0.0.1"
    q_tmux_start >/dev/null 2>&1
    _wait_for_session "q_${Q_SESSION_NAME}"

    run q_tmux_run_parallel "echo {{TARGET}}"
    [ "$status" -ne 0 ]
    [[ "$output" =~ q\ run ]] || [[ "$output" =~ run\  ]]
}

# ---------------------------------------------------------------------------
# 11. tmux_run_parallel writes per-target tee output to runs/parallel/
# ---------------------------------------------------------------------------
@test "tmux_run_parallel writes per-target tee output to runs/parallel/" {
    _seed_targets "ip:10.0.0.1" "ip:10.0.0.2"
    q_tmux_start >/dev/null 2>&1
    _wait_for_session "q_${Q_SESSION_NAME}"

    # Use a fast-completing command (no sleep needed) — but the panes hold
    # open afterwards thanks to exec $SHELL. The TEE writes happen in
    # parallel, so we wait a bit for the filesystem.
    run q_tmux_run_parallel "echo TEE_PROOF_{{TARGET}}"
    [ "$status" -eq 0 ]

    local out_dir="$(q_session_dir)/runs/parallel"
    local tries=0 found_a=0 found_b=0
    while (( tries < 50 )); do
        if [[ -d "$out_dir" ]]; then
            grep -rqF "TEE_PROOF_10.0.0.1" "$out_dir" 2>/dev/null && found_a=1
            grep -rqF "TEE_PROOF_10.0.0.2" "$out_dir" 2>/dev/null && found_b=1
        fi
        [[ "$found_a" -eq 1 && "$found_b" -eq 1 ]] && break
        sleep 0.1
        tries=$((tries + 1))
    done
    [ "$found_a" -eq 1 ]
    [ "$found_b" -eq 1 ]
}

# ---------------------------------------------------------------------------
# 12. key binding 't' is registered in the q tmux session
# ---------------------------------------------------------------------------
@test "key binding 't' is registered in the q tmux session" {
    q_tmux_start >/dev/null 2>&1
    _wait_for_session "q_${Q_SESSION_NAME}"

    local keys
    keys="$(tmux -L "$Q_TMUX_SOCKET" list-keys 2>/dev/null)"

    # Expect a binding for 't' under the prefix table.
    [[ "$keys" =~ prefix.*[[:space:]]t[[:space:]] ]] \
        || [[ "$keys" =~ bind-key[[:space:]]+\-T[[:space:]]+prefix[[:space:]]+t ]]
}

# ---------------------------------------------------------------------------
# 13. q_tmux_help prints binding table to stderr
# ---------------------------------------------------------------------------
@test "q_tmux_help prints binding table to stderr" {
    # Capture stderr only.
    run --separate-stderr q_tmux_help
    [ "$status" -eq 0 ]
    [[ "$stderr" =~ prefix ]]
    [[ "$stderr" =~ t ]]
}
