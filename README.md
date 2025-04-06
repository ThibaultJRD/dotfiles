# Config

## Terminal

### Iterm 2
- Download [Iterm2](https://iterm2.com/)
- Go to ITerm settings and import 

### OMyZsh
- Install OMyZsh with this command :
> `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`

### HomeBrew
- Install Homebrew with the following command:
> `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Run these commands in your terminal to add Homebrew to your PATH: (Take care about the username)
> `echo >> /Users/thibault/.zprofile`
> `echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/thibault/.zprofile`
> `eval "$(/opt/homebrew/bin/brew shellenv)"`
