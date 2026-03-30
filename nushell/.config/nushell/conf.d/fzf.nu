# ==============================================================================
# FZF & Zoxide Configuration
# ==============================================================================
# File picker (Ctrl+T) and directory picker (Ctrl+G) keybindings

# Zoxide directory picker with fzf (Ctrl+G)
# Reads the commandline to pre-filter zoxide results (e.g. "cd do" + Ctrl+G filters on "do")
def --env zoxide-cd [] {
  let query = (commandline | str replace -r '^cd\s*' '' | str trim)
  let selection = if ($query | is-empty) {
    ^zoxide query --interactive | str trim
  } else {
    ^zoxide query --interactive -- $query | str trim
  }
  if ($selection | is-not-empty) {
    cd $selection
  }
  commandline edit ""
}

# Add FZF keybindings
$env.config.keybindings = ($env.config.keybindings | append [
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
    name: zoxide_directory_picker
    modifier: control
    keycode: char_g
    mode: [emacs vi_insert vi_normal]
    event: {
      send: executehostcommand
      cmd: "zoxide-cd"
    }
  }
])
