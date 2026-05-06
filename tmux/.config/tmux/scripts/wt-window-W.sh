#!/usr/bin/env bash
# prefix + W handler.
# Same session creation as wt-window-w.sh, then sends an agent + task to the
# AI window (index 3). Does NOT switch the client.
#
# Usage: wt-window-W.sh <branch> [<task>]

set -euo pipefail

branch="${1:-}"
task="${2:-}"

if [[ -z "$branch" ]]; then
  tmux display-message "wt-window-W: branch name required"
  exit 2
fi

# Detect agent — same precedence as wt-agent in zsh/nu shell configs.
if [[ -n "${WT_AGENT:-}" ]]; then
  agent="$WT_AGENT"
elif command -v claude >/dev/null 2>&1; then
  agent=claude
elif command -v opencode >/dev/null 2>&1; then
  agent=opencode
else
  tmux display-message "wt-window-W: no AI agent found (set WT_AGENT, install claude/opencode)"
  exit 1
fi

wt switch --create "$branch" --no-cd

read -r repo_path worktree_path <<<"$(wt list --format=json | jq -r --arg br "$branch" '
  [
    (.[] | select(.is_main).path),
    (.[] | select(.branch == $br).path)
  ] | @tsv')"
repo=$(basename "$repo_path")

~/.config/worktrunk/scripts/wt-ensure-session.sh "$repo" "$branch" "$worktree_path"

branch_sanitized=$(printf '%s' "$branch" | sed 's![/.]!-!g')
session="$repo/WT/$branch_sanitized"

# Build the agent invocation. With a task: 'agent <quoted-task>'. Without: 'agent'.
if [[ -n "$task" ]]; then
  cmd="$agent $(printf '%q' "$task")"
else
  cmd="$agent"
fi

tmux send-keys -t "=$session:3" "$cmd" Enter
tmux display-message "worktree '$branch' running $agent in background session"
