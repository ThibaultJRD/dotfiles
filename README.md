# Dotfiles

## Terminal

### Kitty
- Download [Kitty](https://sw.kovidgoyal.net/kitty/binary/)
- Copy kitty folder into your `~/.config`

### OMyZsh
- Install OMyZsh with this command :
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

- Add this following line to your `.zshrc`
```bash
export PATH="/opt/homebrew/bin:${PATH}"
```

### HomeBrew
- Install Homebrew with the following command:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
- Run these commands in your terminal to add Homebrew to your PATH: (Take care about the username)
```bash
echo >> /Users/thibault/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/thibault/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

- Install some Home brew packages with the following command:
```bash
brew install n neovim starship git bat lazygit font-caskaydia-cove-nerd-font font-victor-mono-nerd-font font-symbols-only-nerd-font fzf ripgrep fd luarocks tmux yq gh eza
```

### Starship
- Add this line at **the end** of `.zshrc` file
```bash
eval "$(starship init zsh)"
```
- Add `starship.toml` file to your `~/.config/`

### ZSH plugins
- Install [Zsh syntax highlighting](https://github.com/zsh-users/zsh-syntax-highlighting/tree/master) with:
```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```
- Install [Zsh autosuggestion](https://github.com/zsh-users/zsh-autosuggestions/tree/master) with:
```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

- Add the following plugins to your `plugins=(git zsh-syntax-highlighting zsh-autosuggestions z)`

### Eza
- Add this following line to `.zshrc`
```bash
alias ls='eza --icons --git'
alias la='eza -l --icons --git -a --group-directories-first'
alias lt='eza --tree --level=2 --long --icons --git'
```

### FZF
- Install [fzf](https://github.com/junegunn/fzf)
- Add this to your `.zshrc`
```bash
source <(fzf --zsh)
alias f='nvim $(fzf -m --preview="bat --color=always {}")'
```

### TMUX
- Add the `tmux.conf` file and all folder content to your `.config/tmux` and launch `tmux` command

### N
- Configure N, add following lines to your `.zshrc`
```bash
export N_PREFIX=$HOME/.n
export PATH=$N_PREFIX/bin:$PATH
```
- Install desire node version

### Yarn
- Install yarn with:
```bash
npm -g install yarn
```

### Bun
- Install bun with:
```bash
curl -fsSL https://bun.sh/install | bash
```
