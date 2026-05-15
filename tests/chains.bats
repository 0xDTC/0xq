#!/usr/bin/env bats
# Tests for lib/chains.sh — YAML-defined command chains.

load test_helper

setup() {
    # Run the shared setup to get session/core libs loaded into BATS_TEST_TMPDIR
    # (test_helper.bash defines its own setup() — we extend it here).
    Q_TEST_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    export Q_TEST_ROOT
    export Q_ROOT="$Q_TEST_ROOT"
    export Q_VERSION="test"

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
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/variables.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/chains.sh"

    # Point user chains dir at a writable temp location so tests can stage
    # extra YAMLs without polluting the repo's chains/ directory.
    export Q_USER_CHAINS_DIR="$BATS_TEST_TMPDIR/user_chains"
    mkdir -p "$Q_USER_CHAINS_DIR"
}

# ---------------------------------------------------------------------------
# 1. chain_list finds chains in repo chains/ dir
# ---------------------------------------------------------------------------
@test "chain_list finds chains in repo chains/ dir" {
    run q_chain_list
    [ "$status" -eq 0 ]
    [[ "$output" == *"example_recon"* ]]
    [[ "$output" == *"Quick recon flow"* ]]
}

# ---------------------------------------------------------------------------
# 2. chain_list finds user chains and merges with repo chains
# ---------------------------------------------------------------------------
@test "chain_list finds user chains and merges with repo chains" {
    cat > "$Q_USER_CHAINS_DIR/userchain.yaml" <<'EOF'
name: userchain
description: A user-supplied chain
steps:
  - title: only
    command: echo user
    continue_on_error: false
EOF
    run q_chain_list
    [ "$status" -eq 0 ]
    [[ "$output" == *"userchain"* ]]
    [[ "$output" == *"example_recon"* ]]
}

# ---------------------------------------------------------------------------
# 3. chain_show prints steps with titles and commands
# ---------------------------------------------------------------------------
@test "chain_show prints steps with titles and commands" {
    # Copy a fixture into the user chains dir so resolution picks it up.
    cp "$Q_TEST_ROOT/tests/fixtures/chains/simple.yaml" "$Q_USER_CHAINS_DIR/simple.yaml"
    run q_chain_show simple
    [ "$status" -eq 0 ]
    [[ "$output" == *"Say hello"* ]]
    [[ "$output" == *"echo hello {{TARGET}}"* ]]
    [[ "$output" == *"Say goodbye"* ]]
    [[ "$output" == *"echo goodbye {{TARGET}}"* ]]
}

# ---------------------------------------------------------------------------
# 4. chain_run --dry-run prints filled commands without executing
# ---------------------------------------------------------------------------
@test "chain_run --dry-run prints filled commands without executing" {
    cp "$Q_TEST_ROOT/tests/fixtures/chains/simple.yaml" "$Q_USER_CHAINS_DIR/simple.yaml"
    q_session_set TARGET 10.0.0.1 >/dev/null 2>&1

    run q_chain_run simple --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"echo hello 10.0.0.1"* ]]
    [[ "$output" == *"echo goodbye 10.0.0.1"* ]]

    # Dry runs MUST NOT log to history.
    local hist
    hist="$(q_session_dir)/history.log"
    [ ! -s "$hist" ] || ! grep -q 'echo hello' "$hist"
}

# ---------------------------------------------------------------------------
# 5. chain_run substitutes session vars into step commands
# ---------------------------------------------------------------------------
@test "chain_run substitutes session vars into step commands" {
    cp "$Q_TEST_ROOT/tests/fixtures/chains/simple.yaml" "$Q_USER_CHAINS_DIR/simple.yaml"
    q_session_set TARGET host.example.com >/dev/null 2>&1

    run q_chain_run simple
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello host.example.com"* ]]
    [[ "$output" == *"goodbye host.example.com"* ]]
}

