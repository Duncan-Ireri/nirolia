#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/00-preflight.sh — Environment validation and AUR helper setup
# ---------------------------------------------------------------------------
source "$(dirname "$0")/lib.sh"

section "Pre-flight checks"

# Not root
if [[ $EUID -eq 0 ]]; then
    err "Do not run this script as root. It calls sudo when needed."
    exit 1
fi

# Arch-based check
if ! grep -qiE '(endeavouros|arch|cachyos)' /etc/os-release 2>/dev/null; then
    err "This script targets EndeavourOS / Arch Linux."
    exit 1
fi
ok "Detected Arch-based distro"

# base-devel
if ! pacman -Qq base-devel &>/dev/null; then
    warn "base-devel not found. Installing..."
    sudo pacman -S --needed --noconfirm base-devel >> "$LOG" 2>&1 || {
        err "Failed to install base-devel. Cannot continue."
        exit 1
    }
fi
ok "base-devel present"

# whiptail
if ! command -v whiptail &>/dev/null; then
    info "Installing whiptail (libnewt) for interactive menus..."
    sudo pacman -S --needed --noconfirm libnewt >> "$LOG" 2>&1 || {
        err "Cannot install whiptail."
        exit 1
    }
fi
ok "whiptail available"

# git
if ! command -v git &>/dev/null; then
    sudo pacman -S --needed --noconfirm git >> "$LOG" 2>&1
fi
ok "git available"

# AUR helper
AUR=""
for helper in yay paru; do
    if command -v "$helper" &>/dev/null; then
        AUR="$helper"
        break
    fi
done

if [[ -z "$AUR" ]]; then
    warn "No AUR helper found."
    local aur_choice
    aur_choice=$(whiptail --title "AUR Helper" --radiolist \
        "Select one to install:\n(spacebar to select)" \
        12 50 2 \
        "yay"  "Yet Another Yogurt (recommended)" ON \
        "paru" "Feature-rich AUR helper in Rust"   OFF \
        3>&1 1>&2 2>&3) || { err "Cancelled."; exit 1; }

    info "Installing $aur_choice..."
    if [[ "$aur_choice" == "yay" ]]; then
        git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin >> "$LOG" 2>&1
        (cd /tmp/yay-bin && makepkg -si --noconfirm) >> "$LOG" 2>&1
        rm -rf /tmp/yay-bin
    else
        git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin >> "$LOG" 2>&1
        (cd /tmp/paru-bin && makepkg -si --noconfirm) >> "$LOG" 2>&1
        rm -rf /tmp/paru-bin
    fi
    AUR="$aur_choice"
fi
ok "AUR helper: $AUR"

# NVIDIA detection
HAS_NVIDIA=false
if lspci 2>/dev/null | grep -iqE 'nvidia'; then
    HAS_NVIDIA=true
    ok "NVIDIA GPU detected"
else
    info "No NVIDIA GPU detected"
fi

# Export for downstream scripts
export AUR HAS_NVIDIA
