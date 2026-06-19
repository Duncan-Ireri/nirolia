#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/07-theming.sh — Fonts, GTK/Qt theming, cursors, icons
#
#  Sets Rubik as default system/sans-serif font.
#  Sets JetBrains Mono Nerd Font as default monospace/terminal font.
# ---------------------------------------------------------------------------
source "$(dirname "$0")/lib.sh"

section "Theming: Fonts"

font_pkgs=$(select_packages "Fonts" \
    "ttf-jetbrains-mono-nerd"  "JetBrains Mono Nerd Font (terminal)"   ON \
    "noto-fonts"               "Google Noto fonts"                      ON \
    "noto-fonts-emoji"         "Noto emoji font"                        ON \
    "noto-fonts-cjk"           "CJK (Chinese, Japanese, Korean)"        OFF \
    "inter-font"               "Inter UI font"                          ON \
    "ttf-roboto"               "Roboto font family"                     OFF \
    "otf-font-awesome"         "Font Awesome icons"                     ON \
    "ttf-firacode-nerd"        "Fira Code Nerd Font"                    OFF \
    "ttf-cascadia-code-nerd"   "Cascadia Code Nerd Font"                OFF \
)
install_pacman_batch $font_pkgs

# Rubik is not in official repos -- install from AUR
info "Installing Rubik font (system default)..."
install_aur_batch ttf-rubik

section "Theming: GTK, Qt, Cursors, Icons"

theme_pkgs=$(select_packages "Theming" \
    "adw-gtk-theme"      "Adwaita-style GTK theme"          ON \
    "capitaine-cursors"  "Capitaine cursor theme"            ON \
    "papirus-icon-theme" "Papirus icon theme"                ON \
    "gnome-themes-extra" "Adwaita GTK2 compatibility"       ON \
    "qt6ct"              "Qt6 configuration tool"            ON \
    "nwg-look"           "GTK settings editor for Wayland"  ON \
)
install_pacman_batch $theme_pkgs

# Deploy fontconfig — Rubik as system font, JetBrains Mono as monospace
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

mkdir -p "$HOME/.config/fontconfig"
cp "$REPO_ROOT/configs/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
ok "Deployed fontconfig: Rubik (system) + JetBrains Mono (mono)"

# Rebuild font cache
info "Rebuilding font cache..."
fc-cache -fv >> "$LOG" 2>&1 && ok "Font cache rebuilt" || warn "Font cache issue"
