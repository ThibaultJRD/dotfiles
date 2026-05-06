# ==============================================================================
# Worktrunk Shell Integration
# ==============================================================================
# Loads worktrunk's shell hook so `wt switch` can cd the parent shell.
# Binary: wt. The actual workflow lives in tmux bindings (prefix + w/W/g).

if [[ -o interactive ]] && command -v wt >/dev/null 2>&1; then
  eval "$(wt config shell init zsh)"
fi
