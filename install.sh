#!/bin/bash

# ==============================================================================
# Dotfiles Installation Script
# ==============================================================================
# This script automates the setup of the development environment by symlinking
# configuration files and installing dependencies via a Brewfile.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
VERBOSE="${VERBOSE:-false}"

# --- Utility Functions ---
# For printing informational headers
echo_info() {
  printf "\n\033[1;34m%s\033[0m\n" "$1"
}

# For printing debug messages
echo_debug() {
  [ "$VERBOSE" = "true" ] && printf "\033[0;36m[DEBUG] %s\033[0m\n" "$1"
}

# For printing success messages
echo_success() {
  printf "\033[1;32m✓ %s\033[0m\n" "$1"
}

# For printing warning messages
echo_warning() {
  printf "\033[1;33m! %s\033[0m\n" "$1"
}

# For printing error messages and exiting
echo_error() {
  printf "\033[1;31m✗ %s\033[0m\n" "$1" >&2
  exit 1
}

# --- Variables ---
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/.dotfiles_backup_$BACKUP_DATE"

# --- Pre-run Check and Backup Function ---
backup_and_link() {
  local source_path=$1
  local target_path=$2

  # Ensure backup directory exists
  mkdir -p "$BACKUP_DIR"

  # Check if the target is already a symlink to the source
  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    echo_success "Already linked '$source_path' to '$target_path'. Skipping."
    return 0
  fi

  # If target exists and is not a symlink, back it up
  if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
    backup_file="$target_path.bak.$BACKUP_DATE"
    echo_info "Backing up existing '$target_path' to '$backup_file'"
    mv "$target_path" "$backup_file"
  fi

  # If target is a symlink (but not to the correct source, handled above), remove it
  if [ -L "$target_path" ]; then
    echo "Removing old symlink '$target_path'"
    rm "$target_path"
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
  echo_success "Linked '$source_path' to '$target_path'"
}

# --- Installation Start ---
echo_info "Starting dotfiles setup..."
echo "Your existing configs will be backed up with the suffix .bak.$BACKUP_DATE"

# Pre-requisite checks
echo_info "Checking prerequisites..."
if ! command -v git &>/dev/null; then
  echo_error "Git is not installed. Please install Git to proceed."
fi
if ! command -v curl &>/dev/null; then
  echo_error "Curl is not installed. Please install Curl to proceed."
fi
echo_success "All prerequisites are met."

# 1. Install Homebrew
if [[ -n "${SKIP_HOMEBREW_INSTALL}" ]]; then
  echo_info "Skipping Homebrew installation (SKIP_HOMEBREW_INSTALL is set)..."
  if ! command -v brew &>/dev/null; then
    echo_error "Homebrew is not available but SKIP_HOMEBREW_INSTALL is set. Please ensure Homebrew is installed and in PATH."
  fi
  echo_success "Homebrew is available."
elif ! command -v brew &>/dev/null; then
  echo_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo_info "Adding Homebrew to PATH..."
  if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
  else
    eval "$(/usr/local/bin/brew shellenv)"
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >>"$HOME/.zprofile"
  fi
  echo_success "Homebrew installed and configured."
else
  echo_success "Homebrew is already installed. Updating..."
  set +e
  brew update
  BREW_UPDATE_STATUS=$?
  set -e

  if [ $BREW_UPDATE_STATUS -ne 0 ]; then
    echo_warning "Warning: 'brew update' failed. Continuing with setup..."
  else
    echo_success "Homebrew updated successfully."
  fi
fi

# 2. Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo_info "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo_success "Oh My Zsh installed."
else
  echo_success "Oh My Zsh is already installed."
fi

# 3. Install dependencies from Brewfile
echo_info "Installing all dependencies from Brewfile..."
set +e
brew bundle --file="$DOTFILES_DIR/Brewfile"
BREW_BUNDLE_STATUS=$?
set -e

if [ $BREW_BUNDLE_STATUS -ne 0 ]; then
  echo_warning "Warning: 'brew bundle' finished with errors. Some packages may not be installed."
  echo_info "Continuing with setup - you can manually install missing packages later."
else
  echo_success "All Homebrew dependencies are installed."
fi

# 3. Link Configuration Files
echo_info "Linking other configuration files..."

