# My Personal Dotfiles

![Starship Prompt Image](https://starship.rs/presets/pastel-powerline.png)
_(Feel free to replace this image with a screenshot of your own terminal once it's set up!)_

This repository contains my personal configuration files (dotfiles) for creating a modern and productive terminal environment on macOS. The setup is automated via a simple installation script.

## ✨ Features

- **Shell & Prompt:** Zsh + Oh My Zsh for a powerful shell, with [Starship](https://starship.rs/) for a minimal, fast, and highly customizable prompt.
- **Terminal:** [Kitty](https://sw.kovidgoyal.net/kitty/), a fast, feature-rich, GPU-based terminal emulator.
- **Editor:** A pre-configured [Neovim](https://neovim.io/) setup for a lightweight and efficient coding experience.
- **File Management:**
  - [Eza](https://github.com/eza-community/eza) as a modern replacement for `ls`.
  - [Yazi](https://github.com/sxyazi/yazi) as a terminal file manager with previews.
  - [fzf](https://github.com/junegunn/fzf) for lightning-fast fuzzy finding.
- **Git Integration:**
  - [Lazygit](https://github.com/jesseduffield/lazygit) for a simple terminal UI for git commands.
  - Git aliases and status integrated into the prompt.
- **Tools & Utilities:** [Homebrew](https://brew.sh/) for package management, [bat](https://github.com/sharkdp/bat) as a `cat` clone with syntax highlighting, and much more.

## 🚀 Installation

This setup is designed to be installed with a single command.

> **⚠️ Warning:** The script will create backups of your existing configuration files (`.zshrc`, `.config/kitty`, etc.) before creating symbolic links to the files in this repository.

1. **Clone the repository:**

    ```bash
    git clone [https://github.com/YOUR_USERNAME/YOUR_REPO.git](https://github.com/YOUR_USERNAME/YOUR_REPO.git)
    cd YOUR_REPO
    ```

2. **Run the installation script:**

    ```bash
    ./install.sh
    ```

3. **Restart your terminal:**
    Close and reopen your terminal windows to load the new configuration. You may also need to set the Nerd Font in your terminal's settings to see all the icons correctly.

## 🛠️ Included Software & Configuration

This script will install and configure the following components:

### Terminal Setup

| Tool            | Description                                                                               |
| :-------------- | :---------------------------------------------------------------------------------------- |
| **Kitty**       | My primary terminal emulator. The configuration is located in `.config/kitty/`.           |
| **Zsh**         | The default shell, enhanced with Oh My Zsh.                                               |
| **Oh My Zsh**   | Framework for managing Zsh configuration.                                                 |
| **zsh-plugins** | `zsh-syntax-highlighting` and `zsh-autosuggestions` for a better command-line experience. |
| **Starship**    | Provides the cross-shell prompt. Configured in `.config/starship.toml`.                   |
| **Homebrew**    | The package manager for macOS used to install all the tools.                              |

### Core Utilities

| Tool        | Alias / Command  | Description                                                                |
| :---------- | :--------------- | :------------------------------------------------------------------------- |
| **Neovim**  | `nvim` or `v`    | My main text editor, with configs in `.config/nvim/`.                      |
| **Eza**     | `ls`, `la`, `lt` | A modern `ls` with colors, icons, and git integration.                     |
| **bat**     | `cat`            | A `cat` clone with syntax highlighting and Git integration.                |
| **fzf**     | `f` (custom)     | A command-line fuzzy finder. The alias `f` opens selected files in Neovim. |
| **lazygit** | `lg`             | A simple terminal UI for git commands.                                     |
| **yazi**    | `y`              | A fast terminal file manager with previews.                                |
| **tmux**    | `tmux`           | A terminal multiplexer. Configuration is in `.config/tmux/`.               |

### Development Environment

| Tool             | Description                                              |
| :--------------- | :------------------------------------------------------- |
| **n**            | A simple and effective Node.js version manager.          |
| **npm/yarn/bun** | Essential package managers for the JavaScript ecosystem. |

## Fonts

For a correct display of icons and symbols, this script installs the following "Nerd Fonts" via Homebrew:

- Caskaydia Cove Nerd Font
- Victor Mono Nerd Font
- Symbols Only Nerd Font

After installation, make sure to configure your terminal's font (e.g., in `kitty.conf` or your emulator's preferences) to use `CaskaydiaCove Nerd Font` or another "Nerd Font" of your choice.
