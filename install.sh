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
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"

# No secrets management needed - keep configs simple

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

# Rollback function
rollback_changes() {
  if [ -f "$ROLLBACK_LOG" ]; then
    echo_warning "Rolling back changes..."
    while IFS= read -r line; do
      if [[ "$line" == BACKUP:* ]]; then
        source_backup="${line#BACKUP:}"
        target_file="${source_backup%.bak.$BACKUP_DATE}"
        if [ -f "$source_backup" ]; then
          echo_debug "Restoring $target_file from $source_backup"
          mv "$source_backup" "$target_file"
        fi
      elif [[ "$line" == LINK:* ]]; then
        link_file="${line#LINK:}"
        if [ -L "$link_file" ]; then
          echo_debug "Removing symlink $link_file"
          rm "$link_file"
        fi
      fi
    done <"$ROLLBACK_LOG"
    echo_success "Rollback completed"
  fi
  exit 1
}

# Set up error handling
trap rollback_changes ERR

# --- Variables ---
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/.dotfiles_backup_$BACKUP_DATE"
ROLLBACK_LOG="$BACKUP_DIR/rollback.log"

# --- Pre-run Check and Backup Function ---
backup_and_link() {
  local source_path=$1
  local target_path=$2

  # Dry run mode
  if [ "$DRY_RUN" = "true" ]; then
    echo_info "[DRY RUN] Would link '$source_path' to '$target_path'"
    return 0
  fi

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
    echo "BACKUP:$backup_file" >>"$ROLLBACK_LOG"
  fi

  # If target is a symlink (but not to the correct source, handled above), remove it
  if [ -L "$target_path" ]; then
    echo "Removing old symlink '$target_path'"
    rm "$target_path"
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
  echo "LINK:$target_path" >>"$ROLLBACK_LOG"
  echo_success "Linked '$source_path' to '$target_path'"
}

# Simplified .zshrc management - no secrets handling needed

# --- Installation Start ---
if [ "$DRY_RUN" = "true" ]; then
  echo_info "DRY RUN MODE: No changes will be made to your system"
else
  echo_info "Starting dotfiles setup..."
  echo "Your existing configs will be backed up with the suffix .bak.$BACKUP_DATE"
fi

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
  trap - ERR
  set +e
  brew update
  BREW_UPDATE_STATUS=$?
  set -e
  trap rollback_changes ERR

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

# 3. Tap necessary Homebrew repositories
echo_info "Tapping Homebrew repositories..."
trap - ERR
set +e
brew tap oven-sh/bun
BREW_TAP_STATUS=$?
set -e
trap rollback_changes ERR

if [ $BREW_TAP_STATUS -ne 0 ]; then
  echo_warning "Warning: 'brew tap oven-sh/bun' failed. Some packages may not be available."
else
  echo_success "Required taps are in place."
fi

# 4. Install dependencies from Brewfile
echo_info "Installing all dependencies from Brewfile..."
trap - ERR
set +e
brew bundle --file="$DOTFILES_DIR/Brewfile"
BREW_BUNDLE_STATUS=$?
set -e
trap rollback_changes ERR

if [ $BREW_BUNDLE_STATUS -ne 0 ]; then
  echo_warning "Warning: 'brew bundle' finished with errors. Some packages may not be installed."
  echo_info "Continuing with setup - you can manually install missing packages later."
else
  echo_success "All Homebrew dependencies are installed."
fi

# 5. Setup Zsh Configuration
echo_info "Setting up Zsh configuration..."

# Simple backup and copy approach
if [ -f "$HOME/.zshrc" ]; then
  if ! cmp -s "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"; then
    echo "Backing up existing ~/.zshrc to ~/.zshrc.bak.$BACKUP_DATE"
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$BACKUP_DATE"
    cp "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    echo_success "Updated .zshrc from repository."
  else
    echo_success ".zshrc is already up to date."
  fi
