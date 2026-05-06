#!/usr/bin/env bash
# Sesh startup script — creates a project-specific tmux layout.
#
# Two invocation modes:
#   - no args (sesh-mode): rides on the ghost startup pane that sesh creates;
#     `tmux` commands target the current session.
#   - 2 args (external-mode): builds the session from scratch.
#       sesh-startup.sh <session-name> <cwd>
#
# Git repos get 3 windows (git/IDE/AI). Non-git dirs get a single terminal.
# Config sessions (neovim, tmux, claude) are skipped — they are handled by
# sesh.toml startup_command.

set -euo pipefail

session_arg="${1:-}"
cwd_arg="${2:-}"

if [[ -n "$session_arg" && -n "$cwd_arg" ]]; then
  mode=external
  session="$session_arg"
  cwd="$cwd_arg"
else
  mode=sesh
  session=$(tmux display-message -p '#S')
  cwd="$(pwd)"
fi

# Skip config-session layouts in sesh-mode (their startup_command in sesh.toml
# does its own thing). External-mode never targets these names.
if [[ "$mode" == sesh ]]; then
  case "$session" in
  neovim | tmux | claude) exit 0 ;;
  esac
fi

is_git_repo() {
  git -C "$1" rev-parse --is-inside-work-tree &>/dev/null
}

# tmux helpers — target a specific window in external-mode, current session in sesh-mode.
new_window() {
  local name="$1"
  if [[ "$mode" == external ]]; then
    tmux new-window -t "$session:" -n "$name" -c "$cwd"
  else
    tmux new-window -n "$name"
  fi
}

send_keys() {
  local target_window="$1"
  local keys="$2"
  if [[ "$mode" == external ]]; then
    tmux send-keys -t "$session:$target_window" "$keys" Enter
  else
    tmux send-keys "$keys" Enter
  fi
}

if is_git_repo "$cwd"; then
  if [[ "$mode" == external ]]; then
    # Build session from zero: window 1 named "git" with no ghost.
    tmux new-session -d -s "$session" -c "$cwd" -n "󰊢 git"
    send_keys 1 "lazygit"

    new_window "󰅩 IDE"
    send_keys 2 "nvim"
    tmux split-window -t "$session:2" -v -l 25% -c "$cwd"
    tmux select-pane -t "$session:2.1"

    new_window "󰚩 AI"
    send_keys 3 "lt"

    tmux select-window -t "$session:3"
  else
    # Sesh-mode: ride the ghost pane. Indexes go 1=ghost, 2=git, 3=IDE, 4=AI;
    # ghost dies on script exit, renumber-window collapses to 1=git, 2=IDE, 3=AI.
    tmux new-window -n "󰊢 git"
    tmux send-keys "lazygit" Enter

    tmux new-window -n "󰅩 IDE"
    tmux send-keys "nvim" Enter
    tmux split-window -v -l 25%
    tmux select-pane -t :.1

    tmux new-window -n "󰚩 AI"
    tmux send-keys "lt" Enter

    tmux select-window -t :4
  fi
else
  if [[ "$mode" == external ]]; then
    tmux new-session -d -s "$session" -c "$cwd"
    send_keys 1 "lt"
  else
    tmux new-window
    tmux send-keys "lt" Enter
  fi
fi
