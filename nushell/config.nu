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
        trim: {
            methodology: wrapping
            wrapping_try_keep_words: true
        }
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
        algorithm: "fuzzy"
    }

    cursor_shape: {
        emacs: line
        vi_insert: line
        vi_normal: block
    }

    edit_mode: vi
}

# --- Theme ---
source ~/.config/nushell/catppuccin_mocha.nu

# --- Aliases ---
# Common commands with sensible defaults
alias cat = bat
alias la = ls -a
alias lt = eza --tree --level=2 --long --icons --git
alias v = nvim
alias lg = lazygit
alias p = pnpm

# --- Vi Mode Indicators ---
# Visual feedback for vi mode state
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }

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
