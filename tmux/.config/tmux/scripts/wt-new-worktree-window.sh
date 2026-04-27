#!/usr/bin/env bash
# Create a new git worktree in a new tmux WINDOW (inside the current session).
# Window name becomes the branch name; window cwd is the worktree path.
# The agent runs inside the window; when it exits, `exec $SHELL` takes over so
# the window persists with a shell still inside the worktree.
#
# Usage: wt-new-worktree-window.sh <branch> [<task>] [--detached]
#
#   --detached (or -d)  create the window in the background, stay on the
#                       current window. Without this flag the new window
#                       gets focus.

set -euo pipefail

detached=0
branch=""
task=""

while (($#)); do
  case "$1" in
    -d|--detached) detached=1; shift ;;
    *)
      if [[ -z "$branch" ]]; then
        branch="$1"
      elif [[ -z "$task" ]]; then
        task="$1"
      else
        echo "wt-new-worktree-window: unexpected arg: $1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [[ -z "$branch" ]]; then
  echo "wt-new-worktree-window: branch name required" >&2
  exit 2
fi

# Agent detection — mirrors wt-agent() in the shell configs.
if [[ -n "${WT_AGENT:-}" ]]; then
  agent="$WT_AGENT"
elif command -v claude >/dev/null 2>&1; then
  agent=claude
elif command -v opencode >/dev/null 2>&1; then
  agent=opencode
else
  tmux display-message "wt-new-worktree-window: no AI agent found (install claude or opencode, or set WT_AGENT)"
  exit 1
fi

# Pre-create the worktree from outside tmux so we can resolve its path and
# pass `-c <path>` to `tmux new-window`. This way the new window starts
# directly inside the worktree dir — no shell-integration warning, and
# `exec $SHELL` (after the agent exits) lands in the right cwd.
wt switch --create "$branch" >/dev/null 2>&1 || true

# Find the worktree path for the branch from `wt list --format=json`.
worktree_path=$(wt list --format=json 2>/dev/null \
  | jq -r --arg br "$branch" '.[] | select(.branch == $br) | .path' 2>/dev/null \
  | head -1)

if [[ -z "$worktree_path" || ! -d "$worktree_path" ]]; then
  tmux display-message "wt-new-worktree-window: could not resolve worktree path for '$branch'"
  exit 1
fi

# Shell-escape values for the final `sh -c <string>` that tmux new-window runs.
agent_q=$(printf '%q' "$agent")
shell_q=$(printf '%q' "${SHELL:-/bin/sh}")

# The window starts in the worktree (-c). The agent runs there, and when it
# exits `exec $SHELL` keeps the window alive as a shell in the worktree.
if [[ -n "$task" ]]; then
  task_q=$(printf '%q' "$task")
  cmd="$agent_q $task_q; exec $shell_q"
else
  cmd="$agent_q; exec $shell_q"
fi

# -d = detached (don't switch to the new window)
new_window_flags=(-n "$branch" -c "$worktree_path")
if ((detached)); then
  new_window_flags=(-d "${new_window_flags[@]}")
fi

tmux new-window "${new_window_flags[@]}" "$cmd"

if ((detached)); then
  tmux display-message "🌿 worktree '$branch' running in background window"
fi