else
  cp "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  echo_success "Copied .zshrc to home directory."
fi

# 6. Link Other Configuration Files
echo_info "Linking other configuration files..."

# Automatically link modular tool config directories
for tool_dir in "$DOTFILES_DIR"/*/; do
  # Skip .git, zsh_configs, fish, and nushell directories (handled separately)
  if [ ! -d "$tool_dir" ] || [[ "$tool_dir" == *".git/"* ]] || [[ "$tool_dir" == *"zsh_configs/"* ]] || [[ "$tool_dir" == *"fish/"* ]] || [[ "$tool_dir" == *"nushell/"* ]]; then
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

# Link Fish shell configuration
FISH_SOURCE_DIR="$DOTFILES_DIR/fish"
FISH_TARGET_DIR="$HOME/.config/fish"
if [ -d "$FISH_SOURCE_DIR" ]; then
  echo_info "Linking Fish shell configuration..."
  backup_and_link "$FISH_SOURCE_DIR" "$FISH_TARGET_DIR"
  echo_success "Fish configuration linked."
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

# 7. Build Caches
echo_info "Building caches for tools..."
if command -v bat &>/dev/null; then
  trap - ERR
  set +e
  bat cache --build
  BAT_CACHE_STATUS=$?
  set -e
  trap rollback_changes ERR

  if [ $BAT_CACHE_STATUS -ne 0 ]; then
    echo_warning "Warning: 'bat cache --build' failed. Syntax highlighting may not work optimally."
  else
    echo_success "Bat cache rebuilt."
  fi
else
  echo_warning "Warning: 'bat' command not found. Skipping cache build."
fi

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

# 10. Install tools
echo_info "Installing tools..."
curl -fsSL https://claude.ai/install.sh | bash
curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
echo_success "Tools installed."

# 11. Setup Fish Shell
if command -v fish &>/dev/null; then
  echo_info "Setting up Fish shell..."

  # Add Fish to /etc/shells if not present
  FISH_PATH=$(which fish)
  if ! grep -q "^$FISH_PATH$" /etc/shells 2>/dev/null; then
    echo_info "Adding Fish to /etc/shells..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    echo_success "Fish added to /etc/shells"
  else
    echo_success "Fish is already in /etc/shells"
  fi

  # Check if Fish is already the default shell
  CURRENT_SHELL=$(basename "$SHELL")
  if [ "$CURRENT_SHELL" = "fish" ]; then
    echo_success "Fish is already your default shell"
  else
    # Offer to change default shell to Fish
    echo ""
    echo_info "Fish shell is installed and configured."
    echo_info "Would you like to set Fish as your default shell?"
    echo_info "Current shell: $SHELL"
    echo_info "New shell would be: $FISH_PATH"
    echo ""
    read -p "Change default shell to Fish? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      chsh -s "$FISH_PATH"
      echo_success "Default shell changed to Fish!"
      echo_info "Please restart your terminal for changes to take effect."
      echo_info "Your Zsh configuration is preserved and you can switch back anytime with: chsh -s \$(which zsh)"
    else
      echo_info "Keeping current shell. You can switch to Fish later with: chsh -s \$(which fish)"
      echo_info "Or just run 'fish' to try it temporarily."
    fi
  fi
else
  echo_warning "Fish shell not found. Run 'brew install fish' to install it."
fi

# --- Installation End ---
echo_info "-------------------------------------------------"
echo_success "Setup complete!"
echo ""
echo_info "Installed shells:"
echo_info "  • Zsh (current): source ~/.zshrc or restart terminal"
echo_info "  • Fish (recommended): Switch with 'chsh -s \$(which fish)' or run 'fish' to try"
echo_info "  • Nushell (data tasks): Run 'nu' to start or 'nu -c \"command\"' for one-off tasks"
echo ""
echo_info "See fish/README.md and nushell/README.md for usage guides."

# Clear the trap on successful completion
trap - ERR
