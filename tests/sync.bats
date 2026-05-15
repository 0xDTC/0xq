#!/usr/bin/env bats
# tests/sync.bats — exercises lib/sync.sh against a local bare-git fixture.
# No network. Each test runs in a fresh BATS_TEST_TMPDIR.

load test_helper

setup() {
    # Sandbox every path so the live repo's cheatsheets/ never gets touched.
    # NB: lib/core.sh hard-resets some of these on source, so we re-export
    # AFTER sourcing it.
    # shellcheck disable=SC2154
    export XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
    export Q_SESSION_NAME="test_$$"
    export Q_RED='' Q_GREEN='' Q_YELLOW='' Q_BLUE='' Q_CYAN=''
    export Q_MAGENTA='' Q_DIM='' Q_BOLD='' Q_RESET=''

    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/core.sh"

    # Override the dir constants core.sh just set, before any code uses them.
    export Q_DATA_DIR="$XDG_DATA_HOME/q"
    export Q_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
    export Q_SHEETS_DIR="$BATS_TEST_TMPDIR/cheatsheets"
    export Q_SESSION_DIR="$Q_DATA_DIR/sessions"
    export Q_VAR_HISTORY_DIR="$Q_DATA_DIR/var_history"
    mkdir -p "$Q_DATA_DIR" "$Q_CACHE_DIR" "$Q_SHEETS_DIR" \
             "$Q_SESSION_DIR" "$Q_VAR_HISTORY_DIR"

    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/session.sh"
    # shellcheck disable=SC1091
    source "$Q_TEST_ROOT/lib/sync.sh"

    # Force git author so commits work even without global config.
    export GIT_AUTHOR_NAME="bats" GIT_AUTHOR_EMAIL="bats@local"
    export GIT_COMMITTER_NAME="bats" GIT_COMMITTER_EMAIL="bats@local"
}

# Build a bare repo seeded with a markdown tree.
# Args: $1=destination bare repo path
#       $2=optional subdir to nest content under (e.g. "src")
# Echoes the file:// URL.
_make_bare_repo() {
    local bare="$1" subdir="${2:-}"
    local work="$BATS_TEST_TMPDIR/work_$RANDOM"
    mkdir -p "$work"
    git -C "$work" init -q -b main
    if [[ -n "$subdir" ]]; then
        mkdir -p "$work/$subdir/cat1"
        printf '# Hello from %s\n' "$subdir" > "$work/$subdir/cat1/note.md"
        printf '# Root level\n' > "$work/README.md"
    else
        mkdir -p "$work/cat1"
        printf '# Hello cheatsheet\n' > "$work/cat1/note.md"
    fi
    git -C "$work" add -A
    git -C "$work" commit -q -m "seed"
    git init -q --bare -b main "$bare"
    git -C "$work" remote add origin "$bare"
    git -C "$work" push -q origin main
    rm -rf "$work"
    printf 'file://%s' "$bare"
}

# Append a commit to an existing bare repo (used to test pulls).
# Args: $1=bare repo path  $2=optional subdir
_append_commit_to_bare() {
    local bare="$1" subdir="${2:-}"
    local work="$BATS_TEST_TMPDIR/work2_$RANDOM"
    git clone -q "$bare" "$work"
    if [[ -n "$subdir" ]]; then
        mkdir -p "$work/$subdir/cat1"
        printf '# Second file\n' > "$work/$subdir/cat1/second.md"
    else
        printf '# Second file\n' > "$work/cat1/second.md"
    fi
    git -C "$work" add -A
    git -C "$work" commit -q -m "add second"
    git -C "$work" push -q origin main
    rm -rf "$work"
}

# ---------------------------------------------------------------------------
# 1. sync_list shows built-in sources with 'not synced' before first run
# ---------------------------------------------------------------------------
@test "sync_list shows built-in sources with 'not synced' before first run" {
    run q_sync_list
    [ "$status" -eq 0 ]
    [[ "$output" == *"hacktricks"* ]]
    [[ "$output" == *"payloads"* ]]
    [[ "$output" == *"not synced"* ]]
}

# ---------------------------------------------------------------------------
# 2. sync_add appends user source and sync_list shows it
# ---------------------------------------------------------------------------
@test "sync_add appends user source and sync_list shows it" {
    run q_sync_add demo "file:///tmp/demo.git"
    [ "$status" -eq 0 ]
    [ -f "$Q_DATA_DIR/sync_sources" ]
    grep -q '^demo=file:///tmp/demo.git$' "$Q_DATA_DIR/sync_sources"

    run q_sync_list
    [ "$status" -eq 0 ]
    [[ "$output" == *"demo"* ]]
}

