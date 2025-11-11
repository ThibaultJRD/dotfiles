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

# ==============================================================================
# Generate integration files
# ==============================================================================
# These files are regenerated each time the shell starts to ensure they're up-to-date

# Starship prompt
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu

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
