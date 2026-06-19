#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/06-nvidia.sh — NVIDIA driver install + kernel/modeset config
# ---------------------------------------------------------------------------
source "$(dirname "$0")/lib.sh"

section "NVIDIA GPU Drivers"

pkgs=$(select_packages "NVIDIA Drivers" \
    "nvidia-dkms"         "NVIDIA DKMS driver"                         ON \
    "nvidia-utils"        "NVIDIA utilities"                           ON \
    "nvidia-settings"     "NVIDIA settings GUI"                        ON \
    "libva-nvidia-driver" "VA-API driver for hardware video decode"     ON \
    "linux-headers"       "Kernel headers (needed for DKMS)"           ON \
)
install_pacman_batch $pkgs

# mkinitcpio modules
if pacman -Qi nvidia-dkms &>/dev/null; then
    local mkinit="/etc/mkinitcpio.conf"
    if ! grep -q 'nvidia nvidia_modeset nvidia_uvm nvidia_drm' "$mkinit" 2>/dev/null; then
        info "Adding NVIDIA modules to mkinitcpio..."
        sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$mkinit" >> "$LOG" 2>&1
        sudo mkinitcpio -P >> "$LOG" 2>&1 \
            && ok "mkinitcpio regenerated" || warn "mkinitcpio issue"
    fi

    # nvidia-drm modeset
    if [[ ! -f /etc/modprobe.d/nvidia.conf ]] || ! grep -q 'modeset=1' /etc/modprobe.d/nvidia.conf 2>/dev/null; then
        echo "options nvidia-drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf >> "$LOG" 2>&1
        ok "NVIDIA DRM modeset enabled"
    fi

    ok "NVIDIA kernel config complete"
fi
