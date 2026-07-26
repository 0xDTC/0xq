#!/usr/bin/env bash
# runner.sh — Parallel multi-target command runner
# Sourced by the main `q` script; not meant to be executed directly.
#
# Provides:
#   q_run_parallel CMD [-j N]   Run CMD against every target in parallel.
#   q_run_show TARGET           Cat the most recent output for a target.
#   q_run_clean [--force]       Wipe runs/parallel/ (prompts unless --force).
#
# Concurrency choice: we use `xargs -P N` instead of GNU parallel. Rationale:
#   1. `xargs` is in coreutils — zero install footprint, no citation banner.
#   2. We already have the fully-substituted command per target, so the
#      "fan out one command per line" job is trivial — we don't need
#      parallel's job-spec sugar.
#   3. xargs's -P / -I primitives give us identical concurrency control with
#      a smaller blast radius (no perl, no rcfile, no env import surprises).
# GNU `parallel` would work too; we just pick the simpler dep.

# ===========================================================================
# Internal: figure out the per-target value substitution for the placeholders
# the spec lists ({{TARGET}}, {{IP}}, {{URL}}, {{HOST}}, {{RHOST}}, {{DOMAIN}}).
# Returns the filled template on stdout, or exits 1 if the template references
# a type-specific placeholder this target doesn't match.
# Usage: _q_runner_fill_target TTYPE VALUE CMD_TEMPLATE
# ===========================================================================
_q_runner_fill_target() {
    local ttype="$1" value="$2" cmd="$3"

    # If the template contains a type-specific placeholder this target can't
    # satisfy, skip the target by returning 1.
    if [[ "$cmd" == *"{{IP}}"* ]] && [[ "$ttype" != "ip" ]]; then
        return 1
    fi
    if [[ "$cmd" == *"{{URL}}"* ]] && [[ "$ttype" != "url" ]]; then
        return 1
    fi
    if [[ "$cmd" == *"{{DOMAIN}}"* ]] && [[ "$ttype" != "domain" ]]; then
        return 1
    fi
    # HOST/RHOST: ip, domain, url all qualify
    if [[ "$cmd" == *"{{HOST}}"* || "$cmd" == *"{{RHOST}}"* ]]; then
        case "$ttype" in
            ip|domain|url) ;;
            *) return 1 ;;
        esac
    fi

    # Apply substitutions. {{TARGET}} always matches the value.
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
# _q_runner_safe_name — turn a target value into a safe filename component
# ===========================================================================
_q_runner_safe_name() {
    local v="$1"
    # Replace anything that's not alnum, dot, dash, underscore with '_'
    printf '%s' "${v//[^a-zA-Z0-9._-]/_}"
}

