#!/bin/bash

# ==============================================================================
# Dotfiles Installation Script
# ==============================================================================
# This script automates the setup of my development environment by symlinking
# configuration files from this repository to their proper locations.
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
# The directory of this script, which is the root of the dotfiles repository.
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# Path to the .config directory in this repository
CONFIG_SOURCE_DIR="$DOTFILES_DIR/.config"
# Path to the system's .config directory
CONFIG_TARGET_DIR="$HOME/.config"
# Date for backup file names
BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")

# --- Pre-run Check and Backup Function ---
# Creates a backup of a file or directory before replacing it.
backup_and_link() {
  local source_path=$1
  local target_path=$2
  
  # If the target exists and is not already a symlink, create a backup
  if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
    echo "Backing up existing '$target_path' to '$target_path.bak.$BACKUP_DATE'"
    mv "$target_path" "$target_path.bak.$BACKUP_DATE"
  fi
  
  # Remove existing symlink if it exists
  if [ -L "$target_path" ]; then
    rm "$target_path"
  fi
  
  # Ensure parent directory of the target exists
  mkdir -p "$(dirname "$target_path")"
  
  # Create the symlink
  ln -s "$source_path" "$target_path"
  echo_success "Linked '$source_path' to '$target_path'"
}


# --- Installation Start ---

echo_info "Starting dotfiles setup..."
echo "Your existing configs will be backed up with the suffix .bak.$BACKUP_DATE"

# 1. Install Homebrew
if ! command -v brew &> /dev/null; then
  echo_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  echo_info "Adding Homebrew to PATH for this session and for future sessions..."
  # For Apple Silicon (ARM)
  if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  # For Intel (x86_64)
  else
    eval "$(/usr/local/bin/brew shellenv)"
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
  fi
  echo_success "Homebrew installed and configured."
else
  echo_success "Homebrew is already installed. Updating..."
  brew update
fi

# 2. Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo_info "Installing Oh My Zsh..."
  # The installer will create a default .zshrc, which we will replace.
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo_success "Oh My Zsh installed."
else
  echo_success "Oh My Zsh is already installed."
fi

# 3. Install Homebrew Packages & Fonts
echo_info "Installing Homebrew packages and fonts..."
brew install n neovim starship git bat lazygit fzf ripgrep fd luarocks tmux yq gh eza
brew tap homebrew/cask-fonts
brew install --cask font-caskaydia-cove-nerd-font font-victor-mono-nerd-font font-symbols-only-nerd-font
echo_success "Homebrew packages installed."

# 4. Link Configuration Files
echo_info "Linking configuration files..."
backup_and_link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
backup_and_link "$CONFIG_SOURCE_DIR/kitty" "$CONFIG_TARGET_DIR/kitty"
backup_and_link "$CONFIG_SOURCE_DIR/tmux" "$CONFIG_TARGET_DIR/tmux"
backup_and_link "$CONFIG_SOURCE_DIR/nvim" "$CONFIG_TARGET_DIR/nvim"
backup_and_link "$CONFIG_SOURCE_DIR/starship.toml" "$CONFIG_TARGET_DIR/starship.toml"
echo_success "All config files linked."

# 5. Install Zsh Plugins (as defined in your .zshrc)
echo_info "Cloning Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" || true
git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" || true
echo_success "Zsh plugins cloned."

# 6. Install Node.js tools
echo_info "Installing Yarn and Bun..."
# Source .zshrc to make 'n' available if it was just configured
source "$HOME/.zshrc"
# Install latest LTS Node.js via n
n lts
npm install -g yarn
curl -fsSL https://bun.sh/install | bash
echo_success "Yarn and Bun installed."

# --- Installation End ---
echo_info "-------------------------------------------------"
echo_success "Setup complete!"
echo_info "Please restart your terminal or run 'source ~/.zshrc' to apply all changes."
