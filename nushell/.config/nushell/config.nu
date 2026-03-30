# ==============================================================================
# Nushell Configuration
# ==============================================================================

# --- Carapace Completer ---
let carapace_completer = {|spans: list<string>|
  carapace $spans.0 nushell ...$spans | from json
}

# --- Basic Settings ---
$env.config = {
  show_banner: false

  ls: {
    use_ls_colors: true
    clickable_links: true
  }

  rm: {
    always_trash: false
  }

  table: {
    mode: rounded
    index_mode: always
    show_empty: true
    padding: { left: 1, right: 1 }
    trim: {
      methodology: wrapping
      wrapping_try_keep_words: true
    }
  }

  explore: {
    status_bar_background: { fg: "#1D1F21", bg: "#C4C9C6" },
    command_bar_text: { fg: "#C4C9C6" },
    highlight: { fg: "black", bg: "yellow" },
    status: {
      error: { fg: "white", bg: "red" },
      warn: {}
      info: {}
    },
    selected_cell: { bg: light_blue },
  }

  history: {
    max_size: 100_000
    sync_on_enter: true
    file_format: "sqlite"
    isolation: false
  }

  completions: {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "prefix"
    external: {
      enable: true
      max_results: 100
      completer: $carapace_completer
    }
    use_ls_colors: true
  }

  cursor_shape: {
    emacs: line
    vi_insert: line
    vi_normal: block
  }

  edit_mode: vi
  highlight_resolved_externals: true

  shell_integration: {
    osc2: true
    osc7: true
    osc8: true
    osc9_9: true
    osc133: true
    osc633: true
    reset_application_mode: true
  }

  hooks: {
    display_output: "if (term size).columns >= 100 { table -e } else { table }"
  }

  # Keybindings are added by conf.d/fzf.nu
  keybindings: []
}

# --- Theme ---
source ~/.config/nushell/catppuccin_mocha.nu

# --- Aliases ---
# Common commands with sensible defaults
alias cat = bat
alias la = ls -a
alias lt = eza --tree --level=2 --long --icons --git --git-ignore
alias ll = eza -l --icons --git -a --group-directories-first
alias v = nvim
alias lg = lazygit
alias p = pnpm
alias glow = glow -t

# Git Aliases
alias gc = git commit -m
alias gca = git commit -a -m
alias gp = git push origin HEAD
alias gpu = git pull origin
alias gst = git status
alias glog = git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit
alias gdiff = git diff
alias gco = git checkout
alias gb = git branch
alias gba = git branch -a
alias gadd = git add
alias ga = git add -p
alias gcoall = git checkout -- .
alias gr = git remote
alias gre = git reset

# --- Vi Mode Indicators ---
# Visual feedback for vi mode state (using Starship-style symbols with colors)
$env.PROMPT_INDICATOR_VI_INSERT = {|| $"(ansi green_bold)❯(ansi reset) " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| $"(ansi yellow_bold)❮(ansi reset) " }

# --- Integrations ---
# Starship prompt (use 'use' instead of 'source' for starship)
use ~/.cache/starship/init.nu

# Zoxide (smart cd) - using 'cd' command instead of 'z'
source ~/.zoxide.nu

# Atuin (shell history sync)
source ~/.local/share/atuin/init.nu

# Carapace (advanced completions)
source ~/.cache/carapace/init.nu

# Rust integration
source $"($nu.home-dir)/.cargo/env.nu"

# --- Modular Configurations ---
source ~/.config/nushell/conf.d/fzf.nu
source ~/.config/nushell/conf.d/yazi.nu
