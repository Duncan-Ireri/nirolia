#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  install.sh — Entry point for curl-based installation
#
#  Usage:
#    bash <(curl -sL https://raw.githubusercontent.com/Duncan-Ireri/nirolia/main/install.sh)
#
#  Clones the full repo (configs + module scripts) then runs setup.sh.
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
    ╔╗╔╦╦═╗╔═╗╦  ╦╔═╗
    ║║║║╠╦╝║ ║║  ║╠═╣
    ╝╚╝╩╩╚═╚═╝╩═╝╩╩ ╩
    Niri + Noctalia Shell Installer
    for EndeavourOS / Arch Linux
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

# Verify repo structure before proceeding
if [[ ! -d "$CLONE_DIR/scripts" ]] || [[ ! -f "$CLONE_DIR/setup.sh" ]]; then
    echo -e "${RED}[FAIL]${RST}  Repo structure is incomplete."
    echo "  Expected directories: scripts/ configs/"
    echo "  Expected files: setup.sh, scripts/lib.sh"
    echo ""
    echo "  Make sure you pushed the full directory tree:"
    echo "    git add -A && git commit -m 'fix structure' && git push"
    exit 1
fi

# Make scripts executable
chmod +x "$CLONE_DIR/setup.sh"
find "$CLONE_DIR/scripts" -name '*.sh' -exec chmod +x {} \;

# Hand off to the orchestrator
exec bash "$CLONE_DIR/setup.sh"
