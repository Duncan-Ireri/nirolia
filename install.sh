#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  install.sh — Entry point for curl-based installation
#
#  Usage:
#    bash <(curl -sL https://raw.githubusercontent.com/USER/niri-noctalia-eos/main/install.sh)
#
#  This script clones the full repo (needed for configs and module scripts)
#  then hands off to setup.sh which orchestrates everything.
# ---------------------------------------------------------------------------

set -euo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
CYN='\033[0;36m'
RST='\033[0m'

REPO_URL="https://github.com/Duncan-Ireri/nirolia.git"
CLONE_DIR="$HOME/.cache/nirolia"

echo -e "${CYN}"
cat << 'EOF'
    ╔═╗╦╦═╗╦  ╔╗╔╔═╗╔═╗╔╦╗╔═╗╦  ╦╔═╗
    ║╠╝║╠╦╝║  ║║║║ ║║   ║ ╠═╣║  ║╠═╣
    ╝╚╝╩╩╚═╩═╝╝╚╝╚═╝╚═╝ ╩ ╩ ╩╩═╝╩╩ ╩
EOF
echo -e "${RST}"

# Ensure git is available
if ! command -v git &>/dev/null; then
    echo -e "${CYN}[INFO]${RST}  Installing git..."
    sudo pacman -S --needed --noconfirm git
fi

# Clone or update the repo
if [[ -d "$CLONE_DIR/.git" ]]; then
    echo -e "${CYN}[INFO]${RST}  Updating existing clone..."
    cd "$CLONE_DIR"
    git pull --ff-only 2>/dev/null || {
        echo -e "${RED}[WARN]${RST}  Pull failed. Re-cloning..."
        rm -rf "$CLONE_DIR"
        git clone --depth=1 "$REPO_URL" "$CLONE_DIR"
        cd "$CLONE_DIR"
    }
else
    echo -e "${CYN}[INFO]${RST}  Cloning installer repo..."
    rm -rf "$CLONE_DIR"
    git clone --depth=1 "$REPO_URL" "$CLONE_DIR"
    cd "$CLONE_DIR"
fi

# Make scripts executable
chmod +x setup.sh scripts/*.sh

# Hand off to the orchestrator
exec bash setup.sh
