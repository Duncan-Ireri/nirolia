#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/04-terminal.sh — Terminal emulators + kitty config
# ---------------------------------------------------------------------------
source "$(dirname "$0")/lib.sh"

section "Terminal Emulators"

pkgs=$(select_packages "Terminals (official repos)" \
    "kitty"       "GPU-accelerated terminal (primary)"  ON \
    "foot"        "Lightweight Wayland terminal"         OFF \
    "alacritty"   "GPU-accelerated, minimal config"      OFF \
)
install_pacman_batch $pkgs

aur_pkgs=$(select_packages "Terminals (AUR)" \
    "ghostty-bin" "Zig-based GPU terminal (Mitchell Hashimoto)" OFF \
)
install_aur_batch $aur_pkgs

# Deploy kitty config with JetBrains Mono
if pacman -Qi kitty &>/dev/null; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(dirname "$SCRIPT_DIR")"

    mkdir -p "$HOME/.config/kitty"
    cp "$REPO_ROOT/configs/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    ok "Deployed kitty.conf (JetBrains Mono Nerd Font, dark theme)"
fi