# ===========================================================================
# q_run_parallel CMD [-j N]
# ===========================================================================
q_run_parallel() {
    # --- Argument parsing ----------------------------------------------------
    local jobs=""
    local cmd=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j)
                jobs="$2"
                shift 2
                ;;
            -j*)
                jobs="${1#-j}"
                shift
                ;;
            *)
                if [[ -z "$cmd" ]]; then
                    cmd="$1"
                else
                    cmd="$cmd $1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$cmd" ]]; then
        q_error "q_run_parallel: missing command template"
        return 1
    fi

    if [[ -z "$jobs" ]]; then
        jobs="$(nproc 2>/dev/null || echo 4)"
    fi
    if ! [[ "$jobs" =~ ^[0-9]+$ ]] || [[ "$jobs" -lt 1 ]]; then
        q_error "q_run_parallel: -j requires a positive integer (got: $jobs)"
        return 1
    fi

    # --- Load targets --------------------------------------------------------
    local sdir
    sdir="$(q_session_dir)"
    local targets_file="${sdir}/targets"
    if [[ ! -f "$targets_file" ]] || [[ ! -s "$targets_file" ]]; then
        q_warn "No targets in session '${Q_SESSION_NAME}'."
        return 0
    fi

    # --- Prepare runs dir ----------------------------------------------------
    local runs_dir="${sdir}/runs/parallel"
    mkdir -p "$runs_dir"

    # --- Build a job queue ---------------------------------------------------
    # Each line in the queue file is: <safe_target><TAB><filled_cmd>
    local queue
    queue="$(mktemp)"

    local ts
    printf -v ts '%(%Y%m%d-%H%M%S)T' -1

    local line ttype tvalue filled safe_name
    local total=0 queued=0 skipped=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        total=$((total + 1))
        ttype="${line%%:*}"
        tvalue="${line#*:}"

        # Pass 1: type-aware target substitution
        if ! filled="$(_q_runner_fill_target "$ttype" "$tvalue" "$cmd")"; then
            q_warn "Skipping target (type mismatch): ${ttype}:${tvalue}"
            skipped=$((skipped + 1))
            continue
        fi

        # Pass 2: session-var fill for any remaining {{VAR}} placeholders
        if [[ "$filled" == *"{{"* ]]; then
            local resolved
            if resolved="$(q_fill_vars_auto "$filled" 2>/dev/null)"; then
                filled="$resolved"
            else
                q_warn "Skipping target (unresolved variable): ${tvalue}"
                skipped=$((skipped + 1))
                continue
            fi
        fi

        safe_name="$(_q_runner_safe_name "$tvalue")"
        # TAB-separated so we can split robustly in the worker
        printf '%s\t%s\n' "$safe_name" "$filled" >> "$queue"
        queued=$((queued + 1))
    done < "$targets_file"

    if [[ "$queued" -eq 0 ]]; then
        q_warn "Nothing to run. Total: ${total}, skipped: ${skipped}"
        printf '[%d] succeeded  [%d] failed  [%d] skipped\n' 0 0 "$skipped"
        rm -f "$queue"
        return 0
    fi

    q_info "Running ${queued} task(s) with -j ${jobs}..."

    # --- Run with xargs -P ---------------------------------------------------
    # We need to pass: safe_name, ts, runs_dir, and the filled command to a
    # worker. Each queue line is SAFE<TAB>CMD; pass it as "$1" (data, never
    # interpolated into the worker-script text) so quotes/$()/backticks in a
    # target value can't break or inject into the worker.
    local results_file
    results_file="$(mktemp)"

    # Worker script: read SAFE\tCMD on $1, write output, log result.
    # We pass runs_dir, ts, results_file via env so the subshell can see them.
    export _Q_RUNS_DIR="$runs_dir" _Q_TS="$ts" _Q_RESULTS="$results_file"

    # shellcheck disable=SC2016
    xargs -d '\n' -P "$jobs" -n 1 bash -c '
        line="$1"
        safe="${line%%	*}"
        cmd="${line#*	}"
        out="${_Q_RUNS_DIR}/${safe}-${_Q_TS}.out"
        bash -c "$cmd" >"$out" 2>&1
        rc=$?
        printf "%s\t%d\n" "$safe" "$rc" >> "$_Q_RESULTS"
    ' _ < "$queue"

    # --- Tabulate results ----------------------------------------------------
    local succeeded=0 failed=0
    local -a fail_lines=()
    if [[ -f "$results_file" ]]; then
        local rname rcode
        while IFS=$'\t' read -r rname rcode; do
            if [[ "$rcode" -eq 0 ]]; then
                succeeded=$((succeeded + 1))
            else
                failed=$((failed + 1))
                fail_lines+=("${rname} (exit ${rcode})")
            fi
        done < "$results_file"
    fi

    # --- Print failures + summary --------------------------------------------
    if [[ "$failed" -gt 0 ]]; then
        q_warn "Failures:"
        local fl
        for fl in "${fail_lines[@]}"; do
            printf '  %s\n' "$fl" >&2
        done
    fi

    printf '[%d] succeeded  [%d] failed  [%d] skipped\n' \
        "$succeeded" "$failed" "$skipped"

    # --- Cleanup -------------------------------------------------------------
    rm -f "$queue" "$results_file"
    unset _Q_RUNS_DIR _Q_TS _Q_RESULTS

    # Log to history — use the user-facing `q run` shape so the entry is
    # replayable (the internal function name isn't a real command).
    q_history_log "q run -j ${jobs} ${cmd}" "-" "-"

    return 0
}

# ===========================================================================
# q_run_show TARGET
# Cat the most recent parallel-run output file for the given target value.
# ===========================================================================
q_run_show() {
    local target="$1"
    if [[ -z "$target" ]]; then
        q_error "q_run_show: target required"
        return 1
    fi

    local runs_dir
    runs_dir="$(q_session_dir)/runs/parallel"
    if [[ ! -d "$runs_dir" ]]; then
        q_warn "No parallel runs recorded for session '${Q_SESSION_NAME}'."
        return 1
    fi

    local safe_name
    safe_name="$(_q_runner_safe_name "$target")"

    # Find the most recent file with this safe_name prefix.
    local newest
    newest="$(q_ls_newest "$runs_dir" 1 "${safe_name}-*.out" | head -1)"

    if [[ -z "$newest" ]] || [[ ! -f "$newest" ]]; then
        q_warn "No output found for target: ${target}"
        return 1
    fi

    cat "$newest"
}

# ===========================================================================
# q_run_clean [--force]
# Wipe sessions/<name>/runs/parallel/. Prompts unless --force is given.
# ===========================================================================
q_run_clean() {
    local force=false
    if [[ "${1:-}" == "--force" ]]; then
        force=true
    fi

    local runs_dir
    runs_dir="$(q_session_dir)/runs/parallel"

    if [[ ! -d "$runs_dir" ]]; then
        q_info "Nothing to clean: ${runs_dir} doesn't exist."
        return 0
    fi

    if [[ "$force" != true ]]; then
        printf 'Wipe %s? [y/N] ' "$runs_dir" >&2
        local reply
        IFS= read -r reply || reply=""
        case "$reply" in
            y|Y|yes|YES) ;;
            *) q_info "Aborted."; return 0 ;;
        esac
    fi

    rm -rf "$runs_dir"
    mkdir -p "$runs_dir"
    q_success "Wiped parallel runs dir."
}
