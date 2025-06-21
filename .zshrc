# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# -------------------------------------------------------------------
# PATH Configuration
# -------------------------------------------------------------------
# The order is important. Homebrew should be first to take precedence.
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.n/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$PATH:$(brew --prefix go)/libexec/bin:$HOME/go/bin"

# -------------------------------------------------------------------
# Oh My Zsh Configuration
# -------------------------------------------------------------------
# List of plugins for Oh My Zsh.
plugins=(
  git
  z
  fzf
  sudo
  zsh-completions
  zsh-syntax-highlighting
  zsh-autosuggestions
  history-substring-search
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# -------------------------------------------------------------------
# Environment & Aliases
# -------------------------------------------------------------------
export EDITOR='nvim'

# Set system language to English for CLI tools
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Environment variables for tools
export N_PREFIX=$HOME/.n
export GOPATH=$HOME/go
export BUN_INSTALL="$HOME/.bun"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# General aliases
alias cat='bat'
alias lg='lazygit'
alias v='nvim'
alias f='nvim $(fzf -m --preview="bat --color=always {}")'
alias ls='eza --icons --git'
alias la='eza -l --icons --git -a --group-directories-first'
alias lt='eza --tree --level=2 --long --icons --git'

# Yazi: Function to change directory on exit
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# -------------------------------------------------------------------
# Starship Prompt
# Must be at the end of the file to take control of the prompt.
# -------------------------------------------------------------------
eval "$(starship init zsh)"
