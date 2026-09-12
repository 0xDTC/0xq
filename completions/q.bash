# q — bash completion
# Source from ~/.bashrc:  source /path/to/q/completions/q.bash
# install.sh wires this in automatically.

_q_completion() {
    local cur prev words cword
    _init_completion 2>/dev/null || {
        # Fallback for hosts without bash-completion package
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
    }

    local subs="set get session add targets history rebuild config lint t rm c ls promote chain run tmux logs sync new author edit"

    # First token after `q`
    if [[ $cword -eq 1 ]]; then
        # Complete subcommands + cheatsheet titles/tool names
        local titles=""
        local index="${Q_CACHE_DIR:-$HOME/.local/share/q/cache}/index.tsv"
        [[ ! -s "$index" ]] && index="$(_q_find_index 2>/dev/null)"
        if [[ -s "$index" ]]; then
            titles="$(cut -f2,3 "$index" | tr '\t' '\n' | sort -u | tr '\n' ' ')"
        fi
        COMPREPLY=($(compgen -W "$subs $titles --os --help --version --inline" -- "$cur"))
        return 0
    fi

    # Second+ token — dispatch by subcommand
    case "${words[1]}" in
        set|get|config)
            if [[ $cword -eq 2 ]]; then
                if [[ "${words[1]}" == "config" ]]; then
                    COMPREPLY=($(compgen -W "list get set unset path" -- "$cur"))
                else
                    _q_complete_var_names
                fi
            elif [[ "${words[1]}" == "config" ]] && [[ $cword -eq 3 ]]; then
                case "${words[2]}" in
                    get|set|unset) _q_complete_config_keys ;;
                esac
            fi
            ;;
        session)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "create use list purge replay history" -- "$cur"))
            elif [[ $cword -eq 3 ]] && [[ "${words[2]}" =~ ^(use|purge)$ ]]; then
                _q_complete_sessions
            fi
            ;;
        chain)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "list show run" -- "$cur"))
            elif [[ $cword -eq 3 ]] && [[ "${words[2]}" =~ ^(show|run)$ ]]; then
                _q_complete_chains
            fi
            ;;
        tmux)
            [[ $cword -eq 2 ]] && COMPREPLY=($(compgen -W "start attach a kill list ls send help" -- "$cur"))
            ;;
        logs)
            [[ $cword -eq 2 ]] && COMPREPLY=($(compgen -W "ls show prune" -- "$cur"))
            ;;
        sync)
            [[ $cword -eq 2 ]] && COMPREPLY=($(compgen -W "list add disable remove rm run" -- "$cur"))
            ;;
        run)
            [[ $cword -eq 2 ]] && COMPREPLY=($(compgen -W "show clean --tmux -j" -- "$cur"))
            ;;
        rm|remove)
            _q_complete_targets
            ;;
        --os)
            [[ $cword -eq 2 ]] && COMPREPLY=($(compgen -W "windows linux macos any" -- "$cur"))
            ;;
    esac

    # File-completion fallback for path-shaped queries
    if [[ ${#COMPREPLY[@]} -eq 0 ]] && [[ "$cur" == /* || "$cur" == ./* || "$cur" == ~/* ]]; then
        COMPREPLY=($(compgen -f -- "$cur"))
    fi
}

_q_find_index() {
    for d in "$HOME/.local/share/q/cache" "$(command -v q 2>/dev/null)"; do
        [[ -z "$d" ]] && continue
        [[ -L "$d" ]] && d="$(readlink -f "$d" 2>/dev/null)"
        [[ -f "$d" ]] && d="$(dirname "$d")/cache"
        [[ -f "$d/index.tsv" ]] && { printf '%s' "$d/index.tsv"; return 0; }
    done
    return 1
}

_q_complete_var_names() {
    local vars_file="${Q_DATA_DIR:-$HOME/.local/share/q}/sessions/${Q_SESSION_NAME:-default}/vars"
    local live=""
    [[ -f "$vars_file" ]] && live="$(cut -d= -f1 "$vars_file" | tr '\n' ' ')"
    local common="TARGET RHOST LHOST LPORT DOMAIN USERNAME PASSWORD NTHASH DC_IP DC_HOST HIVE PLUGIN"
    COMPREPLY=($(compgen -W "$live $common" -- "$cur"))
}

_q_complete_config_keys() {
    local keys="Q_CONFIRM_EXEC Q_FZF_OPTS Q_PREVIEW_SIZE Q_PREVIEW_POS Q_SESSION_NAME Q_SESSION_USE_TAIL Q_OS_FILTER Q_FILE_MAXDEPTH Q_FILE_MAXCOUNT Q_HOME_MAXDEPTH Q_HOME_MAXCOUNT"
    COMPREPLY=($(compgen -W "$keys" -- "$cur"))
}

_q_complete_sessions() {
    local sdir="${Q_DATA_DIR:-$HOME/.local/share/q}/sessions"
    [[ -d "$sdir" ]] || return
    local sessions
    sessions="$(find "$sdir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | tr '\n' ' ')"
    COMPREPLY=($(compgen -W "$sessions" -- "$cur"))
}

_q_complete_chains() {
    local user_dir="${Q_USER_CHAINS_DIR:-${Q_DATA_DIR:-$HOME/.local/share/q}/chains}"
    local repo_dir names=""
    repo_dir="$(dirname "$(readlink -f "$(command -v q 2>/dev/null)" 2>/dev/null)" 2>/dev/null)/chains"
    for d in "$user_dir" "$repo_dir"; do
        [[ -d "$d" ]] || continue
        names="$names $(find "$d" -maxdepth 1 -type f \( -name '*.yaml' -o -name '*.yml' \) -printf '%f\n' 2>/dev/null | sed 's/\.ya\?ml$//' | tr '\n' ' ')"
    done
    COMPREPLY=($(compgen -W "$names" -- "$cur"))
}

_q_complete_targets() {
    local tfile="${Q_DATA_DIR:-$HOME/.local/share/q}/sessions/${Q_SESSION_NAME:-default}/targets"
    [[ -f "$tfile" ]] || return
    local vals
    vals="$(cut -d: -f2- "$tfile" | tr '\n' ' ')"
    COMPREPLY=($(compgen -W "$vals" -- "$cur"))
}

complete -F _q_completion q
