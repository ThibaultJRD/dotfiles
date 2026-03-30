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

# Zoxide interactive directory picker (Ctrl+G)
# Pre-filters with the query after "cd " if present on the commandline
zoxide-cd-widget() {
  local result
  if [[ "$BUFFER" == cd\ * ]]; then
    local query="${BUFFER#cd }"
    result="$(zoxide query --interactive -- "$query" </dev/tty 2>/dev/null)"
  else
    result="$(zoxide query --interactive </dev/tty 2>/dev/null)"
  fi
  if [[ -n "$result" ]]; then
    BUFFER="cd $result"
    CURSOR=${#BUFFER}
  fi
  zle reset-prompt
}
zle -N zoxide-cd-widget
bindkey -M viins '^G' zoxide-cd-widget
bindkey -M vicmd '^G' zoxide-cd-widget


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
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --level=2 --color=always --git-ignore {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

# Assign the preview command to the CTRL+T keybinding.
export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"

# Zoxide fzf options (used by cdi and Ctrl+G)
export _ZO_FZF_OPTS="--height 40% --layout=reverse --border --preview 'eza --tree --level=2 --color=always --git-ignore {2..}' --preview-window=right,50%,border-left --color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 --color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 --color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 --color=selected-bg:#494D64 --color=border:#363A4F,label:#CAD3F5"


# --- FZF Preview for Tab Completion ---
# This function provides custom previews for different commands during tab completion.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --level=2 --color=always --git-ignore {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"                       "$@" ;;
    ssh)          fzf --preview 'dig {}'                                 "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview"              "$@" ;;
  esac
}
