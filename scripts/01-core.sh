#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/01-core.sh — Niri + Noctalia Shell + Wayland essentials
#
#  Handles:
#  - Core Niri + Wayland packages
#  - quickshell vs noctalia-qs conflict resolution
#  - Noctalia Shell installation + verification
#  - Detect existing DEs/WMs and warn about conflicts
#  - Ensure Niri session file exists for display managers
#  - Mask conflicting notification/bar daemons
# ---------------------------------------------------------------------------
source "$(dirname "$0")/lib.sh"

section "Core Desktop: Niri + Noctalia Shell"

# -----------------------------------------------------------------------
# DETECT EXISTING DEs/WMs
# -----------------------------------------------------------------------
info "Checking for existing desktop environments..."

EXISTING_DE=()
declare -A DE_NAMES=(
    [plasma-desktop]="KDE Plasma"
    [gnome-shell]="GNOME"
    [hyprland]="Hyprland"
    [sway]="Sway"
    [xfce4-session]="XFCE"
    [i3-wm]="i3"
    [budgie-desktop]="Budgie"
    [cinnamon]="Cinnamon"
    [mate-session-manager]="MATE"
)

for pkg in "${!DE_NAMES[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
        EXISTING_DE+=("${DE_NAMES[$pkg]}")
        ok "Found: ${DE_NAMES[$pkg]}"
    fi
done

if [[ ${#EXISTING_DE[@]} -gt 0 ]]; then
    local de_list=""
    for de in "${EXISTING_DE[@]}"; do
        de_list+="  - $de\n"
    done

    whiptail --title "Existing DEs/WMs Detected" --msgbox \
        "The following desktop environments are installed:\n\n${de_list}\n\
Niri + Noctalia will be installed alongside them.\n\
You can switch between sessions from your display manager.\n\n\
Conflicting notification daemons (dunst, mako, swaync)\n\
will be masked for the Niri session to avoid double\n\
notifications with Noctalia." \
        18 64
else
    info "No existing DEs detected. Clean install."
fi

# -----------------------------------------------------------------------
# INSTALL CORE PACKAGES
# -----------------------------------------------------------------------
info "Installing core Niri + Wayland packages..."

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

# -----------------------------------------------------------------------
# HANDLE QUICKSHELL / NOCTALIA-QS CONFLICTS
# noctalia-shell depends on quickshell OR noctalia-qs (their fork).
# noctalia-qs conflicts with quickshell and quickshell-git.
# -----------------------------------------------------------------------
section "Noctalia Shell runtime"

NOCTALIA_QS_BIN="qs"  # default binary name

if pacman -Qi quickshell &>/dev/null; then
    info "quickshell (official) is already installed."
    info "noctalia-shell will use it. No conflict."
    NOCTALIA_QS_BIN="qs"
elif pacman -Qi quickshell-git &>/dev/null; then
    warn "quickshell-git is installed. noctalia-qs will conflict with it."
    if whiptail --title "Quickshell Conflict" --yesno \
        "quickshell-git is installed and conflicts with noctalia-qs.\n\n\
Option 1: Remove quickshell-git, install noctalia-qs (recommended)\n\
Option 2: Keep quickshell-git, skip noctalia-qs\n\n\
Remove quickshell-git and install noctalia-qs?" \
        14 64; then
        info "Removing quickshell-git..."
        sudo pacman -Rdd --noconfirm quickshell-git >> "$LOG" 2>&1 || true
    else
        info "Keeping quickshell-git. noctalia-shell will try to use it."
    fi
elif pacman -Qi noctalia-qs &>/dev/null; then
    info "noctalia-qs already installed."
    NOCTALIA_QS_BIN="noctalia-qs"
fi

# Install noctalia-shell (pulls quickshell or noctalia-qs as dependency)
info "Installing noctalia-shell from AUR (this compiles from source)..."
install_aur_batch noctalia-shell

# Determine the correct binary after install
if command -v noctalia-qs &>/dev/null; then
    NOCTALIA_QS_BIN="noctalia-qs"
    ok "Noctalia runtime: noctalia-qs"
elif command -v qs &>/dev/null; then
    NOCTALIA_QS_BIN="qs"
    ok "Noctalia runtime: qs (quickshell)"
else
    err "Neither qs nor noctalia-qs found after install."
    err "Noctalia Shell will not start. Check $LOG for build errors."
fi

# Export for use by 09-configs.sh
export NOCTALIA_QS_BIN

# -----------------------------------------------------------------------
# VERIFY NOCTALIA SHELL IS ACCESSIBLE
# -----------------------------------------------------------------------
section "Verifying Noctalia Shell"

# Check if the shell config is findable
if "$NOCTALIA_QS_BIN" -c noctalia-shell --help &>/dev/null 2>&1 || \
   [[ -d /usr/share/quickshell/noctalia-shell ]] || \
   [[ -d "$HOME/.config/quickshell/noctalia-shell" ]] || \
   [[ -d /usr/share/noctalia-shell ]]; then
    ok "Noctalia Shell config found"
else
    warn "Could not verify noctalia-shell config location."
    warn "It may still work after reboot. Check: $NOCTALIA_QS_BIN -c noctalia-shell"
fi

# -----------------------------------------------------------------------
# ENSURE NIRI SESSION FILE EXISTS FOR DISPLAY MANAGERS
# -----------------------------------------------------------------------
section "Session registration"

NIRI_SESSION="/usr/share/wayland-sessions/niri.desktop"
if [[ -f "$NIRI_SESSION" ]]; then
    ok "Niri session file exists: $NIRI_SESSION"
else
    warn "Niri session file missing. Creating it..."
    sudo tee "$NIRI_SESSION" > /dev/null << 'DESKTOP_EOF'
[Desktop Entry]
Name=Niri
Comment=Scrollable-tiling Wayland compositor with Noctalia Shell
Exec=niri-session
Type=Application
DesktopNames=niri
DESKTOP_EOF
    ok "Created Niri session file"
fi

# -----------------------------------------------------------------------
# MASK CONFLICTING NOTIFICATION DAEMONS
# These would cause double notifications alongside Noctalia's built-in.
# Only masks them — they still work when launching their own DE session.
# -----------------------------------------------------------------------
CONFLICTING_DAEMONS=(dunst mako swaync)
for daemon in "${CONFLICTING_DAEMONS[@]}"; do
    if command -v "$daemon" &>/dev/null; then
        info "Masking $daemon for Niri session (Noctalia handles notifications)..."
        systemctl --user mask "$daemon.service" >> "$LOG" 2>&1 || true
    fi
done

ok "Core desktop setup complete"
