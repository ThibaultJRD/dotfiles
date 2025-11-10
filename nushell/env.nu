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
