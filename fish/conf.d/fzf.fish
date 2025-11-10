# ==============================================================================
# FZF Advanced Configuration for Fish
# ==============================================================================
# This file configures fzf with advanced options, keybindings, and previews

# --- FZF Commands Configuration ---
# Core command used by fzf to find files
set -gx FZF_DEFAULT_COMMAND "fd --hidden --strip-cwd-prefix --exclude .git"

# Use the same command for CTRL+T keybinding
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"

# For ALT+C, find only directories
set -gx FZF_ALT_C_COMMAND "fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# --- FZF Theme (Catppuccin Macchiato) ---
set -gx FZF_DEFAULT_OPTS "\
--color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 \
--color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
--color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
--color=selected-bg:#494D64 \
--color=border:#363A4F,label:#CAD3F5"

# --- FZF Previews ---
# Preview command for files and directories
set -l show_file_or_dir_preview "if test -d {}; eza --tree --level=2 --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; end"

# Assign preview to CTRL+T
set -gx FZF_CTRL_T_OPTS "--preview '$show_file_or_dir_preview'"

# Preview for ALT+C (directory tree)
set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --color=always {} | head -200'"

# --- FZF Path Completion (for Fish) ---
# Note: Fish has excellent native completion, but fzf can enhance it further
# Install fzf.fish plugin with Fisher for advanced fzf+Fish integration:
#   fisher install PatrickF1/fzf.fish
#
# This provides:
# - CTRL+R: Search command history with fzf
# - CTRL+ALT+F: Search files with fzf
# - CTRL+ALT+L: Search git log with fzf
# - CTRL+V: Search and preview environment variables
