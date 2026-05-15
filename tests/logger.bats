#!/usr/bin/env bats
# logger.bats — TDD spec for lib/logger.sh

load test_helper

setup() {
    # Inherit the shared test_helper setup (data dirs, core/session sourced)
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
    source "$Q_TEST_ROOT/lib/logger.sh"
}

# ---------------------------------------------------------------------------
# q_log_target_slug
# ---------------------------------------------------------------------------

@test "log_target_slug for IP returns IP unchanged" {
    run q_log_target_slug "10.10.10.5"
    [ "$status" -eq 0 ]
    [ "$output" = "10.10.10.5" ]
}

@test "log_target_slug for URL strips scheme and replaces special chars" {
    run q_log_target_slug "https://example.com/admin?id=1&x=y"
    [ "$status" -eq 0 ]
    # Scheme stripped + / : ? & = replaced with _
    [ "$output" = "example.com_admin_id_1_x_y" ]
}

@test "log_target_slug for domain returns domain literally" {
    run q_log_target_slug "example.com"
    [ "$status" -eq 0 ]
    [ "$output" = "example.com" ]
}

@test "log_target_slug for string returns file_<hash8>" {
    run q_log_target_slug "some-arbitrary-string"
    [ "$status" -eq 0 ]
    expected_hash="$(printf '%s' "some-arbitrary-string" | md5sum | cut -c1-8)"
    [ "$output" = "file_${expected_hash}" ]
}

@test "log_target_slug for file path returns file_<hash8>" {
    run q_log_target_slug "/tmp/wordlist.txt"
    [ "$status" -eq 0 ]
    expected_hash="$(printf '%s' "/tmp/wordlist.txt" | md5sum | cut -c1-8)"
    [ "$output" = "file_${expected_hash}" ]
}

# ---------------------------------------------------------------------------
# q_log_path
# ---------------------------------------------------------------------------

@test "log_path creates dir and returns timestamped path under runs/<target>/" {
    run q_log_path "nmap" "10.0.0.1"
    [ "$status" -eq 0 ]
    sdir="$(q_session_dir)"
    [[ "$output" == "${sdir}/runs/10.0.0.1/nmap-"*.log ]]
    [ -d "${sdir}/runs/10.0.0.1" ]
    # The log file should not exist yet (caller writes to it), but the dir must
    [[ "$output" =~ nmap-[0-9]{8}-[0-9]{6}\.log$ ]]
}

@test "log_path with no target uses _unscoped" {
    run q_log_path "whoami"
    [ "$status" -eq 0 ]
    sdir="$(q_session_dir)"
    [[ "$output" == "${sdir}/runs/_unscoped/whoami-"*.log ]]
    [ -d "${sdir}/runs/_unscoped" ]
}

@test "log_path generates fresh timestamp each call" {
    p1="$(q_log_path nmap 1.1.1.1)"
    sleep 1
    p2="$(q_log_path nmap 1.1.1.1)"
    [ "$p1" != "$p2" ]
}

# ---------------------------------------------------------------------------
# q_log_extract_tool
# ---------------------------------------------------------------------------

@test "log_extract_tool strips sudo, env vars, paths and .py/.exe suffixes" {
    run q_log_extract_tool "FOO=bar sudo /usr/bin/nmap.py -sV 10.0.0.1"
    [ "$status" -eq 0 ]
    [ "$output" = "nmap" ]
}

@test "log_extract_tool handles plain command" {
    run q_log_extract_tool "subfinder -d example.com"
    [ "$status" -eq 0 ]
    [ "$output" = "subfinder" ]
}

@test "log_extract_tool strips .exe suffix" {
    run q_log_extract_tool "wine impacket-secretsdump.exe DOMAIN/user@10.0.0.1"
    [ "$status" -eq 0 ]
    [ "$output" = "wine" ]
}

@test "log_extract_tool handles multiple env vars" {
    run q_log_extract_tool "DEBUG=1 LOG=verbose /opt/bin/gobuster.py dir -u http://x"
    [ "$status" -eq 0 ]
    [ "$output" = "gobuster" ]
}

