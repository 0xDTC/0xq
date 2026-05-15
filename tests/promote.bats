#!/usr/bin/env bats
# promote.bats — tests for lib/promote.sh
# Covers discovery->target promotion and extended parsers.

load test_helper

# Source the lib under test on top of helper's setup (which sources core+session).
# BATS calls the helper's setup() automatically before each test; we just add to it.
_promote_setup() {
    # shellcheck disable=SC1091
    source "${BATS_TEST_DIRNAME}/../lib/promote.sh"
}

# Per-test setup: run helper's setup first, then ours.
# bats lets us redefine setup() after `load`; we replicate helper behaviour and
# add the promote.sh source on top.
setup() {
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

    _promote_setup
}

# --------------------------------------------------------------------------
# q_promote_discoveries
# --------------------------------------------------------------------------

@test "promote_discoveries adds IPs from discovery store to targets" {
    q_discover_add ips "10.10.11.45" "192.168.1.10"

    run q_promote_discoveries
    [ "$status" -eq 0 ]

    local tfile
    tfile="$(q_session_dir)/targets"
    [ -f "$tfile" ]
    grep -qxF "ip:10.10.11.45" "$tfile"
    grep -qxF "ip:192.168.1.10" "$tfile"
}

@test "promote_discoveries skips IPs already in targets" {
    q_target_add "10.10.11.45" "manual"
    q_discover_add ips "10.10.11.45" "192.168.1.10"

    run q_promote_discoveries
    [ "$status" -eq 0 ]

    local tfile
    tfile="$(q_session_dir)/targets"
    # 10.10.11.45 should appear exactly once (no duplicate from promotion)
    local count
    count="$(grep -cxF "ip:10.10.11.45" "$tfile")"
    [ "$count" -eq 1 ]
    grep -qxF "ip:192.168.1.10" "$tfile"
}

@test "promote_discoveries adds domains and URLs" {
    q_discover_add domains "dc01.lab.local" "web.lab.local"
    q_discover_add urls "https://lab.local/admin" "http://10.10.11.45/login"

    run q_promote_discoveries
    [ "$status" -eq 0 ]

    local tfile
    tfile="$(q_session_dir)/targets"
    grep -qxF "domain:dc01.lab.local" "$tfile"
    grep -qxF "domain:web.lab.local" "$tfile"
    grep -qxF "url:https://lab.local/admin" "$tfile"
    grep -qxF "url:http://10.10.11.45/login" "$tfile"
}

@test "promote_discoveries handles empty discovery store gracefully" {
    # No discoveries added at all
    run q_promote_discoveries
    [ "$status" -eq 0 ]

    local tfile="$(q_session_dir)/targets"
    # File may not exist or may be empty — both fine
    if [[ -f "$tfile" ]]; then
        [ ! -s "$tfile" ]
    fi
}

@test "promote_discoveries reports count via q_info" {
    q_discover_add ips "10.0.0.1" "10.0.0.2"
    q_discover_add domains "lab.local"

    run q_promote_discoveries
    [ "$status" -eq 0 ]
    [[ "$output" == *"Promoted"* ]]
    [[ "$output" == *"3"* ]]
}

# --------------------------------------------------------------------------
# q_parse_output_extra — SMB shares
# --------------------------------------------------------------------------

@test "parse_output_extra extracts SMB shares from crackmapexec output" {
    local out
    out="$(cat "${BATS_TEST_DIRNAME}/fixtures/promote/cme.txt")"
    run q_parse_output_extra "$out" "nxc smb 10.10.11.45 -u jdoe -p Password123 --shares"
    [ "$status" -eq 0 ]

    local shares
    shares="$(q_discover_get shares 2>/dev/null || true)"
    [[ "$shares" == *"Reports"* ]]
    [[ "$shares" == *"Backups"* ]]
    [[ "$shares" == *"IPC"* ]]
}

# --------------------------------------------------------------------------
# q_parse_output_extra — JWT tokens
# --------------------------------------------------------------------------

@test "parse_output_extra extracts JWT tokens" {
    local out
    out="$(cat "${BATS_TEST_DIRNAME}/fixtures/promote/jwt.txt")"
    run q_parse_output_extra "$out" "curl -i https://api.lab.local/login"
    [ "$status" -eq 0 ]

    local jwts
    jwts="$(q_discover_get jwts 2>/dev/null || true)"
    [ -n "$jwts" ]
    # At least one of the two JWTs in the fixture should be captured
    [[ "$jwts" == *"eyJ"* ]]
    # And it should be a long string (>100 chars total)
    local longest
    longest="$(printf '%s\n' "$jwts" | awk '{ if (length > max) { max = length; line = $0 } } END { print line }')"
    [ "${#longest}" -gt 100 ]
}

