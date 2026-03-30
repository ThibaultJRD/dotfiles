#!/usr/bin/env bash

# Smart preview for sesh picker:
# - tmux sessions → sesh preview (pane capture)
# - directories → eza tree

if sesh list -t | grep -qx "$1"; then
  sesh preview "$1"
else
  path="${1/#\~/$HOME}"
  eza --tree --level=2 --color=always --git-ignore "$path"
fi
