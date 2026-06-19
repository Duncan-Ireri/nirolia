#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/09-configs.sh — Deploy Niri config, GTK dark theme, directories
# ---------------------------------------------------------------------------
source "$(dirname "$0")/lib.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

section "Config deployment"

# -- Directories -------------------------------------------------------------
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/Pictures/Wallpapers"
mkdir -p "$HOME/.local/bin"

# -- Niri config -------------------------------------------------------------
NIRI_DIR="$HOME/.config/niri"
NIRI_CFG="$NIRI_DIR/config.kdl"
mkdir -p "$NIRI_DIR"

write_config=true
if [[ -f "$NIRI_CFG" ]]; then
    if whiptail --title "Niri Config Exists" --yesno \
        "Existing config found at:\n  $NIRI_CFG\n\nOverwrite? (current will be backed up)" \
        10 60; then
        backup="$NIRI_CFG.bak.$(date +%s)"
        cp "$NIRI_CFG" "$backup"
        ok "Backed up to $backup"
    else
        write_config=false
        if ! grep -q 'noctalia-shell' "$NIRI_CFG" 2>/dev/null; then
            # Detect the correct binary
            local qs_bin="qs"
            command -v noctalia-qs &>/dev/null && qs_bin="noctalia-qs"
            echo '' >> "$NIRI_CFG"
            echo '// -- Noctalia Shell (added by nirolia installer) --' >> "$NIRI_CFG"
            echo "spawn-at-startup \"${qs_bin}\" \"-c\" \"noctalia-shell\"" >> "$NIRI_CFG"
            ok "Noctalia spawn line appended (using $qs_bin)"
        fi
        # Ensure D-Bus activation is present
        if ! grep -q 'dbus-update-activation-environment' "$NIRI_CFG" 2>/dev/null; then
            echo 'spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP=niri"' >> "$NIRI_CFG"
            ok "D-Bus activation line appended"
        fi
    fi
fi

if [[ "$write_config" == true ]]; then
    # Detect NVIDIA and set env block
    nvidia_env=""
    if [[ "${HAS_NVIDIA:-false}" == true ]]; then
        nvidia_env='
    // NVIDIA GPU detected
    __GLX_VENDOR_LIBRARY_NAME "nvidia"
    GBM_BACKEND "nvidia-drm"
    WLR_NO_HARDWARE_CURSORS "1"'
    else
        nvidia_env='
    // Uncomment for NVIDIA:
    // __GLX_VENDOR_LIBRARY_NAME "nvidia"
    // GBM_BACKEND "nvidia-drm"
    // WLR_NO_HARDWARE_CURSORS "1"'
    fi

    # Detect the correct noctalia binary
    local qs_bin="qs"
    command -v noctalia-qs &>/dev/null && qs_bin="noctalia-qs"
    [[ -n "${NOCTALIA_QS_BIN:-}" ]] && qs_bin="$NOCTALIA_QS_BIN"
    noctalia_spawn="spawn-at-startup \"${qs_bin}\" \"-c\" \"noctalia-shell\""

    # Write config with placeholder substitution
    sed -e "s|{{NVIDIA_ENV}}|${nvidia_env}|" \
        -e "s|{{QS_BIN}}|${qs_bin}|g" \
        "$REPO_ROOT/configs/config.kdl" > "$NIRI_CFG"
    ok "Niri config deployed (noctalia via: $qs_bin)"
fi

# -- GTK dark theme -----------------------------------------------------------
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=capitaine-cursors
gtk-cursor-theme-size=24
gtk-font-name=Rubik 11
EOF
ok "GTK3 dark theme configured (Rubik 11)"

mkdir -p "$HOME/.config/gtk-4.0"
cat > "$HOME/.config/gtk-4.0/settings.ini" << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-cursor-theme-name=capitaine-cursors
gtk-cursor-theme-size=24
gtk-font-name=Rubik 11
EOF
ok "GTK4 dark theme configured (Rubik 11)"

# -- Cursor theme for Wayland --------------------------------------------------
mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" << 'EOF'
[Icon Theme]
Inherits=capitaine-cursors
EOF
ok "Cursor theme set"

# -- Environment variables for Wayland apps ------------------------------------
mkdir -p "$HOME/.config/environment.d"
cat > "$HOME/.config/environment.d/niri.conf" << 'EOF'
QT_QPA_PLATFORM=wayland
QT_STYLE_OVERRIDE=adwaita-dark
GDK_BACKEND=wayland
MOZ_ENABLE_WAYLAND=1
ELECTRON_OZONE_PLATFORM_HINT=auto
XDG_CURRENT_DESKTOP=niri
XDG_SESSION_TYPE=wayland
EOF
ok "Wayland environment variables set"
