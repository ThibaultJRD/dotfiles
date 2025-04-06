# Config

## Terminal

### Iterm 2
- Download [Iterm2](https://iterm2.com/)
- Go to ITerm settings and import `catppuccin-mocha.itermcolors` in color presets

### OMyZsh
- Install OMyZsh with this command :
> `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`

- Add this following line to your `.zshrc`
> `export PATH="/opt/homebrew/bin:${PATH}"`

### HomeBrew
- Install Homebrew with the following command:
> `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Run these commands in your terminal to add Homebrew to your PATH: (Take care about the username)
> `echo >> /Users/thibault/.zprofile`
> `echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/thibault/.zprofile`
> `eval "$(/opt/homebrew/bin/brew shellenv)"`

- Install some Home brew packages with the following command:
> `brew install n neovim starship git bat lazygit font-jetbrains-mono-nerd-font font-victor-mono-nerd-font font-symbols-only-nerd-font fzf`

### N
- Configure N, add following lines to your `.zshrc`
```bash
export N_PREFIX=$HOME/.n
export PATH=$N_PREFIX/bin:$PATH
```
- Install desire node version

### Yarn
- Install yarn with:
> `npm -g install yarn`

### Starship
- Add this line at **the end** of `.zshrc` file
> `eval "$(starship init zsh)"`
- Add `starship.toml` file to your `~/.config/`

### Fonts
- Go to Iterms settings and `Text` then choose JetBrain nerd font, 14, ligature and check "use built in powerline glyphs"
- Choose symbols only nerd font for no Ascii font
