#!/usr/bin/env bash
# tmux.sh — tmux integration for q sessions
# Sourced by the main `q` script; not meant to be executed directly.
#
# Provides:
#   q_tmux_start [NAME]         Create the tmux session for a q session.
#   q_tmux_attach [NAME]        Attach to / switch to that tmux session.
#   q_tmux_kill [NAME]          Kill that tmux session.
#   q_tmux_list                 List q-managed tmux sessions.
#   q_tmux_send CMD [PANE]      Send a command into a pane (default 0).
#   q_tmux_run_parallel CMD     Fan a command out to one pane per target.
#   q_tmux_help                 Print the key-binding cheatsheet.
#
# Tmux socket isolation:
#   Every tmux call goes through _q_tmux which honors Q_TMUX_SOCKET (used by
#   the test harness to point at a private server). Production leaves it
#   unset so the user's default socket is used.
#
# Key-binding scoping:
#   tmux does not let us scope `bind-key` per-session. Rather than mutate the
#   user's global tmux config, we write a per-session config snippet at
#   start-time and `source-file` it. The bindings live globally on whatever
#   tmux server hosts the q session, but they were not added until the user
#   ran `q tmux start`, so the user explicitly opted in. We document this
#   trade-off in q_tmux_help.

# ===========================================================================
# _q_tmux — wrapper that routes through Q_TMUX_SOCKET when set
# ===========================================================================
_q_tmux() {
    if [[ -n "${Q_TMUX_SOCKET:-}" ]]; then
        tmux -L "$Q_TMUX_SOCKET" "$@"
    else
        tmux "$@"
    fi
}

# ===========================================================================
# q_tmux_session_name — print the user-facing tmux session label
# ===========================================================================
# Usage: q_tmux_session_name [Q_SESSION_NAME]
# Returns the public identifier 'q:<name>' that we use in user-facing logs.
# NOTE: tmux disallows ':' in real session names (it parses as the
# session:window separator), so internal tmux operations use the sanitized
# form returned by _q_tmux_real_name. Callers that only need to *display*
# the session label should use this; callers that need to invoke tmux
# should use _q_tmux_real_name.
q_tmux_session_name() {
    local name="${1:-$Q_SESSION_NAME}"
    printf 'q:%s' "$name"
}

# ===========================================================================
# _q_tmux_real_name — tmux-safe internal session name
# ===========================================================================
# tmux refuses ':' in session names (collapses it to '_'), so we keep an
# explicit sanitized form: 'q_<name>'. This is what we pass to every
# -t flag.
_q_tmux_real_name() {
    local name="${1:-$Q_SESSION_NAME}"
    printf 'q_%s' "$name"
}

# ===========================================================================
# _q_tmux_runner_fill — type-aware target placeholder substitution
# ===========================================================================
# Mirrors lib/runner.sh::_q_runner_fill_target — keep behavior in sync but
# do not reuse the function so this lib has zero load-order dependencies.
# Returns 0 with the filled template on stdout, or 1 if the target type is
# incompatible with the placeholders in the template.
_q_tmux_runner_fill() {
    local ttype="$1" value="$2" cmd="$3"

    if [[ "$cmd" == *"{{IP}}"* ]] && [[ "$ttype" != "ip" ]]; then
        return 1
    fi
    if [[ "$cmd" == *"{{URL}}"* ]] && [[ "$ttype" != "url" ]]; then
        return 1
    fi
    if [[ "$cmd" == *"{{DOMAIN}}"* ]] && [[ "$ttype" != "domain" ]]; then
        return 1
    fi
    if [[ "$cmd" == *"{{HOST}}"* || "$cmd" == *"{{RHOST}}"* ]]; then
        case "$ttype" in
            ip|domain|url) ;;
            *) return 1 ;;
        esac
    fi

    local result="$cmd"
    result="${result//\{\{TARGET\}\}/$value}"
    result="${result//\{\{IP\}\}/$value}"
    result="${result//\{\{URL\}\}/$value}"
    result="${result//\{\{HOST\}\}/$value}"
    result="${result//\{\{RHOST\}\}/$value}"
    result="${result//\{\{DOMAIN\}\}/$value}"

    printf '%s' "$result"
}

