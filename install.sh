#!/bin/bash

# ==============================================================================
# Dotfiles Installation Script
# ==============================================================================
# This script automates the setup of the development environment by symlinking
# configuration files and installing dependencies via a Brewfile.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Utility Functions ---
# For printing informational headers
echo_info() {
  printf "\n\033[1;34m%s\033[0m\n" "$1"
}

# For printing success messages
echo_success() {
  printf "\033[1;32m✓ %s\033[0m\n" "$1"
}

# --- Variables ---
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CONFIG_TARGET_DIR="$HOME/.config"
BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")

# --- Pre-run Check and Backup Function ---
backup_and_link() {
  local source_path=$1
  local target_path=$2

  if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
    echo "Backing up existing '$target_path' to '$target_path.bak.$BACKUP_DATE'"
    mv "$target_path" "$target_path.bak.$BACKUP_DATE"
  fi

  if [ -L "$target_path" ]; then
    rm "$target_path"
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
  echo_success "Linked '$source_path' to '$target_path'"
}

# --- Installation Start ---
echo_info "Starting dotfiles setup..."
echo "Your existing configs will be backed up with the suffix .bak.$BACKUP_DATE"

# 1. Install Homebrew
if ! command -v brew &>/dev/null; then
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
  brew update
fi

# 2. Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo_info "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo_success "Oh My Zsh installed."
else
  echo_success "Oh My Zsh is already installed."
fi

# 3. Tap necessary Homebrew repositories
echo_info "Tapping Homebrew repositories..."
brew tap oven-sh/bun
echo_success "Required taps are in place."

# 4. Install dependencies from Brewfile
echo_info "Installing all dependencies from Brewfile..."
set +e
brew bundle --file="$DOTFILES_DIR/Brewfile"
BREW_BUNDLE_STATUS=$?
set -e

if [ $BREW_BUNDLE_STATUS -ne 0 ]; then
  echo_info "Warning: 'brew bundle' finished with errors. Continuing with setup..."
else
  echo_success "All Homebrew dependencies are installed."
fi

# 5. Link Configuration Files
echo_info "Linking configuration files..."

# Handle .zshrc specifically, as it's in the root
backup_and_link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Automatically link all modular config directories
# This loop finds each tool's directory (like kitty/, nvim/, etc.) at the root,
# finds the actual config inside its .config/ subfolder, and links it.
for tool_dir in "$DOTFILES_DIR"/*/; do
  # Continue if the item is not a directory or is the .git directory
  if [ ! -d "$tool_dir" ] || [[ "$tool_dir" == *".git/"* ]]; then
    continue
  fi

  # Find the actual config file or directory inside the tool's .config folder
  source_item=$(find "$tool_dir.config/" -mindepth 1 -maxdepth 1 2>/dev/null)

  # If a config item was found, link it
  if [ -n "$source_item" ]; then
    target_name=$(basename "$source_item")
    backup_and_link "$source_item" "$CONFIG_TARGET_DIR/$target_name"
  fi
done
echo_success "All config files are linked."

# 6. Install or Update Zsh Plugins
echo_info "Installing or updating Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
# Function to simplify plugin install/update
install_or_update_plugin() {
  local repo_url=$1
  local plugin_dir_name=$(basename "$repo_url" .git)
  local target_dir="${ZSH_CUSTOM}/plugins/${plugin_dir_name}"
  if [ -d "$target_dir" ]; then
    (cd "$target_dir" && git pull)
  else
    git clone "$repo_url" "$target_dir"
  fi
}
install_or_update_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git
install_or_update_plugin https://github.com/zsh-users/zsh-autosuggestions.git
install_or_update_plugin https://github.com/zsh-users/zsh-completions.git
install_or_update_plugin https://github.com/zsh-users/zsh-history-substring-search.git
echo_success "Zsh plugins are up to date."

# 7. Install Node.js LTS version
echo_info "Installing latest Node.js LTS via 'n'..."
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
n lts
echo_success "Node.js LTS is installed."

# --- Installation End ---
echo_info "-------------------------------------------------"
echo_success "Setup complete!"
echo_info "Please restart your terminal or run 'source ~/.zshrc' to apply all changes."