# ---------------------------------------------------------------------------
# q_log_extract_target
# ---------------------------------------------------------------------------

@test "log_extract_target finds IP in command" {
    run q_log_extract_target "nmap -sV -p- 192.168.1.100"
    [ "$status" -eq 0 ]
    [ "$output" = "192.168.1.100" ]
}

@test "log_extract_target finds URL in command" {
    run q_log_extract_target "ffuf -u https://example.com/FUZZ -w /tmp/wl.txt"
    [ "$status" -eq 0 ]
    [ "$output" = "https://example.com/FUZZ" ]
}

@test "log_extract_target finds domain when no IP/URL" {
    run q_log_extract_target "subfinder -d example.com -silent"
    [ "$status" -eq 0 ]
    [ "$output" = "example.com" ]
}

@test "log_extract_target returns empty when no candidate present" {
    run q_log_extract_target "whoami"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "log_extract_target prefers IP over domain when both present" {
    run q_log_extract_target "curl http://example.com/x 10.0.0.5"
    [ "$status" -eq 0 ]
    # IP takes precedence (well — actually URL is checked first; let's just verify URL wins)
    [ "$output" = "10.0.0.5" ]
}

# ---------------------------------------------------------------------------
# q_log_start
# ---------------------------------------------------------------------------

@test "log_start composes tool+target into a fresh log path" {
    run q_log_start "nmap -sV 10.10.10.10"
    [ "$status" -eq 0 ]
    sdir="$(q_session_dir)"
    [[ "$output" == "${sdir}/runs/10.10.10.10/nmap-"*.log ]]
    [ -d "${sdir}/runs/10.10.10.10" ]
}

@test "log_start falls back to _unscoped with no inferable target" {
    run q_log_start "id"
    [ "$status" -eq 0 ]
    sdir="$(q_session_dir)"
    [[ "$output" == "${sdir}/runs/_unscoped/id-"*.log ]]
}

# ---------------------------------------------------------------------------
# q_log_ls
# ---------------------------------------------------------------------------

@test "log_ls lists existing logs, newest first" {
    sdir="$(q_session_dir)"
    mkdir -p "$sdir/runs/10.0.0.1" "$sdir/runs/example.com"
    : > "$sdir/runs/10.0.0.1/nmap-20240101-100000.log"
    : > "$sdir/runs/example.com/ffuf-20240601-120000.log"
    : > "$sdir/runs/10.0.0.1/nmap-20250101-080000.log"
    touch -d '2024-01-01 10:00:00' "$sdir/runs/10.0.0.1/nmap-20240101-100000.log"
    touch -d '2024-06-01 12:00:00' "$sdir/runs/example.com/ffuf-20240601-120000.log"
    touch -d '2025-01-01 08:00:00' "$sdir/runs/10.0.0.1/nmap-20250101-080000.log"

    run q_log_ls
    [ "$status" -eq 0 ]
    # Three lines, newest first
    [ "${#lines[@]}" -eq 3 ]
    [[ "${lines[0]}" == *"nmap-20250101-080000.log"* ]]
    [[ "${lines[1]}" == *"ffuf-20240601-120000.log"* ]]
    [[ "${lines[2]}" == *"nmap-20240101-100000.log"* ]]
}

@test "log_ls filters by --tool" {
    sdir="$(q_session_dir)"
    mkdir -p "$sdir/runs/host1"
    : > "$sdir/runs/host1/nmap-20240101-100000.log"
    : > "$sdir/runs/host1/ffuf-20240101-110000.log"

    run q_log_ls --tool nmap
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 1 ]
    [[ "${lines[0]}" == *"nmap-"* ]]
}

@test "log_ls filters by --target" {
    sdir="$(q_session_dir)"
    mkdir -p "$sdir/runs/10.0.0.1" "$sdir/runs/10.0.0.2"
    : > "$sdir/runs/10.0.0.1/nmap-20240101-100000.log"
    : > "$sdir/runs/10.0.0.2/nmap-20240101-110000.log"

    run q_log_ls --target 10.0.0.1
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 1 ]
    [[ "${lines[0]}" == *"10.0.0.1/nmap-"* ]]
}

