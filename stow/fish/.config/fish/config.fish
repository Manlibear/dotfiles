if status is-interactive
# Commands to run in interactive sessions can go here
end

oh-my-posh init fish --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/refs/heads/main/themes/amro.omp.json" | source


alias ls "eza --icons"
alias la "eza -la --icons"
alias ll "eza -l --icons"
alias lt "eza --tree --icons"
alias backlog "~/Projects/GamesBacklog/.venv/bin/python3 ~/Projects/GamesBacklog/app.py"
# GamesBacklog IGDB credentials now live in ~/Projects/GamesBacklog/config.json instead