# Automatically link modular tool config directories
for tool_dir in "$DOTFILES_DIR"/*/; do
  # Skip .git, zsh_configs, and nushell directories (handled separately)
  if [ ! -d "$tool_dir" ] || [[ "$tool_dir" == *".git/"* ]] || [[ "$tool_dir" == *"zsh_configs/"* ]] || [[ "$tool_dir" == *"nushell/"* ]]; then
    continue
  fi

  tool_name=$(basename "$tool_dir")

  # Case 1: Configuration in .config/TOOL_NAME or .config/TOOL_NAME.ext
  # This covers kitty, nvim, bat, yazi, starship, tmux
  if [ -d "${tool_dir}.config/" ]; then
    source_item_config=$(find "${tool_dir}.config/" -mindepth 1 -maxdepth 1 2>/dev/null)
    if [ -n "$source_item_config" ]; then
      target_name=$(basename "$source_item_config")
      backup_and_link "$source_item_config" "${HOME}/.config/${target_name}"
    fi
  fi

  # Case 2: Configuration in .TOOL_NAME (e.g., .gemini)
  # This covers gemini
  source_item_dot="${tool_dir}.${tool_name}"
  if [ -d "$source_item_dot" ] || [ -f "$source_item_dot" ]; then
    backup_and_link "$source_item_dot" "${HOME}/.${tool_name}"
  fi
done

# Link custom zsh configuration files
ZSH_CONF_SOURCE_DIR="$DOTFILES_DIR/zsh_configs"
ZSH_CONF_TARGET_DIR="$HOME/.config/zsh/conf.d"
if [ -d "$ZSH_CONF_SOURCE_DIR" ]; then
  echo_info "Linking custom Zsh configurations..."
  mkdir -p "$ZSH_CONF_TARGET_DIR"
  for conf_file in "$ZSH_CONF_SOURCE_DIR"/*.zsh; do
    if [ -f "$conf_file" ]; then
      backup_and_link "$conf_file" "$ZSH_CONF_TARGET_DIR/$(basename "$conf_file")"
    fi
  done
fi

# Link Nushell configuration
NUSHELL_SOURCE_DIR="$DOTFILES_DIR/nushell"
NUSHELL_TARGET_DIR="$HOME/.config/nushell"
if [ -d "$NUSHELL_SOURCE_DIR" ]; then
  echo_info "Linking Nushell configuration..."
  backup_and_link "$NUSHELL_SOURCE_DIR" "$NUSHELL_TARGET_DIR"
  echo_success "Nushell configuration linked."
fi

echo_success "All config files are linked."

# 4. Build Caches
echo_info "Building caches for tools..."
if command -v bat &>/dev/null; then
  set +e
  bat cache --build
  BAT_CACHE_STATUS=$?
  set -e

  if [ $BAT_CACHE_STATUS -ne 0 ]; then
    echo_warning "Warning: 'bat cache --build' failed. Syntax highlighting may not work optimally."
  else
    echo_success "Bat cache rebuilt."
  fi
else
  echo_warning "Warning: 'bat' command not found. Skipping cache build."
fi

# 5. Install or Update Zsh Plugins
echo_info "Installing or updating Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# List of Zsh plugins to install
ZSH_PLUGINS=(
  "https://github.com/zsh-users/zsh-syntax-highlighting.git"
  "https://github.com/zsh-users/zsh-autosuggestions.git"
  "https://github.com/zsh-users/zsh-completions.git"
  "https://github.com/zsh-users/zsh-history-substring-search.git"
)

# Install or update each plugin
for repo_url in "${ZSH_PLUGINS[@]}"; do
  plugin_dir_name=$(basename "$repo_url" .git)
  target_dir="${ZSH_CUSTOM}/plugins/${plugin_dir_name}"
  if [ -d "$target_dir" ]; then
    (cd "$target_dir" && git pull)
  else
    git clone "$repo_url" "$target_dir"
  fi
done
echo_success "Zsh plugins are up to date."

# 6. Install Node.js LTS version
echo_info "Installing latest Node.js LTS via 'n'..."
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
n lts
echo_success "Node.js LTS is installed."

# 7. Install tools
echo_info "Installing tools..."
curl -fsSL https://bun.sh/install | bash
curl -fsSL https://claude.ai/install.sh | bash
curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
echo_success "Tools installed."

# 8. Setup Starship for Nushell
if command -v starship &>/dev/null; then
  echo_info "Setting up Starship for Nushell..."
  mkdir -p ~/.cache/starship
  starship init nu > ~/.cache/starship/init.nu
  echo_success "Starship configuration for Nushell generated."
else
  echo_warning "Starship not found. Skipping Nushell Starship setup."
fi

# --- Installation End ---
echo_info "-------------------------------------------------"
echo_success "Setup complete!"
echo ""
echo_info "Your Zsh shell is configured and ready to use with vi mode."
echo_info "Nushell is available for data manipulation tasks - run 'nu' to start."
echo ""
echo_info "Restart your terminal to apply all changes."
