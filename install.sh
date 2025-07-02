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
CONFIG_TARGET_DIR="$HOME/.config"
BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")

# --- Secrets Management ---
# Add any secret environment variables you want the script to manage here.
SECRETS_TO_MANAGE=(
  "GEMINI_API_KEY"
  # "ANOTHER_API_KEY" # Example: Add more keys here in the future
)

# --- Pre-run Check and Backup Function ---
backup_and_link() {
  local source_path=$1
  local target_path=$2

  # Check if the target is already a symlink to the source
  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    echo_success "Already linked '$source_path' to '$target_path'. Skipping."
    return 0
  fi

  # If target exists and is not a symlink, back it up
  if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
    echo_info "Backing up existing '$target_path' to '$target_path.bak.$BACKUP_DATE'"
    mv "$target_path" "$target_path.bak.$BACKUP_DATE"
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

# 5. Setup Zsh Configuration and API Keys
echo_info "Setting up Zsh configuration and local secrets..."

# Preserve existing secrets using standard arrays for macOS compatibility
declare -a preserved_keys=()
declare -a preserved_values=()
if [ -f "$HOME/.zshrc" ]; then
  for key_name in "${SECRETS_TO_MANAGE[@]}"; do
    if grep -q "$key_name" "$HOME/.zshrc"; then
      value=$(grep "$key_name" "$HOME/.zshrc" | cut -d'=' -f2 | tr -d '"')
      preserved_keys+=("$key_name")
      preserved_values+=("$value")
      echo "Found existing $key_name. Preserving it."
    fi
  done
fi

# Always update the base .zshrc from the repository.
if [ -f "$HOME/.zshrc" ]; then
  echo "Backing up existing ~/.zshrc to ~/.zshrc.bak.$BACKUP_DATE"
  mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$BACKUP_DATE"
fi
cp "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
echo_success "Copied .zshrc template to home directory."

# Handle API keys: re-apply preserved keys or prompt for new ones.
LOCAL_ONLY_MARKER="# Local-only secrets (not in Git)"

# Re-apply all preserved keys first
if ((${#preserved_keys[@]} > 0)); then
  echo -e "\n$LOCAL_ONLY_MARKER" >>"$HOME/.zshrc"
  for i in "${!preserved_keys[@]}"; do
    key_name="${preserved_keys[$i]}"
    key_value="${preserved_values[$i]}"
    echo "export $key_name=\"$key_value\"" >>"$HOME/.zshrc"
    echo_success "Restored existing $key_name."
  done
fi

# Now, prompt for any keys that are in the list but were not preserved
for key_name in "${SECRETS_TO_MANAGE[@]}"; do
  if ! grep -q "$key_name" "$HOME/.zshrc"; then
    echo_info "Setting up $key_name..."
    read -s -p "Enter your $key_name (will not be displayed): " new_key_value
    echo # Newline for cleaner output
    if [ -n "$new_key_value" ]; then
      # Add the marker only if it's not there yet
      if ! grep -q "$LOCAL_ONLY_MARKER" "$HOME/.zshrc"; then
        echo -e "\n$LOCAL_ONLY_MARKER" >>"$HOME/.zshrc"
      fi
      echo "export $key_name=\"$new_key_value\"" >>"$HOME/.zshrc"
      echo_success "$key_name saved to ~/.zshrc"
    else
      echo "No value entered for $key_name. Skipping."
    fi
  fi
done

# 6. Link Other Configuration Files
echo_info "Linking other configuration files..."

# Automatically link all modular tool config directories (kitty, nvim, etc.)
for tool_dir in "$DOTFILES_DIR"/*/; do
  if [ ! -d "$tool_dir" ] || [[ "$tool_dir" == *".git/"* ]] || [[ "$tool_dir" == *"zsh_configs/"* ]]; then
    continue
  fi
  source_item=$(find "$tool_dir.config/" -mindepth 1 -maxdepth 1 2>/dev/null)
  if [ -n "$source_item" ]; then
    target_name=$(basename "$source_item")
    backup_and_link "$source_item" "$CONFIG_TARGET_DIR/$target_name"
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

echo_success "All config files are linked."

# 7. Build Caches
echo_info "Building caches for tools..."
bat cache --build
echo_success "Bat cache rebuilt."

# 8. Install or Update Zsh Plugins
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

# 9. Install Node.js LTS version
echo_info "Installing latest Node.js LTS via 'n'..."
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
n lts
echo_success "Node.js LTS is installed."

# 10. Install Global NPM Packages
echo_info "Installing global NPM packages..."
npm install -g @google/gemini-cli
echo_success "Global NPM packages installed."

# --- Installation End ---
echo_info "-------------------------------------------------"
echo_success "Setup complete!"
echo_info "Please restart your terminal or run 'source ~/.zshrc' to apply all changes."
