#!/usr/bin/env bash

# Sesh startup script — creates a project-specific tmux layout.
# Git repos get 3 windows (git/ide/AI), non-git dirs get a single terminal.
# Config sessions (neovim, tmux, claude) are handled by sesh.toml startup_command.

session_name=$(tmux display-message -p '#S')
case "$session_name" in
neovim | tmux | claude) exit 0 ;;
esac

if git rev-parse --is-inside-work-tree &>/dev/null; then
  # Window: rename to "git" and launch lazygit
  tmux new-window -n "󰊢 git"
  tmux send-keys "lazygit" Enter

  # Window: "IDE" — nvim (75%) + terminal (25%) stacked vertically
  tmux new-window -n "󰅩 IDE"
  tmux send-keys "nvim" Enter
  tmux split-window -v -l 25%
  tmux select-pane -t :.1

  # Window: "AI" — show project tree
  tmux new-window -n "󰚩 AI"
  tmux send-keys "lt" Enter

  # Start on window (AI) to see project tree
  tmux select-window -t :4
else
  # Non-git: show project tree
  tmux new-window
  tmux send-keys "lt" Enter
fi
