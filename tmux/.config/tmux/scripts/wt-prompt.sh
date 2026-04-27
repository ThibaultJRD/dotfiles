#!/usr/bin/env bash
# Interactive prompt wrapper for wt-new-worktree-window.sh.
# Used by the which-key menu where deeply-nested tmux command-prompt
# escaping is unreliable. Runs inside `display-popup -E`.
#
# Usage: wt-prompt.sh <switch|detached>
#   switch    — prompt for branch only, focus the new window
#   detached  — prompt for branch + task, leave focus on current window

set -euo pipefail

mode="${1:?usage: wt-prompt.sh <switch|detached>}"

read -rp "Branch: " branch
[[ -z "$branch" ]] && exit 0

case "$mode" in
  detached)
    read -rp "Task: " task
    exec ~/.config/tmux/scripts/wt-new-worktree-window.sh --detached "$branch" "$task"
    ;;
  switch)
    exec ~/.config/tmux/scripts/wt-new-worktree-window.sh "$branch"
    ;;
  *)
    echo "wt-prompt: unknown mode: $mode" >&2
    exit 2
    ;;
esac