# ---------------------------------------------------------------------------
# 3. sync_run clones a fresh source from a local file:// remote
# ---------------------------------------------------------------------------
@test "sync_run clones a fresh source from a local file:// remote" {
    local bare="$BATS_TEST_TMPDIR/bare.git"
    local url
    url="$(_make_bare_repo "$bare")"

    q_sync_add demo "$url"
    run q_sync_run demo
    [ "$status" -eq 0 ]
    [ -d "$Q_SHEETS_DIR/external/demo" ]
    [ -f "$Q_SHEETS_DIR/external/demo/cat1/note.md" ]
    grep -q "Hello cheatsheet" "$Q_SHEETS_DIR/external/demo/cat1/note.md"
}

# ---------------------------------------------------------------------------
# 4. sync_run on existing source runs git pull
# ---------------------------------------------------------------------------
@test "sync_run on existing source runs git pull" {
    local bare="$BATS_TEST_TMPDIR/bare.git"
    local url
    url="$(_make_bare_repo "$bare")"

    q_sync_add demo "$url"
    q_sync_run demo
    [ -f "$Q_SHEETS_DIR/external/demo/cat1/note.md" ]

    _append_commit_to_bare "$bare"

    run q_sync_run demo
    [ "$status" -eq 0 ]
    [ -f "$Q_SHEETS_DIR/external/demo/cat1/second.md" ]
}

# ---------------------------------------------------------------------------
# 5. sync_run with subpath copies only that directory
# ---------------------------------------------------------------------------
@test "sync_run with subpath copies only that directory" {
    local bare="$BATS_TEST_TMPDIR/bare.git"
    local url
    url="$(_make_bare_repo "$bare" "src")"

    q_sync_add demo "${url}#src"
    run q_sync_run demo
    [ "$status" -eq 0 ]
    [ -d "$Q_SHEETS_DIR/external/demo" ]
    [ -f "$Q_SHEETS_DIR/external/demo/cat1/note.md" ]
    # README.md lived at repo root, OUTSIDE src/, so it must NOT be present.
    [ ! -f "$Q_SHEETS_DIR/external/demo/README.md" ]
}

# ---------------------------------------------------------------------------
# 6. sync_remove --force wipes the external/<name>/ dir
# ---------------------------------------------------------------------------
@test "sync_remove --force wipes the external/<name>/ dir" {
    local bare="$BATS_TEST_TMPDIR/bare.git"
    local url
    url="$(_make_bare_repo "$bare")"

    q_sync_add demo "$url"
    q_sync_run demo
    [ -d "$Q_SHEETS_DIR/external/demo" ]

    run q_sync_remove demo --force
    [ "$status" -eq 0 ]
    [ ! -d "$Q_SHEETS_DIR/external/demo" ]
}

# ---------------------------------------------------------------------------
# 7. sync_run writes .sync_meta with timestamp
# ---------------------------------------------------------------------------
@test "sync_run writes .sync_meta with timestamp" {
    local bare="$BATS_TEST_TMPDIR/bare.git"
    local url
    url="$(_make_bare_repo "$bare")"

    q_sync_add demo "$url"
    q_sync_run demo
    local meta="$Q_SHEETS_DIR/external/demo/.sync_meta"
    [ -f "$meta" ]
    grep -q '^timestamp=' "$meta"
    grep -q '^commit='    "$meta"
}

# ---------------------------------------------------------------------------
# 8. sync_disable causes sync_run (no arg) to skip the source
# ---------------------------------------------------------------------------
@test "sync_disable causes sync_run (no arg) to skip the source" {
    local bare="$BATS_TEST_TMPDIR/bare.git"
    local url
    url="$(_make_bare_repo "$bare")"

    q_sync_add demo "$url"
    q_sync_disable demo
    # Also disable all built-ins so a no-arg run won't try the network.
    q_sync_disable hacktricks
    q_sync_disable payloads

    run q_sync_run
    [ "$status" -eq 0 ]
    [ ! -d "$Q_SHEETS_DIR/external/demo" ]
}

# ---------------------------------------------------------------------------
# 9. sync_run fails clearly when remote URL is unreachable
# ---------------------------------------------------------------------------
@test "sync_run fails clearly when remote URL is unreachable" {
    q_sync_add demo "file:///nonexistent/repo.git"
    run q_sync_run demo
    [ "$status" -ne 0 ]
    [[ "$output" == *"[-]"* ]] || [[ "$output" == *"error"* ]] || [[ "$output" == *"fail"* ]]
}
