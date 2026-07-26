#!/usr/bin/env bash
# install.sh — Set up q: symlink, config dirs, shell widget (Ctrl+Q), alias

# Re-exec under bash >= 4 if launched with an older bash (macOS ships 3.2, which
# lacks the associative arrays this installer and q itself use).
if [ -z "${_Q_BASH_REEXEC:-}" ] && [ "${BASH_VERSINFO:-0}" -lt 4 ]; then
    for _qb in /opt/homebrew/bin/bash /usr/local/bin/bash /usr/bin/bash bash; do
        command -v "$_qb" >/dev/null 2>&1 || continue
        _qv="$("$_qb" -c 'echo ${BASH_VERSINFO:-0}' 2>/dev/null || echo 0)"
        if [ "${_qv:-0}" -ge 4 ]; then _Q_BASH_REEXEC=1 exec "$_qb" "$0" "$@"; fi
    done
    printf 'q installer: needs bash >= 4 (macOS ships 3.2). Install with: brew install bash\n' >&2
    exit 1
fi

set -euo pipefail

# ===========================================================================
# Resolve paths
# ===========================================================================
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
Q_BIN="${SCRIPT_DIR}/q"

# Colors for output
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

info()    { printf '%s[*]%s %s\n' "$CYAN"   "$RESET" "$*"; }
warn()    { printf '%s[!]%s %s\n' "$YELLOW"  "$RESET" "$*"; }
error()   { printf '%s[-]%s %s\n' "$RED"     "$RESET" "$*"; }
success() { printf '%s[+]%s %s\n' "$GREEN"   "$RESET" "$*"; }

OS="$(uname)"
# Portable in-place sed: GNU sed has --version, BSD/macOS sed does not and needs
# an explicit (empty) backup suffix argument.
sed_inplace() {
    if sed --version >/dev/null 2>&1; then sed -i "$@"; else sed -i '' "$@"; fi
}

# ===========================================================================
# Preflight: check that the q script exists and is executable
# ===========================================================================
if [[ ! -x "$Q_BIN" ]]; then
    error "Cannot find executable q script at: ${Q_BIN}"
    error "Run this installer from the q project directory."
    exit 1
fi

echo ""
echo "${BOLD}  q installer${RESET}  ${DIM}— fast command launcher for pentesters${RESET}"
echo ""

# ===========================================================================
# 1. Create symlink in ~/.local/bin
# ===========================================================================
BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"
ln -sf "$Q_BIN" "${BIN_DIR}/q"
success "Symlinked ${BIN_DIR}/q -> ${Q_BIN}"

# ===========================================================================
# 2. Create config directory
# ===========================================================================
CONFIG_DIR="${HOME}/.config/q"
mkdir -p "$CONFIG_DIR"
success "Config directory ready: ${CONFIG_DIR}"

# ===========================================================================
# 3. Create data directories (via the tool itself)
# ===========================================================================
export Q_ROOT="$SCRIPT_DIR"
# shellcheck source=lib/core.sh
source "${Q_ROOT}/lib/core.sh"
q_ensure_dirs
success "Data directories ready: ${Q_DATA_DIR}"

