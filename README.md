# My Personal Dotfiles

<img width="476" alt="Capture d’écran 2025-06-21 à 23 54 31" src="https://github.com/user-attachments/assets/c149ee55-8844-40d3-a833-a63e136217a2" />

This repository contains my personal configuration files (dotfiles) for creating a modern and productive terminal environment on macOS. The setup is automated via a simple installation script.

## ✨ Features

- **Terminal:** [Kitty](https://sw.kovidgoyal.net/kitty/), a fast, feature-rich, GPU-based terminal emulator.
- **Shell & Prompt:** Zsh + Oh My Zsh, with [Starship](https://starship.rs/) for a minimal, fast, and highly customizable prompt.
- **Theming:** A consistent [Catppuccin Mocha](https://github.com/catppuccin) theme across `kitty`, `bat`, and `yazi`.
- **Editor:** A pre-configured [Neovim (LazyVim)](https://neovim.io/) setup for a lightweight and efficient coding experience.
- **File Management:**
  - [Eza](https://github.com/eza-community/eza) as a modern replacement for `ls`.
  - [Yazi](https://github.com/sxyazi/yazi) as a terminal file manager with rich media previews.
  - [fzf](https://github.com/junegunn/fzf) for lightning-fast fuzzy finding and history search.
- **Tools & Utilities:** [Homebrew](https://brew.sh/) for package management, [bat](https://github.com/sharkdp/bat) for syntax highlighting, `zoxide` for intelligent directory jumping, and much more.

## 🚀 Installation

This setup is designed to be installed with a few simple commands.

> **⚠️ Warning:** The script will create backups of your existing configuration files (`.zshrc`, `.config/kitty`, etc.) before creating symbolic links to the files in this repository.

1. **Install a real terminal emulator:**
   Install and open [Kitty](https://sw.kovidgoyal.net/kitty/binary)
   ```bash
   curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
   open /Applications/kitty.app
   ```

2.  **Clone the repository:**
    ```bash
    git clone https://github.com/ThibaultJRD/dotfiles.git
    cd dotfiles
    ```

3.  **Make the script executable:**
    Before running the script, you need to give it execution permissions.
    ```bash
    chmod +x install.sh
    ```

4.  **Run the installation script:**
    ```bash
    ./install.sh
    ```

5.  **Restart your terminal:**
    Close and reopen your terminal windows to load the new configuration. You may also need to set the Nerd Font in your terminal's settings to see all the icons correctly.

6. **Launch Tmux**
   ```bash
   tmux
   ```

## 🛠️ Included Software & Configuration

This script will install and configure the following components:

### Terminal Setup
| Tool | Description |
| :--- | :--- |
| **Kitty** | My primary terminal emulator. The configuration is located in the `kitty/` directory. |
| **Zsh** | The default shell, enhanced with Oh My Zsh. |
| **Oh My Zsh** | Framework for managing Zsh configuration and plugins. |
| **Starship** | Provides the cross-shell prompt. Configured in `starship/`. |
| **Homebrew** | The package manager for macOS used to install all the tools. |

### Zsh Plugins
| Plugin | Description |
| :--- | :--- |
| **git** | Adds many Git aliases and convenience functions. |
| **fzf** | Supercharges history search (`Ctrl+R`) and other bindings. |
| **sudo** | Easily prepend `sudo` to the current command by pressing `Esc` twice. |
| **zsh-completions** | Adds a vast number of `Tab` completions for common tools. |
| **zsh-syntax-highlighting** | Provides real-time syntax highlighting in the command line. |
| **zsh-autosuggestions** | Suggests commands as you type based on your history. |
| **history-substring-search**| Allows searching history with partial matches (up/down arrows). |


### Core Utilities
| Tool | Alias / Command | Description |
| :--- | :--- | :--- |
| **Neovim** | `nvim` or `v` | Main text editor. Configured in `nvim/`. |
| **Eza** | `ls`, `la`, `lt` | Modern `ls` with custom `ls` alias for a clean output. |
| **bat** | `cat` | A `cat` clone with syntax highlighting. Themed in `bat/`. |
| **lazygit**| `lg` | A simple terminal UI for git commands. |
| **yazi** | `y` (function) | Fast terminal file manager. Themed and configured in `yazi/`. |
| **tmux** | `tmux` | Terminal multiplexer. Configured in `tmux/`. |
| **zoxide** | `z <dir>` | A smarter `cd` command that learns your habits. Activated in `.zshrc`. |

### Yazi Preview Dependencies
The `Brewfile` includes the following optional dependencies to enable rich media previews in `yazi`:
- `ffmpeg` for video thumbnails.
- `imagemagick` for image previews.
- `poppler` for PDF previews.
- `resvg` for SVG previews.
- `sevenzip` for archive previews.
- `jq` for JSON previews.

### Development Environment
| Tool | Description |
| :--- | :--- |
| **n** | A simple and effective Node.js version manager. |
| **Go** | The Go programming language toolchain. |
| **npm/yarn/bun** | Essential package managers for the JavaScript ecosystem. |

## Fonts

For a correct display of icons and symbols, this script installs the following "Nerd Fonts" via Homebrew:
- Caskaydia Cove Nerd Font
- Victor Mono Nerd Font
- Symbols Only Nerd Font
- JetBrains Mono NL Nerd Font

After installation, make sure to configure your terminal's font (e.g., in `kitty.conf` or your emulator's preferences) to use a "Nerd Font" of your choice.