# ===========================================================================
# _q_tmux_safe_name — turn a target value into a filename-safe slug
# ===========================================================================
_q_tmux_safe_name() {
    local v="$1"
    printf '%s' "${v//[^a-zA-Z0-9._-]/_}"
}

# ===========================================================================
# _q_tmux_write_bindings — write per-session binding config and source it
# ===========================================================================
# We render a tmux config snippet into the session dir and source-file it
# against the running server. This avoids editing ~/.tmux.conf and keeps the
# bindings tied to a q session lifecycle (clean kill = no leftover state on
# next start).
_q_tmux_write_bindings() {
    local tmux_name="$1" sdir="$2" q_bin="$3"
    local cfg="${sdir}/tmux.conf"

    # Heredoc — tmux is permissive about quoting in its own DSL. We use single
    # quotes around shell commands so $-vars are evaluated when tmux fires
    # the binding (via run-shell), not now.
    cat > "$cfg" <<TMUXCFG
# Per-q-session tmux bindings (sourced by lib/tmux.sh)
# Session: ${tmux_name}
# q binary: ${q_bin}

# Show the q session in the status line.
set-option -t '${tmux_name}' status on
set-option -t '${tmux_name}' status-left '#[bold]q:${Q_SESSION_NAME}#[default] | '
set-option -t '${tmux_name}' status-right '#(${q_bin} ls 2>/dev/null | grep -c ^ || echo 0) lines | %H:%M'
set-option -t '${tmux_name}' status-interval 5

# Mark this session so conditional hooks can target it.
set-option -t '${tmux_name}' @q_session '${Q_SESSION_NAME}'

# Prefix + t : add target
bind-key -T prefix -N 'q: add target'      t command-prompt -p 'target>' "send-keys -t '${tmux_name}.0' '${q_bin} t %1' C-m"

# Prefix + s : set variable
bind-key -T prefix -N 'q: set var'         s command-prompt -p 'KEY=VALUE>' "send-keys -t '${tmux_name}.0' '${q_bin} set %1' C-m"

# Prefix + r : interactive search
bind-key -T prefix -N 'q: search'          r send-keys -t '${tmux_name}.0' '${q_bin}' C-m

# Prefix + p : promote
bind-key -T prefix -N 'q: promote'         p send-keys -t '${tmux_name}.0' '${q_bin} promote' C-m

# Prefix + L : logs ls (popup if tmux >= 3.2, else split window)
bind-key -T prefix -N 'q: logs ls'         L if-shell '[ "\$(tmux -V | awk "{print \$2}" | cut -d. -f1)" -ge 3 ]' "display-popup -E '${q_bin} logs ls; read -n1'" "split-window -h '${q_bin} logs ls; read -n1'"

# Prefix + Y : capture pane to clipboard
bind-key -T prefix -N 'q: capture pane'    Y run-shell "tmux capture-pane -p -t '${tmux_name}' | xclip -selection clipboard 2>/dev/null"

# Prefix + ? : help popup
bind-key -T prefix -N 'q: help'            \\? display-popup -E "cat <<HLP
q tmux bindings (prefix = C-b)
  prefix t     add target
  prefix s     set KEY=VALUE
  prefix r     interactive search
  prefix p     promote discoveries
  prefix L     logs ls
  prefix Y     capture pane to clipboard
  prefix ?     this help
HLP
read -n1"
TMUXCFG

    _q_tmux source-file -t "$tmux_name" "$cfg" 2>/dev/null || true
}

# ===========================================================================
# q_tmux_start [Q_SESSION_NAME] — create the tmux session if missing
# ===========================================================================
q_tmux_start() {
    local name="${1:-$Q_SESSION_NAME}"
    local label real
    label="$(q_tmux_session_name "$name")"
    real="$(_q_tmux_real_name "$name")"

    if _q_tmux has-session -t "$real" 2>/dev/null; then
        q_info "Session exists, attach with q tmux attach"
        return 0
    fi

    local sdir="${Q_SESSION_DIR}/${name}"
    [[ -d "$sdir" ]] || mkdir -p "$sdir"

    local q_bin="${Q_ROOT}/q"
    local shell="${SHELL:-/bin/bash}"

    # Main pane: cd to session dir with the q session env exported.
    _q_tmux new-session -d -s "$real" -x 200 -y 50 \
        -n main \
        "cd '$sdir' && Q_SESSION_NAME='$name' exec $shell"

    # Bottom-left pane (split off the main, takes ~30% of width below).
    # The pane runs `q ls` on a 2-sec watch loop.
    _q_tmux split-window -v -t "${real}:0.0" -p 30 \
        "watch -n 2 -d '$q_bin ls 2>&1 | tail -40'"

    # Bottom-right pane: follow history.log.
    local hist_file="${sdir}/history.log"
    touch "$hist_file"
    _q_tmux split-window -h -t "${real}:0.1" -p 50 \
        "tail -F '$hist_file' 2>/dev/null"

    # Move focus back to the main pane.
    _q_tmux select-pane -t "${real}:0.0" 2>/dev/null || true

    # Stash the q session name on the tmux env so panes can read it.
    _q_tmux setenv -t "$real" Q_SESSION_NAME "$name" 2>/dev/null || true

    _q_tmux_write_bindings "$real" "$sdir" "$q_bin"

    q_success "tmux session created: ${label}. Attach with: q tmux attach"
    return 0
}