# ===========================================================================
# 4. Auto-install dependencies
# ===========================================================================
install_deps() {
    # Command name -> package name, per platform. Clipboard: macOS uses the
    # built-in pbcopy/pbpaste, so xclip is Linux-only. `batcat` is the Debian
    # binary name for bat; on macOS/brew it installs as `bat`.
    local want_cmds=(fzf batcat xclip)
    local -A brew_pkg=( [fzf]="fzf" [batcat]="bat" [xclip]="" )
    local -A apt_pkg=(  [fzf]="fzf" [batcat]="bat" [xclip]="xclip" )

    local to_install=()
    local cmd
    for cmd in "${want_cmds[@]}"; do
        # macOS: `bat` satisfies `batcat`, and pbcopy replaces xclip.
        [[ "$cmd" == batcat ]] && command -v bat &>/dev/null && continue
        [[ "$cmd" == xclip && "$OS" == Darwin ]] && continue
        command -v "$cmd" &>/dev/null && continue
        if [[ "$OS" == Darwin ]]; then
            [[ -n "${brew_pkg[$cmd]}" ]] && to_install+=("${brew_pkg[$cmd]}")
        else
            to_install+=("${apt_pkg[$cmd]}")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        success "All dependencies already installed."
        return 0
    fi

    info "Missing packages: ${BOLD}${to_install[*]}${RESET}"
    info "Installing dependencies..."

    # ---- macOS: Homebrew ----
    if [[ "$OS" == Darwin ]]; then
        if command -v brew &>/dev/null; then
            if brew install "${to_install[@]}"; then
                success "Installed: ${to_install[*]}"
            else
                error "Auto-install failed. Install manually:  brew install ${to_install[*]}"
            fi
        else
            warn "Homebrew not found (https://brew.sh). Then run:  brew install ${to_install[*]}"
        fi
        return 0
    fi

    # ---- Linux: apt ----
    # Skip apt-get update if it was run within the last hour
    _apt_update_if_stale() {
        local stamp="/var/lib/apt/lists/partial"
        local -i age_limit=3600
        if [[ -d "$stamp" ]]; then
            local -i now mtime
            printf -v now '%(%s)T' -1
            mtime="$(stat -c '%Y' "$stamp" 2>/dev/null)" || mtime=0
            if (( now - mtime < age_limit )); then
                return 0
            fi
        fi
        "$@" apt-get update -qq 2>/dev/null
    }

    # Try to install — use sudo if available
    if command -v sudo &>/dev/null; then
        if _apt_update_if_stale sudo && \
           sudo apt-get install -y -qq "${to_install[@]}" 2>/dev/null; then
            success "Installed: ${to_install[*]}"
        else
            error "Auto-install failed. Install manually:"
            error "  sudo apt install ${to_install[*]}"
            # Don't exit — tool can partially work without optional deps
        fi
    elif [[ "$(id -u)" -eq 0 ]]; then
        # Already root
        if _apt_update_if_stale && \
           apt-get install -y -qq "${to_install[@]}" 2>/dev/null; then
            success "Installed: ${to_install[*]}"
        else
            error "Auto-install failed. Install manually:"
            error "  apt install ${to_install[*]}"
        fi
    else
        warn "Cannot auto-install without sudo. Install manually:"
        warn "  sudo apt install ${to_install[*]}"
    fi
}

install_deps

# ===========================================================================
# 5. Detect shell and configure Ctrl+Q widget + alias
# ===========================================================================
CURRENT_SHELL="$(basename "${SHELL:-/bin/bash}")"

setup_zsh() {
    local rc_file="${HOME}/.zshrc"

    # Ensure the rc file exists
    touch "$rc_file"

    # --- Ctrl+Q widget ---------------------------------------------------
    if grep -q 'q-widget' "$rc_file" 2>/dev/null; then
        info "Ctrl+Q widget already present in ${rc_file} — skipping."
    else
        cat >> "$rc_file" << 'WIDGET_EOF'

# q - Quick command launcher (Ctrl+Q)
q-widget() {
    local result
    result="$(Q_ROOT_PATH/q --inline 2>/dev/null)"
    if [[ -n "$result" ]]; then
        BUFFER="$result"
        CURSOR=$#BUFFER
    fi
    zle reset-prompt
}
zle -N q-widget
bindkey '^Q' q-widget
WIDGET_EOF
        # Replace placeholder with actual path
        local escaped_dir
        escaped_dir="$(printf '%s' "${SCRIPT_DIR}" | sed 's/[|\\&]/\\&/g')"
        sed_inplace "s|Q_ROOT_PATH|${escaped_dir}|g" "$rc_file"
        success "Ctrl+Q widget added to ${rc_file}"
    fi

    # --- Alias ------------------------------------------------------------
    if grep -q "alias q=" "$rc_file" 2>/dev/null; then
        info "Alias 'q' already present in ${rc_file} — skipping."
    else
        printf '\n# q command launcher alias\nalias q='\''%s'\''\n' "$Q_BIN" >> "$rc_file"
        success "Alias added to ${rc_file}"
    fi

    # --- Word-delete keybindings (Alt+Backspace; Ctrl+W always works too) -
    if grep -q 'q: word-delete keys' "$rc_file" 2>/dev/null; then
        info "zsh word-delete bindings already present in ${rc_file} — skipping."
    else
        cat >> "$rc_file" << 'KEYS_EOF'

# q: word-delete keys — make Alt+Backspace delete the previous word
bindkey '^[^?' backward-kill-word
bindkey '^[^H' backward-kill-word
KEYS_EOF
        success "zsh word-delete bindings added to ${rc_file}"
    fi
}

