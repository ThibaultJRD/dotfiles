# ==============================================================================
# Nushell Configuration
# ==============================================================================
# Nushell is designed for structured data manipulation, not as a daily driver
# Use it for: JSON/CSV processing, API calls, data transformation tasks

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
    file_format: "plaintext"
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
      completer: null
    }
    use_ls_colors: true
  }

  cursor_shape: {
    emacs: line
    vi_insert: line
    vi_normal: block
  }

  edit_mode: vi

  keybindings: [
    {
      name: fzf_file_picker
      modifier: control
      keycode: char_t
      mode: [emacs vi_insert vi_normal]
      event: [
        {
          send: ExecuteHostCommand
          cmd: "commandline edit (
                  if ((commandline | str trim | str length) == 0) {
                      (^fd --hidden --strip-cwd-prefix --exclude .git | ^fzf --height=40% --layout=reverse --preview 'if [ -d {} ]; then eza --tree --level=2 --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi' | decode utf-8 | str trim)
                  } else if (commandline | str ends-with ' ') {
                      [
                          (commandline)
                          (^fd --hidden --strip-cwd-prefix --exclude .git | ^fzf --height=40% --layout=reverse --preview 'if [ -d {} ]; then eza --tree --level=2 --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi' | decode utf-8 | str trim)
                      ] | str join
                  } else {
                      [
                          (commandline | split words | reverse | skip 1 | reverse | str join ' ')
                          (^fd --hidden --strip-cwd-prefix --exclude .git | ^fzf --height=40% --layout=reverse -q (commandline | split words | last) | decode utf-8 | str trim)
                      ] | str join ' '
                  }
                )"
        }
      ]
    }
    {
      name: fzf_directory_picker
      modifier: alt
      keycode: char_c
      mode: [emacs vi_insert vi_normal]
      event: {
        send: executehostcommand
        cmd: "fzf-cd"
      }
    }
  ]
}

# --- Theme ---
source ~/.config/nushell/catppuccin_mocha.nu

# --- Aliases ---
# Common commands with sensible defaults
alias cat = bat
alias la = ls -a
alias lt = eza --tree --level=2 --long --icons --git
alias ll = eza -l --icons --git -a --group-directories-first
alias v = nvim
alias lg = lazygit
alias p = pnpm

# --- FZF Custom Commands ---
# Directory picker for quick navigation
def --env fzf-cd [] {
  let selection = (
    ^fd --type=d --hidden --strip-cwd-prefix --exclude .git
    | ^fzf --preview 'eza --tree --level=2 --color=always {} | head -200'
    | str trim
  )
  if ($selection | is-not-empty) {
    cd $selection
  }
}

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

# Yazi integration
def --env y [...args] {
  let tmp = (mktemp -t "yazi-cwd.XXXXXX")
  yazi ...$args --cwd-file $tmp
  let cwd = (open $tmp)
  if $cwd != "" and $cwd != $env.PWD {
    cd $cwd
  }
  rm -f $tmp
}
