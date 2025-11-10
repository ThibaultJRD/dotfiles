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

# --- Secrets Management ---
# Add any secret environment variables you want the script to manage here.
SECRETS_TO_MANAGE=(
  # "GEMINI_API_KEY"
  # "ANOTHER_API_KEY" # Example: Add more keys here in the future
)

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

# Function to extract template content from .zshrc (without API keys)
extract_template_content() {
  local zshrc_file=$1
  if [ ! -f "$zshrc_file" ]; then
    echo ""
    return
  fi

  # Extract everything before the local secrets marker
  awk '/^# Local-only secrets \(not in Git\)/{exit} {print}' "$zshrc_file" | sed '/^[[:space:]]*$/d'
}

# Function to extract secret value from .zshrc
extract_secret_value() {
  local zshrc_file=$1
  local key_name=$2
  if [ ! -f "$zshrc_file" ]; then
    echo ""
    return
  fi

  # Look for the export line and extract the value between quotes
  grep "^export $key_name=" "$zshrc_file" | head -1 | sed 's/^export [^=]*="\(.*\)"$/\1/'
}

# Function to remove all instances of a secret from .zshrc
remove_secret_from_zshrc() {
  local zshrc_file=$1
  local key_name=$2

  # Create a temporary file without the secret entries and the marker if it becomes empty
  awk -v key="$key_name" '
    BEGIN { in_secrets = 0; skip_line = 0 }
    /^# Local-only secrets \(not in Git\)/ { 
      secrets_marker_line = NR
      in_secrets = 1
      print
      next
    }
    in_secrets && /^export / && $0 ~ "^export " key "=" {
      skip_line = 1
      next
    }
    in_secrets && /^[[:space:]]*$/ && skip_line {
      skip_line = 0
      next
    }
    in_secrets && /^[^#]/ && !/^export/ && !/^[[:space:]]*$/ {
      in_secrets = 0
    }
    !skip_line { print }
  ' "$zshrc_file" >"$zshrc_file.tmp" && mv "$zshrc_file.tmp" "$zshrc_file"
}

# Function to check if zshrc template has changed
zshrc_template_changed() {
  local existing_zshrc="$HOME/.zshrc"
  local template_zshrc="$DOTFILES_DIR/.zshrc"

  if [ ! -f "$existing_zshrc" ]; then
    echo_debug "No existing .zshrc found, template change detected"
    return 0 # Consider as changed if no existing file
  fi

  local existing_template_content=$(extract_template_content "$existing_zshrc")
  local new_template_content=$(extract_template_content "$template_zshrc")

  if [ "$existing_template_content" = "$new_template_content" ]; then
    echo_debug ".zshrc template content is identical, no backup needed"
    return 1 # No change
  else
    echo_debug ".zshrc template content differs, backup needed"
    return 0 # Changed
  fi
}

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

# 5. Setup Zsh Configuration and API Keys
echo_info "Setting up Zsh configuration and local secrets..."

# Preserve existing secrets using standard arrays for macOS compatibility
declare -a preserved_keys=()
declare -a preserved_values=()
if [ -f "$HOME/.zshrc" ]; then
  for key_name in "${SECRETS_TO_MANAGE[@]}"; do
    value=$(extract_secret_value "$HOME/.zshrc" "$key_name")
    if [ -n "$value" ]; then
      preserved_keys+=("$key_name")
      preserved_values+=("$value")
      echo "Found existing $key_name. Preserving it."
      # Remove all instances of this key from the file to avoid duplicates
      remove_secret_from_zshrc "$HOME/.zshrc" "$key_name"
    fi
  done
fi

# Check if template has changed before backing up
if zshrc_template_changed; then
  # Template has changed, backup and replace
  if [ -f "$HOME/.zshrc" ]; then
    echo "Backing up existing ~/.zshrc to ~/.zshrc.bak.$BACKUP_DATE (template changed)"
    mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$BACKUP_DATE"
  fi
  cp "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  echo_success "Updated .zshrc template from repository."
else
  # Template hasn't changed, only update if no existing file
  if [ ! -f "$HOME/.zshrc" ]; then
    cp "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    echo_success "Copied .zshrc template to home directory."
  else
    echo_success ".zshrc template is up to date, preserving existing file."
  fi
fi

# Handle API keys: re-apply preserved keys or prompt for new ones.
LOCAL_ONLY_MARKER="# Local-only secrets (not in Git)"

# Re-apply all preserved keys first
if ((${#preserved_keys[@]} > 0)); then
  # Add the marker only if it's not there yet
  if ! grep -q "$LOCAL_ONLY_MARKER" "$HOME/.zshrc"; then
    echo -e "\n$LOCAL_ONLY_MARKER" >>"$HOME/.zshrc"
  fi
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

# Automatically link modular tool config directories
for tool_dir in "$DOTFILES_DIR"/*/; do
  # Skip .git and zsh_configs directories
  if [ ! -d "$tool_dir" ] || [[ "$tool_dir" == *".git/"* ]] || [[ "$tool_dir" == *"zsh_configs/"* ]]; then
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

# 10. Install Claude Code
echo_info "Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash
echo_success "Claude Code installed."

# --- Installation End ---
echo_info "-------------------------------------------------"
echo_success "Setup complete!"
echo_info "Please restart your terminal or run 'source ~/.zshrc' to apply all changes."
echo_info "To test your installation, run: ./test.sh"

# Clear the trap on successful completion
trap - ERR
