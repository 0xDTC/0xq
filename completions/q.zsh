#compdef q
# q — zsh completion
# Source from ~/.zshrc:  source /path/to/q/completions/q.zsh
# install.sh wires this in automatically.

_q() {
    local -a subs
    subs=(
        'set:set a session variable'
        'get:get a session variable'
        'session:manage sessions'
        'add:add a target'
        'targets:list session targets'
        'history:show command history'
        'rebuild:rebuild the cheatsheet index'
        'config:list/get/set config knobs'
        'lint:report cross-file duplicate commands'
        't:add target(s) quickly'
        'rm:remove a target'
        'c:clear session targets'
        'ls:list vars and targets'
        'promote:promote discoveries to targets'
        'chain:manage YAML chains'
        'run:parallel run against session targets'
        'tmux:tmux integration'
        'logs:per-target output logs'
        'sync:sync external cheatsheet repos'
        'new:add a new cheatsheet command'
        'edit:edit or delete a cheatsheet command'
        '--os:filter results by target OS'
        '--help:show help'
        '--version:show version'
        '--inline:print filled command (widget mode)'
    )

    _arguments -C \
        '1: :->first' \
        '*:: :->rest'

    case $state in
        first)
            local -a titles
            local index="${Q_CACHE_DIR:-$HOME/.local/share/q/cache}/index.tsv"
            [[ ! -s "$index" ]] && index="$(_q_find_index 2>/dev/null)"
            if [[ -s "$index" ]]; then
                titles=(${(f)"$(cut -f2,3 "$index" | tr '\t' '\n' | sort -u)"})
                _describe -t titles 'cheatsheet' titles
            fi
            _describe -t commands 'q command' subs
            ;;
        rest)
            case ${words[1]} in
                set|get)
                    _q_var_names
                    ;;
                config)
                    _q_config_dispatch
                    ;;
                session)
                    _q_session_dispatch
                    ;;
                chain)
                    _q_chain_dispatch
                    ;;
                tmux)
                    _values 'tmux' start attach a kill list ls send help
                    ;;
                logs)
                    _values 'logs' ls show prune
                    ;;
                sync)
                    _values 'sync' list add disable remove rm run
                    ;;
                run)
                    _values 'run' show clean --tmux -j
                    ;;
                rm|remove)
                    _q_targets
                    ;;
                --os)
                    _values 'os' windows linux macos any
                    ;;
            esac
            ;;
    esac
}

_q_find_index() {
    local d
    for d in "$HOME/.local/share/q/cache" "$(command -v q 2>/dev/null)"; do
        [[ -z "$d" ]] && continue
        [[ -L "$d" ]] && d="$(readlink -f "$d" 2>/dev/null)"
        [[ -f "$d" ]] && d="$(dirname "$d")/cache"
        [[ -f "$d/index.tsv" ]] && { print -r "$d/index.tsv"; return 0; }
    done
    return 1
}

_q_var_names() {
    local vars_file="${Q_DATA_DIR:-$HOME/.local/share/q}/sessions/${Q_SESSION_NAME:-default}/vars"
    local -a live=()
    [[ -f "$vars_file" ]] && live=(${(f)"$(cut -d= -f1 "$vars_file")"})
    local -a common=(TARGET RHOST LHOST LPORT DOMAIN USERNAME PASSWORD NTHASH DC_IP DC_HOST HIVE PLUGIN)
    _describe -t vars 'variable' live
    _describe -t common 'common var' common
}

_q_config_dispatch() {
    if (( CURRENT == 2 )); then
        _values 'config subcommand' list get set unset path
    elif (( CURRENT == 3 )); then
        case ${words[2]} in
            get|set|unset)
                local -a keys=(Q_CONFIRM_EXEC Q_FZF_OPTS Q_PREVIEW_SIZE Q_PREVIEW_POS Q_SESSION_NAME Q_SESSION_USE_TAIL Q_OS_FILTER Q_FILE_MAXDEPTH Q_FILE_MAXCOUNT Q_HOME_MAXDEPTH Q_HOME_MAXCOUNT)
                _describe -t config-keys 'config key' keys
                ;;
        esac
    fi
}

_q_session_dispatch() {
    if (( CURRENT == 2 )); then
        _values 'session subcommand' create use list purge replay history
    elif (( CURRENT == 3 )); then
        case ${words[2]} in
            use|purge)
                local sdir="${Q_DATA_DIR:-$HOME/.local/share/q}/sessions"
                [[ -d "$sdir" ]] || return
                local -a sessions=(${(f)"$(find "$sdir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null)"})
                _describe -t sessions 'session' sessions
                ;;
        esac
    fi
}

_q_chain_dispatch() {
    if (( CURRENT == 2 )); then
        _values 'chain subcommand' list show run
    elif (( CURRENT == 3 )); then
        case ${words[2]} in
            show|run)
                local user_dir="${Q_USER_CHAINS_DIR:-${Q_DATA_DIR:-$HOME/.local/share/q}/chains}"
                local repo_dir="$(dirname "$(readlink -f "$(command -v q 2>/dev/null)" 2>/dev/null)" 2>/dev/null)/chains"
                local -a names=()
                for d in "$user_dir" "$repo_dir"; do
                    [[ -d "$d" ]] || continue
                    names+=(${(f)"$(find "$d" -maxdepth 1 -type f \( -name '*.yaml' -o -name '*.yml' \) -printf '%f\n' 2>/dev/null | sed 's/\.ya\?ml$//')"})
                done
                _describe -t chains 'chain' names
                ;;
        esac
    fi
}

_q_targets() {
    local tfile="${Q_DATA_DIR:-$HOME/.local/share/q}/sessions/${Q_SESSION_NAME:-default}/targets"
    [[ -f "$tfile" ]] || return
    local -a vals=(${(f)"$(cut -d: -f2- "$tfile")"})
    _describe -t targets 'target' vals
}

_q "$@"
