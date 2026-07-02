#!/usr/bin/env bash
# Bootstrap a fresh Arch install with these dotfiles.
#
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/Manlibear/dotfiles/main/install.sh)"
#
# Safe to re-run: every step here is idempotent (pacman --needed, stow
# symlinks, systemctl enable, etc. all no-op if already done).

set -euo pipefail

REPO_URL="git@github.com:Manlibear/dotfiles.git"
REPO_HTTPS_URL="https://github.com/Manlibear/dotfiles.git"
DEST="$HOME/Projects/dotfiles"

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

# --- 1. Make sure the repo is cloned locally, then re-exec from there ------
if [ ! -d "$DEST/.git" ]; then
    log "Cloning dotfiles into $DEST"
    mkdir -p "$(dirname "$DEST")"
    if ! git clone "$REPO_URL" "$DEST" 2>/dev/null; then
        git clone "$REPO_HTTPS_URL" "$DEST"
    fi
fi

# If we were invoked via curl|sh (not as this file), hand off to the real
# script now that it exists on disk, so relative paths below all work.
if [ "$(cd "$(dirname "$0")" 2>/dev/null && pwd)" != "$DEST" ]; then
    exec "$DEST/install.sh" "$@"
fi

cd "$DEST"

# --- 2. Official repo packages ----------------------------------------------
log "Installing pacman packages"
sudo pacman -S --needed - <packages.txt

# --- 3. AUR helper (paru) ---------------------------------------------------
if ! command -v paru >/dev/null 2>&1; then
    log "Installing paru (AUR helper)"
    sudo pacman -S --needed --noconfirm base-devel git
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si)
    rm -rf "$tmp"
fi

# --- 4. AUR packages ---------------------------------------------------------
log "Installing AUR packages"
paru -S --needed - <aur-packages.txt

# --- 5. Symlink config files with stow --------------------------------------
log "Stowing dotfiles"
mkdir -p "$HOME/.local/bin"
stow -d stow -t "$HOME" --restow fish niri noctalia scripts

# --- 6. oh-my-posh (fish prompt) --------------------------------------------
if ! command -v oh-my-posh >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/oh-my-posh" ]; then
    log "Installing oh-my-posh"
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
fi

# --- 7. systemd --user units -------------------------------------------------
log "Installing systemd user units"
mkdir -p "$HOME/.config/systemd/user"
cp systemd/*.service "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
for unit in systemd/*.service; do
    systemctl --user enable --now "$(basename "$unit")"
done

# --- 8. Default shell --------------------------------------------------------
if [ "$SHELL" != "$(command -v fish)" ]; then
    log "Setting fish as your default shell (you'll be prompted for your password)"
    chsh -s "$(command -v fish)"
fi

log "Done. Log out/in (or reboot) to pick up the shell change and niri session."
