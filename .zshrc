# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export PATH="/opt/homebrew/bin:${PATH}"

ZSH_THEME="robbyrussell"

plugins=(git zsh-syntax-highlighting zsh-autosuggestions z)

source $ZSH/oh-my-zsh.sh

export EDITOR='nvim'

# N
export N_PREFIX=$HOME/.n
export PATH=$N_PREFIX/bin:$PATH

# FZF
source <(fzf --zsh)
alias f='nvim $(fzf -m --preview="bat --color=always {}")'

# Eza
alias ls='eza --icons --git'
alias la='eza -l --icons --git -a --group-directories-first'
alias lt='eza --tree --level=2 --long --icons --git'

# General aliases
alias cat=bat
alias lg='lazygit'
alias v='nvim'
alias y='yazi'

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Starship : Must be at the end of the file
eval "$(starship init zsh)"
