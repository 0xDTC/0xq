# bash completion for the `q` command launcher.
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
# whitespace and de-duplicated. Both columns may contain spaces (e.g.
# "Active Directory Attacks"), so we split into tokens rather than trying
# to feed multi-word entries through bash's word-oriented completion.
#
# The parsed pool is cached in _Q_COMPLETE_TOKENS (namespaced global,
# owned by this function) and only rebuilt when the index mtime changes.
#
# Install: source this file from ~/.bashrc.

_q_complete() {
    local cur
    cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=()

    # Resolve index path — honour $Q_CACHE_DIR override.
    local idx
    if [[ -n "${Q_CACHE_DIR:-}" ]]; then
        idx="$Q_CACHE_DIR/index.tsv"
    else
        idx="${HOME}/.local/share/q/index.tsv"
    fi

    # Rebuild the cached token pool only when the index changes.
    local mtime="0"
    if [[ -r "$idx" ]]; then
        mtime=$(stat -c %Y "$idx" 2>/dev/null || stat -f %m "$idx" 2>/dev/null || echo 0)
    fi
    if [[ "$mtime" != "${_Q_COMPLETE_MTIME:-}" || ${#_Q_COMPLETE_TOKENS[@]} -eq 0 ]]; then
        _Q_COMPLETE_MTIME="$mtime"
        _Q_COMPLETE_TOKENS=()
        if [[ -r "$idx" ]]; then
            # Pull cols 2+3, split into tokens, dedupe, drop empties.
            while IFS= read -r tok; do
                _Q_COMPLETE_TOKENS+=("$tok")
            done < <(
                awk -F'\t' 'NF>=3 { print $2; print $3 }' "$idx" 2>/dev/null \
                    | tr -s '[:space:]' '\n' \
                    | LC_ALL=C sort -u \
                    | grep -v '^$'
            )
        fi
    fi

    local subcmds="edit rebuild lint config get history log tools help"

    # Position 1: first arg after `q`.
    if (( COMP_CWORD == 1 )); then
        COMPREPLY=( $(compgen -W "${_Q_COMPLETE_TOKENS[*]} ${subcmds}" -- "$cur") )
        return 0
    fi

    # Positions 2+ depend on the first word.
    case "${COMP_WORDS[1]}" in
        config)
            if (( COMP_CWORD == 2 )); then
                COMPREPLY=( $(compgen -W "get" -- "$cur") )
            fi
            ;;
        log)
            if (( COMP_CWORD == 2 )); then
                COMPREPLY=( $(compgen -W "-f follow tail clear reset cat" -- "$cur") )
            fi
            ;;
        rebuild|lint|history|tools|help)
            # No further arguments.
            ;;
        *)
            # `edit <query>` or a freeform picker query — keep offering tokens.
            COMPREPLY=( $(compgen -W "${_Q_COMPLETE_TOKENS[*]}" -- "$cur") )
            ;;
    esac
}

complete -F _q_complete q