@test "parse_output_extra does not flag short base64 strings as JWTs" {
    local out="header.payload.sig"
    run q_parse_output_extra "$out" "echo hi"
    [ "$status" -eq 0 ]

    local jwts
    jwts="$(q_discover_get jwts 2>/dev/null || true)"
    [ -z "$jwts" ]
}

# --------------------------------------------------------------------------
# q_parse_output_extra — NTLM/Kerberos hashes
# --------------------------------------------------------------------------

@test "parse_output_extra extracts NTLM hashes" {
    local out
    out="$(cat "${BATS_TEST_DIRNAME}/fixtures/promote/hashes.txt")"
    run q_parse_output_extra "$out" "secretsdump.py LAB/jdoe@10.10.11.45"
    [ "$status" -eq 0 ]

    local hashes
    hashes="$(q_discover_get hashes 2>/dev/null || true)"
    [ -n "$hashes" ]
    # The Administrator line is the classic NTLM pwdump format
    [[ "$hashes" == *"Administrator"* ]] || [[ "$hashes" == *"31d6cfe0d16ae931b73c59d7e0c089c0"* ]]
    # Should also pick up the krb5 asrep/tgs
    [[ "$hashes" == *'$krb5'* ]]
}

# --------------------------------------------------------------------------
# q_parse_output_extra — LDAP base DNs
# --------------------------------------------------------------------------

@test "parse_output_extra extracts LDAP base DNs" {
    local out
    out="$(cat "${BATS_TEST_DIRNAME}/fixtures/promote/ldap.txt")"
    run q_parse_output_extra "$out" "ldapsearch -x -H ldap://dc01.lab.local -b DC=lab,DC=local"
    [ "$status" -eq 0 ]

    local dns
    dns="$(q_discover_get ldap_dns 2>/dev/null || true)"
    [ -n "$dns" ]
    [[ "$dns" == *"DC=lab,DC=local"* ]]
}

# --------------------------------------------------------------------------
# q_parse_output_extra — HTTP titles
# --------------------------------------------------------------------------

@test "parse_output_extra extracts HTTP titles" {
    local out
    out="$(cat "${BATS_TEST_DIRNAME}/fixtures/promote/titles.txt")"
    run q_parse_output_extra "$out" "curl -s http://10.10.11.45/"
    [ "$status" -eq 0 ]

    local titles
    titles="$(q_discover_get titles 2>/dev/null || true)"
    [ -n "$titles" ]
    [[ "$titles" == *"Acme Corporate Intranet - Login"* ]]
}

# --------------------------------------------------------------------------
# q_promote_after_run — integration
# --------------------------------------------------------------------------

@test "promote_after_run integrates parse + promote" {
    # Synthesize nmap-ish output so q_parse_output (in session.sh) picks ips
    local out="Nmap scan report for 10.10.11.45
Host is up.
PORT     STATE SERVICE
22/tcp   open  ssh
80/tcp   open  http"

    run q_promote_after_run "$out" "nmap -sV 10.10.11.45"
    [ "$status" -eq 0 ]

    # parse_output should have populated ips discovery
    local ips
    ips="$(q_discover_get ips)"
    [[ "$ips" == *"10.10.11.45"* ]]

    # And promote_discoveries should have copied that into targets
    local tfile
    tfile="$(q_session_dir)/targets"
    grep -qxF "ip:10.10.11.45" "$tfile"
}

@test "promote_after_run also runs extra parsers" {
    local out
    out="$(cat "${BATS_TEST_DIRNAME}/fixtures/promote/cme.txt")"
    run q_promote_after_run "$out" "nxc smb 10.10.11.45 --shares"
    [ "$status" -eq 0 ]

    # Shares should have been picked up by the extra parser
    local shares
    shares="$(q_discover_get shares)"
    [[ "$shares" == *"Reports"* ]]

    # And the IP from the output should be a target now
    local tfile
    tfile="$(q_session_dir)/targets"
    grep -qxF "ip:10.10.11.45" "$tfile"
}
