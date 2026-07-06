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
STOW_PACKAGES="fish niri noctalia scripts hypr"
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

# --- 7. Visage (face-unlock) system config -----------------------------------
#
# visage-bin (in packages.txt) only installs the binary + its own systemd
# units. Everything below is what actually makes it authenticate:
#   - a udev rule mapping this laptop's IR camera to a stable /dev/video-ir
#     symlink — HARDWARE-SPECIFIC (matches this exact USB path), won't do
#     anything useful on different hardware
#   - a systemd drop-in pointing visaged at that device + liveness tuning
#   - a pam_visage.so line in sudo/system-auth, positioned so it's tried
#     first and falls through to your password on failure (PAM `sufficient`)
# Your enrolled face data (/var/lib/visage/faces.db, .key) is NOT tracked
# here — it's biometric data, not config. Run `visage enroll` after this.
log "Installing visage system config"

udev_target="/etc/udev/rules.d/99-visage-ir.rules"
if [ -e "$udev_target" ] && ! cmp -s system/udev/99-visage-ir.rules "$udev_target"; then
    log "Backing up pre-existing $udev_target"
    mkdir -p "$BACKUP_DIR/etc/udev/rules.d"
    sudo cp "$udev_target" "$BACKUP_DIR/etc/udev/rules.d/"
fi
sudo cp system/udev/99-visage-ir.rules "$udev_target"
sudo udevadm control --reload-rules
sudo udevadm trigger

override_target="/etc/systemd/system/visaged.service.d/override.conf"
if [ -e "$override_target" ] && ! cmp -s system/systemd/visaged.service.d/override.conf "$override_target"; then
    log "Backing up pre-existing $override_target"
    mkdir -p "$BACKUP_DIR/etc/systemd/system/visaged.service.d"
    sudo cp "$override_target" "$BACKUP_DIR/etc/systemd/system/visaged.service.d/"
fi
sudo mkdir -p "$(dirname "$override_target")"
sudo cp system/systemd/visaged.service.d/override.conf "$override_target"
sudo systemctl daemon-reload
sudo systemctl enable --now visaged.service
sudo systemctl restart visaged.service   # pick up the drop-in if it changed
sudo systemctl enable visage-resume.service

for pam_file in sudo system-auth; do
    target="/etc/pam.d/$pam_file"
    if ! grep -q pam_visage.so "$target"; then
        log "Adding pam_visage.so to $target"
        case "$pam_file" in
            sudo)
                # First line after the header, ahead of the system-auth include,
                # so face auth is tried before falling through to the password stack.
                sudo sed -i '/^auth\s\+include\s\+system-auth/i auth            sufficient      pam_visage.so' "$target"
                ;;
            system-auth)
                # Ahead of the pam_unix.so password check, same "try biometric
                # first, fall through on failure" ordering.
                sudo sed -i '/\[success=1 default=bad\]/i auth      sufficient    pam_visage.so' "$target"
                ;;
        esac
    fi
done

# --- 8. Noctalia notification patches ----------------------------------------
#
# noctalia-shell's real desktop notifications (Discord etc.) render through
# its stock Notification.qml card and only reliably auto-dismiss when
# nothing else owns the org.freedesktop.Notifications dbus name. Two fixes,
# both patches against noctalia-shell 4.7.7-3's stock files:
#   - route real notifications through ToastService (same UI as internal
#     toasts — volume/DND/plugins) instead of the notification card, for a
#     consistent look and an animation-driven dismiss instead of a polling
#     timer; also plumb a real app icon/avatar through the toast (falls
#     back to a generic glyph when the sender doesn't supply one)
#   - mako (installed by something pulling it in as niri's optional dep,
#     never listed in packages.txt) was racing noctalia's own
#     NotificationServer for that dbus name and usually winning, which is
#     why patching noctalia's QML alone did nothing — masked via systemctl
#     below so it can never grab the name even if it reappears
# These are full-file replacements of package-owned files under
# /etc/xdg/quickshell — a noctalia-shell update can change those files
# upstream, and re-running this step will blindly overwrite any upstream
# changes with our stale copy. Worth diffing against the new package
# version after a noctalia-shell bump rather than trusting this blindly.
log "Installing noctalia notification patches"

systemctl --user mask mako.service >/dev/null 2>&1 || true

QS_TARGET_ROOT="/etc/xdg/quickshell/noctalia-shell"
while IFS= read -r -d '' src; do
    rel="${src#system/quickshell/noctalia-shell/}"
    target="$QS_TARGET_ROOT/$rel"
    if [ -e "$target" ] && ! cmp -s "$src" "$target"; then
        log "Backing up pre-existing $target"
        mkdir -p "$BACKUP_DIR/$(dirname "${target#/}")"
        sudo cp "$target" "$BACKUP_DIR/${target#/}"
    fi
    sudo cp "$src" "$target"
done < <(find system/quickshell/noctalia-shell -type f -print0)

# --- 9. Default shell --------------------------------------------------------
if [ "$SHELL" != "$(command -v fish)" ]; then
    log "Setting fish as your default shell (you'll be prompted for your password)"
    chsh -s "$(command -v fish)"
fi

[ -d "$BACKUP_DIR" ] && log "Pre-existing files backed up to $BACKUP_DIR"
log "Done. Run 'visage enroll' to set up face-unlock (your face data isn't tracked)."
log "Log out/in (or reboot) to pick up the shell change and niri session."
