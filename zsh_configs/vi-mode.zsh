# ==============================================================================
# Vi Mode Configuration for Zsh
# ==============================================================================
# This file configures vi-style keybindings for command line editing in Zsh.
# It provides visual feedback through cursor shape changes and prompt symbols.
# ==============================================================================

# Enable vi mode for command line editing
bindkey -v

# Reduce ESC key delay to 0.1 seconds for faster mode switching
export KEYTIMEOUT=1

# Better vi mode cursor (only works in some terminals)
# Insert mode: line cursor, Normal mode: block cursor
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

# Start with beam cursor on zsh startup
echo -ne '\e[5 q'

# Beam cursor on new prompt
function zle-line-init {
  echo -ne "\e[5 q"
}
zle -N zle-line-init
