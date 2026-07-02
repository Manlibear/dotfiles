# dotfiles

Personal Arch Linux config: niri, noctalia, fish (+ oh-my-posh), a few custom
scripts, and the systemd user units that glue them together.

## Fresh install

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Manlibear/dotfiles/main/install.sh)"
```

Clones this repo to `~/Projects/dotfiles`, bootstraps `paru` if it's missing,
installs every package in `packages.txt` through it (paru checks the
official repos before falling back to AUR, so one list covers both),
symlinks everything under `stow/` into `$HOME` with GNU Stow, installs
oh-my-posh, installs + enables the systemd user units, and offers to set
fish as your login shell. Safe to re-run.

## Layout

```
stow/
  fish/.config/fish/…       # config.fish, functions/
  niri/.config/niri/…       # config.kdl, dms/*.kdl
  noctalia/.config/noctalia/…  # settings.json, plugins.json, plugins/
  scripts/.local/bin/…      # desktop-entry-maker, hide-apps, sync-*
systemd/                    # copied to ~/.config/systemd/user/, not stowed
packages.txt                # paru -S --needed (official repo + AUR, one list)
install.sh
```

Each top-level dir under `stow/` is a stow "package" — `stow -d stow -t ~
fish niri noctalia scripts` symlinks its contents into `$HOME`, mirroring
the path under it (e.g. `stow/fish/.config/fish/config.fish` →
`~/.config/fish/config.fish`).

## Deliberately not tracked

- `~/.config/noctalia/colors.json` — regenerated at runtime from the active
  wallpaper/theme, not something you'd want to overwrite on a fresh machine.
- `~/.config/noctalia/plugins/daily-wallpaper/downloads/` — cached wallpaper
  images, regenerates itself.
- `niri/config.kdl.backup*` / `.dmsbackup*` — local backup cruft.
- The oh-my-posh binary itself, AppImages, and the `claude` symlink in
  `~/.local/bin` — reinstalled by `install.sh` or just not config.

`systemd/swayidle.service` is normally written by a package/setup script
(hence root-owned on this machine) rather than hand-authored, but it's
included so a fresh install doesn't need to rediscover it.

## Adding something new

1. Move/copy the real file into the right place under `stow/<package>/…`
   (create a new top-level package dir for unrelated tools).
2. Re-run `stow -d stow -t ~ --restow <package>` (or just `install.sh`
   again) to symlink it back into place.
3. Commit.
