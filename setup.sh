#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  setup.sh — Main orchestrator for nirolia installer
#  Runs module scripts in sequence based on user-selected categories.
# ---------------------------------------------------------------------------

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared library
source "$SCRIPT_DIR/scripts/lib.sh"

# Initialize logs
: > "$LOG"
: > "$FAILED_LOG"

# -- Banner ------------------------------------------------------------------
echo -e "${CYN}"
cat << 'EOF'
    ╔╗╔╦╦═╗╔═╗╦  ╦╔═╗
    ║║║║╠╦╝║ ║║  ║╠═╣
    ╝╚╝╩╩╚═╚═╝╩═╝╩╩ ╩
    Niri + Noctalia Shell Installer  v2.0.0
    for EndeavourOS / Arch Linux
EOF
echo -e "${RST}"

# -- Preflight ---------------------------------------------------------------
source "$SCRIPT_DIR/scripts/00-preflight.sh"

# -- System update -----------------------------------------------------------
section "System update"
info "Updating package databases and system..."
sudo pacman -Syu --noconfirm >> "$LOG" 2>&1 || warn "System update had warnings"

# -- Category selection ------------------------------------------------------
section "Select installation categories"

nvidia_default="OFF"
[[ "${HAS_NVIDIA:-false}" == true ]] && nvidia_default="ON"

CATEGORIES=$(whiptail --title "Nirolia Installer" --checklist \
    "Select what to install. Spacebar to toggle, Enter to confirm.\n\n\
Core Desktop is required. Everything else is optional.\n\
Each category will open a sub-menu for individual packages." \
    26 74 14 \
    "CORE"     "Niri + Noctalia Shell + essentials (required)" ON \
    "AUDIO"    "PipeWire audio stack"                          ON \
    "SHELL"    "Zsh + Oh My Zsh + Starship prompt"             ON \
    "TERMINAL" "Terminal emulators (kitty default)"             ON \
    "DEVTOOLS" "Languages, databases, containers, CLI tools"   ON \
    "APPS"     "Browsers, editors, file managers, extras"       ON \
    "NVIDIA"   "NVIDIA GPU drivers + kernel config"            "$nvidia_default" \
    "THEME"    "Fonts, GTK/Qt theming, cursors, icons"         ON \
    "CONFIGS"  "Deploy Niri config, GTK theme, env vars"       ON \
    3>&1 1>&2 2>&3)

if [[ $? -ne 0 ]] || [[ -z "$CATEGORIES" ]]; then
    err "No categories selected. Exiting."
    exit 1
fi

# Enforce CORE
if [[ ! "$CATEGORIES" =~ "CORE" ]]; then
    warn "Core Desktop is required. Adding it back."
    CATEGORIES="\"CORE\" $CATEGORIES"
fi

# Export for module scripts
export AUR HAS_NVIDIA CATEGORIES

# -- Run selected modules ----------------------------------------------------

[[ "$CATEGORIES" =~ "CORE" ]]     && source "$SCRIPT_DIR/scripts/01-core.sh"
[[ "$CATEGORIES" =~ "AUDIO" ]]    && source "$SCRIPT_DIR/scripts/02-audio.sh"
[[ "$CATEGORIES" =~ "SHELL" ]]    && source "$SCRIPT_DIR/scripts/03-shell.sh"
[[ "$CATEGORIES" =~ "TERMINAL" ]] && source "$SCRIPT_DIR/scripts/04-terminal.sh"
[[ "$CATEGORIES" =~ "DEVTOOLS" ]] && source "$SCRIPT_DIR/scripts/05-devtools.sh"
[[ "$CATEGORIES" =~ "NVIDIA" ]]   && source "$SCRIPT_DIR/scripts/06-nvidia.sh"
[[ "$CATEGORIES" =~ "THEME" ]]    && source "$SCRIPT_DIR/scripts/07-theming.sh"
[[ "$CATEGORIES" =~ "APPS" ]]     && source "$SCRIPT_DIR/scripts/08-apps.sh"
[[ "$CATEGORIES" =~ "CONFIGS" ]]  && source "$SCRIPT_DIR/scripts/09-configs.sh"

# -- Final report ------------------------------------------------------------
section "Installation complete"

echo ""
echo -e "${GRN}${BLD}========================================${RST}"
echo -e "${GRN}${BLD}  Nirolia -- Install Complete           ${RST}"
echo -e "${GRN}${BLD}========================================${RST}"
echo ""
echo -e "  Packages installed:  ${GRN}$TOTAL_INSTALLED${RST}"
echo -e "  Packages skipped:    ${CYN}$TOTAL_SKIPPED${RST}"
echo -e "  Packages failed:     ${RED}$TOTAL_FAILED${RST}"
echo -e "  Full log:            $LOG"
echo ""

if [[ $TOTAL_FAILED -gt 0 ]]; then
    warn "Failed packages:"
    echo -e "${YLW}"
    cat "$FAILED_LOG"
    echo -e "${RST}"
    echo "  Retry manually:"
    echo "    sudo pacman -S <package>"
    echo "    $AUR -S <package>"
    echo ""
fi

echo "Next steps:"
echo "  1. Log out of your current session"
echo "  2. Select 'Niri' from your display manager"
echo "  3. Log in -- Noctalia Shell starts automatically"
echo ""
echo "Config locations:"
echo "  Niri:      ~/.config/niri/config.kdl"
echo "  Noctalia:  ~/.config/noctalia/settings.json"
echo "  Kitty:     ~/.config/kitty/kitty.conf"
echo "  Starship:  ~/.config/starship.toml"
echo "  Zsh:       ~/.zshrc"
echo "  Fonts:     ~/.config/fontconfig/fonts.conf"
echo ""

if whiptail --title "Reboot?" --yesno \
    "A reboot is recommended for drivers and services.\n\nReboot now?" \
    10 50; then
    info "Rebooting..."
    sudo reboot
else
    info "Remember to reboot before using Niri."
fi
