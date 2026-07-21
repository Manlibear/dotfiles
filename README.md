# dotfiles

Personal Arch Linux config: Hyprland and niri (both kept side-by-side, switch
at the login screen), noctalia, fish (+ oh-my-posh), a few custom scripts, and
the systemd user units that glue them together.

## Fresh install

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Manlibear/dotfiles/main/install.sh)"
```

Clones this repo to `~/Projects/dotfiles`, bootstraps `paru` if it's missing,
installs every package in `packages.txt` through it (paru checks the
official repos before falling back to AUR, so one list covers both),
symlinks everything under `stow/` into `$HOME` with GNU Stow, installs
oh-my-posh, installs + enables the systemd user units, wires up visage
face-unlock (udev rule + systemd override + PAM), patches noctalia-shell's
notification handling (see below) and masks mako, vendors the Noctalia SDDM
theme and the KvNoctalia Kvantum theme and activates both, logs into `gh`,
generates a new per-machine SSH key and registers it with GitHub, sets up
snapper + grub-btrfs for btrfs snapshot rollback (assumes the `@`/`@home`
subvolume layout from `archinstall`; no-ops if snapper/grub aren't in use),
and offers to set fish as your login shell. Safe to re-run.

## Niri HDR (optional)

```sh
~/Projects/dotfiles/install_niri_hdr.sh
```

Not part of `install.sh` — builds the [dividebysandwich](https://github.com/dividebysandwich/niri)
HDR fork of niri (+ its paired Smithay fork) from source and installs it as a
second, parallel "Niri HDR" SDDM session, so the pacman-packaged niri stays
untouched. Slow (compiles a Rust compositor) and only useful on HDR-panel
hardware, hence opt-in. Safe to re-run — pulls the latest commits on
`hdr-smithay-master`/`ds-hdr-master` and rebuilds in place.

## Layout

```
stow/
  fish/.config/fish/…       # config.fish, functions/
  hypr/.config/hypr/…       # hyprland.lua — Hyprland's own Lua config format,
                             #   scripts/preload-wallpaper.sh
  niri/.config/niri/…       # config.kdl — niri's own KDL config format
  kde/.config/…              # kdeglobals (widgetStyle=kvantum, noctalia-folders
                             #   icon theme), Kvantum/kvantum.kvconfig,
                             #   Kvantum/KvNoctalia/KvNoctalia.kvconfig.template,
                             #   Kvantum/KvNoctalia/KvNoctalia.svg (patched
                             #   copy of kvantum-git's KvGnomeDark.svg — see
                             #   below)
  noctalia/.config/noctalia/…  # settings.json, plugins.json, plugins/,
                             #   user-templates.toml
  scripts/.local/bin/…      # desktop-entry-maker, hide-apps, sync-*,
                             #   hypr-toggle-maximize-column
systemd/                    # copied to ~/.config/systemd/user/, not stowed
system/                      # root-owned /etc files, installed via sudo, not stowed
  udev/99-visage-ir.rules
  systemd/visaged.service.d/override.conf
  quickshell/noctalia-shell/…  # patches over the package's own /etc/xdg files
  sddm/theme.conf              # -> /etc/sddm.conf.d/theme.conf, activates the
                                #   Noctalia SDDM theme (Current=noctalia)
