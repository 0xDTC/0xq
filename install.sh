#!/usr/bin/env bash
# q installer — builds the Go binary and installs it as ~/.local/bin/q,
# then wires the Ctrl+Q shell widget for bash/zsh.
#
# Requires: go >= 1.22 (only for the build; not needed at runtime).

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'
CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
info()    { printf '%s[*]%s %s\n' "$CYAN"   "$RESET" "$*"; }
warn()    { printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*"; }
error()   { printf '%s[-]%s %s\n' "$RED"    "$RESET" "$*"; }
success() { printf '%s[+]%s %s\n' "$GREEN"  "$RESET" "$*"; }

printf '\n%s  q installer%s  %s— single Go binary + Ctrl+Q widget%s\n\n' "$BOLD" "$RESET" "$DIM" "$RESET"

# ─── 1. build ───────────────────────────────────────────────────────────
if ! command -v go >/dev/null 2>&1; then
    error "go not found on PATH (needed to build the binary)"
    error "install via: sudo apt install golang-go   (or your distro's Go)"
    exit 1
fi
info "building q..."
(cd "$SCRIPT_DIR" && go build -trimpath -ldflags '-s -w' -o q ./cmd/q)
strip "$SCRIPT_DIR/q" 2>/dev/null || true
success "built $(du -h "$SCRIPT_DIR/q" | cut -f1) binary at $SCRIPT_DIR/q"

# ─── 2. install ─────────────────────────────────────────────────────────
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
# If ~/.local/bin/q already exists (symlink to the old bash script,
# or a previous Go install), back it up once.
if [[ -e "$BIN_DIR/q" && ! -e "$BIN_DIR/q.pre-go" ]]; then
    mv "$BIN_DIR/q" "$BIN_DIR/q.pre-go"
    info "backed up existing q → $BIN_DIR/q.pre-go"
fi
cp -f "$SCRIPT_DIR/q" "$BIN_DIR/q"
chmod +x "$BIN_DIR/q"
success "installed → $BIN_DIR/q"

# ─── 3. Ctrl+Q widget ───────────────────────────────────────────────────
# The widget captures stdout, so the picker/executor must speak on
# /dev/tty. This binary already does — no wrapper needed.

install_widget() {
    local rc="$1" shell="$2"
    touch "$rc"
    if grep -q 'q-widget' "$rc" 2>/dev/null; then
        info "$shell widget already present in $rc — skipping"
        return
    fi
    case "$shell" in
        zsh)
            cat >> "$rc" <<'ZWIDGET'

# q — Fast command launcher (Ctrl+Q)
# The =(...) process substitution keeps zsh's globbing from choking
# on ANSI bytes if the picker misbehaves; setopt localoptions turns
# NOMATCH off inside the widget so a stray `?` doesn't blow up.
q-widget() {
    setopt localoptions no_nomatch no_glob_subst
    local result
    result="$(command q --inline 2>/dev/null)"
    # Strip any leaked control bytes (defence in depth — bubbletea
    # should NOT be writing to stdout, but if a bug leaks some, we
    # want the widget to fail cleanly rather than paste garbage).
    result="${result//$'\x1b'[*[!m]*[a-zA-Z]/}"
    result="${result//$'\r'/}"
    if [[ -n "$result" ]]; then
        BUFFER="$result"
        CURSOR=$#BUFFER
    fi
    zle reset-prompt
}
zle -N q-widget
bindkey '^Q' q-widget

# XON/XOFF eats Ctrl+Q by default — free it so the widget fires.
[ -t 0 ] && stty -ixon 2>/dev/null
ZWIDGET
            success "zsh widget added to $rc"
            ;;
        bash)
            cat >> "$rc" <<'BWIDGET'

# q — Fast command launcher (Ctrl+Q)
q-widget() {
    local result
    result="$(command q --inline 2>/dev/null)"
    # Strip leaked control bytes (belt + suspenders — bubbletea
    # should stay off stdout, but if it leaks we want to fail
    # cleanly rather than paste garbage).
    result="${result//$'\r'/}"
    if [[ -n "$result" ]]; then
        READLINE_LINE="$result"
        READLINE_POINT=${#result}
    fi
}
bind -x '"\C-q": q-widget'

# XON/XOFF eats Ctrl+Q by default — free it so the widget fires.
[ -t 0 ] && stty -ixon 2>/dev/null
BWIDGET
            success "bash widget added to $rc"
            ;;
    esac
}

CURRENT_SHELL="$(basename "${SHELL:-/bin/bash}")"
case "$CURRENT_SHELL" in
    zsh)   install_widget "$HOME/.zshrc"  zsh  ;;
    bash)  install_widget "$HOME/.bashrc" bash ;;
    *)
        warn "unrecognised shell '$CURRENT_SHELL' — installing both widgets"
        [[ -f "$HOME/.zshrc"  ]] && install_widget "$HOME/.zshrc"  zsh
        [[ -f "$HOME/.bashrc" ]] && install_widget "$HOME/.bashrc" bash
        ;;
esac

# ─── 4. PATH sanity ─────────────────────────────────────────────────────
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    warn "$BIN_DIR is not on your PATH."
    warn "add this to your shell rc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ─── 5. finish ──────────────────────────────────────────────────────────
echo
success "$BOLD q installed! $RESET"
echo
echo "  Next: open a new terminal (or ${CYAN}source ~/.${CURRENT_SHELL}rc${RESET}), then:"
echo "     ${CYAN}q${RESET}         interactive picker"
echo "     ${CYAN}q nmap${RESET}    picker pre-filtered to 'nmap'"
echo "     ${CYAN}Ctrl+Q${RESET}    invoke from any shell prompt"
echo
if [[ -f "$BIN_DIR/q.pre-go" ]]; then
    echo "  Old binary preserved at ${DIM}$BIN_DIR/q.pre-go${RESET}"
    echo "  Rollback:  ${CYAN}mv $BIN_DIR/q.pre-go $BIN_DIR/q${RESET}"
fi
echo