# ---------------------------------------------------------------------------
# 6. chain_run executes steps in order and logs to history
# ---------------------------------------------------------------------------
@test "chain_run executes steps in order and logs to history" {
    cp "$Q_TEST_ROOT/tests/fixtures/chains/simple.yaml" "$Q_USER_CHAINS_DIR/simple.yaml"
    q_session_set TARGET zzz >/dev/null 2>&1

    run q_chain_run simple
    [ "$status" -eq 0 ]

    local hist
    hist="$(q_session_dir)/history.log"
    [ -s "$hist" ]

    # Both substituted commands should appear in the history log, in order.
    grep -q 'echo hello zzz' "$hist"
    grep -q 'echo goodbye zzz' "$hist"

    # Verify order: hello before goodbye
    local hello_line goodbye_line
    hello_line="$(grep -n 'echo hello zzz' "$hist" | head -1 | cut -d: -f1)"
    goodbye_line="$(grep -n 'echo goodbye zzz' "$hist" | head -1 | cut -d: -f1)"
    [ "$hello_line" -lt "$goodbye_line" ]
}

# ---------------------------------------------------------------------------
# 7. chain_run halts on first failure when continue_on_error is false
# ---------------------------------------------------------------------------
@test "chain_run halts on first failure when continue_on_error is false" {
    cp "$Q_TEST_ROOT/tests/fixtures/chains/failhalt.yaml" "$Q_USER_CHAINS_DIR/failhalt.yaml"

    run q_chain_run failhalt
    [ "$status" -ne 0 ]
    [[ "$output" == *"first ok"* ]]
    # The "Never" step's echo must NOT appear in output
    [[ "$output" != *"never runs"* ]]
}

# ---------------------------------------------------------------------------
# 8. chain_run continues past failure when continue_on_error is true
# ---------------------------------------------------------------------------
@test "chain_run continues past failure when continue_on_error is true" {
    cp "$Q_TEST_ROOT/tests/fixtures/chains/failcont.yaml" "$Q_USER_CHAINS_DIR/failcont.yaml"

    run q_chain_run failcont
    # Overall return code is 0 because the failing step had continue_on_error: true
    [ "$status" -eq 0 ]
    [[ "$output" == *"first ok"* ]]
    [[ "$output" == *"last runs"* ]]
}

# ---------------------------------------------------------------------------
# 9. chain_run skips step when 'when:' gate var is unset
# ---------------------------------------------------------------------------
@test "chain_run skips step when 'when:' gate var is unset" {
    cp "$Q_TEST_ROOT/tests/fixtures/chains/gated.yaml" "$Q_USER_CHAINS_DIR/gated.yaml"

    # Do NOT set PORT_80 — the gated step should be skipped.
    run q_chain_run gated
    [ "$status" -eq 0 ]
    [[ "$output" == *"always"* ]]
    [[ "$output" != *"http"* ]]
    [[ "$output" == *"end"* ]]

    # Now set the gate var and re-run — gated step should run.
    q_session_set PORT_80 1 >/dev/null 2>&1
    run q_chain_run gated
    [ "$status" -eq 0 ]
    [[ "$output" == *"http"* ]]
}

# ---------------------------------------------------------------------------
# 10. chain_run honors chain vars but does not overwrite session vars
# ---------------------------------------------------------------------------
@test "chain_run honors chain vars but does not overwrite session vars" {
    cp "$Q_TEST_ROOT/tests/fixtures/chains/withvars.yaml" "$Q_USER_CHAINS_DIR/withvars.yaml"

    # Pre-seed session with a PORTS value that should take precedence over
    # the chain's declared default of "1-1000".
    q_session_set PORTS 22 >/dev/null 2>&1
    q_session_set TARGET host >/dev/null 2>&1
    # Leave RATE unset in the session so the chain's value ("fast") fills it.

    run q_chain_run withvars
    [ "$status" -eq 0 ]
    [[ "$output" == *"scanning 22 on host at fast"* ]]

    # The session's PORTS must remain "22" (chain did not overwrite it).
    local ports
    ports="$(q_session_get PORTS)"
    [ "$ports" = "22" ]

    # RATE should now be set to the chain's value.
    local rate
    rate="$(q_session_get RATE)"
    [ "$rate" = "fast" ]
}
