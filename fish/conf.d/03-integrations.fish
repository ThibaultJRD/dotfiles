# ==============================================================================
# Tool Integrations
# ==============================================================================
# Initialize various CLI tools with Fish shell

# --- Zoxide (smarter cd) ---
if type -q zoxide
    zoxide init fish --cmd cd | source
end

# --- Starship Prompt ---
# Must be at the end to take control of the prompt
if type -q starship
    starship init fish | source
end

# --- Atuin (shell history) ---
if type -q atuin
    atuin init fish | source
end

# --- Bun completions ---
if test -s $HOME/.bun/_bun
    source $HOME/.bun/_bun
end
