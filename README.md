# 🏠 Personal Dotfiles

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-Sonoma+-blue.svg)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://zsh.sourceforge.io/)
[![Theme](https://img.shields.io/badge/Theme-Catppuccin-pink.svg)](https://github.com/catppuccin)

<img width="476" alt="Modern terminal setup with Catppuccin theme" src="https://github.com/user-attachments/assets/c149ee55-8844-40d3-a833-a63e136217a2" />

A modern, automated dotfiles setup for macOS that creates a beautiful and productive terminal environment. Features a consistent Catppuccin theme, powerful CLI tools, and seamless integration between all components.

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Customization](#-customization)
- [Included Software](#-included-software)
- [Fonts](#-fonts)
- [Troubleshooting](#-troubleshooting)
- [Uninstallation](#-uninstallation)
- [License](#-license)

## ⚡ Quick Start

```bash
# Clone and install
git clone https://github.com/ThibaultJRD/dotfiles.git
cd dotfiles
./install.sh
```

> **Note:** The script will backup your existing configs before making changes.

## ✨ Features

### 🖥️ Terminal Environment

- **[Kitty](https://sw.kovidgoyal.net/kitty/)** - GPU-accelerated terminal emulator
- **[Zsh](https://zsh.sourceforge.io/) + [Oh My Zsh](https://ohmyz.sh/)** - Enhanced shell with plugins
- **[Starship](https://starship.rs/)** - Lightning-fast, customizable prompt
- **[Tmux](https://github.com/tmux/tmux)** - Advanced terminal multiplexer with rich plugin ecosystem

#### 🔧 Tmux Configuration

A powerful tmux setup featuring 12+ plugins for enhanced productivity, session management, and system monitoring:

**Essential Plugins:**
- **[tmux-sensible](https://github.com/tmux-plugins/tmux-sensible)** - Sensible default configurations
- **[tmux-yank](https://github.com/tmux-plugins/tmux-yank)** - Enhanced system clipboard integration
- **[vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)** - Seamless navigation between tmux panes and vim splits
- **[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)** - Persist tmux sessions across system restarts
- **[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)** - Automatic session saving every 15 minutes

**Theme & UI Enhancement:**
- **[catppuccin/tmux](https://github.com/catppuccin/tmux)** - Beautiful Catppuccin theme integration
- **[tmux-nerd-font-window-name](https://github.com/joshmedeski/tmux-nerd-font-window-name)** - Nerd Font icons for window names
- **[tmux-which-key](https://github.com/alexwforsythe/tmux-which-key)** - Interactive key binding help (`Prefix + Space`)

**System Monitoring:**
- **[tmux-cpu](https://github.com/tmux-plugins/tmux-cpu)** - Real-time CPU usage display
- **[tmux-battery](https://github.com/tmux-plugins/tmux-battery)** - Battery status (when available)
- **[tmux-primary-ip](https://github.com/dreknix/tmux-primary-ip)** - Network interface IP address display

**Advanced Tools:**
- **[tmux-sessionx](https://github.com/omerxx/tmux-sessionx)** - Fuzzy session manager with zoxide integration (`Prefix + o`)

**Key Features:**
- **Custom Prefix:** `Ctrl+s` for ergonomic access
- **Smart Window Splitting:** `|` (horizontal) and `-` (vertical) with current path preservation
- **Vim-style Navigation:** `Ctrl+h/j/k/l` seamlessly between tmux panes and Neovim
- **Session Persistence:** Automatic save/restore with Neovim session support
- **Status Bar:** Top-positioned with CPU, memory, IP, and battery monitoring
- **Mouse Support:** Enabled for pane selection and resizing

### 🎨 Consistent Theming

- **[Catppuccin Mocha](https://github.com/catppuccin)** theme across all tools
- Seamless visual integration between terminal, editor, and file manager
- Carefully selected color palette for reduced eye strain

### 🛠️ Development Tools

- **[Neovim (LazyVim)](https://neovim.io/)** - Modern, extensible text editor
- **[Lazygit](https://github.com/jesseduffield/lazygit)** - Terminal UI for Git operations
- **Node.js, Go, npm/yarn/bun** - Complete development environment

### 📁 File Management

- **[Yazi](https://github.com/sxyazi/yazi)** - Fast terminal file manager with previews
- **[Eza](https://github.com/eza-community/eza)** - Modern `ls` replacement with icons
- **[fzf](https://github.com/junegunn/fzf)** - Fuzzy finder for files and history
- **[Zoxide](https://github.com/ajeetdsouza/zoxide)** - Smart directory navigation

### 🔧 Enhanced CLI Experience

- **[Bat](https://github.com/sharkdp/bat)** - Syntax-highlighted `cat` replacement
- Intelligent autosuggestions and syntax highlighting
- Rich media previews for images, videos, and documents
- Extensive shell completions and aliases

## 📋 Requirements

- macOS Sonoma (14.0) or later
- Git (for cloning the repository)
- Internet connection (for downloading dependencies)

## 🚀 Installation

> **⚠️ Backup Notice:** The script automatically creates timestamped backups of existing configuration files before making changes.

### Option 1: Full Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/ThibaultJRD/dotfiles.git
cd dotfiles

# Run the installation script
./install.sh

# Restart your terminal
# Set a Nerd Font in your terminal settings for proper icon display
```

### Option 2: Preview Changes (Dry Run)

```bash
# See what changes would be made without applying them
DRY_RUN=true ./install.sh
```

### Option 3: Install Dependencies Only

```bash
# Install Homebrew packages without configuration
brew bundle --file=Brewfile
```

### Post-Installation

1. **Configure Terminal Font**: Set a Nerd Font in your terminal preferences
2. **Test Installation**: Run `./test.sh` to verify everything works
3. **Start Tmux**: Launch `tmux` for session management with automatic plugin installation
4. **Explore**: Try `y` (yazi), `lg` (lazygit), `v` (neovim)

## 🔧 Customization

<details>
<summary><strong>🎨 Changing Themes</strong></summary>

### Starship Prompt

```bash
# Edit starship/.config/starship.toml
palette = 'your_preferred_palette'  # Change from 'catppuccin_mocha'
```

### Kitty Terminal

```bash
# Edit kitty/.config/kitty/kitty.conf
include your-theme.conf  # Replace the theme include line
```

### Tmux

```bash
# Edit tmux/.config/tmux/tmux.conf
set -g @catppuccin_flavor 'your_flavor'  # Change from 'macchiato'

# Customize key bindings
set -g prefix C-a  # Change prefix from C-s to C-a

# Disable specific plugins
# set -g @plugin 'tmux-plugins/tmux-cpu'  # Comment out unwanted plugins
```

</details>

<details>
<summary><strong>⚙️ Adding Custom Configuration</strong></summary>

### Custom Aliases and Functions

```bash
# Create custom Zsh config (preserved during updates)
mkdir -p ~/.config/zsh/conf.d
echo 'alias myalias="my command"' > ~/.config/zsh/conf.d/custom.zsh
```

### Environment Variables

```bash
# Add to ~/.zshrc (automatically preserved by install script)
export YOUR_VAR="your_value"
export API_KEY="your_secret_key"
```

### Adding New Tools

1. **Add to Brewfile:**

   ```bash
   echo 'brew "your-tool"' >> Brewfile
   ```

2. **Create configuration:**

   ```bash
   mkdir -p your-tool/.config/your-tool
   # Add your config files here
   ```

3. **Update install script** if needed for symlinks

</details>

<details>
<summary><strong>🧪 Testing and Validation</strong></summary>

### Test Installation

```bash
./test.sh  # Comprehensive validation suite
```

The test script validates:
- **Homebrew**: Installation and PATH configuration
- **Shell Configuration**: Zsh, .zshrc, Oh My Zsh, Starship
- **Core Tools**: All 25+ CLI tools and applications
- **Configuration Files**: Symlinks and config file existence
- **Environment**: Variables, PATH, and shell integration
- **Aliases**: All custom aliases and functions
- **Node.js**: n version manager and npm setup
- **Fonts**: Nerd Font installation verification
- **Zsh Plugins**: All custom plugins properly installed

### Preview Changes

```bash
DRY_RUN=true ./install.sh  # See what would change without applying
```

### Reinstall After Changes

```bash
./install.sh  # Safely reinstall with automatic backups
```

</details>

## 🛠️ Included Software

<details>
<summary><strong>🖥️ Terminal & Shell</strong></summary>

| Tool         | Command | Description                                 |
| ------------ | ------- | ------------------------------------------- |
| **Kitty**    | `kitty` | GPU-accelerated terminal emulator           |
| **Zsh**      | `zsh`   | Enhanced shell with Oh My Zsh framework     |
| **Starship** | -       | Cross-shell prompt with Git integration     |
| **Tmux**     | `tmux`  | Advanced terminal multiplexer with 12+ plugins |
| **Homebrew** | `brew`  | macOS package manager                       |

### Zsh Plugins

- **git** - Git aliases and functions
- **fzf** - Fuzzy finder integration (`Ctrl+R`)
- **sudo** - Add sudo with `Esc` twice
- **zsh-completions** - Extended tab completions
- **zsh-syntax-highlighting** - Real-time syntax highlighting
- **zsh-autosuggestions** - History-based suggestions
- **history-substring-search** - Enhanced history search

### Shell Aliases & Functions

**File Operations:**
- `cat` → `bat` - Syntax-highlighted file viewing
- `ls` → `eza --color=always --long --git --icons` - Enhanced file listing
- `la` → `eza -l --icons --git -a --group-directories-first` - All files with details
- `lt` → `eza --tree --level=2 --long --icons --git` - Tree view (2 levels)

**Development Tools:**
- `v` → `nvim` - Quick Neovim access
- `lg` → `lazygit` - Git TUI launcher

**Smart Functions:**
- `y()` - Yazi with directory navigation (changes shell directory on exit)
- `z <directory>` - Smart directory jumping with zoxide
- `killports` - Kill processes by port number or range (with auto-completion)
- `listports` - List active network connections and ports
- `cleanup` - Interactive development environment cleanup tool (TUI)

</details>

<details>
<summary><strong>📝 Development Tools</strong></summary>

| Tool             | Alias       | Description                                  |
| ---------------- | ----------- | -------------------------------------------- |
| **Neovim**       | `nvim`, `v` | Modern text editor with LazyVim              |
| **Lazygit**      | `lg`        | Terminal UI for Git operations               |
| **Lazydocker**   | -           | Terminal UI for Docker management            |
| **Cleanup Tool** | `cleanup`   | Interactive development cache cleanup (Go/TUI) |
| **Node.js**      | `node`      | JavaScript runtime (via `n` version manager) |
| **Go**           | `go`        | Go programming language                      |
| **npm/yarn/bun** | -           | JavaScript package managers                  |
| **Glow**         | `glow`      | Terminal markdown renderer                   |
| **Visual Studio Code** | `code` | GUI code editor                             |

</details>

<details>
<summary><strong>📁 File Management</strong></summary>

| Tool       | Alias            | Description                         |
| ---------- | ---------------- | ----------------------------------- |
| **Yazi**   | `y`              | Terminal file manager with previews and smart directory navigation |
| **Eza**    | `ls`, `la`, `lt` | Modern `ls` with icons and colors   |
| **Zoxide** | `z <dir>`        | Smart directory navigation          |
| **fzf**    | `fzf`            | Fuzzy finder with Catppuccin theme and advanced previews |

#### 🎯 Advanced fzf Configuration

The fzf setup includes sophisticated features for enhanced productivity:

**Theme & Appearance:**
- **Catppuccin Macchiato** theme integration for consistent styling
- Custom color scheme matching the overall dotfiles theme
- Border and highlight colors optimized for readability

**Enhanced Previews:**
- **File previews** with `bat` syntax highlighting (first 500 lines)
- **Directory previews** with `eza` tree structure (2 levels deep)
- **Tab completion previews** for different commands (`cd`, `ssh`, environment variables)

**Smart File Discovery:**
- Uses `fd` instead of `find` for better performance
- Includes hidden files and directories (configurable)
- Excludes `.git` directories automatically
- Strips current working directory prefix for cleaner output

**Key Bindings:**
- `Ctrl+T` - Find files with preview
- `Alt+C` - Find directories with tree preview  
- `Ctrl+R` - Enhanced history search with Oh My Zsh integration

#### 🗂️ Smart Yazi Integration

The `y` function provides seamless directory navigation:
- **Auto-navigation**: Changes shell directory to last browsed location on exit
- **Temporary file handling**: Uses secure temporary files for directory tracking
- **Path preservation**: Maintains current working directory context

### Yazi Preview Support

- **ffmpeg** - Video thumbnails
- **imagemagick** - Image previews
- **poppler** - PDF previews
- **resvg** - SVG previews
- **sevenzip** - Archive previews
- **jq** - JSON formatting

</details>

<details>
<summary><strong>🔧 CLI Utilities</strong></summary>

| Tool        | Alias  | Description                    |
| ----------- | ------ | ------------------------------ |
| **Bat**     | `cat`  | Syntax-highlighted file viewer |
| **Ripgrep** | `rg`   | Fast text search tool          |
| **fd**      | `find` | Fast file finder               |
| **jq**      | `jq`   | JSON processor and formatter   |
| **yq**      | `yq`   | YAML processor and formatter   |
| **Docker**  | `docker` | Containerization platform    |

</details>

## 🔤 Fonts

**Nerd Fonts** are automatically installed for proper icon display:

- **Caskaydia Cove Nerd Font** - Cascadia Code with icons
- **Victor Mono Nerd Font** - Cursive italic programming font
- **JetBrains Mono NL Nerd Font** - Clean, readable monospace
- **Symbols Only Nerd Font** - Icon fallback font

**Configuration**: The default font is set in `kitty.conf`, but you can change it in your terminal preferences.

## 🩺 Troubleshooting

<details>
<summary><strong>Common Issues</strong></summary>

### Icons Not Displaying

- Ensure you're using a Nerd Font in your terminal settings
- Restart your terminal after font installation
- Check if the font is properly installed: `fc-list | grep -i nerd`

### Zsh Plugins Not Loading

- Verify Oh My Zsh installation: `ls ~/.oh-my-zsh`
- Check plugin directory: `ls ~/.oh-my-zsh/custom/plugins`
- Reload shell: `source ~/.zshrc`

### Tool Not Found After Installation

- Check if tool is in PATH: `which <tool-name>`
- Restart terminal or run: `source ~/.zshrc`
- Verify Homebrew installation: `brew doctor`

### Configuration Not Applied

- Check if symlinks were created: `ls -la ~/.config/`
- Verify backup files exist: `ls -la ~/*.backup.*`
- Re-run installation: `./install.sh`

</details>

<details>
<summary><strong>Reset and Debug</strong></summary>

### Test Installation

```bash
./test.sh  # Run diagnostic tests
```

### Check Dependencies

```bash
brew doctor  # Check Homebrew health
brew list    # List installed packages
```

### View Installation Logs

```bash
# Check for error messages during installation
./install.sh 2>&1 | tee install.log
```

</details>

## 🗑️ Uninstallation

<details>
<summary><strong>Remove Dotfiles Configuration</strong></summary>

### Restore Backups

```bash
# Restore backed up configurations
for backup in ~/.*.backup.*; do
  original="${backup%.backup.*}"
  mv "$backup" "$original"
done
```

### Remove Symlinks

```bash
# Remove symlinks (be careful!)
find ~/.config -type l -ls | grep dotfiles
# Remove specific symlinks:
# rm ~/.config/kitty ~/.config/nvim ~/.config/yazi # etc.
```

### Uninstall Homebrew Packages

```bash
# Remove packages (optional)
brew uninstall --ignore-dependencies $(brew list)
```

### Clean Oh My Zsh

```bash
# Remove Oh My Zsh installation
rm -rf ~/.oh-my-zsh
```

</details>

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <strong>Happy coding! 🚀</strong>
  <p>Built with ❤️ by <a href="https://github.com/ThibaultJRD">ThibaultJRD</a></p>
</div>