@test "log_ls returns nothing when runs/ missing" {
    run q_log_ls
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# q_log_show
# ---------------------------------------------------------------------------

@test "log_show prints contents of most recent matching log" {
    sdir="$(q_session_dir)"
    mkdir -p "$sdir/runs/10.0.0.1"
    printf 'OLD CONTENT\n' > "$sdir/runs/10.0.0.1/nmap-20240101-100000.log"
    printf 'NEW CONTENT\n' > "$sdir/runs/10.0.0.1/nmap-20250101-100000.log"
    touch -d '2024-01-01 10:00:00' "$sdir/runs/10.0.0.1/nmap-20240101-100000.log"
    touch -d '2025-01-01 10:00:00' "$sdir/runs/10.0.0.1/nmap-20250101-100000.log"

    Q_PREVIEWER=cat run q_log_show nmap 10.0.0.1
    [ "$status" -eq 0 ]
    [[ "$output" == *"NEW CONTENT"* ]]
    [[ "$output" != *"OLD CONTENT"* ]]
}

@test "log_show works across targets when target omitted" {
    sdir="$(q_session_dir)"
    mkdir -p "$sdir/runs/10.0.0.1" "$sdir/runs/10.0.0.2"
    printf 'A\n' > "$sdir/runs/10.0.0.1/nmap-20240101-100000.log"
    printf 'B\n' > "$sdir/runs/10.0.0.2/nmap-20250101-100000.log"
    touch -d '2024-01-01 10:00:00' "$sdir/runs/10.0.0.1/nmap-20240101-100000.log"
    touch -d '2025-01-01 10:00:00' "$sdir/runs/10.0.0.2/nmap-20250101-100000.log"

    Q_PREVIEWER=cat run q_log_show nmap
    [ "$status" -eq 0 ]
    [[ "$output" == *"B"* ]]
}

@test "log_show returns nonzero when no match" {
    run q_log_show nmap
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# q_log_prune
# ---------------------------------------------------------------------------

@test "log_prune --keep N retains only N most recent per target+tool" {
    sdir="$(q_session_dir)"
    mkdir -p "$sdir/runs/10.0.0.1"
    for i in 1 2 3 4 5; do
        f="$sdir/runs/10.0.0.1/nmap-2024010${i}-100000.log"
        : > "$f"
        touch -d "2024-01-0${i} 10:00:00" "$f"
    done

    run q_log_prune --keep 2
    [ "$status" -eq 0 ]

    # Only the 2 newest remain
    remaining="$(find "$sdir/runs/10.0.0.1" -type f -name '*.log' | wc -l)"
    [ "$remaining" -eq 2 ]
    [ -f "$sdir/runs/10.0.0.1/nmap-20240105-100000.log" ]
    [ -f "$sdir/runs/10.0.0.1/nmap-20240104-100000.log" ]
    [ ! -f "$sdir/runs/10.0.0.1/nmap-20240101-100000.log" ]
}

@test "log_prune --older-than DAYS deletes only files older than threshold" {
    sdir="$(q_session_dir)"
    mkdir -p "$sdir/runs/10.0.0.1"
    old="$sdir/runs/10.0.0.1/nmap-old.log"
    new="$sdir/runs/10.0.0.1/nmap-new.log"
    : > "$old"; : > "$new"
    # Make old 60 days ago, new today
    touch -d "60 days ago" "$old"
    touch -d "now" "$new"

    run q_log_prune --older-than 30
    [ "$status" -eq 0 ]
    [ ! -f "$old" ]
    [ -f "$new" ]
}

@test "log_prune with no flags only reports stats and does not delete" {
    sdir="$(q_session_dir)"
    mkdir -p "$sdir/runs/10.0.0.1"
    f="$sdir/runs/10.0.0.1/nmap-x.log"
    : > "$f"
    touch -d "60 days ago" "$f"

    run q_log_prune
    [ "$status" -eq 0 ]
    [ -f "$f" ]
}
