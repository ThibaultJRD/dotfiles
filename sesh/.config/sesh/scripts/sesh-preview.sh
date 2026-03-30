#!/usr/bin/env bash

# Smart preview for sesh picker:
# - tmux sessions → sesh preview (pane capture)
# - directories → eza tree

if sesh list -t | grep -qx "$1"; then
  sesh preview "$1"
else
  eza --tree --level=2 --color=always "$1"
fi
