# ==============================================================================
# FZF Advanced Configuration
# ==============================================================================
# This file contains advanced options and keybindings for fzf.

# --- Keybinding Configurations ---

# ALT+C: Find a directory and 'cd' into it immediately.
# Using 'eza --long' instead of 'eza --tree' for much better performance.
export FZF_ALT_C_OPTS="--preview 'eza --long --color=always {} | head -200'"


# --- Custom Smart Keybinding: CTRL+T ---

# This function defines a custom widget for CTRL+T.
# - If a directory is selected, it will immediately 'cd' into it.
# - If a file is selected, it will place 'nvim <file>' on the command line.
_fzf_smart_ctrl_t() {
  local selection
  
  # The preview command has been optimized for performance.
  local preview_command="if [ -d {} ]; then eza --long --color=always {} | head -200; else bat --color=always --style=numbers --line-range :500 {}; fi"

  # Use 'fd' to find both files and directories, then pipe to fzf
  selection=$(fd --hidden --strip-cwd-prefix --exclude .git . | fzf --exit-0 --header 'CTRL+T: Select file to edit, or directory to enter' --preview "$preview_command")
  
  # Exit if there was no selection
  if [ -z "$selection" ]; then
    zle send-break
    return
  fi
  
  # Check if the selection is a directory
  if [ -d "$selection" ]; then
    # For a directory, directly change directory. This is faster than using LBUFFER and accept-line.
    builtin cd "${selection}"
    # Clear the command buffer
    LBUFFER=""
    # Redraw the prompt in the new directory.
    zle reset-prompt
  else
    # For a file, place 'nvim <file>' in the buffer for the user to execute.
    LBUFFER="nvim '${selection}'"
    # Redraw the buffer to show the command.
    zle redisplay
  fi
}

# Register the function as a Zle (Zsh Line Editor) widget
zle -N _fzf_smart_ctrl_t

# --- Force custom keybinding over fzf plugin's default ---
# Unbind the default CTRL+T from the fzf plugin, then bind our custom widget.
# This ensures our smart function is always used.
bindkey -r '^T'
bindkey '^T' _fzf_smart_ctrl_t

