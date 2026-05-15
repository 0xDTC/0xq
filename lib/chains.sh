#!/usr/bin/env bash
# chains.sh — YAML-defined command chains for q.
#
# Sourced by the main `q` script. Provides three public entry points:
#
#   q_chain_list           List all known chains (name: description).
#   q_chain_show NAME      Pretty-print the steps of a chain.
#   q_chain_run NAME [--dry-run]
#                          Execute a chain's steps in order, halting on the
#                          first failure unless the step is marked
#                          continue_on_error: true.
#
# ----------------------------------------------------------------------------
# Supported YAML schema (strict — only this subset is parsed):
#
#   name: <string>                  # chain identifier
#   description: <string>           # one-line summary
#   vars:                           # optional — merged into session, never
#     KEY1: "value1"                # overwriting an existing session value
#     KEY2: "value2"
#   steps:                          # required, ordered list
#     - title: <string>             # human-readable label
#       command: <string>           # shell command (may contain {{VAR}})
#       when: "<VAR_NAME>"          # optional gate — step runs only if the
#                                   # session variable VAR_NAME is set and
#                                   # non-empty
#       continue_on_error: <bool>   # default false — when false, a non-zero
#                                   # exit halts the chain
#
# ----------------------------------------------------------------------------
# Parsing approach: we shell out to `yq` (Python yq, jq-compatible syntax,
# already a build dep on Kali). A custom awk parser was considered, but yq
# correctly handles quoted strings, escaped characters, comments, and edge
# cases (true/false booleans, missing keys via `// ""`) for free. The overhead
# of one `yq` call per field is acceptable for chain orchestration — chains
# are run interactively, not in tight inner loops.
# ----------------------------------------------------------------------------

# ===========================================================================
# Directory discovery
# ===========================================================================

# User-supplied chains live in ${Q_USER_CHAINS_DIR} if set; otherwise default
# to ${Q_DATA_DIR}/chains. Repo-shipped chains live in ${Q_ROOT}/chains.
_q_chain_user_dir() {
    if [[ -n "${Q_USER_CHAINS_DIR:-}" ]]; then
        printf '%s' "$Q_USER_CHAINS_DIR"
    else
        printf '%s/chains' "$Q_DATA_DIR"
    fi
}

_q_chain_repo_dir() {
    printf '%s/chains' "$Q_ROOT"
}

