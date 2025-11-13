# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# XDG Base Directory specification
# This ensures tools like Nushell use ~/.config for their configuration
export XDG_CONFIG_HOME="$HOME/.config"
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# -------------------------------------------------------------------
# PATH Configuration
# -------------------------------------------------------------------
# The order is important. Homebrew should be first to take precedence.
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.n/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.atuin/bin:$PATH"
export PATH="$PATH:$(brew --prefix go)/libexec/bin:$HOME/go/bin"

# -------------------------------------------------------------------
# Oh My Zsh Configuration
# -------------------------------------------------------------------
# ZSH_THEME is set to "" because we use Starship to handle the prompt.
ZSH_THEME=""

# List of plugins for Oh My Zsh.
plugins=(
  git
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
# Load Custom Configurations
# -------------------------------------------------------------------
# Source all .zsh files from our custom config directory
ZSH_CUSTOM_CONF_DIR="$HOME/.config/zsh/conf.d"
if [ -d "$ZSH_CUSTOM_CONF_DIR" ]; then
  for config_file in $ZSH_CUSTOM_CONF_DIR/*.zsh; do
    [ -r "$config_file" ] && source "$config_file"
  done
  unset config_file
fi

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

# Zoxide (smarter cd)
eval "$(zoxide init zsh --cmd cd)"

# Atuin (shell history)
eval "$(atuin init zsh)"

# Carapace (advanced completions)
eval "$(carapace _carapace)"

# General aliases
alias cat='bat'
alias lg='lazygit'
alias v='nvim'
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias la='eza -l --icons --git -a --group-directories-first'
alias lt='eza --tree --level=2 --long --icons --git'
alias p='pnpm'

# -------------------------------------------------------------------
# Starship Prompt
# Must be at the end of the file to take control of the prompt.
# -------------------------------------------------------------------
eval "$(starship init zsh)"

