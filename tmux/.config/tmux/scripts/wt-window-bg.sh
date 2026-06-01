#!/usr/bin/env bash
# prefix + W handler (background variant).
# Same session creation as wt-window-fg.sh, then sends an agent + task to the
# AI window (index 3). Does NOT switch the client.
#
# Usage: wt-window-bg.sh <branch> [<task>]

set -euo pipefail

branch="${1:-}"
task="${2:-}"

if [[ -z "$branch" ]]; then
  tmux display-message "wt-window-bg: branch name required"
  exit 2
fi

# Detect agent. Precedence: $WT_AGENT > claude > opencode > error.
if [[ -n "${WT_AGENT:-}" ]]; then
  agent="$WT_AGENT"
elif command -v claude >/dev/null 2>&1; then
  agent=claude
elif command -v opencode >/dev/null 2>&1; then
  agent=opencode
else
  tmux display-message "wt-window-bg: no AI agent found (set WT_AGENT, install claude/opencode)"
  exit 1
fi

# New branch: create the worktree. Existing branch: worktrunk errors on
# --create, so fall back to a plain switch. --base=@ branches off the current
# worktree (ignored when the branch exists).
wt switch --create "$branch" --no-cd --base=@ 2>/dev/null \
  || wt switch "$branch" --no-cd

read -r repo_path worktree_path <<<"$(wt list --format=json | jq -r --arg br "$branch" '
  [
    (.[] | select(.is_main).path),
    (.[] | select(.branch == $br).path)
  ] | @tsv')"
repo=$(basename "$repo_path")

# Ensure the session exists and capture its resolved name (handles main vs WT).
session=$(~/.config/worktrunk/scripts/wt-ensure-session.sh "$repo" "$branch" "$worktree_path")

# Build the agent invocation. The default shell here is nushell, so we wrap
# the task in double quotes (literal in both bash and nushell — nushell only
# interpolates inside $"..." strings) and backslash-escape the four chars
# that are special inside a double-quoted string in either shell.
# Order matters: escape the backslash first.
if [[ -n "$task" ]]; then
  esc=$task
  esc=${esc//\\/\\\\}
  esc=${esc//\"/\\\"}
  esc=${esc//\$/\\\$}
  esc=${esc//\`/\\\`}
  cmd="$agent \"$esc\""
else
  cmd="$agent"
fi

# Wait for nushell's first prompt in window 3 before sending the agent
# command. Without this, send-keys fires while nushell is still initializing
# — the keys get echoed by the pty in cooked mode but discarded when
# nushell switches to raw mode, so the agent never starts. Polling for the
# starship prompt indicator is enough; ~4s is plenty even on cold start.
for _ in {1..40}; do
  if tmux capture-pane -t "=$session:3" -p 2>/dev/null | grep -q '>_'; then
    break
  fi
  sleep 0.1
done

tmux send-keys -t "=$session:3" "$cmd" Enter
tmux display-message "🌿 worktree '$branch' running $agent in background session"
