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
CONFIG_SOURCE_DIR="$DOTFILES_DIR/.config"
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

# 3. Install dependencies from Brewfile
echo_info "Installing all dependencies from Brewfile..."
# Temporarily disable 'exit on error' for brew bundle, as it can fail on
# a single package but we want the script to continue.
set +e
brew bundle --file="$DOTFILES_DIR/Brewfile"
BREW_BUNDLE_STATUS=$? # Capture the exit code
set -e                # Re-enable 'exit on error'

if [ $BREW_BUNDLE_STATUS -ne 0 ]; then
  echo_info "Warning: 'brew bundle' finished with errors. This can happen if packages like 'n' or fonts were already installed. Please review the log above. Continuing with setup..."
else
  echo_success "All Homebrew dependencies are installed."
fi

# 4. Link Configuration Files
echo_info "Linking configuration files..."
backup_and_link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
backup_and_link "$CONFIG_SOURCE_DIR/kitty" "$CONFIG_TARGET_DIR/kitty"
backup_and_link "$CONFIG_SOURCE_DIR/tmux" "$CONFIG_TARGET_DIR/tmux"
backup_and_link "$CONFIG_SOURCE_DIR/starship.toml" "$CONFIG_TARGET_DIR/starship.toml"
backup_and_link "$CONFIG_SOURCE_DIR/nvim" "$CONFIG_TARGET_DIR/nvim"
echo_success "All config files linked."

# 5. Install or Update Zsh Plugins
echo_info "Installing or updating Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
SYNTAX_HIGHLIGHTING_DIR="${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
AUTOSUGGESTIONS_DIR="${ZSH_CUSTOM}/plugins/zsh-autosuggestions"

# zsh-syntax-highlighting
if [ -d "$SYNTAX_HIGHLIGHTING_DIR" ]; then
  (cd "$SYNTAX_HIGHLIGHTING_DIR" && git pull)
else
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_HIGHLIGHTING_DIR"
fi

# zsh-autosuggestions
if [ -d "$AUTOSUGGESTIONS_DIR" ]; then
  (cd "$AUTOSUGGESTIONS_DIR" && git pull)
else
  git clone https://github.com/zsh-users/zsh-autosuggestions.git "$AUTOSUGGESTIONS_DIR"
fi
echo_success "Zsh plugins are up to date."

# 6. Install Node.js LTS version
echo_info "Installing latest Node.js LTS via 'n'..."
# CORRECTED: Set the necessary PATH for 'n' directly in the script
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
n lts
echo_success "Node.js LTS is installed."

# --- Installation End ---
echo_info "-------------------------------------------------"
echo_success "Setup complete!"
echo_info "Please restart your terminal or run 'source ~/.zshrc' to apply all changes."
