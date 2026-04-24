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

# Pre-resolve the worktree path from worktrunk BEFORE we open the window, so
# we can pass `-c <path>` to tmux new-window. `wt path` prints the absolute
# worktree path for a branch, creating the worktree if missing.
#
# We also need to know if the branch is new or existing: `wt switch --create`
# works for both, but if the worktree already exists we'd want to reuse it.
# Simplest: let worktrunk's `wt switch --create` handle both paths; we just
# need to know the target path afterwards.
#
# Strategy: use `wt path <branch>` as a pure query if available; otherwise
# fall back to letting `wt switch --create` cd us as part of the `-x` flow
# (no `-c` on new-window in that case — inherit from current pane).
if worktree_path=$(wt path "$branch" 2>/dev/null) && [[ -n "$worktree_path" ]]; then
  # Ensure worktree exists (no-op if present)
  wt switch --create "$branch" >/dev/null 2>&1 || true
  cwd_flag=(-c "$worktree_path")
else
  # `wt path` not available or errored — skip pre-creation, let -x handle it,
  # new-window will start from the current pane's cwd.
  cwd_flag=()
fi

# Shell-escape values for the final `sh -c <string>` that tmux new-window runs.
branch_q=$(printf '%q' "$branch")
agent_q=$(printf '%q' "$agent")
shell_q=$(printf '%q' "${SHELL:-/bin/sh}")

if [[ -n "$task" ]]; then
  task_q=$(printf '%q' "$task")
  cmd="wt switch --create $branch_q -x $agent_q -- $task_q; exec $shell_q"
else
  cmd="wt switch --create $branch_q -x $agent_q; exec $shell_q"
fi

# -d = detached (don't switch to the new window)
new_window_flags=(-n "$branch")
if ((detached)); then
  new_window_flags=(-d "${new_window_flags[@]}")
fi

tmux new-window "${new_window_flags[@]}" "${cwd_flag[@]}" "$cmd"

if ((detached)); then
  tmux display-message "🌿 worktree '$branch' running in background window"
fi
