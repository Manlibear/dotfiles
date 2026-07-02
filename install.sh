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

# --- 2. AUR helper (paru) ---------------------------------------------------
# Bootstrapped via plain pacman since paru doesn't exist yet; everything
# after this goes through paru, which checks the official repos before
# falling back to AUR, so one package list covers both.
if ! command -v paru >/dev/null 2>&1; then
    log "Installing paru (AUR helper)"
    sudo pacman -S --needed --noconfirm base-devel git
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si)
    rm -rf "$tmp"
fi

# --- 3. Packages (official repo + AUR) ---------------------------------------
log "Installing packages"
paru -S --needed $(<packages.txt)

# --- 4. Symlink config files with stow --------------------------------------
#
# Some packages (niri notably) seed a default config file on first launch if
# none exists yet. If that happened before this script ran — e.g. the
# install media auto-started a session — stow refuses to overwrite a real
# file with a symlink. Move any such real file aside first so our tracked
# version wins; back it up rather than deleting in case there's something
# worth diffing later.
BACKUP_DIR="$HOME/.dotfiles-preexisting-$(date +%Y%m%d-%H%M%S)"
STOW_PACKAGES="fish niri noctalia scripts"
for pkg in $STOW_PACKAGES; do
    while IFS= read -r -d '' src; do
        rel="${src#stow/$pkg/}"
        target="$HOME/$rel"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            log "Backing up pre-existing $target"
            mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
            mv "$target" "$BACKUP_DIR/$rel"
        fi
    done < <(find "stow/$pkg" -type f -print0)
done

log "Stowing dotfiles"
mkdir -p "$HOME/.local/bin"
stow -d stow -t "$HOME" --restow $STOW_PACKAGES

# --- 5. oh-my-posh (fish prompt) --------------------------------------------
if ! command -v oh-my-posh >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/oh-my-posh" ]; then
    log "Installing oh-my-posh"
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
fi

# --- 6. systemd --user units -------------------------------------------------
log "Installing systemd user units"
mkdir -p "$HOME/.config/systemd/user"
for unit in systemd/*.service; do
    target="$HOME/.config/systemd/user/$(basename "$unit")"
    if [ -e "$target" ]; then
        log "Backing up pre-existing $target"
        mkdir -p "$BACKUP_DIR/.config/systemd/user"
        cp "$target" "$BACKUP_DIR/.config/systemd/user/"
        # Some units (e.g. swayidle.service on this machine) get written
        # root-owned by a package/setup script despite living under
        # ~/.config. We can read/back it up but not overwrite it — clear it
        # with sudo so the replacement ends up normally user-owned, which
        # makes future runs self-healing (no sudo needed after the first).
        if [ ! -w "$target" ]; then
            sudo rm -f "$target"
        fi
    fi
    cp "$unit" "$target"
done
systemctl --user daemon-reload
for unit in systemd/*.service; do
    systemctl --user enable --now "$(basename "$unit")"
done

# --- 7. Default shell --------------------------------------------------------
if [ "$SHELL" != "$(command -v fish)" ]; then
    log "Setting fish as your default shell (you'll be prompted for your password)"
    chsh -s "$(command -v fish)"
fi

[ -d "$BACKUP_DIR" ] && log "Pre-existing files backed up to $BACKUP_DIR"
log "Done. Log out/in (or reboot) to pick up the shell change and niri session."
