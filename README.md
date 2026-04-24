# Dotfiles

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-Sonoma+-blue.svg)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/Shell-Zsh%20%7C%20Nushell-green.svg)](https://www.zsh.org/)
[![Theme](https://img.shields.io/badge/Theme-Catppuccin-pink.svg)](https://github.com/catppuccin)

<p>
  <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="400" />
</p>

<img width="476" alt="Terminal screenshot" src="https://github.com/user-attachments/assets/c149ee55-8844-40d3-a833-a63e136217a2" />

Automated macOS terminal setup — tmux, neovim, and 40+ CLI tools with a consistent Catppuccin theme.

**New to this setup?** Start with [`docs/workflow.md`](docs/workflow.md) — a hands-on guide for tmux, sesh, and worktrunk.

---

## ⚡ Quick Start

```bash
git clone https://github.com/ThibaultJRD/dotfiles.git
cd dotfiles
./install.sh
```

Open Kitty, run `tmux`, you're ready. The script backs up existing configs before making changes.

---

## 📦 What's Included

| Category | Tool | Description | Launch |
|----------|------|-------------|--------|
| **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) | GPU-accelerated terminal | `kitty` |
| **Shell** | [Zsh](https://zsh.sourceforge.io/) + Oh My Zsh | System default shell | default |
| **Shell** | [Nushell](https://www.nushell.sh/) | Structured data shell (tmux default) | `nu` |
| **Prompt** | [Starship](https://starship.rs/) | Cross-shell prompt with vi mode indicators | auto |
| **Multiplexer** | [Tmux](https://github.com/tmux/tmux) | Terminal multiplexer with 12+ plugins | `tmux` |
| **Sessions** | [sesh](https://github.com/joshmedeski/sesh) | Smart tmux session manager with project layouts | `Prefix + o` |
| **Editor** | [Neovim](https://neovim.io/) (LazyVim) | Extensible text editor | `v` |
| **Files** | [Yazi](https://github.com/sxyazi/yazi) | Terminal file manager with previews | `y` |
| **Git** | [Lazygit](https://github.com/jesseduffield/lazygit) | Git TUI | `lg` |
| **Git** | [gh](https://cli.github.com/) | GitHub CLI | `gh` |
| **Search** | [fzf](https://github.com/junegunn/fzf) | Fuzzy finder | `Ctrl+T` |
| **Search** | [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast text search | `rg` |
| **Search** | [fd](https://github.com/sharkdp/fd) | Fast file finder | `fd` |
| **Navigation** | [Zoxide](https://github.com/ajeetdsouza/zoxide) | Smart cd (replaces `cd`) | `cd` |
| **History** | [Atuin](https://github.com/atuinsh/atuin) | Shell history with fuzzy search | `Ctrl+R` |
| **Viewer** | [bat](https://github.com/sharkdp/bat) | Syntax-highlighted cat | `cat` |
| **Viewer** | [eza](https://github.com/eza-community/eza) | Modern ls with icons | `ls` |
| **Viewer** | [glow](https://github.com/charmbracelet/glow) | Markdown renderer | `glow` |
| **Viewer** | [jq](https://github.com/jqlang/jq) / [yq](https://github.com/mikefarah/yq) | JSON / YAML processors | `jq`, `yq` |
| **Viewer** | [delta](https://github.com/dandavison/delta) | Syntax-highlighted git diffs | auto |
| **Monitor** | [btop](https://github.com/aristocratos/btop) | System resource monitor | `btop` |
| **Completions** | [Carapace](https://github.com/carapace-sh/carapace-bin) | Multi-shell completion engine | auto |
| **Dev** | Node.js via [n](https://github.com/tj/n) | JavaScript runtime | `node` |
| **Dev** | [Go](https://go.dev/) | Go language | `go` |
| **Dev** | Rust via [rustup](https://rustup.rs/) | Rust toolchain | `cargo` |
| **Dev** | [pnpm](https://pnpm.io/) / yarn / bun | JS package managers | `p` |
| **Docker** | [Lazydocker](https://github.com/jesseduffield/lazydocker) | Docker TUI | `lazydocker` |
| **Utility** | [Lazyprune](https://github.com/ThibaultJRD/lazyprune) | Find and delete heavy cache dirs + kill processes by port | `lazyprune` |
| **Worktrees** | [worktrunk](docs/workflow.md#5-worktrunk--parallel-branches-parallel-agents) | Worktrees + AI agents: parallel branches, parallel agents | `wt` |

---

## 🖥️ Tmux — The Core Workflow

Tmux is the hub of this setup. Everything runs inside it: sessions persist across restarts, panes navigate seamlessly into Neovim, and the status bar monitors your system.

### 🚀 Getting Started

```bash
tmux                      # new session
tmux new -s myproject     # new named session
tmux a                    # attach to last session
```

The **prefix** is `Ctrl+s` — all tmux shortcuts start with it. Press `Prefix + Space` to open the which-key help menu and discover all available bindings.

### 📋 Session Management

| Key | Action |
|-----|--------|
| `Prefix + o` | **Sesh** — fuzzy session picker (tmux sessions, zoxide dirs, configs) |
| `Prefix + Tab` | Switch to last session |
| `Prefix + d` | Detach from current session |
| `Prefix + $` | Rename session |

Sessions are managed by [sesh](https://github.com/joshmedeski/sesh). Connecting to a git repo automatically creates a 3-window layout (lazygit, nvim+terminal, AI terminal). Non-git directories get a simple terminal. The `sesh.toml` config is in `sesh/.config/sesh/`.

### 🪟 Windows and Panes

| Key | Action |
|-----|--------|
| `Prefix + c` | New window (preserves current path) |
| `Prefix + \|` | Split pane horizontally |
| `Prefix + -` | Split pane vertically |
| `Ctrl+h/j/k/l` | Navigate between panes **and** Neovim splits |
| `Prefix + H/J/K/L` | Resize pane (5px increments, repeatable) |
| `Prefix + <` | Swap window left |
| `Prefix + >` | Swap window right |

Pane navigation uses [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) — `Ctrl+h/j/k/l` moves between tmux panes and Neovim splits seamlessly, no prefix needed.

### ⚡ Power Features

| Key | Action | Plugin |
|-----|--------|--------|
| `Prefix + f` | Floating terminal overlay (80% screen) | [tmux-floax](https://github.com/omerxx/tmux-floax) |
| `Prefix + T` | Vimium-style copy hints (lowercase = copy, UPPERCASE = paste) | [tmux-thumbs](https://github.com/fcsonline/tmux-thumbs) |
| `Prefix + u` | Fuzzy-find and open URLs from terminal output | [tmux-fzf-url](https://github.com/wfxr/tmux-fzf-url) |
| `Prefix + Space` | Interactive keybinding help | [tmux-which-key](https://github.com/alexwforsythe/tmux-which-key) |
| `Prefix + r` | Reload tmux configuration | built-in |

Mouse is enabled for pane selection and resizing.

### 📊 Status Bar

Top-positioned, showing: **session name** | windows | **IP** | **CPU** | **RAM** | **battery** (if available) | **date/time**

### 🐚 Default Shell

Tmux launches **Nushell** by default. To switch to Zsh, edit `tmux/.config/tmux/tmux.conf`:

```bash
# Change this line:
set -g default-command /opt/homebrew/bin/nu
# To:
set -g default-command /bin/zsh
```

Then reload with `Prefix + r`.

### 🔌 Tmux Plugins

| Plugin | Purpose |
|--------|---------|
| [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) | Sane defaults |
| [tmux-yank](https://github.com/tmux-plugins/tmux-yank) | System clipboard integration |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless pane/split navigation |
| [catppuccin/tmux](https://github.com/catppuccin/tmux) | Catppuccin Macchiato theme |
| [tmux-nerd-font-window-name](https://github.com/joshmedeski/tmux-nerd-font-window-name) | Nerd Font icons in window names |
| [tmux-which-key](https://github.com/alexwforsythe/tmux-which-key) | Keybinding discovery |
| [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu) | CPU monitoring |
| [tmux-battery](https://github.com/tmux-plugins/tmux-battery) | Battery status |
| [tmux-primary-ip](https://github.com/dreknix/tmux-primary-ip) | Network IP display |
| [tmux-floax](https://github.com/omerxx/tmux-floax) | Floating terminal pane |
| [tmux-fzf-url](https://github.com/wfxr/tmux-fzf-url) | URL picker |
| [tmux-thumbs](https://github.com/fcsonline/tmux-thumbs) | Copy hints |
| [sesh](https://github.com/joshmedeski/sesh) | Smart session manager (standalone CLI) |

Plugins are managed by [TPM](https://github.com/tmux-plugins/tpm) and installed automatically on first launch. To manually install: `Prefix + I`.

---

## ⌨️ Shell Keybindings

These work in both Zsh and Nushell:

| Key | Action |
|-----|--------|
| `Ctrl+T` | fzf file picker with bat/eza preview |
| `Ctrl+G` | Zoxide interactive directory picker with tree preview |
| `Ctrl+R` | Atuin history search (fuzzy, vi mode) |
| `Esc` | Toggle vi mode (cursor changes: beam = insert, block = normal) |

Vi mode is enabled in both shells with cursor shape feedback.

---

## 🔗 Aliases

### Shared (Zsh + Nushell)

| Alias | Expands to | Description |
|-------|------------|-------------|
| `cat` | `bat` | Syntax-highlighted file viewing |
| `lt` | `eza --tree` (2 levels) | Tree view |
| `v` | `nvim` | Neovim |
| `lg` | `lazygit` | Git TUI |
| `p` | `pnpm` | Package manager |
| `y` | yazi (cd-on-exit) | File manager |

### Zsh only

| Alias | Expands to | Description |
|-------|------------|-------------|
| `ls` | `eza` (icons, git, colors) | Enhanced file listing |
| `la` | `eza -la` (grouped dirs first) | All files with details |

### Nushell only

| Alias | Expands to | Description |
|-------|------------|-------------|
| `la` | `ls -a` (Nushell built-in) | All files |
| `ll` | `eza -la` (grouped dirs first) | All files with details |

### Git Aliases (Nushell only)

| Alias | Command | Description |
|-------|---------|-------------|
| `gst` | `git status` | Status |
| `gc` | `git commit -m` | Commit with message |
| `gca` | `git commit -a -m` | Commit all with message |
| `gp` | `git push origin HEAD` | Push current branch |
| `gpu` | `git pull origin` | Pull |
| `glog` | `git log --graph` (formatted) | Visual commit graph |
| `gdiff` | `git diff` | Show diff |
| `gco` | `git checkout` | Checkout |
| `gb` | `git branch` | List branches |
| `gba` | `git branch -a` | List all branches |
| `ga` | `git add -p` | Interactive patch staging |
| `gadd` | `git add` | Stage files |
| `gcoall` | `git checkout -- .` | Discard all changes |
| `gr` | `git remote` | Remotes |
| `gre` | `git reset` | Reset |

### 🛠️ Custom Functions

**`y [args]`** — Opens [Yazi](https://github.com/sxyazi/yazi) file manager. On exit, your shell `cd`s to the last directory you browsed.

---

## ✏️ Neovim

Built on [LazyVim](https://www.lazyvim.org/) with these additions:

| Plugin | Purpose |
|--------|---------|
| [copilot.vim](https://github.com/github/copilot.vim) | GitHub Copilot |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless tmux pane navigation |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | File picker with hidden files |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Colorscheme |

`Ctrl+h/j/k/l` navigates between Neovim splits and tmux panes — same keybindings, zero context switch. `maplocalleader` is set to `ù`. ESLint and Prettier integration enabled.

---

## 📁 File Management — Yazi

Launch with `y`. Uses vim-style keybindings:

| Key | Action |
|-----|--------|
| `h/j/k/l` | Navigate |
| `Enter` | Open file |
| `y / x / p` | Copy / Cut / Paste |
| `d` | Move to trash |
| `D` | Permanent delete |
| `a` | Create file/directory |
| `r` | Rename |
| `s` | Search by name (fd) |
| `S` | Search by content (rg) |
| `z` | Jump with fzf |
| `Z` | Jump with zoxide |
| `Space` | Select / deselect |
| `t` | New tab |
| `.` | Toggle hidden files |
| `w` | Task manager |

Previews supported for: images (ImageMagick), videos (ffmpeg), PDFs (poppler), SVGs (resvg), archives (7zip), code (bat with syntax highlighting).

---

## 🎨 Theme

**Catppuccin** across the entire stack:

- **Mocha**: Kitty, Starship, Yazi, Lazygit, bat, btop, Atuin, Nushell
- **Macchiato**: Tmux, fzf
- **TokyoNight**: Neovim (LazyVim default — change in `nvim/lua/plugins/tokyonight.lua`)

**Vi mode** is enabled across all tools with cursor shape feedback:
- Insert mode: beam cursor (`|`)
- Normal mode: block cursor (`█`)

**Nerd Fonts** installed:
- **CaskaydiaCove** — primary font (Cascadia Code with Nerd Font icons)
- **VictorMono** — italic font for code comments
- **JetBrains Mono NL** — symbol fallback
- **Symbols Only** — icon-only fallback

---

## 🔧 Customization

### Change the theme

```bash
# Starship — edit starship/.config/starship/starship.toml
palette = 'your_palette'

# Kitty — edit kitty/.config/kitty/kitty.conf
include your-theme.conf

# Tmux — edit tmux/.config/tmux/tmux.conf
set -g @catppuccin_flavor 'your_flavor'
```

### Add custom aliases

```bash
# Create a file in the Zsh custom config directory (preserved across reinstalls)
echo 'alias myalias="my command"' > ~/.config/zsh/conf.d/custom.zsh
```

### Add new tools

1. Add to `Brewfile`: `brew "your-tool"`
2. Create config: `mkdir -p your-tool/.config/your-tool`
3. Update `install.sh` if symlinks are needed
4. Run `./install.sh`

---

## 📥 Installation Details

### Prerequisites

- macOS Sonoma (14.0) or later
- Git and internet connection

### What `install.sh` Does

1. Installs [Homebrew](https://brew.sh/) if missing
2. Installs [Oh My Zsh](https://ohmyz.sh/) with plugins (syntax-highlighting, autosuggestions, completions, history-substring-search)
3. Runs `brew bundle` to install all packages from `Brewfile`
4. Installs Rust toolchain and [Lazyprune](https://github.com/ThibaultJRD/lazyprune)
5. Creates symlinks from dotfiles to `~/.config/` for each tool
6. Installs Node.js LTS via `n`, Bun, and Atuin
7. Builds bat syntax theme cache

Existing config files are backed up with a timestamp suffix before symlinking.

### Reinstall

```bash
./install.sh    # safe to re-run — backs up existing files, skips installed packages
```

---

## 🩺 Troubleshooting

**Icons not displaying** — Make sure Kitty (or your terminal) is using a Nerd Font. Restart the terminal after font installation.

**Tmux plugins not installed** — Press `Prefix + I` (capital I) inside tmux to trigger TPM plugin installation.

**Tool not found after install** — Restart your terminal or run `source ~/.zshrc`. Check Homebrew health with `brew doctor`.

**Config not applied** — Verify symlinks exist: `ls -la ~/.config/`. Re-run `./install.sh` if needed.

---

## License

MIT — see [LICENSE](LICENSE).
