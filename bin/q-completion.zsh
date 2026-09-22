#compdef q
# zsh completion for the `q` command launcher.
#
# Completes:
#   q <TAB>              → subcommand names + tokens pulled from the index
#   q edit <TAB>         → tokens from cheatsheet titles + tool names
#   q <query> <TAB>      → same token pool (multi-word queries build up piecewise)
#   q config <TAB>       → `get`
#   q log <TAB>          → `-f follow tail clear reset cat`
#
# The token pool is column 2 (tool) + column 3 (title) of the TSV index at
# $Q_CACHE_DIR/index.tsv (or ~/.local/share/q/index.tsv), tokenised on
# whitespace and de-duplicated.
#
# The parsed pool is cached in _Q_COMPLETE_TOKENS (namespaced global,
# owned by this function) and only rebuilt when the index mtime changes.
#
# Install: drop this file into a directory on $fpath and run compinit,
# or source it after compinit has been called.

_q() {
    local idx mtime
    local -a subcmds

    # Resolve index path — honour $Q_CACHE_DIR override.
    if [[ -n "${Q_CACHE_DIR-}" ]]; then
        idx="$Q_CACHE_DIR/index.tsv"
    else
        idx="${HOME}/.local/share/q/index.tsv"
    fi

    # Rebuild the cached token pool only when the index changes.
    mtime="0"
    if [[ -r "$idx" ]]; then
        mtime=$(stat -c %Y "$idx" 2>/dev/null || stat -f %m "$idx" 2>/dev/null || echo 0)
    fi
    if [[ "$mtime" != "${_Q_COMPLETE_MTIME-}" || ${#_Q_COMPLETE_TOKENS[@]} -eq 0 ]]; then
        typeset -g _Q_COMPLETE_MTIME="$mtime"
        typeset -ga _Q_COMPLETE_TOKENS
        _Q_COMPLETE_TOKENS=()
        if [[ -r "$idx" ]]; then
            _Q_COMPLETE_TOKENS=(
                ${(f)"$(
                    awk -F'\t' 'NF>=3 { print $2; print $3 }' "$idx" 2>/dev/null \
                        | tr -s '[:space:]' '\n' \
                        | LC_ALL=C sort -u \
                        | grep -v '^$'
                )"}
            )
        fi
    fi

    subcmds=(
        'edit:open a cheatsheet in $EDITOR'
        'rebuild:rebuild the index'
        'lint:report duplicate commands'
        'config:read a config knob'
        'get:read a config knob (alias)'
        'history:show session history'
        'log:show / tail / clear the debug log'
        'tools:list indexed tools'
        'help:show usage'
    )

    if (( CURRENT == 2 )); then
        _describe -t subcommands 'subcommand' subcmds
        compadd -a _Q_COMPLETE_TOKENS
        return
    fi

    case "$words[2]" in
        config)
            if (( CURRENT == 3 )); then
                _values 'config action' 'get[read a config knob]'
            fi
            ;;
        log)
            if (( CURRENT == 3 )); then
                _values 'log action' '-f' 'follow' 'tail' 'clear' 'reset' 'cat'
            fi
            ;;
        rebuild|lint|history|tools|help)
            ;;
        *)
            compadd -a _Q_COMPLETE_TOKENS
            ;;
    esac
}

# When the file is autoloaded through $fpath, the `#compdef q` line above
# handles registration and this call is a no-op. When the file is sourced
# directly after compinit, this makes the completion take effect.
compdef _q q 2>/dev/null || true