packages.txt                # paru -S --needed (official repo + AUR, one list)
install.sh
install_niri_hdr.sh         # optional: HDR niri fork as a second SDDM session
```

Each top-level dir under `stow/` is a stow "package" — `stow -d stow -t ~
fish noctalia scripts hypr niri kde` symlinks its contents into `$HOME`, mirroring
the path under it (e.g. `stow/fish/.config/fish/config.fish` →
`~/.config/fish/config.fish`).

## Deliberately not tracked

- `~/.config/noctalia/colors.json` — regenerated at runtime from the active
  wallpaper/theme, not something you'd want to overwrite on a fresh machine.
- `~/.config/noctalia/plugins/daily-wallpaper/downloads/` — cached wallpaper
  images, regenerates itself.
- `~/.cache/hypr-colwidth/` — per-window column-width state written by
  `hypr-toggle-maximize-column`, runtime scratch, not config.
- The oh-my-posh binary itself, AppImages, and the `claude` symlink in
  `~/.local/bin` — reinstalled by `install.sh` or just not config.
- `/usr/share/sddm/themes/noctalia/` (the theme's QML, assets, scripts) —
  not vendored in this repo, `install.sh` clones
  [mda-dev/noctalia-sddm-theme](https://github.com/mda-dev/noctalia-sddm-theme)
  fresh each time it's missing. Only the bit that says *use this theme*
  (`system/sddm/theme.conf`) and the noctalia-shell side of the sync
  (`stow/noctalia`'s `user-templates.toml` + `settings.json` hooks) are
  tracked.

`systemd/swayidle.service` is normally written by a package/setup script
(hence root-owned on this machine) rather than hand-authored, but it's
included so a fresh install doesn't need to rediscover it.

- `/var/lib/visage/faces.db` and `.key` — your enrolled face data. Biometric
  data, not config; never tracked. Run `visage enroll` after a fresh install.
- `system/udev/99-visage-ir.rules` is pinned to *this laptop's* exact USB
  path for the IR camera (`ID_PATH=="pci-0000:00:14.0-usb-0:8:1.2"`). On
  different hardware this rule just won't match anything — `/dev/video-ir`
  won't exist, and `visaged` will stay up but fail to authenticate (PAM
  falls through to your password, so nothing breaks, face-unlock just won't
  work until the rule's path is updated for that machine).
- `system/quickshell/noctalia-shell/…` is a full-file patch against
  noctalia-shell 4.7.7-3's stock `ToastService.qml`, `Toast.qml`,
  `ToastScreen.qml`, `NImageRounded.qml`, and `NotificationService.qml` —
  it routes real desktop notifications through the same toast UI as
  internal events (consistent look, reliable auto-dismiss, real app
  icons) instead of the stock notification card. Because it's a whole-file
  replacement rather than a diff, a future noctalia-shell package update
  can change those files upstream and `install.sh` will silently overwrite
  the new version with this stale one — diff against the freshly installed
  package before re-running after a noctalia-shell bump. Also masks
  `mako.service`, which niri pulls in as an optional dep and which races
  noctalia's own notification server for the dbus name (and usually wins) —
  the mask stays regardless of which compositor is active, since niri is
  back in the mix alongside Hyprland.

Hyprland and niri border colors and the Papirus folder-icon recolor
(`sync-hypr-border`, `sync-niri-border`, `sync-folder-color` under
`stow/scripts`) aren't triggered by a systemd watcher — they're wired into
noctalia-shell's own `hooks.colorGeneration` hook (`stow/noctalia`'s
`settings.json`), which fires whenever noctalia regenerates `colors.json`,
whether that's from a wallpaper change or a manual scheme switch. Both
border-sync scripts also push the same primary color to the keyboard/case
RGB via `asusctl aura effect static -c`, so the ROG Aura lighting stays in
sync regardless of which compositor is active. `sync-folder-color` recolors
Papirus-Dark's `folder-blue*`/`user-blue*` variants (symlinked down to their
unsuffixed names — `folder-blue-pictures.svg` → `folder-pictures.svg`) *and*
the plain `folder.svg`/`folder-open.svg` used for ordinary, uncategorized
folders — easy to only do the first half and end up with every XDG folder
(Documents, Downloads, …) themed but plain folders stuck on Papirus's stock
blue. It also symlinks `folder.svg` → `inode-directory.svg` in the same
output directory: file managers look up folder icons by MIME type
(`inode-directory`) before falling back to the generic `folder` name, and
Papirus-Dark only ships `inode-directory.svg` as a 16x16 symlink — without
our own copy at every size, that MIME lookup skips the recolored icon
entirely and falls through to Papirus's stock blue at anything above 16px.

Dolphin's translucent navy theme (`stow/kde`) is a Kvantum theme
(`KvNoctalia`) recolored from the live palette by noctalia-shell's *template*
engine (not the hook system above — it's the same `user-templates.toml`
mechanism the SDDM theme uses, driven by `settings.json`'s
`templates.activeTemplates`). Two gotchas if this ever looks wrong again:
- `kdeglobals`' `widgetStyle` must be the literal string `kvantum`, not
  `qt6ct-style`. Going through qt6ct's own style pointer (even when it
  points at `kvantum-dark`) bypasses Kvantum's `[Applications]`
  per-app theme override, so Dolphin silently falls back to a default
  light style instead of picking up `KvNoctalia`.
- The transparency itself is a single Hyprland `opacity` windowrule on
  `org.kde.dolphin` (`stow/hypr/hyprland.lua`), same active/inactive value
  (a window that gets lighter on losing focus reads as a bug) — blur behind
  it is automatic (global `decoration.blur.enabled`) once opacity is < 1, no
  separate per-window blur rule needed (`hl.window_rule` doesn't expose one
  anyway — that's only a field on `hl.layer_rule`). Kvantum's own
  `translucent_windows` and `transparent_dolphin_view` are both **off** in
  the theme — turning them on made Kvantum apply its *own* per-pixel alpha
  on top of Hyprland's, which (a) double-stacked with the windowrule for a
  washed-out look and (b) only punched through the file-view pane, not the
  Places sidebar, so the two panels looked like different windows. One
  opacity source (Hyprland) painting one fully-opaque Kvantum surface,
  uniformly, is the version that actually looks like a single window.

`KvNoctalia.svg` (`stow/kde`) is a small hand-patch of kvantum-git's
`KvGnomeDark.svg`, not the pristine upstream file — Kvantum's `.kvconfig`
only drives generic Qt-palette colors, not the toolbar/menubar background,
which is baked directly into the theme's SVG as a fixed gradient
(`linearGradient5047`/`5035`, id `menubar-normal`/`menubar-normal-inactive`)
shared with an unrelated `titlebar-normal` element. The patch gives the
toolbar its own (darker, slightly-`fill-opacity`'d) gradient instead of
touching the shared one, so the breadcrumb bar reads as a distinct, darker
strip without recoloring anything else. Since this diverges from upstream,
it's tracked directly rather than vendored fresh by `install.sh` — a
`kvantum-git` update won't silently overwrite it, but it also won't pick up
upstream SVG fixes; diff against the new package version if this looks
stale after a bump.

The Places sidebar's selection highlight (`KFilePlacesView`) ignored
`KvNoctalia.kvconfig`'s `highlight.color` entirely — chased this through a
couple of wrong turns (`qt6ct`'s `custom_palette`, a custom KDE color
scheme) before finding the real cause: KvGnomeDark's original accent blue,
`#15539e`, is baked directly into 61 separate SVG elements (`itemview-toggled`,
`itemview-pressed`, `menuitem-pressed-*`, `radio`, `dial-handle`, …) as the
theme's pervasive "selected/pressed" indicator color, completely bypassing
the kvconfig. Same fix as the toolbar: a plain find-and-replace on that one
hex value across the SVG (now `#1a1a1a`, matching the toolbar), kept in sync
with `highlight.color`/`inactive.highlight.color` in the kvconfig template
so a future full re-theme (if `KvNoctalia.svg` is ever rebuilt from a
different base theme) doesn't silently reintroduce a mismatched blue.

## Adding something new

1. Move/copy the real file into the right place under `stow/<package>/…`
   (create a new top-level package dir for unrelated tools).
2. Re-run `stow -d stow -t ~ --restow <package>` (or just `install.sh`
   again) to symlink it back into place.
3. Commit.
