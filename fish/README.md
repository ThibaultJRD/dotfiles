# Fish Shell Configuration

Modern, user-friendly shell configuration with all your favorite tools integrated.

## What is Fish?

Fish (Friendly Interactive SHell) is a smart and user-friendly command line shell that works out of the box with:
- **Syntax highlighting** (built-in, no plugins needed!)
- **Autosuggestions** (built-in, inspired by Fish!)
- **Smart completions** (learns from man pages automatically)
- **Better defaults** (sane, no configuration needed)

Fish was the inspiration for the `zsh-syntax-highlighting` and `zsh-autosuggestions` plugins you were using in Zsh.

## Directory Structure

```
fish/
├── config.fish              # Main configuration file
├── conf.d/                  # Auto-loaded configurations
│   ├── 01-env.fish         # Environment variables & PATH
│   ├── 02-aliases.fish     # Command aliases
│   ├── 03-integrations.fish # Tool integrations (zoxide, starship, atuin)
│   └── fzf.fish            # FZF configuration
├── functions/               # Custom functions
│   ├── y.fish              # Yazi integration
│   ├── listports.fish      # List network ports
│   └── killports.fish      # Kill processes by port
└── README.md               # This file
```

## Installed Tools Integration

All your tools work natively with Fish:

| Tool | Status | Description |
|------|--------|-------------|
| **zoxide** | ✅ Native | Smarter `cd` command |
| **starship** | ✅ Native | Cross-shell prompt |
| **atuin** | ✅ Native | Shell history sync |
| **fzf** | ✅ Enhanced | Fuzzy finder (install `fzf.fish` plugin for best experience) |
| **eza** | ✅ Native | Modern `ls` replacement |
| **bat** | ✅ Native | `cat` with syntax highlighting |
| **yazi** | ✅ Native | Terminal file manager |
| **lazygit** | ✅ Native | Git TUI |

## Key Differences from Zsh

### Variable Assignment
```fish
# Zsh
export PATH="/usr/local/bin:$PATH"
FOO="bar"

# Fish
set -gx PATH /usr/local/bin $PATH  # -gx = global export
set FOO bar                         # Local variable
fish_add_path /usr/local/bin       # Preferred for PATH
```

### Functions
```fish
# Zsh
function myfunction() {
    echo "Hello $1"
}

# Fish
function myfunction
    echo "Hello $argv[1]"
end
```

### If Statements
```fish
# Zsh
if [ -f "$file" ]; then
    echo "exists"
fi

# Fish
if test -f $file
    echo "exists"
end
```

### Command Substitution
```fish
# Zsh
result=$(command)
result=`command`

# Fish
set result (command)
```

## Migrated Features

### From .zshrc
- ✅ All PATH entries
- ✅ All environment variables (EDITOR, LANG, etc.)
- ✅ All aliases (cat→bat, ls→eza, etc.)
- ✅ Tool integrations (zoxide, starship, atuin)

### From zsh_configs/
- ✅ **fzf.zsh** → `conf.d/fzf.fish` (FZF configuration with Catppuccin theme)
- ✅ **yazi.zsh** → `functions/y.fish` (Directory change on quit)
- ✅ **ports.zsh** → `functions/listports.fish` + `functions/killports.fish`

## Enhanced FZF Integration

For the best FZF experience with Fish, install the `fzf.fish` plugin:

```bash
# Install Fisher (Fish plugin manager)
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# Install fzf.fish plugin
fisher install PatrickF1/fzf.fish
```

This provides:
- **CTRL+R**: Search command history with fzf
- **CTRL+ALT+F**: Search files with fzf and preview
- **CTRL+ALT+L**: Search git log with fzf
- **CTRL+V**: Search and preview environment variables

## Setting Fish as Default Shell

After installation via `install.sh`, you can set Fish as your default shell:

```bash
# Check available shells
cat /etc/shells

# Add Fish if not present (install.sh does this automatically)
echo $(which fish) | sudo tee -a /etc/shells

# Change default shell to Fish
chsh -s $(which fish)

# Restart your terminal
```

## Reverting to Zsh

If you want to switch back to Zsh:

```bash
chsh -s $(which zsh)
# Restart your terminal
```

Your Zsh configuration remains intact and will work immediately.

## Useful Fish Commands

```bash
# List all functions
functions

# Show definition of a function
functions functionname

# Edit a function interactively
funced functionname

# Save a function permanently
funcsave functionname

# List all variables
set

# Show specific variable
echo $VARIABLE

# List all aliases
alias

# Get help
man fish
help
```

## Learning Resources

- Official tutorial: `fish_tutorial` (run in Fish)
- Documentation: https://fishshell.com/docs/current/
- Quick intro: https://fishshell.com/docs/current/tutorial.html

## Troubleshooting

### Issue: Command not found after switching to Fish
Fish has a different PATH mechanism. Run:
```fish
echo $PATH
# If missing paths, they should be added in conf.d/01-env.fish
```

### Issue: Some tool doesn't work
Fish is intentionally non-POSIX. If a script fails:
1. Run it explicitly with bash: `bash script.sh`
2. Or add `#!/bin/bash` shebang to the script

### Issue: Want to try Fish without changing default shell
```bash
# Just run fish from any shell
fish

# Exit with
exit
```

## Why Fish Over Zsh?

- **Better out-of-the-box experience**: No plugins needed for basic features
- **Cleaner syntax**: More consistent and easier to learn
- **Better completions**: Automatically generated from man pages
- **All your tools work**: Native support for zoxide, starship, atuin, fzf, etc.
- **Fast**: Quick startup time even with features enabled

Enjoy your new Fish shell! 🐟