# Resolve a chain name to a YAML path. User dir wins over repo dir.
# Echoes the path on stdout; returns 1 if the chain is not found.
_q_chain_path() {
    local name="$1"
    local user_dir repo_dir candidate

    user_dir="$(_q_chain_user_dir)"
    repo_dir="$(_q_chain_repo_dir)"

    for candidate in \
        "${user_dir}/${name}.yaml" \
        "${user_dir}/${name}.yml" \
        "${repo_dir}/${name}.yaml" \
        "${repo_dir}/${name}.yml"
    do
        if [[ -f "$candidate" ]]; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

# ===========================================================================
# yq sanity check
# ===========================================================================

_q_chain_require_yq() {
    if ! command -v yq &>/dev/null; then
        q_error "yq is required for chain support. Install with: sudo apt install yq"
        return 1
    fi
    return 0
}

# ===========================================================================
# q_chain_list — discover all chain files and print "name: description"
# ===========================================================================
q_chain_list() {
    _q_chain_require_yq || return 1

    local user_dir repo_dir
    user_dir="$(_q_chain_user_dir)"
    repo_dir="$(_q_chain_repo_dir)"

    local -A seen=()           # avoid printing duplicate names twice
    local printed_any=0
    local dir f name desc

    # User dir first (so user overrides win the dedupe race)
    for dir in "$user_dir" "$repo_dir"; do
        [[ -d "$dir" ]] || continue
        for f in "$dir"/*.yaml "$dir"/*.yml; do
            [[ -f "$f" ]] || continue
            name="$(yq -r '.name // ""' "$f" 2>/dev/null)"
            [[ -z "$name" ]] && continue
            if [[ -n "${seen[$name]:-}" ]]; then
                continue
            fi
            seen[$name]=1
            desc="$(yq -r '.description // ""' "$f" 2>/dev/null)"
            if [[ -n "$desc" ]]; then
                printf '%s: %s\n' "$name" "$desc"
            else
                printf '%s\n' "$name"
            fi
            printed_any=1
        done
    done

    if [[ "$printed_any" -eq 0 ]]; then
        q_info "No chains found."
    fi
    return 0
}

# ===========================================================================
# q_chain_show NAME — pretty-print a chain's steps
# ===========================================================================
q_chain_show() {
    local name="$1"
    if [[ -z "$name" ]]; then
        q_error "Usage: q_chain_show NAME"
        return 1
    fi

    _q_chain_require_yq || return 1

    local path
    if ! path="$(_q_chain_path "$name")"; then
        q_error "Chain not found: $name"
        return 1
    fi

    local chain_desc step_count i title cmd when coe
    chain_desc="$(yq -r '.description // ""' "$path" 2>/dev/null)"
    step_count="$(yq -r '.steps | length' "$path" 2>/dev/null)"

    printf '%s%sChain:%s %s\n' "$Q_BOLD" "$Q_CYAN" "$Q_RESET" "$name"
    [[ -n "$chain_desc" ]] && printf '  %s%s%s\n' "$Q_DIM" "$chain_desc" "$Q_RESET"
    printf '\n'

    if [[ -z "$step_count" ]] || [[ "$step_count" == "null" ]] || [[ "$step_count" -eq 0 ]]; then
        q_warn "Chain has no steps."
        return 0
    fi

    for (( i=0; i<step_count; i++ )); do
        title="$(yq -r ".steps[$i].title // \"(untitled)\"" "$path" 2>/dev/null)"
        cmd="$(_q_chain_field_str "$path" ".steps[$i].command")"
        when="$(yq -r ".steps[$i].when // \"\"" "$path" 2>/dev/null)"
        coe="$(yq -r ".steps[$i].continue_on_error // false" "$path" 2>/dev/null)"

        printf '  %s[%d]%s %s%s%s\n' "$Q_DIM" "$((i+1))" "$Q_RESET" "$Q_BOLD" "$title" "$Q_RESET"
        printf '      %s$%s %s\n' "$Q_GREEN" "$Q_RESET" "$cmd"
        [[ -n "$when" ]] && printf '      %swhen:%s %s\n' "$Q_DIM" "$Q_RESET" "$when"
        [[ "$coe" == "true" ]] && printf '      %scontinue_on_error:%s true\n' "$Q_DIM" "$Q_RESET"
    done
    return 0
}

# ===========================================================================
# _q_chain_field_str — yq extract that treats nulls as empty but preserves
# the boolean strings "true"/"false" (so a YAML `command: false` becomes the
# shell command `false`, not silently empty).
# ===========================================================================
_q_chain_field_str() {
    local path="$1" expr="$2"
    yq -r "${expr} | if . == null then \"\" else . | tostring end" \
        "$path" 2>/dev/null
}

# ===========================================================================
# _q_chain_merge_vars — copy chain vars into session, never overwriting
# ===========================================================================
# Reads .vars.* from the chain YAML and calls q_session_set for each key
# whose session value is currently empty. Existing session values win.
_q_chain_merge_vars() {
    local path="$1"
    local keys k existing

    # Get the list of var keys; bail early if none.
    keys="$(yq -r '.vars // {} | keys[]' "$path" 2>/dev/null)"
    [[ -z "$keys" ]] && return 0

    while IFS= read -r k; do
        [[ -z "$k" ]] && continue
        existing="$(q_session_get "$k" 2>/dev/null)" || existing=""
        if [[ -n "$existing" ]]; then
            continue
        fi
        local val
        # shellcheck disable=SC2016
        # $k is a jq variable injected via --arg, not a shell expansion.
        val="$(yq -r --arg k "$k" '.vars[$k] // ""' "$path" 2>/dev/null)"
        [[ -z "$val" ]] && continue
        q_session_set "$k" "$val" >/dev/null 2>&1
    done <<< "$keys"
}

# ===========================================================================
# q_chain_run NAME [--dry-run]
# ===========================================================================
q_chain_run() {
    local name="" dry_run=0
    local arg
    for arg in "$@"; do
        case "$arg" in
            --dry-run) dry_run=1 ;;
            -*)        q_error "Unknown flag: $arg"; return 2 ;;
            *)         [[ -z "$name" ]] && name="$arg" ;;
        esac
    done

    if [[ -z "$name" ]]; then
        q_error "Usage: q_chain_run NAME [--dry-run]"
        return 2
    fi

    _q_chain_require_yq || return 1

    local path
    if ! path="$(_q_chain_path "$name")"; then
        q_error "Chain not found: $name"
        return 1
    fi

    # 1. Merge chain-declared vars into the session (without overwriting).
    _q_chain_merge_vars "$path"

    local step_count
    step_count="$(yq -r '.steps | length' "$path" 2>/dev/null)"
    if [[ -z "$step_count" ]] || [[ "$step_count" == "null" ]] || [[ "$step_count" -eq 0 ]]; then
        q_warn "Chain '$name' has no steps."
        return 0
    fi

    if [[ "$dry_run" -eq 1 ]]; then
        q_info "Chain '$name' — DRY RUN (no commands will execute, no history logged)"
    else
        q_info "Chain '$name' — running ${step_count} step(s)"
    fi

    local run_count=0 skipped=0 failed=0
    local exit_code=0
    local i title cmd when coe filled rc

    for (( i=0; i<step_count; i++ )); do
        title="$(yq -r ".steps[$i].title // \"(untitled)\"" "$path" 2>/dev/null)"
        cmd="$(_q_chain_field_str "$path" ".steps[$i].command")"
        when="$(yq -r ".steps[$i].when // \"\"" "$path" 2>/dev/null)"
        coe="$(yq -r ".steps[$i].continue_on_error // false" "$path" 2>/dev/null)"

        if [[ -z "$cmd" ]]; then
            q_warn "Step $((i+1)) '$title' has no command — skipping"
            (( skipped++ )) || true
            continue
        fi

        # 2. when: gate
        if [[ -n "$when" ]]; then
            local gate_val
            gate_val="$(q_session_get "$when" 2>/dev/null)" || gate_val=""
            if [[ -z "$gate_val" ]]; then
                q_info "Step $((i+1)) '$title' skipped — gate '$when' is unset"
                (( skipped++ )) || true
                continue
            fi
        fi

        # 3. Substitute {{VAR}} placeholders
        if ! filled="$(q_fill_vars_auto "$cmd" 2>/dev/null)"; then
            q_warn "Step $((i+1)) '$title' has unresolved variables — skipping"
            (( skipped++ )) || true
            continue
        fi

        # 4. Dry run: print and move on (no exec, no history)
        if [[ "$dry_run" -eq 1 ]]; then
            printf '%s[%d]%s %s\n' "$Q_DIM" "$((i+1))" "$Q_RESET" "$title"
            printf '    %s$%s %s\n' "$Q_GREEN" "$Q_RESET" "$filled"
            (( run_count++ )) || true
            continue
        fi

        # 5. Real run
        printf '%s[%d]%s %s\n' "$Q_DIM" "$((i+1))" "$Q_RESET" "$title" >&2
        printf '    %s$%s %s\n' "$Q_GREEN" "$Q_RESET" "$filled" >&2
        q_history_log "$filled"

        # Execute. Use bash -c so the eval'd command's failures don't kill the
        # caller's shell under `set -e`. We deliberately use `eval` to honor
        # shell pipes/redirects in step commands.
        set +e
        eval "$filled"
        rc=$?
        set -e
        (( run_count++ )) || true

        if [[ "$rc" -ne 0 ]]; then
            (( failed++ )) || true
            if [[ "$coe" == "true" ]]; then
                q_warn "Step $((i+1)) failed (exit $rc) — continuing (continue_on_error: true)"
            else
                q_error "Step $((i+1)) '$title' failed (exit $rc) — halting chain"
                exit_code="$rc"
                break
            fi
        fi
    done

    # Summary
    q_info "Chain '$name' summary: ${run_count} run, ${skipped} skipped, ${failed} failed"
    return "$exit_code"
}
