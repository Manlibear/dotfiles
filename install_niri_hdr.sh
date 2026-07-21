#!/usr/bin/env bash
# Clone/update, build, and install the dividebysandwich HDR fork of niri as a
# parallel "Niri HDR" SDDM session, alongside the untouched pacman niri.
#
# Not part of install.sh — this builds a Rust compositor from source (slow,
# and only useful on HDR-panel hardware), so it's opt-in:
#
#   ~/Projects/dotfiles/install_niri_hdr.sh
#
# Safe to re-run: pulls latest commits, rebuilds, and re-copies everything in
# place. The pacman-packaged niri.service/niri-shutdown.target/niri.desktop
# are never touched.
#
# Installs:
#   ~/Projects/niri-hdr-fork/{niri,smithay}   - source checkouts
#   /usr/local/bin/niri-hdr                   - compositor binary
#   /usr/local/bin/niri-hdr-session           - SDDM session launcher
#   /etc/systemd/user/niri-hdr.service
#   /etc/systemd/user/niri-hdr-shutdown.target
#   /usr/share/wayland-sessions/niri-hdr.desktop

set -euo pipefail

NIRI_REPO="https://github.com/dividebysandwich/niri.git"
NIRI_BRANCH="hdr-smithay-master"
SMITHAY_REPO="https://github.com/dividebysandwich/smithay.git"
SMITHAY_BRANCH="ds-hdr-master"

FORK_DIR="$HOME/Projects/niri-hdr-fork"
NIRI_DIR="$FORK_DIR/niri"
SMITHAY_DIR="$FORK_DIR/smithay"

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

clone_or_update() {
    local dir="$1" repo="$2" branch="$3"
    if [ -d "$dir/.git" ]; then
        log "Updating $(basename "$dir") ($branch)"
        git -C "$dir" fetch origin "$branch"
        git -C "$dir" checkout "$branch"
        git -C "$dir" reset --hard "origin/$branch"
    else
        log "Cloning $(basename "$dir") ($branch)"
        git clone --branch "$branch" "$repo" "$dir"
    fi
}

mkdir -p "$FORK_DIR"
clone_or_update "$NIRI_DIR" "$NIRI_REPO" "$NIRI_BRANCH"
clone_or_update "$SMITHAY_DIR" "$SMITHAY_REPO" "$SMITHAY_BRANCH"

log "Building niri-hdr (cargo build --release)"
(cd "$NIRI_DIR" && cargo build --release)

BIN_SRC="$NIRI_DIR/target/release/niri"
if [ ! -x "$BIN_SRC" ]; then
    echo "Build did not produce $BIN_SRC" >&2
    exit 1
fi

log "Installing binary to /usr/local/bin/niri-hdr"
sudo install -Dm755 "$BIN_SRC" /usr/local/bin/niri-hdr

log "Installing session launcher to /usr/local/bin/niri-hdr-session"
sudo install -Dm755 /dev/stdin /usr/local/bin/niri-hdr-session <<'EOF'
#!/bin/sh
# SDDM session entry point for the dividebysandwich HDR fork of niri, kept as a
# parallel session so the pacman-packaged niri.service/niri-shutdown.target are
# untouched. See ~/Projects/niri-hdr-fork for the source checkout.

if [ -n "${MANAGERPID:-}" ] && [ "${SYSTEMD_EXEC_PID:-}" = "$$" ]; then
    case "$(ps -p "$MANAGERPID" -o cmd=)" in
    *systemd*--user*)
        exec /usr/local/bin/niri-hdr --session
        ;;
    esac
fi

if [ -n "$SHELL" ] &&
   grep -q "$SHELL" /etc/shells &&
   ! (echo "$SHELL" | grep -q "false") &&
   ! (echo "$SHELL" | grep -q "nologin"); then
  if [ "$1" != '-l' ]; then
    exec bash -c "exec -l '$SHELL' -c '$0 -l $*'"
  else
    shift
  fi
fi

if hash systemctl >/dev/null 2>&1; then
    if systemctl --user -q is-active niri-hdr.service; then
      echo 'A niri-hdr session is already running.'
      exit 1
    fi

    systemctl --user reset-failed

    systemctl --user import-environment

    if hash dbus-update-activation-environment 2>/dev/null; then
        dbus-update-activation-environment --all
    fi

    systemctl --user --wait start niri-hdr.service

    systemctl --user start --job-mode=replace-irreversibly niri-hdr-shutdown.target

    systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP NIRI_SOCKET
else
    echo "No systemd detected, please use niri-hdr --session instead."
fi
EOF

log "Installing systemd user units"
sudo install -Dm644 /dev/stdin /etc/systemd/user/niri-hdr.service <<'EOF'
[Unit]
Description=A scrollable-tiling Wayland compositor (HDR fork)
BindsTo=graphical-session.target
Before=graphical-session.target
Wants=graphical-session-pre.target
After=graphical-session-pre.target

Wants=xdg-desktop-autostart.target
Before=xdg-desktop-autostart.target

[Service]
Slice=session.slice
Type=notify
ExecStart=/usr/local/bin/niri-hdr --session
EOF

sudo install -Dm644 /dev/stdin /etc/systemd/user/niri-hdr-shutdown.target <<'EOF'
[Unit]
Description=Shutdown running niri HDR session
DefaultDependencies=no
StopWhenUnneeded=true

Conflicts=graphical-session.target graphical-session-pre.target
After=graphical-session.target graphical-session-pre.target
EOF

log "Installing SDDM session entry"
sudo install -Dm644 /dev/stdin /usr/share/wayland-sessions/niri-hdr.desktop <<'EOF'
[Desktop Entry]
Name=Niri HDR
Comment=Niri (dividebysandwich HDR fork, hdr-smithay-master)
Exec=niri-hdr-session
Type=Application
DesktopNames=niri
Keywords=hdr;color-management;
EOF

log "Done. \"Niri HDR\" is available as a session on the SDDM login screen."
echo "Binary: $(readlink -f /usr/local/bin/niri-hdr) ($(stat -c %y /usr/local/bin/niri-hdr))"
