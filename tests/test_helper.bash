#!/usr/bin/env bash
# Shared bats helper — isolates each test run from the real session/data dirs.
# Source via: load 'test_helper'  (drops the .bash suffix per bats convention).

# Resolve repo root (parent of tests/)
Q_TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export Q_TEST_ROOT
export Q_ROOT="$Q_TEST_ROOT"
export Q_VERSION="test"

# Per-test ephemeral data/cache dirs — bats wipes BATS_TMPDIR per test.
setup() {
    export XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
    export Q_DATA_DIR="$XDG_DATA_HOME/q"
    export Q_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
    export Q_SHEETS_DIR="$Q_TEST_ROOT/cheatsheets"
    export Q_SESSION_DIR="$Q_DATA_DIR/sessions"
    export Q_VAR_HISTORY_DIR="$Q_DATA_DIR/var_history"
    export Q_SESSION_NAME="test_$$"
    mkdir -p "$Q_DATA_DIR" "$Q_CACHE_DIR" "$Q_SESSION_DIR" "$Q_VAR_HISTORY_DIR"

    # Suppress color codes in tests for clean assertions
    export Q_RED='' Q_GREEN='' Q_YELLOW='' Q_BLUE='' Q_CYAN=''
    export Q_MAGENTA='' Q_DIM='' Q_BOLD='' Q_RESET=''

    # Source core libraries so logging + session helpers are available.
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/core.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/session.sh"
}

teardown() {
    :
}
