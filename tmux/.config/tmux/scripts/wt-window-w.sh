#!/usr/bin/env bash
# prefix + w handler.
# Creates a worktree (if missing), ensures the tmux session exists, then
# switches the current tmux client to the AI window (index 3) of that session.
#
# Usage: wt-window-w.sh <branch>

set -euo pipefail

branch="${1:-}"
if [[ -z "$branch" ]]; then
  tmux display-message "wt-window-w: branch name required"
  exit 2
fi

# Trigger creation; pre-start hook builds the session.
# --no-cd is fine here since we drive tmux ourselves.
wt switch --create "$branch" --no-cd

# Resolve repo name (from main worktree path) and the new worktree path.
read -r repo_path worktree_path <<<"$(wt list --format=json | jq -r --arg br "$branch" '
  [
    (.[] | select(.is_main).path),
    (.[] | select(.branch == $br).path)
  ] | @tsv')"
repo=$(basename "$repo_path")

# Idempotent safety net (covers worktree-exists-but-session-killed case).
~/.config/worktrunk/scripts/wt-ensure-session.sh "$repo" "$branch" "$worktree_path"

branch_sanitized=$(printf '%s' "$branch" | sed 's![/.]!-!g')
tmux switch-client -t "=$repo/WT/$branch_sanitized:3"
