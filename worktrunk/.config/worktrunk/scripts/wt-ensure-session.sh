#!/usr/bin/env bash
# wt-ensure-session.sh <repo> <branch> <worktree-path>
#
# Resolves the tmux session name for a worktree, builds the session if it
# doesn't exist, and prints the resolved name on stdout (so callers can
# `tmux switch-client -t "=$(...)"` directly).
#
# Naming:
#   - main worktree (is_main: true)  → "<repo>"
#   - any other worktree             → "<repo>/WT/<branch | sanitize>"
#
# The main case keeps the parent project session unified — picking `main` in
# `wt switch` lands you back on the existing repo session, not a new
# `<repo>/WT/main` one.
#
# Called from:
#   - ~/.config/worktrunk/config.toml [pre-start] (every wt switch --create)
#   - ~/.config/tmux/scripts/wt-window-fg.sh / wt-window-bg.sh / wt-picker.sh
#
# Silently skips (still prints the resolved name) if tmux is missing, so
# wt switch --create stays usable outside tmux.

set -euo pipefail

repo="${1:-}"
branch="${2:-}"
worktree_path="${3:-}"

if [[ -z "$repo" || -z "$branch" || -z "$worktree_path" ]]; then
  echo "wt-ensure-session: usage: $0 <repo> <branch> <worktree-path>" >&2
  exit 2
fi

# Resolve session name. is_main lookup falls back to false on any error.
# Note the explicit pipe before .is_main: with `select().is_main // false`
# inside the array, non-matching entries contribute a phantom `false` via the
# alternative operator, which then beats the real match in `first`.
is_main=$(wt list --format=json 2>/dev/null \
  | jq -r --arg br "$branch" '[.[] | select(.branch == $br) | .is_main] | first // false' 2>/dev/null \
  || echo false)

if [[ "$is_main" == "true" ]]; then
  session="$repo"
else
  branch_sanitized=$(printf '%s' "$branch" | sed 's![/.]!-!g')
  session="$repo/WT/$branch_sanitized"
fi

# Always emit the resolved name so callers can pipe into switch-client.
printf '%s\n' "$session"

# tmux missing → just emit the name and exit.
command -v tmux >/dev/null 2>&1 || exit 0

# Idempotent: skip if the session is already up.
tmux has-session -t "=$session" 2>/dev/null && exit 0

~/.config/sesh/scripts/sesh-startup.sh "$session" "$worktree_path"
