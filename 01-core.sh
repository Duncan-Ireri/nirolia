#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/01-core.sh — Niri + Noctalia Shell + Wayland essentials
# ---------------------------------------------------------------------------
source "$(dirname "$0")/lib.sh"

section "Core Desktop: Niri + Noctalia Shell"

info "These are required packages. All will be installed."

# Official repos
install_pacman_batch \
    niri \
    xwayland-satellite \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    polkit-kde-agent \
    wl-clipboard \
    cliphist \
    grim \
    slurp \
    brightnessctl \
    qt6-svg \
    qt6-declarative

# AUR: Noctalia Shell (pulls noctalia-qs)
install_aur_batch noctalia-shell
