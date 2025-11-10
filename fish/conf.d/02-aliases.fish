# ==============================================================================
# Aliases
# ==============================================================================
# Fish uses `alias` command just like other shells, but you can also define
# functions for more complex aliases

# --- Tool replacements ---
alias cat='bat'
alias ls='eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
alias la='eza -l --icons --git -a --group-directories-first'
alias lt='eza --tree --level=2 --long --icons --git'

# --- Development tools ---
alias v='nvim'
alias lg='lazygit'
alias p='pnpm'

# --- CD replacement (zoxide) ---
# Note: Zoxide integration provides 'cd' command automatically when initialized
# The 'z' command is also available as an alias if you prefer it
