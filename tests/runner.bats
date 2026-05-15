#!/usr/bin/env bats
# Tests for lib/runner.sh — parallel multi-target command runner.

bats_require_minimum_version 1.5.0

load test_helper

setup() {
    # Run parent setup (sets XDG, sources core/session)
    export XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
    export Q_DATA_DIR="$XDG_DATA_HOME/q"
    export Q_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
    export Q_SHEETS_DIR="$Q_TEST_ROOT/cheatsheets"
    export Q_SESSION_DIR="$Q_DATA_DIR/sessions"
    export Q_VAR_HISTORY_DIR="$Q_DATA_DIR/var_history"
    export Q_SESSION_NAME="test_$$"
    mkdir -p "$Q_DATA_DIR" "$Q_CACHE_DIR" "$Q_SESSION_DIR" "$Q_VAR_HISTORY_DIR"
    export Q_RED='' Q_GREEN='' Q_YELLOW='' Q_BLUE='' Q_CYAN=''
    export Q_MAGENTA='' Q_DIM='' Q_BOLD='' Q_RESET=''

    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/core.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/session.sh"
    # variables.sh is required for q_fill_vars_auto
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/variables.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/runner.sh"
}

# Helper: seed targets file directly (per spec — bypass q_target_add to avoid logs).
_seed_targets() {
    local tfile
    tfile="$(q_session_dir)/targets"
    : > "$tfile"
    local entry
    for entry in "$@"; do
        printf '%s\n' "$entry" >> "$tfile"
    done
}

# ---------------------------------------------------------------------------
# 1. run_parallel echoes target value for each target with {{TARGET}}
# ---------------------------------------------------------------------------
@test "run_parallel echoes target value for each target with {{TARGET}}" {
    _seed_targets "ip:10.0.0.1" "ip:10.0.0.2" "ip:10.0.0.3"

    run q_run_parallel "echo HELLO {{TARGET}}"
    [ "$status" -eq 0 ]

    # Each target should appear in some output file
    local out_dir
    out_dir="$(q_session_dir)/runs/parallel"
    [ -d "$out_dir" ]

    grep -rqF "HELLO 10.0.0.1" "$out_dir"
    grep -rqF "HELLO 10.0.0.2" "$out_dir"
    grep -rqF "HELLO 10.0.0.3" "$out_dir"
}

# ---------------------------------------------------------------------------
# 2. run_parallel respects -j concurrency flag
# ---------------------------------------------------------------------------
@test "run_parallel respects -j concurrency flag (j=1)" {
    _seed_targets "ip:1.1.1.1" "ip:2.2.2.2"

    run q_run_parallel -j 1 "echo {{TARGET}}"
    [ "$status" -eq 0 ]

    local out_dir
    out_dir="$(q_session_dir)/runs/parallel"
    grep -rqF "1.1.1.1" "$out_dir"
    grep -rqF "2.2.2.2" "$out_dir"
}

@test "run_parallel respects -j concurrency flag (j=4)" {
    _seed_targets "ip:1.1.1.1" "ip:2.2.2.2"

    run q_run_parallel -j 4 "echo {{TARGET}}"
    [ "$status" -eq 0 ]

    local out_dir
    out_dir="$(q_session_dir)/runs/parallel"
    grep -rqF "1.1.1.1" "$out_dir"
    grep -rqF "2.2.2.2" "$out_dir"
}

# ---------------------------------------------------------------------------
# 3. run_parallel skips ip-typed targets when template has only {{URL}} (and vice versa)
# ---------------------------------------------------------------------------
@test "run_parallel skips ip targets when template uses only {{URL}}" {
    _seed_targets "ip:10.0.0.1" "url:https://example.com"

    run q_run_parallel "echo URL={{URL}}"
    [ "$status" -eq 0 ]

    # Summary should say 1 skipped (the ip)
    [[ "$output" =~ \[?1\]?\ skipped ]]

    local out_dir
    out_dir="$(q_session_dir)/runs/parallel"
    grep -rqF "URL=https://example.com" "$out_dir"
    run ! grep -rqF "URL=10.0.0.1" "$out_dir"
}

@test "run_parallel skips url targets when template uses only {{IP}}" {
    _seed_targets "ip:10.0.0.1" "url:https://example.com"

    run q_run_parallel "echo IP={{IP}}"
    [ "$status" -eq 0 ]

    [[ "$output" =~ \[?1\]?\ skipped ]]

    local out_dir
    out_dir="$(q_session_dir)/runs/parallel"
    grep -rqF "IP=10.0.0.1" "$out_dir"
    run ! grep -rqF "IP=https://example.com" "$out_dir"
}

