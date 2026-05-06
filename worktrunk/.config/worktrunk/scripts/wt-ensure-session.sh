#!/usr/bin/env bash
# wt-ensure-session.sh <repo> <branch> <worktree-path>
#
# Idempotent: if a tmux session named "<repo>/WT/<branch | sanitize>" already
# exists, exit 0. Otherwise call sesh-startup.sh in external-mode to build it.
#
# Called from:
#   - ~/.config/worktrunk/config.toml [pre-start] (every wt switch --create)
#   - ~/.config/tmux/scripts/wt-window-fg.sh / wt-window-bg.sh / wt-picker.sh
#
# Silently skips if tmux is missing (so wt switch --create stays usable when
# tmux isn't around — wt switch is shell-agnostic, the hook shouldn't gate it).

set -euo pipefail

repo="${1:-}"
branch="${2:-}"
worktree_path="${3:-}"

if [[ -z "$repo" || -z "$branch" || -z "$worktree_path" ]]; then
  echo "wt-ensure-session: usage: $0 <repo> <branch> <worktree-path>" >&2
  exit 2
fi

command -v tmux >/dev/null 2>&1 || exit 0

# Mirror worktrunk's `sanitize` filter (replace / and . with -).
branch_sanitized=$(printf '%s' "$branch" | sed 's![/.]!-!g')
session="$repo/WT/$branch_sanitized"

if tmux has-session -t "=$session" 2>/dev/null; then
  exit 0
fi

~/.config/sesh/scripts/sesh-startup.sh "$session" "$worktree_path"
