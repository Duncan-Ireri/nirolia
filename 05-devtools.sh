#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  scripts/05-devtools.sh — Languages, databases, containers, CLI tools
# ---------------------------------------------------------------------------
source "$(dirname "$0")/lib.sh"

# -----------------------------------------------------------------------
# LANGUAGES & RUNTIMES
# -----------------------------------------------------------------------
section "Dev: Languages & Runtimes"

lang_pkgs=$(select_packages "Languages & Runtimes" \
    "python"            "Python 3 interpreter"           ON \
    "python-pip"        "Python package installer"       ON \
    "python-virtualenv" "Python virtual environments"    ON \
    "go"                "Go programming language"        ON \
    "rustup"            "Rust toolchain manager"         ON \
    "nodejs"            "Node.js runtime"                ON \
    "npm"               "Node.js package manager"        ON \
    "jdk-openjdk"       "Java Development Kit (OpenJDK)" OFF \
    "ruby"              "Ruby interpreter"               OFF \
    "lua"               "Lua scripting language"          OFF \
    "zig"               "Zig systems language"            OFF \
)
install_pacman_batch $lang_pkgs

lang_aur=$(select_packages "Languages (AUR)" \
    "fnm"   "Fast Node Manager (Rust-based)" OFF \
)
install_aur_batch $lang_aur

# Rust stable toolchain
if command -v rustup &>/dev/null; then
    if ! rustup toolchain list 2>/dev/null | grep -q stable; then
        info "Installing Rust stable toolchain..."
        rustup default stable >> "$LOG" 2>&1 && ok "Rust stable ready" || warn "Rustup issue"
    fi
fi

# -----------------------------------------------------------------------
# DATABASES
# -----------------------------------------------------------------------
section "Dev: Databases"

db_pkgs=$(select_packages "Databases" \
    "postgresql"  "PostgreSQL server + client"   ON \
    "redis"       "Redis in-memory data store"   ON \
    "sqlite"      "SQLite embedded database"     ON \
    "mariadb"     "MariaDB (MySQL fork)"         OFF \
)
install_pacman_batch $db_pkgs

db_aur=$(select_packages "Database Tools (AUR)" \
    "dbeaver"  "Universal database GUI client"    OFF \
    "pgcli"    "PostgreSQL CLI with autocomplete" OFF \
)
install_aur_batch $db_aur

# PostgreSQL init + enable
if pacman -Qi postgresql &>/dev/null; then
    if [[ ! -d /var/lib/postgres/data ]] || [[ -z "$(ls -A /var/lib/postgres/data 2>/dev/null)" ]]; then
        info "Initializing PostgreSQL database cluster..."
        sudo -iu postgres initdb -D /var/lib/postgres/data >> "$LOG" 2>&1 \
            && ok "PostgreSQL initialized" || warn "PostgreSQL init issue"
    fi
    enable_service postgresql.service
fi

# Redis enable
if pacman -Qi redis &>/dev/null; then
    enable_service redis.service
fi

# -----------------------------------------------------------------------
# CONTAINERS & ORCHESTRATION
# -----------------------------------------------------------------------
section "Dev: Containers"

ctr_pkgs=$(select_packages "Containers" \
    "docker"          "Docker container runtime"   ON \
    "docker-compose"  "Docker Compose"             ON \
    "docker-buildx"   "Docker Buildx plugin"       ON \
    "podman"          "Rootless container engine"   OFF \
    "kubectl"         "Kubernetes CLI"              OFF \
    "helm"            "Kubernetes package manager"  OFF \
    "k9s"             "Kubernetes TUI dashboard"    OFF \
    "lazydocker"      "Docker TUI manager"          ON \
)
install_pacman_batch $ctr_pkgs

ctr_aur=$(select_packages "Container Tools (AUR)" \
    "minikube" "Local Kubernetes cluster" OFF \
)
install_aur_batch $ctr_aur

# Docker group + enable
if pacman -Qi docker &>/dev/null; then
    enable_service docker.service
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER" >> "$LOG" 2>&1
        ok "Added $USER to docker group (re-login required)"
    fi
fi

# -----------------------------------------------------------------------
# CLI DEV TOOLS
# -----------------------------------------------------------------------
section "Dev: CLI Tools"

cli_pkgs=$(select_packages "CLI Dev Tools" \
    "git"         "Version control"               ON \
    "git-lfs"     "Git Large File Storage"        ON \
    "github-cli"  "GitHub CLI (gh)"               ON \
    "ripgrep"     "Fast recursive grep (rg)"      ON \
    "fd"          "Fast find alternative"          ON \
    "fzf"         "Fuzzy finder"                   ON \
    "bat"         "Cat with syntax highlighting"   ON \
    "eza"         "Modern ls replacement"          ON \
    "zoxide"      "Smarter cd command"             ON \
    "jq"          "JSON processor"                 ON \
    "yq"          "YAML/JSON/XML processor"        ON \
    "curl"        "URL transfer tool"              ON \
    "wget"        "Network downloader"             ON \
    "httpie"      "User-friendly HTTP client"      ON \
    "tree"        "Directory tree listing"          ON \
    "htop"        "Interactive process viewer"      ON \
    "tldr"        "Simplified man pages"            ON \
    "make"        "GNU Make"                        ON \
    "cmake"       "Cross-platform build system"    OFF \
    "openssh"     "SSH client and server"           ON \
    "tmux"        "Terminal multiplexer"            ON \
    "unzip"       "ZIP extraction"                  ON \
    "p7zip"       "7-Zip file archiver"             ON \
    "tokei"       "Code line counter"               OFF \
    "hyperfine"   "Benchmarking tool"               OFF \
    "strace"      "System call tracer"              OFF \
)
install_pacman_batch $cli_pkgs

cli_aur=$(select_packages "CLI Dev Tools (AUR)" \
    "lazygit"    "Git TUI client"                ON \
    "dust"       "Disk usage analyzer (du+rust)"  OFF \
    "procs"      "Modern ps replacement"          OFF \
)
install_aur_batch $cli_aur
