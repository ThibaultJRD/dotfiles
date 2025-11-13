# ==============================================================================
# Nushell Environment Configuration
# ==============================================================================
# This file is loaded before config.nu and sets up environment variables

# Environment variables
$env.EDITOR = "nvim"
$env.LANG = "en_US.UTF-8"
$env.LC_ALL = "en_US.UTF-8"

# Tool-specific environment variables
$env.N_PREFIX = ($env.HOME | path join ".n")
$env.GOPATH = ($env.HOME | path join "go")
$env.BUN_INSTALL = ($env.HOME | path join ".bun")

# FZF configuration
$env.FZF_DEFAULT_COMMAND = "fd --hidden --strip-cwd-prefix --exclude .git"
$env.FZF_CTRL_T_COMMAND = "fd --hidden --strip-cwd-prefix --exclude .git"
$env.FZF_ALT_C_COMMAND = "fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# FZF Theme (Catppuccin Mocha) and Layout
$env.FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border --color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 --color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 --color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 --color=selected-bg:#494D64 --color=border:#363A4F,label:#CAD3F5"

# ==============================================================================
# Generate integration files
# ==============================================================================
# These files are regenerated each time the shell starts to ensure they're up-to-date

# Starship prompt (using Nushell-specific config with character module disabled)
# This must be set BEFORE starship init and remain in environment
$env.STARSHIP_CONFIG = ($env.HOME | path join ".config" "starship" "nushell.toml")
mkdir ~/.cache/starship
^starship init nu | save -f ~/.cache/starship/init.nu

# Atuin history sync
mkdir ~/.local/share/atuin
atuin init nu | save -f ~/.local/share/atuin/init.nu

# Zoxide (smart cd) - using --cmd cd to override the default cd command
zoxide init nushell --cmd cd | save -f ~/.zoxide.nu

# Carapace completions
mkdir ~/.cache/carapace
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu

# PATH configuration
# Nushell uses $env.PATH which is a list of strings
$env.PATH = (
    $env.PATH
    | split row (char esep)
    | prepend /opt/homebrew/bin
    | prepend ($env.HOME | path join ".local" "bin")
    | prepend ($env.HOME | path join ".n" "bin")
    | prepend ($env.HOME | path join ".bun" "bin")
    | prepend ($env.HOME | path join "go" "bin")
    | uniq
)
