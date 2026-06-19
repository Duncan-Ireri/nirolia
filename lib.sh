#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/lib.sh — Shared functions for all installer modules
# ---------------------------------------------------------------------------

# -- Globals -----------------------------------------------------------------
SCRIPT_VERSION="2.0.0"
CACHE_DIR="$HOME/.cache/niri-installer"
LOG="$CACHE_DIR/install.log"
FAILED_LOG="$CACHE_DIR/failed_packages.log"
REPO_DIR="$HOME/.cache/niri-noctalia-eos"

mkdir -p "$CACHE_DIR"

# -- Colors ------------------------------------------------------------------
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
CYN='\033[0;36m'
MAG='\033[0;35m'
BLD='\033[1m'
RST='\033[0m'

# -- Logging -----------------------------------------------------------------
_log() { echo -e "$1" | tee -a "$LOG"; }
info()    { _log "${CYN}[INFO]${RST}    $*"; }
ok()      { _log "${GRN}[OK]${RST}      $*"; }
warn()    { _log "${YLW}[WARN]${RST}    $*"; }
err()     { _log "${RED}[FAIL]${RST}    $*"; }
section() { _log "\n${MAG}${BLD}:: $* ::${RST}"; }

# -- Counters ----------------------------------------------------------------
TOTAL_INSTALLED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

# -- Safe package installer --------------------------------------------------
# Installs one package at a time. If it fails, log and continue.
install_pkg() {
    local pkg="$1"
    local src="${2:-pacman}"

    # Skip if already installed
    if pacman -Qi "$pkg" &>/dev/null; then
        ok "Already installed: $pkg"
        ((TOTAL_SKIPPED++))
        return 0
    fi

    info "Installing: $pkg ($src)"

    if [[ "$src" == "aur" ]]; then
        if "$AUR" -S --needed --noconfirm "$pkg" >> "$LOG" 2>&1; then
            ok "Installed: $pkg"
            ((TOTAL_INSTALLED++))
            return 0
        fi
    else
        if sudo pacman -S --needed --noconfirm "$pkg" >> "$LOG" 2>&1; then
            ok "Installed: $pkg"
            ((TOTAL_INSTALLED++))
            return 0
        fi
    fi

    err "Failed to install: $pkg -- logged and continuing"
    echo "$pkg ($src)" >> "$FAILED_LOG"
    ((TOTAL_FAILED++))
    return 1
}

# -- Batch installer ---------------------------------------------------------
install_pacman_batch() {
    for pkg in "$@"; do
        [[ -z "$pkg" ]] && continue
        install_pkg "$pkg" "pacman"
    done
}

install_aur_batch() {
    for pkg in "$@"; do
        [[ -z "$pkg" ]] && continue
        install_pkg "$pkg" "aur"
    done
}

# -- Whiptail checklist helper -----------------------------------------------
# Returns space-separated list of selected packages (quotes stripped)
select_packages() {
    local title="$1"; shift
    local result
    result=$(whiptail --title "$title" --checklist \
        "Spacebar to toggle, Enter to confirm.\n" \
        24 74 14 \
        "$@" \
        3>&1 1>&2 2>&3) || true
    echo "$result" | tr -d '"'
}

# -- Enable systemd service safely -------------------------------------------
enable_service() {
    local svc="$1"
    local scope="${2:-system}" # "system" or "user"

    if [[ "$scope" == "user" ]]; then
        systemctl --user enable --now "$svc" >> "$LOG" 2>&1 \
            && ok "Enabled (user): $svc" \
            || warn "Issue enabling (user): $svc"
    else
        sudo systemctl enable --now "$svc" >> "$LOG" 2>&1 \
            && ok "Enabled: $svc" \
            || warn "Issue enabling: $svc"
    fi
}