setup_bash() {
    local rc_file="${HOME}/.bashrc"

    # Ensure the rc file exists
    touch "$rc_file"

    # --- Ctrl+Q widget ---------------------------------------------------
    if grep -q 'q-widget' "$rc_file" 2>/dev/null; then
        info "Ctrl+Q widget already present in ${rc_file} — skipping."
    else
        cat >> "$rc_file" << 'WIDGET_EOF'

# q - Quick command launcher (Ctrl+Q)
q-widget() {
    local result
    result="$(Q_ROOT_PATH/q --inline 2>/dev/null)"
    if [[ -n "$result" ]]; then
        READLINE_LINE="$result"
        READLINE_POINT=${#result}
    fi
}
bind -x '"\C-q": q-widget'
WIDGET_EOF
        # Replace placeholder with actual path
        local escaped_dir
        escaped_dir="$(printf '%s' "${SCRIPT_DIR}" | sed 's/[|\\&]/\\&/g')"
        sed_inplace "s|Q_ROOT_PATH|${escaped_dir}|g" "$rc_file"
        success "Ctrl+Q widget added to ${rc_file}"
    fi

    # --- Alias ------------------------------------------------------------
    if grep -q "alias q=" "$rc_file" 2>/dev/null; then
        info "Alias 'q' already present in ${rc_file} — skipping."
    else
        printf '\n# q command launcher alias\nalias q='\''%s'\''\n' "$Q_BIN" >> "$rc_file"
        success "Alias added to ${rc_file}"
    fi

    # --- Word-delete keybindings (Alt+Backspace; Ctrl+W always works too) -
    if grep -q 'q: word-delete keys' "$rc_file" 2>/dev/null; then
        info "bash word-delete binding already present in ${rc_file} — skipping."
    else
        cat >> "$rc_file" << 'KEYS_EOF'

# q: word-delete keys — make Alt+Backspace delete the previous word
bind '"\e\C-?": backward-kill-word' 2>/dev/null
bind '"\e\C-h": backward-kill-word' 2>/dev/null
KEYS_EOF
        success "bash word-delete binding added to ${rc_file}"
    fi
}

setup_tmux() {
    local conf="${HOME}/.tmux.conf"
    touch "$conf"

    # Bootstrap TPM + session-persistence plugins so save/restore works out of the box
    local plugins_dir="${HOME}/.tmux/plugins"
    if command -v git >/dev/null 2>&1; then
        local repo
        for repo in tpm tmux-resurrect tmux-continuum; do
            if [[ ! -d "${plugins_dir}/${repo}" ]]; then
                if git clone --depth 1 "https://github.com/tmux-plugins/${repo}" \
                        "${plugins_dir}/${repo}" >/dev/null 2>&1; then
                    success "Installed tmux plugin: ${repo}"
                else
                    warn "Could not clone ${repo} (session save/restore needs it)."
                fi
            fi
        done
    else
        warn "git not found — install TPM + tmux-resurrect/continuum manually for session save/restore."
    fi

    # Remove any previous q block first so re-running the installer UPDATES it
    # (rather than skipping) and keeps the config in sync with new releases.
    if grep -q '# >>> q toolkit tmux config' "$conf" 2>/dev/null; then
        sed_inplace '/# >>> q toolkit tmux config/,/# <<< q toolkit tmux config/d' "$conf"
        info "Refreshing q tmux config in ${conf}."
    fi
    cat >> "$conf" <<'TMUXEOF'

# >>> q toolkit tmux config (added by q installer) >>>
# Prefix: Ctrl+A instead of Ctrl+B (press C-a twice to send a literal C-a)
set -g prefix C-a
unbind C-b
bind C-a send-prefix
# Mouse on — scroll panes freely with the wheel, like a normal terminal
set -g mouse on
set -g history-limit 50000
# Session persistence — autosave every 1 min, save on detach, restore on start.
# Lightweight: layout/commands only (no scrollback capture); prune to newest ~15 saves.
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @resurrect-capture-pane-contents 'off'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '1'
set -g @resurrect-hook-post-save-all 'd="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"; l="$(readlink "$d/last" 2>/dev/null)"; ls -1 "$d"/tmux_resurrect_*.txt 2>/dev/null | sort -r | tail -n +16 | grep -vxF "$d/$l" | xargs -I{} rm -f -- {}'
set-hook -g client-detached 'run-shell "~/.tmux/plugins/tmux-resurrect/scripts/save.sh"'
# Mouse selection -> system clipboard (keeps wheel scroll). Drag to select one
# line or many and release to copy; double-click copies a word, triple-click a
# line. Or hold Shift while dragging to use the terminal's own native selection
# (bypasses tmux). Uses pbcopy on macOS, xclip on Linux.
set -g set-clipboard on
set -s copy-command 'Q_CLIP_CMD'
bind -T copy-mode    MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel
bind -n DoubleClick1Pane select-pane \; copy-mode -M \; send-keys -X select-word \; send-keys -X copy-pipe-and-cancel
bind -n TripleClick1Pane select-pane \; copy-mode -M \; send-keys -X select-line \; send-keys -X copy-pipe-and-cancel
# Ctrl+Q — open q in a popup in ANY pane (ssh / evil-winrm / ftp / container)
# and paste the chosen command into the current session (review, then press Enter).
bind -n C-q display-popup -E -w 95% -h 90% "Q_NO_POPUP=1 'Q_BIN_PATH' --inline > /tmp/.q_anywhere 2>/dev/null" \; if-shell '[ -s /tmp/.q_anywhere ]' 'load-buffer /tmp/.q_anywhere ; paste-buffer -d'
# Initialize TPM — must come after all @plugin lines above
run '~/.tmux/plugins/tpm/tpm'
# <<< q toolkit tmux config <<<
TMUXEOF
    local escaped
    escaped="$(printf '%s' "${Q_BIN}" | sed 's/[|\\&]/\\&/g')"
    sed_inplace "s|Q_BIN_PATH|${escaped}|g" "$conf"
    # Clipboard command for tmux copy: pbcopy on macOS, xclip on Linux.
    local clip_cmd="xclip -in -selection clipboard"
    command -v pbcopy >/dev/null 2>&1 && clip_cmd="pbcopy"
    sed_inplace "s|Q_CLIP_CMD|${clip_cmd}|g" "$conf"
    success "q tmux config written to ${conf} (prefix C-a, scroll, mouse-copy, Ctrl+Q)"
    # Apply to a running tmux server immediately, if one exists.
    if command -v tmux >/dev/null 2>&1 && tmux list-sessions &>/dev/null; then
        tmux source-file "$conf" 2>/dev/null && info "Reloaded tmux config on the running server."
    fi
}

case "$CURRENT_SHELL" in
    zsh)
        setup_zsh
        ;;
    bash)
        setup_bash
        ;;
    *)
        # Try both if we can't determine the shell
        warn "Unrecognized shell '${CURRENT_SHELL}'. Attempting zsh and bash setup."
        [[ -f "${HOME}/.zshrc" ]]  && setup_zsh
        [[ -f "${HOME}/.bashrc" ]] && setup_bash
        ;;
esac

setup_tmux

# ===========================================================================
# 6. Verify ~/.local/bin is in PATH
# ===========================================================================
if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
    warn "${BIN_DIR} is not in your PATH."
    warn "Add this to your shell rc file:"
    echo "    export PATH=\"\${HOME}/.local/bin:\${PATH}\""
    echo ""
fi

# ===========================================================================
# Done
# ===========================================================================
echo ""
success "${BOLD}q is installed!${RESET}"
echo ""
echo "  ${BOLD}Next steps:${RESET}"
echo "    1. Reload your shell:  ${CYAN}source ~/.${CURRENT_SHELL}rc${RESET}  or open a new terminal"
echo "    2. Try it out:"
echo "       ${CYAN}q${RESET}                    Interactive search"
echo "       ${CYAN}q nmap${RESET}               Search for nmap commands"
echo "       ${CYAN}q set RHOST 10.10.10.1${RESET}"
echo "       ${CYAN}Ctrl+Q${RESET}               Launch inline from anywhere"
echo ""
echo "  ${BOLD}Configuration:${RESET}"
echo "    ${DIM}${CONFIG_DIR}/config.sh${RESET}"
echo ""
