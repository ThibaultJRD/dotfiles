# ==============================================================================
# Fish Shell Configuration
# ==============================================================================
# This is the main configuration file for Fish shell.
# Additional configurations are loaded automatically from conf.d/
#
# Fish shell features enabled by default:
# - Syntax highlighting
# - Autosuggestions
# - Smart tab completions
# - History substring search
#
# All modular configurations are in conf.d/ directory
# All custom functions are in functions/ directory
# ==============================================================================

# Disable Fish greeting message
set -g fish_greeting

# Set default editor
set -gx EDITOR nvim

# Set locale
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
