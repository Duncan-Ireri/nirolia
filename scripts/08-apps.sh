#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/08-apps.sh — Browsers, editors, file managers, extras
#  Includes Zed install via official zed.dev script.
# ---------------------------------------------------------------------------
source "$(dirname "$0")/lib.sh"

# -----------------------------------------------------------------------
# FILE MANAGERS
# -----------------------------------------------------------------------
section "File Managers"

fm_pkgs=$(select_packages "File Managers" \
    "nautilus"              "GNOME Files"                     ON \
    "yazi"                  "Terminal file manager (Rust)"    ON \
    "thunar"                "Xfce file manager"              OFF \
    "thunar-archive-plugin" "Archive support for Thunar"     OFF \
    "nemo"                  "Cinnamon file manager"          OFF \
)
install_pacman_batch $fm_pkgs

# -----------------------------------------------------------------------
# BROWSERS
# -----------------------------------------------------------------------
section "Browsers"

br_pkgs=$(select_packages "Web Browsers" \
    "firefox"   "Mozilla Firefox"         ON \
    "chromium"  "Chromium (open source)"  OFF \
)
install_pacman_batch $br_pkgs

br_aur=$(select_packages "Browsers (AUR)" \
    "zen-browser-bin" "Zen Browser (Firefox-based, privacy)" OFF \
)
install_aur_batch $br_aur

# -----------------------------------------------------------------------
# CODE EDITORS
# -----------------------------------------------------------------------
section "Code Editors"

ed_pkgs=$(select_packages "Editors (official repos)" \
    "neovim"  "Terminal-based editor"  ON \
    "vim"     "Classic Vi IMproved"    OFF \
)
install_pacman_batch $ed_pkgs

ed_aur=$(select_packages "Editors (AUR)" \
    "visual-studio-code-bin" "VS Code (Microsoft binary)" ON \
)
install_aur_batch $ed_aur

# Zed — install via official script from zed.dev
if whiptail --title "Zed Editor" --yesno \
    "Install Zed editor using the official install script?\n\n\
This runs: curl -f https://zed.dev/install.sh | sh\n\
Zed will be installed to ~/.local/bin/zed" \
    12 60; then
    info "Installing Zed via official script..."
    curl -f https://zed.dev/install.sh 2>/dev/null | sh >> "$LOG" 2>&1 \
        && ok "Zed installed" \
        || warn "Zed install had issues -- check ~/.local/bin/zed"
fi

# -----------------------------------------------------------------------
# EXTRAS
# -----------------------------------------------------------------------
section "Extras"

extra_pkgs=$(select_packages "Extras" \
    "btop"                   "System monitor TUI"             ON \
    "fastfetch"              "System info fetch tool"         ON \
    "wlsunset"               "Night light / blue light"      ON \
    "network-manager-applet" "NetworkManager tray applet"     ON \
    "gvfs"                   "Virtual filesystem (trash,MTP)" ON \
    "file-roller"            "Archive manager"                ON \
    "imagemagick"            "Image manipulation CLI"         ON \
    "power-profiles-daemon"  "Power profile switching"        ON \
    "ddcutil"                "External monitor brightness"    OFF \
)
install_pacman_batch $extra_pkgs

extra_aur=$(select_packages "Extras (AUR)" \
    "cava" "Audio visualizer" OFF \
)
install_aur_batch $extra_aur

# Bluetooth (optional)
if whiptail --title "Bluetooth" --yesno "Install Bluetooth support (bluez + blueman)?" 8 50; then
    install_pacman_batch bluez bluez-utils blueman
    enable_service bluetooth.service
fi

# Power profiles
if pacman -Qi power-profiles-daemon &>/dev/null; then
    enable_service power-profiles-daemon.service
fi
