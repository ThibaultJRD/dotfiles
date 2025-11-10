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
        index_mode: auto
        show_empty: true
        trim: {
            methodology: wrapping
            wrapping_try_keep_words: true
        }
    }

    history: {
        max_size: 100_000
        sync_on_enter: true
        file_format: "sqlite"
    }

    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
    }

    filesize: {
        metric: false
        format: "auto"
    }

    cursor_shape: {
        emacs: line
        vi_insert: line
        vi_normal: block
    }

    edit_mode: emacs
    shell_integration: true
    use_grid_icons: true
}

# --- Aliases ---
# Common commands with sensible defaults
alias cat = bat
alias ls = eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions
alias la = eza -l --icons --git -a --group-directories-first
alias lt = eza --tree --level=2 --long --icons --git
alias v = nvim
alias lg = lazygit

# --- Integrations ---
# Starship prompt (optional, uncomment if you want to use it in Nushell)
# source ~/.cache/starship/init.nu

# Zoxide integration
source ~/.local/share/zoxide/init.nu

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
