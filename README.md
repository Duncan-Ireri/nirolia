# niri-noctalia-eos

Interactive, modular installer for Niri + Noctalia Shell on EndeavourOS / Arch Linux. Sets up a complete desktop environment and development workstation.

## Quick Install

```bash
bash <(curl -sL https://raw.githubusercontent.com/USER/niri-noctalia-eos/main/install.sh)
```

## Project Structure

```
install.sh              # Entry point (curl target, clones repo, runs setup)
setup.sh                # Orchestrator (category selection, runs modules)

scripts/
  lib.sh                # Shared: colors, logging, safe installer, whiptail helpers
  00-preflight.sh       # Distro check, AUR helper, NVIDIA detection
  01-core.sh            # Niri + Noctalia Shell + Wayland essentials
  02-audio.sh           # PipeWire full stack
  03-shell.sh           # Zsh + Oh My Zsh + plugins + Starship prompt
  04-terminal.sh        # Kitty (primary) + optional alternatives
  05-devtools.sh        # Languages, databases, containers, CLI tools
  06-nvidia.sh          # NVIDIA drivers + mkinitcpio + modeset
  07-theming.sh         # Fonts (Rubik + JetBrains Mono), GTK/Qt, cursors
  08-apps.sh            # Browsers, editors (inc. Zed), file managers, extras
  09-configs.sh         # Niri config, GTK dark theme, env vars, cursor

configs/
  .zshrc                # Oh My Zsh + autosuggestions + syntax highlighting + starship
  starship.toml         # iNiR-inspired Material Design prompt
  kitty.conf            # JetBrains Mono, Catppuccin dark, Wayland-native
  fonts.conf            # fontconfig: Rubik (system) + JetBrains Mono (mono)
  config.kdl            # Niri config template (NVIDIA env auto-detected)
```

## Design Decisions

**Modular scripts** -- Each concern is in its own file. Easy to maintain, test, or run individually. Want to re-run just the shell setup? `source scripts/lib.sh && source scripts/03-shell.sh`

**Safe failovers** -- Every package installs individually. If one fails (wrong name, build error, network issue), it's logged to `~/.cache/niri-installer/failed_packages.log` and the installer continues.

**Interactive selection** -- Top-level category checklist, then per-package sub-menus via whiptail. You see and control everything before it runs.

**Zed via official script** -- Zed installs using `curl -f https://zed.dev/install.sh | sh` (their recommended method for Linux) rather than an AUR package, for faster updates.

## Font Defaults

| Context | Font | Set via |
|---|---|---|
| System / UI / sans-serif | Rubik | fontconfig + GTK settings |
| Terminal / monospace | JetBrains Mono Nerd Font | fontconfig + kitty.conf |
| Starship icons | JetBrains Mono Nerd Font | Nerd Font glyphs |

## Shell Setup

Zsh is the default shell with:
- **Oh My Zsh** as the framework
- **zsh-autosuggestions** for inline history suggestions
- **zsh-syntax-highlighting** for real-time command coloring
- **zsh-completions** for extended completion definitions
- **Starship** as the prompt (replaces Oh My Zsh themes)

The starship config uses iNiR-inspired rounded powerline segments with Catppuccin Mocha colors and dev-focused modules (git, Go, Python, Rust, Node, Docker).

## After Install

1. Log out
2. Select **Niri** from your display manager
3. Log in -- Noctalia Shell starts automatically

## License

MIT
