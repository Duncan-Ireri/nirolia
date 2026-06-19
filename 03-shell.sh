#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/03-shell.sh — Zsh + Oh My Zsh + plugins + Starship prompt
# ---------------------------------------------------------------------------
source "$(dirname "$0")/lib.sh"

section "Shell: Zsh + Oh My Zsh + Starship"

# Install zsh and starship from official repos
install_pacman_batch zsh starship

# Install zsh plugins from official repos
install_pacman_batch \
    zsh-autosuggestions \
    zsh-completions \
    zsh-syntax-highlighting

# Install Oh My Zsh (non-interactive, no auto chsh)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >> "$LOG" 2>&1 \
        && ok "Oh My Zsh installed" \
        || warn "Oh My Zsh install had issues"
else
    ok "Oh My Zsh already installed"
fi

# Write .zshrc with Oh My Zsh, plugins, and starship init
ZSHRC="$HOME/.zshrc"
if [[ -f "$ZSHRC" ]]; then
    cp "$ZSHRC" "$ZSHRC.bak.$(date +%s)"
    ok "Backed up existing .zshrc"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

cp "$REPO_ROOT/configs/.zshrc" "$ZSHRC"
ok "Wrote .zshrc with Oh My Zsh + plugins + starship"

# Deploy starship config (iNiR-inspired Material Design aesthetic)
mkdir -p "$HOME/.config"
cp "$REPO_ROOT/configs/starship.toml" "$HOME/.config/starship.toml"
ok "Deployed starship.toml"

# Set zsh as default shell
if [[ "$SHELL" != *"zsh"* ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)" >> "$LOG" 2>&1 \
        && ok "Default shell set to zsh" \
        || warn "Could not change default shell. Run: chsh -s \$(which zsh)"
fi
