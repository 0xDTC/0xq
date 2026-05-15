#!/usr/bin/env bash
# install.sh — Set up q: symlink, config dirs, shell widget (Ctrl+Q), alias
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
    # All packages q needs, mapped to their apt package names
    local -A deps=(
        [fzf]="fzf"
        [xclip]="xclip"
        [batcat]="bat"
    )

    local to_install=()
    local cmd

    for cmd in "${!deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            to_install+=("${deps[$cmd]}")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        success "All dependencies already installed."
        return 0
    fi

    info "Missing packages: ${BOLD}${to_install[*]}${RESET}"
    info "Installing dependencies..."

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
        sed -i "s|Q_ROOT_PATH|${escaped_dir}|g" "$rc_file"
        success "Ctrl+Q widget added to ${rc_file}"
    fi

    # --- Alias ------------------------------------------------------------
    if grep -q "alias q=" "$rc_file" 2>/dev/null; then
        info "Alias 'q' already present in ${rc_file} — skipping."
    else
        printf '\n# q command launcher alias\nalias q='\''%s'\''\n' "$Q_BIN" >> "$rc_file"
        success "Alias added to ${rc_file}"
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
        sed -i "s|Q_ROOT_PATH|${escaped_dir}|g" "$rc_file"
        success "Ctrl+Q widget added to ${rc_file}"
    fi

    # --- Alias ------------------------------------------------------------
    if grep -q "alias q=" "$rc_file" 2>/dev/null; then
        info "Alias 'q' already present in ${rc_file} — skipping."
    else
        printf '\n# q command launcher alias\nalias q='\''%s'\''\n' "$Q_BIN" >> "$rc_file"
        success "Alias added to ${rc_file}"
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
