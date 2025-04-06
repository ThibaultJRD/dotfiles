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
> `brew install n neovim starship git bat lazygit`
