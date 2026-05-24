#!/usr/bin/env bats
load 'test_helper'

setup() {
    export XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
    export Q_DATA_DIR="$XDG_DATA_HOME/q"
    export Q_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
    export Q_SHEETS_DIR="$Q_TEST_ROOT/cheatsheets"
    export Q_SESSION_DIR="$Q_DATA_DIR/sessions"
    export Q_VAR_HISTORY_DIR="$Q_DATA_DIR/var_history"
    export Q_SESSION_NAME="test_$$"
    mkdir -p "$Q_DATA_DIR" "$Q_CACHE_DIR" "$Q_SESSION_DIR" "$Q_VAR_HISTORY_DIR"
    export Q_RED='' Q_GREEN='' Q_YELLOW='' Q_BLUE='' Q_CYAN='' Q_MAGENTA='' Q_DIM='' Q_BOLD='' Q_RESET=''
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/core.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/session.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/variables.sh"
}

@test "q_fill_vars_auto prefers .fill_state over session" {
    q_session_set USER alice
    printf 'USER=bob\n' > "$Q_CACHE_DIR/.fill_state"
    run q_fill_vars_auto 'id -u {{USER}}'
    [ "$status" -eq 0 ]
    [ "$output" = "id -u bob" ]
}

@test "q_fill_vars_auto falls back to session when .fill_state absent" {
    q_session_set USER alice
    run q_fill_vars_auto 'id -u {{USER}}'
    [ "$status" -eq 0 ]
    [ "$output" = "id -u alice" ]
}

@test "q_fill_vars_auto returns 1 when a var is unresolved" {
    run q_fill_vars_auto 'id -u {{USER}}'
    [ "$status" -eq 1 ]
}

@test "q_unresolved_vars lists only unresolved names" {
    q_session_set HOST 10.0.0.1
    printf 'USER=bob\n' > "$Q_CACHE_DIR/.fill_state"
    run q_unresolved_vars 'ssh {{USER}}@{{HOST}} -p {{PORT}}'
    [ "$status" -eq 0 ]
    [ "$output" = "PORT" ]
}

@test "q_unresolved_vars empty when all resolved (incl default)" {
    printf 'USER=bob\n' > "$Q_CACHE_DIR/.fill_state"
    q_session_set HOST 10.0.0.1
    run q_unresolved_vars 'ssh {{USER}}@{{HOST}} -p {{PORT:port:22}}'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
