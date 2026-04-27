#!/usr/bin/env bash
# Open a tmux WINDOW in a git worktree (creating the worktree if missing).
#
# Default (shell mode): focused window with a plain shell. Idempotent — if
#   a window with the branch name already exists in the current session,
#   jump to it instead of creating a duplicate.
#
# --agent [<task>]: detached window running the AI agent (claude/opencode),
#   with the optional task as initial prompt. Always creates a new window.
#   When the agent exits, `exec $SHELL` keeps the window alive as a shell
#   in the worktree dir.
#
# Usage:
#   wt-new-worktree-window.sh <branch>
#   wt-new-worktree-window.sh <branch> --agent
#   wt-new-worktree-window.sh <branch> --agent "<task>"

set -euo pipefail

branch=""
agent_mode=0
task=""

while (($#)); do
  case "$1" in
    --agent)
      agent_mode=1
      shift
      # Optional task after --agent (anything not starting with --)
      if (($#)) && [[ "$1" != --* ]]; then
        task="$1"
        shift
      fi
      ;;
    *)
      if [[ -z "$branch" ]]; then
        branch="$1"
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

# Pre-create the worktree (silent no-op if it exists)
wt switch --create "$branch" >/dev/null 2>&1 || true

# Resolve the worktree path
worktree_path=$(wt list --format=json 2>/dev/null \
  | jq -r --arg br "$branch" '.[] | select(.branch == $br) | .path' 2>/dev/null \
  | head -1)

if [[ -z "$worktree_path" || ! -d "$worktree_path" ]]; then
  tmux display-message "wt-new-worktree-window: could not resolve worktree path for '$branch'"
  exit 1
fi

# ---- Shell mode (default, idempotent) ---------------------------------------
if ((!agent_mode)); then
  # If a window with the same name already exists, jump to it instead
  # of creating a duplicate. Use window_id to avoid select-window's
  # ambiguous-target error if multiple windows share the name.
  window_id=$(tmux list-windows -F '#{window_id} #{window_name}' \
    | awk -v name="$branch" '$2 == name {print $1; exit}')

  if [[ -n "$window_id" ]]; then
    tmux select-window -t "$window_id"
  else
    tmux new-window -n "$branch" -c "$worktree_path"
  fi
  exit 0
fi

# ---- Agent mode (detached, always creates) ----------------------------------
# Detect which agent to spawn. Mirrors wt-agent() in the shell configs.
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

agent_q=$(printf '%q' "$agent")
shell_q=$(printf '%q' "${SHELL:-/bin/sh}")

if [[ -n "$task" ]]; then
  task_q=$(printf '%q' "$task")
  cmd="$agent_q $task_q; exec $shell_q"
else
  cmd="$agent_q; exec $shell_q"
fi

tmux new-window -d -n "$branch" -c "$worktree_path" "$cmd"
tmux display-message "🌿 worktree '$branch' running in background window"
