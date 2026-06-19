#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/02-audio.sh — PipeWire audio stack
# ---------------------------------------------------------------------------
source "$(dirname "$0")/lib.sh"

section "Audio: PipeWire stack"

pkgs=$(select_packages "Audio Stack" \
    "pipewire"          "PipeWire audio server"             ON \
    "pipewire-alsa"     "ALSA compatibility"                ON \
    "pipewire-pulse"    "PulseAudio compatibility"          ON \
    "pipewire-jack"     "JACK compatibility"                ON \
    "wireplumber"       "Session manager for PipeWire"      ON \
    "pavucontrol"       "Volume control GUI"                ON \
    "pamixer"           "CLI mixer for PipeWire"            ON \
    "playerctl"         "MPRIS media player controller"     ON \
)

install_pacman_batch $pkgs

# Enable user services
if pacman -Qi pipewire &>/dev/null; then
    enable_service pipewire.service user
    enable_service pipewire-pulse.service user
    enable_service wireplumber.service user
fi
