# ==============================================================================
# FZF Advanced Configuration
# ==============================================================================
# This file contains advanced options, keybindings, and previews for fzf.

# --- FZF Commands Configuration ---
# This is the core command used by fzf to find files.
# - `fd` is used for its high performance.
# - `--hidden` includes hidden files and directories (e.g., .zshrc).
# - `--strip-cwd-prefix` removes the './' from the beginning of paths.
# - `--exclude .git` ignores the .git directory itself.
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"

# Use the same command for the CTRL+T keybinding.
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# For ALT+C, find only directories.
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"


# --- FZF Tab Completion ---
# Use fd for path completion.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}
# Use fd for directory completion.
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}


# --- FZF Theme & Options ---
export FZF_DEFAULT_OPTS=" \
--color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 \
--color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
--color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
--color=selected-bg:#494D64 \
--color=border:#363A4F,label:#CAD3F5"


# --- FZF Previews ---
# This command is used to generate previews.
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --level=2 --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

# Assign the preview command to the CTRL+T keybinding.
export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"

# Use the same tree preview for ALT+C.
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {} | head -200'"


# --- FZF Preview for Tab Completion ---
# This function provides custom previews for different commands during tab completion.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --level=2 --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"                       "$@" ;;
    ssh)          fzf --preview 'dig {}'                                 "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview"              "$@" ;;
  esac
}
