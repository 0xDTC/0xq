#!/usr/bin/env bash
# executor.sh — Command pre-checks, confirmation, execution, and history display
# Sourced by the main `q` script; not meant to be executed directly.

# ===========================================================================
# q_pre_exec_check — verify the command's primary binary exists
# ===========================================================================
# Extracts the first word of the command (the tool binary) and checks if it
# is available on the system. Returns 1 with a helpful message if missing.
q_pre_exec_check() {
    local command="$1"

    # Parse the command to find the actual binary name, skipping env vars and sudo.
    # Split into words and walk through them.
    local -a words
    read -ra words <<< "$command"

    local binary=""
    local i=0

    # Skip leading environment variable assignments (FOO=bar)
    while [[ $i -lt ${#words[@]} ]] && [[ "${words[$i]}" == *=* ]] && \
          [[ "${words[$i]}" =~ ^[A-Za-z_] ]]; do
        ((i++))
    done

    # Skip sudo and its flags
    if [[ $i -lt ${#words[@]} ]] && [[ "${words[$i]}" == "sudo" ]]; then
        ((i++))
        while [[ $i -lt ${#words[@]} ]] && [[ "${words[$i]}" == -* ]]; do
            local flag="${words[$i]}"
            ((i++))
            # Flags that consume the next word as an argument
            case "$flag" in
                -u|-g|-C|-D) ((i++)) ;;
            esac
        done
    fi

    if [[ $i -lt ${#words[@]} ]]; then
        binary="${words[$i]}"
    fi

    # Skip check for shell builtins and empty commands
    case "$binary" in
        ""|cd|echo|printf|export|source|.) return 0 ;;
    esac

    if ! command -v "$binary" &>/dev/null; then
        q_warn "Tool '${binary}' not found on this system."
        q_warn "Install with: ${Q_BOLD}sudo apt install ${binary}${Q_RESET}"
        # Ask whether to continue anyway
        printf '%s' "${Q_YELLOW}Continue anyway? [y/N] ${Q_RESET}" >&2
        local reply
        read -rsn1 reply < /dev/tty
        printf '\n' >&2
        if [[ "$reply" != "y" ]] && [[ "$reply" != "Y" ]]; then
            return 1
        fi
    fi

    return 0
}

# ===========================================================================
# _q_copy_to_clipboard — copy text to system clipboard
# ===========================================================================
# Delegates to q_clipboard_write (session.sh) for the actual clipboard access.
_q_copy_to_clipboard() {
    local text="$1"

    if q_clipboard_write "$text"; then
        return 0
    fi

    q_warn "No clipboard tool available."
    return 1
}

# ===========================================================================
# _q_edit_command — open command in editor, return edited version
# ===========================================================================
_q_edit_command() {
    local command="$1"
    local tmpfile
    tmpfile="$(mktemp /tmp/q_edit_XXXXXX.sh)"

    printf '%s\n' "$command" > "$tmpfile"

    local editor="${EDITOR:-${VISUAL:-nano}}"
    $editor "$tmpfile" < /dev/tty > /dev/tty 2>&1

    local edited
    edited="$(cat "$tmpfile")"
    rm -f "$tmpfile"

    printf '%s' "$edited"
}

# ===========================================================================
# q_confirm_and_run — display, confirm, then execute a command
# ===========================================================================
q_confirm_and_run() {
    local command="$1"

    # Display the final command prominently
    printf '\n' >&2
    printf '%s%s %s %s\n' "$Q_BOLD" "$Q_GREEN" "$command" "$Q_RESET" >&2
    printf '\n' >&2

    if [[ "${Q_CONFIRM_EXEC}" == "yes" ]]; then
        # Flush any stale input left in terminal buffer from fzf/variable fill
        while read -rsn1 -t 0.05 _ < /dev/tty 2>/dev/null; do :; done

        # Interactive confirmation prompt
        printf '%s[Enter]%s Run  ' "$Q_BOLD" "$Q_RESET" >&2
        printf '%s[e]%s Edit  '    "$Q_BOLD" "$Q_RESET" >&2
        printf '%s[c]%s Copy  '    "$Q_BOLD" "$Q_RESET" >&2
        printf '%s[q]%s Cancel  '  "$Q_BOLD" "$Q_RESET" >&2
        printf '\n' >&2

        local key
        read -rsn1 key < /dev/tty
        printf '\n' >&2

        case "$key" in
            # Enter key, 'y', 'r', or empty — execute
            ''|y|Y|r|R)
                _q_execute "$command"
                ;;
            # Edit in editor
            e|E)
                local edited
                edited="$(_q_edit_command "$command")"
                if [[ -z "$edited" ]]; then
                    q_info "Empty command after editing — cancelled."
                    return 0
                fi
                if [[ "$edited" != "$command" ]]; then
                    q_info "Edited command:"
                    printf '%s%s %s %s\n' "$Q_BOLD" "$Q_GREEN" "$edited" "$Q_RESET" >&2
                fi
                _q_execute "$edited"
                ;;
            # Copy to clipboard
            c|C)
                if _q_copy_to_clipboard "$command"; then
                    q_success "Copied to clipboard."
                fi
                ;;
            # Cancel (q, Escape, or anything else)
            *)
                q_info "Cancelled."
                ;;
        esac
    else
        # No confirmation needed — execute directly
        _q_execute "$command"
    fi
}

# ===========================================================================
# _q_execute — run the actual command after checks
# ===========================================================================
_q_execute() {
    local command="$1"

    # Pre-flight binary check
    if ! q_pre_exec_check "$command"; then
        return 1
    fi

    # Log to history
    q_history_log "$command"

    # Resolve a persistent per-target log path under sessions/<name>/runs/.
    # q_log_start returns a fresh timestamped path with its parent dir created.
    # If logger.sh isn't sourced (defensive), fall back to a temp file.
    local logfile
    if declare -f q_log_start >/dev/null 2>&1; then
        logfile="$(q_log_start "$command")"
    else
        logfile="$(mktemp /tmp/q_output_XXXXXX)"
    fi

    printf '%s--- Executing ---%s\n' "$Q_DIM" "$Q_RESET" >&2
    printf '%slog: %s%s\n' "$Q_DIM" "$logfile" "$Q_RESET" >&2
    # Disable errexit around the user command — many tools legitimately exit
    # non-zero (no results, failed auth); that must NOT abort q before the
    # output is parsed/promoted and the exit code is returned.
    local exit_code
    set +e
    eval "$command" 2>&1 | tee "$logfile"
    exit_code=${PIPESTATUS[0]}
    set -e
    printf '%s--- Finished (exit %d) ---%s\n' "$Q_DIM" "$exit_code" "$Q_RESET" >&2

    # Parse output for discoverable data and promote high-confidence findings
    # (IPs, domains, URLs) into the session's target list. q_promote_after_run
    # invokes the base parser, the extra parsers (hashes, JWTs, SMB shares,
    # LDAP DNs, titles), then the discovery→target bridge.
    if [[ -s "$logfile" ]]; then
        local captured
        captured="$(cat "$logfile")"
        if declare -f q_promote_after_run >/dev/null 2>&1; then
            q_promote_after_run "$captured" "$command" 2>/dev/null || true
        else
            q_parse_output "$captured" "$command" 2>/dev/null || true
        fi
    fi

    return "$exit_code"
}

# ===========================================================================
# q_show_history — display the session's command history
# ===========================================================================
q_show_history() {
    local log_file
    log_file="$(q_session_dir)/history.log"

    if [[ ! -f "$log_file" ]] || [[ ! -s "$log_file" ]]; then
        q_info "No command history for session '${Q_SESSION_NAME}'."
        return 0
    fi

    printf '%s%sCommand History [%s]:%s\n\n' "$Q_BOLD" "$Q_CYAN" "$Q_SESSION_NAME" "$Q_RESET" >&2

    local line_num=0
    while IFS=$'\t' read -r timestamp cmd; do
        [[ -z "$timestamp" ]] && continue
        line_num=$((line_num + 1))
        printf '  %s%3d  %s%s  %s\n' "$Q_DIM" "$line_num" "$timestamp" "$Q_RESET" "$cmd" >&2
    done < "$log_file"

    printf '\n  %s%d commands total%s\n' "$Q_DIM" "$line_num" "$Q_RESET" >&2
}
