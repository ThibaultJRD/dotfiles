#!/usr/bin/env bash
# prefix + g handler. Runs inside `tmux display-popup -E`.
# Opens worktrunk's native picker (`wt switch --no-cd`); on selection,
# ensures the corresponding tmux session exists and switches the client to
# the AI window (index 3).

set -euo pipefail

if ! command -v wt >/dev/null 2>&1; then
  echo "wt-picker: worktrunk not installed" >&2
  read -rp "Press enter to close..." _
  exit 1
fi

# In picker mode (no branch arg) with --no-cd, wt switch prints the selected
# branch and exits without switching. User abort → exit non-zero / empty stdout.
branch=$(wt switch --no-cd 2>/dev/null) || exit 0
[[ -z "$branch" ]] && exit 0

read -r repo_path worktree_path <<<"$(wt list --format=json | jq -r --arg br "$branch" '
  [
    (.[] | select(.is_main).path),
    (.[] | select(.branch == $br).path)
  ] | @tsv')"
repo=$(basename "$repo_path")

~/.config/worktrunk/scripts/wt-ensure-session.sh "$repo" "$branch" "$worktree_path"

branch_sanitized=$(printf '%s' "$branch" | sed 's![/.]!-!g')
tmux switch-client -t "=$repo/WT/$branch_sanitized:3"
