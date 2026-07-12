#!/bin/sh
# Shows a fixed splash image immediately at Hyprland startup via swaybg, so
# there's no flash of Hyprland's default background before Noctalia's own
# wallpaper layer (quickshell) takes over. Swap the image at will.
exec swaybg -m fill -i "$HOME/Pictures/Wallpapers/default_splash.jpg"
