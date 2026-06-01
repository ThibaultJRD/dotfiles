#!/usr/bin/env bash
# prefix + w handler (foreground variant).
# Creates a worktree (if missing), ensures the tmux session exists, then
# switches the current tmux client to the AI window (index 3) of that session.
#
# Usage: wt-window-fg.sh <branch>

set -euo pipefail

branch="${1:-}"
if [[ -z "$branch" ]]; then
  tmux display-message "wt-window-fg: branch name required"
  exit 2
fi

# New branch: create the worktree. Existing branch: worktrunk errors on
# --create, so fall back to a plain switch. --no-cd since we drive tmux here;
# --base=@ branches off the current worktree (ignored when the branch exists).
wt switch --create "$branch" --no-cd --base=@ 2>/dev/null \
  || wt switch "$branch" --no-cd

# Resolve repo name (from main worktree path) and the new worktree path.
read -r repo_path worktree_path <<<"$(wt list --format=json | jq -r --arg br "$branch" '
  [
    (.[] | select(.is_main).path),
    (.[] | select(.branch == $br).path)
  ] | @tsv')"
repo=$(basename "$repo_path")

# Ensure the session exists (covers worktree-on-disk-but-session-killed). The
# script also resolves the right name (repo for main, repo/WT/branch otherwise)
# and prints it on stdout — capture it and switch the client there.
session=$(~/.config/worktrunk/scripts/wt-ensure-session.sh "$repo" "$branch" "$worktree_path")
tmux switch-client -t "=$session:3"
