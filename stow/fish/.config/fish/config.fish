if status is-interactive
# Commands to run in interactive sessions can go here
end

set -gx WLR_RENDERER vulkan

# oh-my-posh (install.sh) lands here; fish's own PATH doesn't include it
# by default on a fresh machine (fish_add_path persists to the untracked
# fish_variables state file, not to anything dotfiles ships).
fish_add_path $HOME/.local/bin



set -g fish_greeting


oh-my-posh init fish --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/refs/heads/main/themes/amro.omp.json" | source


alias ls "eza --icons=auto"
alias la "eza -la --icons=auto"
alias ll "eza -l --icons=auto"
alias lt "eza --tree --icons=auto"
alias cd.. "cd .."
alias backlog "~/Projects/GamesBacklog/.venv/bin/python3 ~/Projects/GamesBacklog/app.py"
alias edit-hypr "nano ~/Projects/dotfiles/stow/hypr/.config/hypr/hyprland.lua"
