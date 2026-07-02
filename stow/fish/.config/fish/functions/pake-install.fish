function pake-install
    pake $argv[1] --name $argv[2] --targets zst || return 1
    set pkg (string lower $argv[2])*.pkg.tar.zst
    sudo pacman -U $pkg && rm $pkg
end