# ===========================================================================
# q_tmux_attach [Q_SESSION_NAME] — attach or switch to the tmux session
# ===========================================================================
q_tmux_attach() {
    local name="${1:-$Q_SESSION_NAME}"
    local label real
    label="$(q_tmux_session_name "$name")"
    real="$(_q_tmux_real_name "$name")"

    if ! _q_tmux has-session -t "$real" 2>/dev/null; then
        q_error "tmux session '${label}' does not exist."
        q_error "Start it with: q tmux start"
        return 1
    fi

    if [[ -n "${TMUX:-}" ]]; then
        _q_tmux switch-client -t "$real"
    else
        _q_tmux attach -t "$real"
    fi
}

# ===========================================================================
# q_tmux_kill [Q_SESSION_NAME] — kill the tmux session
# ===========================================================================
q_tmux_kill() {
    local name="${1:-$Q_SESSION_NAME}"
    local label real
    label="$(q_tmux_session_name "$name")"
    real="$(_q_tmux_real_name "$name")"

    if ! _q_tmux has-session -t "$real" 2>/dev/null; then
        q_warn "tmux session '${label}' does not exist."
        return 0
    fi

    if _q_tmux kill-session -t "$real" 2>/dev/null; then
        q_success "Killed tmux session: ${label}"
    else
        q_warn "Failed to kill tmux session: ${label}"
        return 1
    fi
}

# ===========================================================================
# q_tmux_list — list q-managed tmux sessions
# ===========================================================================
q_tmux_list() {
    local raw
    raw="$(_q_tmux list-sessions -F '#{session_name}|#{session_activity}' 2>/dev/null || true)"
    if [[ -z "$raw" ]]; then
        q_info "No tmux sessions."
        return 0
    fi

    local tname act qname tfile tcount
    while IFS='|' read -r tname act; do
        [[ "$tname" == q_* ]] || continue
        qname="${tname#q_}"
        tfile="${Q_SESSION_DIR}/${qname}/targets"
        if [[ -f "$tfile" ]]; then
            tcount="$(grep -c . "$tfile" 2>/dev/null || printf '0')"
        else
            tcount="0"
        fi
        # Print user-facing label (q:<name>) so output looks consistent
        # with what q_tmux_session_name returns.
        printf 'q:%s\ttargets=%s\tlast=%s\n' "$qname" "$tcount" "$act"
    done <<< "$raw"
}

# ===========================================================================
# q_tmux_send CMD [PANE] — send a command to a pane
# ===========================================================================
# Default pane is ${q_tmux_session_name}:0.0 (main pane of main window).
q_tmux_send() {
    local cmd="$1" pane="${2:-}"
    if [[ -z "$cmd" ]]; then
        q_error "q_tmux_send: command required"
        return 1
    fi

    local real
    real="$(_q_tmux_real_name)"
    if [[ -z "$pane" ]]; then
        pane="${real}:0.0"
    fi

    if ! _q_tmux has-session -t "$real" 2>/dev/null; then
        q_error "tmux session '$(q_tmux_session_name)' not running. Run: q tmux start"
        return 1
    fi

    _q_tmux send-keys -t "$pane" "$cmd" C-m
}