# ---------------------------------------------------------------------------
# 4. run_parallel writes per-target output files under runs/parallel/
# ---------------------------------------------------------------------------
@test "run_parallel writes per-target output files under sessions/<name>/runs/parallel/" {
    _seed_targets "ip:10.0.0.5" "ip:10.0.0.6"

    run q_run_parallel "echo X{{TARGET}}Y"
    [ "$status" -eq 0 ]

    local out_dir
    out_dir="$(q_session_dir)/runs/parallel"
    [ -d "$out_dir" ]

    # Expect at least 2 output files
    local file_count
    file_count="$(find "$out_dir" -type f -name '*.out' | wc -l)"
    [ "$file_count" -ge 2 ]

    # The filenames should reference targets
    ls "$out_dir" | grep -qF "10.0.0.5"
    ls "$out_dir" | grep -qF "10.0.0.6"
}

# ---------------------------------------------------------------------------
# 5. run_parallel fills non-target placeholders from session vars
# ---------------------------------------------------------------------------
@test "run_parallel fills non-target placeholders from session vars" {
    _seed_targets "ip:10.0.0.10"
    # Set session var WORDLIST via direct file write (q_session_set logs to stderr)
    printf '%s=%s\n' "WORDLIST" "/tmp/wl.txt" > "$(q_session_dir)/vars"

    run q_run_parallel "echo target={{TARGET}} wordlist={{WORDLIST}}"
    [ "$status" -eq 0 ]

    local out_dir
    out_dir="$(q_session_dir)/runs/parallel"
    grep -rqF "target=10.0.0.10 wordlist=/tmp/wl.txt" "$out_dir"
}

@test "run_parallel skips target if non-target placeholder cannot be resolved" {
    _seed_targets "ip:10.0.0.20"
    # No session vars set, no default in placeholder -> cannot resolve.
    : > "$(q_session_dir)/vars"

    run q_run_parallel "echo {{TARGET}} {{UNDEFINED_VAR}}"
    [ "$status" -eq 0 ]

    [[ "$output" =~ \[?1\]?\ skipped ]]
}

# ---------------------------------------------------------------------------
# 6. run_parallel summary shows succeeded/failed/skipped counts
# ---------------------------------------------------------------------------
@test "run_parallel summary shows succeeded/failed/skipped counts" {
    _seed_targets "ip:10.0.0.30" "ip:10.0.0.31"

    # Use a command that always succeeds.
    run q_run_parallel "true"
    [ "$status" -eq 0 ]
    [[ "$output" =~ succeeded ]]
    [[ "$output" =~ failed ]]
    [[ "$output" =~ skipped ]]
    [[ "$output" =~ \[?2\]?\ succeeded ]]
}

@test "run_parallel reports failed commands with exit codes" {
    _seed_targets "ip:10.0.0.40"

    # 'false' fails — but command template should still get substituted.
    run q_run_parallel "false || exit 7"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[?1\]?\ failed ]]
    # The exit code 7 should appear in the failure detail
    [[ "$output" =~ 7 ]]
}

# ---------------------------------------------------------------------------
# 7. run_show prints most recent output for a target
# ---------------------------------------------------------------------------
@test "run_show prints most recent output for a target" {
    _seed_targets "ip:10.0.0.50"

    q_run_parallel "echo first_run_value" >/dev/null 2>&1
    sleep 1
    q_run_parallel "echo second_run_value" >/dev/null 2>&1

    run q_run_show "10.0.0.50"
    [ "$status" -eq 0 ]
    [[ "$output" =~ second_run_value ]]
    [[ ! "$output" =~ first_run_value ]]
}

# ---------------------------------------------------------------------------
# 8. run_clean --force wipes the parallel runs dir
# ---------------------------------------------------------------------------
@test "run_clean --force wipes the parallel runs dir" {
    _seed_targets "ip:10.0.0.60"

    q_run_parallel "echo cleanup_test" >/dev/null 2>&1

    local out_dir
    out_dir="$(q_session_dir)/runs/parallel"
    [ -d "$out_dir" ]
    [ "$(find "$out_dir" -type f | wc -l)" -gt 0 ]

    run q_run_clean --force
    [ "$status" -eq 0 ]

    # After clean: dir is gone, or empty
    if [[ -d "$out_dir" ]]; then
        [ "$(find "$out_dir" -type f | wc -l)" -eq 0 ]
    fi
}
