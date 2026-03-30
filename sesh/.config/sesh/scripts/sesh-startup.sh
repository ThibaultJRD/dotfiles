#!/usr/bin/env bash

# Sesh startup script — creates a project-specific tmux layout.
# Git repos get 3 windows (git/ide/AI), non-git dirs get a single terminal.

if git rev-parse --is-inside-work-tree &>/dev/null; then
  # Window 1: rename to "git" and launch lazygit
  tmux rename-window "git"
  tmux send-keys "lazygit" Enter

  # Window 2: "ide" — nvim (75%) + terminal (25%) stacked vertically
  tmux new-window -n "ide"
  tmux send-keys "nvim" Enter
  tmux split-window -v -l 25%
  tmux select-pane -t :.1

  # Window 3: "AI" — show project tree
  tmux new-window -n "AI"
  tmux send-keys "eza --tree --level=2 --color=always" Enter

  # Return to window 1 (git)
  tmux select-window -t :1
fi