# ===========================================================================
# q_tmux_run_parallel CMD — fan command out to one pane per target
# ===========================================================================
# Spawns a new window named run-<TS> on the q tmux session. Each pane runs
# the substituted command piped through tee to runs/parallel/<target>-<ts>.out
# and then drops into $SHELL so the user can inspect.
q_tmux_run_parallel() {
    local cmd="$*"
    if [[ -z "$cmd" ]]; then
        q_error "q_tmux_run_parallel: command template required"
        return 1
    fi

    local label real
    label="$(q_tmux_session_name)"
    real="$(_q_tmux_real_name)"

    if ! _q_tmux has-session -t "$real" 2>/dev/null; then
        q_error "tmux session '${label}' not running. Run: q tmux start"
        return 1
    fi

    local sdir
    sdir="$(q_session_dir)"
    local targets_file="${sdir}/targets"

    if [[ ! -f "$targets_file" ]] || [[ ! -s "$targets_file" ]]; then
        q_error "No targets in session '${Q_SESSION_NAME}'. Add some with: q t IP"
        return 1
    fi

    # Pre-resolve which targets are compatible — we need to know the count
    # before opening the window so we can short-circuit on <=1.
    local -a pairs=()
    local line ttype tvalue filled
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        ttype="${line%%:*}"
        tvalue="${line#*:}"
        if filled="$(_q_tmux_runner_fill "$ttype" "$tvalue" "$cmd")"; then
            pairs+=("${tvalue}"$'\t'"${filled}")
        fi
    done < "$targets_file"

    if [[ "${#pairs[@]}" -le 1 ]]; then
        q_error "tmux_run_parallel needs >=2 compatible targets. Use 'q run' instead."
        return 1
    fi

    local ts
    printf -v ts '%(%Y%m%d-%H%M%S)T' -1
    local win="run-${ts}"

    local out_dir="${sdir}/runs/parallel"
    mkdir -p "$out_dir"

    # First pair becomes the new window; the rest are split-window onto it.
    local first_target first_cmd safe out_file pane_cmd
    first_target="${pairs[0]%%$'\t'*}"
    first_cmd="${pairs[0]#*$'\t'}"
    safe="$(_q_tmux_safe_name "$first_target")"
    out_file="${out_dir}/${safe}-${ts}.out"
    # Pane shell: run filled command, tee to file, then drop into $SHELL.
    pane_cmd="bash -c '${first_cmd//\'/\'\\\'\'} 2>&1 | tee \"${out_file}\"; exec \${SHELL:-/bin/bash}'"

    _q_tmux new-window -t "$real" -n "$win" "$pane_cmd"

    local idx=1
    while (( idx < ${#pairs[@]} )); do
        local target_i cmd_i
        target_i="${pairs[$idx]%%$'\t'*}"
        cmd_i="${pairs[$idx]#*$'\t'}"
        safe="$(_q_tmux_safe_name "$target_i")"
        out_file="${out_dir}/${safe}-${ts}.out"
        pane_cmd="bash -c '${cmd_i//\'/\'\\\'\'} 2>&1 | tee \"${out_file}\"; exec \${SHELL:-/bin/bash}'"

        _q_tmux split-window -t "${real}:${win}" "$pane_cmd"
        # Re-tile so panes don't shrink off-screen as we add more.
        _q_tmux select-layout -t "${real}:${win}" tiled >/dev/null 2>&1 || true
        idx=$((idx + 1))
    done

    _q_tmux select-layout -t "${real}:${win}" tiled >/dev/null 2>&1 || true

    q_success "Spawned ${#pairs[@]} panes in window ${win}. Switch with: tmux select-window -t ${label}:${win}"
    return 0
}

# ===========================================================================
# q_tmux_help — print the binding cheatsheet to stderr
# ===========================================================================
q_tmux_help() {
    cat >&2 <<HLP
q tmux bindings (prefix = C-b by default)

  prefix t     add target (prompt)
  prefix s     set KEY=VALUE (prompt)
  prefix r     open interactive q search in main pane
  prefix p     run q promote
  prefix L     q logs ls (popup on tmux >= 3.2, else new pane)
  prefix Y     capture current pane to clipboard (xclip)
  prefix ?     show this help in a tmux popup

Notes:
  - Bindings are loaded via 'source-file' on the q tmux session at start time.
  - tmux cannot scope key bindings per-session, so they live globally on
    whatever tmux server hosts the q session. q tmux kill removes the
    session but the binding table persists until the server restarts.
HLP
}
