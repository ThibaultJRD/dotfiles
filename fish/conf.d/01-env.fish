# ==============================================================================
# Environment Variables & PATH Configuration
# ==============================================================================
# Note: Fish uses `set -gx` for environment variables (equivalent to `export`)
# and `fish_add_path` for PATH management

# --- PATH Configuration ---
# Fish automatically deduplicates PATH entries
# The order matters - earlier entries take precedence

# Homebrew (should be first)
fish_add_path /opt/homebrew/bin

# Local binaries
fish_add_path $HOME/.local/bin

# Node.js version manager (n)
fish_add_path $HOME/.n/bin

# Bun
fish_add_path $HOME/.bun/bin

# Go
fish_add_path (brew --prefix go)/libexec/bin
fish_add_path $HOME/go/bin

# --- Tool-specific Environment Variables ---
set -gx N_PREFIX $HOME/.n
set -gx GOPATH $HOME/go
set -gx BUN_INSTALL $HOME/.bun
