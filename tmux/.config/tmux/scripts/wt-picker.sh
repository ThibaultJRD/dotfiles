#!/usr/bin/env bash
# prefix + g handler. Runs inside `tmux display-popup -E`.
# Opens worktrunk's interactive picker, then ensures the selected worktree's
# tmux session exists and switches the client to its AI window (index 3).
#
# --format json reports the selection on stdout while the picker draws on the
# tty; an aborted picker exits non-zero or returns an empty result.

set -euo pipefail

if ! command -v wt >/dev/null 2>&1; then
  echo "wt-picker: worktrunk not installed" >&2
  read -rp "Press enter to close..." _
  exit 1
fi

result=$(wt switch --no-cd --format json) || exit 0
branch=$(jq -r '.branch // empty' <<<"$result")
worktree_path=$(jq -r '.path // empty' <<<"$result")
[[ -z "$branch" || -z "$worktree_path" ]] && exit 0

# repo name = basename of the main worktree path.
repo=$(basename "$(wt list --format=json | jq -r '.[] | select(.is_main) | .path')")

# Ensure the session exists and capture its resolved name (handles main vs WT).
session=$(~/.config/worktrunk/scripts/wt-ensure-session.sh "$repo" "$branch" "$worktree_path")
tmux switch-client -t "=$session:3"
