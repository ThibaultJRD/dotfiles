#!/usr/bin/env bash
# Create a new worktree in a DETACHED tmux session, with the detected AI
# agent spawned inside it. Called by the `prefix + W` bind.
#
# Usage: wt-new-session.sh <branch> <task> <repo_path>

set -euo pipefail

branch="${1:?missing branch}"
task="${2:-}"
repo_path="${3:?missing repo path}"

cd "$repo_path"

# Agent detection — mirrors wt-agent() in zsh_configs/worktrunk.zsh.
if [[ -n "${WT_AGENT:-}" ]]; then
  agent="$WT_AGENT"
elif command -v claude >/dev/null 2>&1; then
  agent=claude
elif command -v opencode >/dev/null 2>&1; then
  agent=opencode
else
  tmux display-message "wt-new-session: no AI agent found (install claude or opencode, or set WT_AGENT)"
  exit 1
fi

# Sanitize branch → tmux session name (slashes illegal in session names).
session_name="wt-${branch//\//_}"

if [[ -n "$task" ]]; then
  tmux new-session -d -s "$session_name" -c "$repo_path" \
    "wt switch --create '$branch' -x $agent -- '$task'"
else
  tmux new-session -d -s "$session_name" -c "$repo_path" \
    "wt switch --create '$branch' -x $agent"
fi

tmux display-message "🌿 worktree '$branch' running in session '$session_name'"
