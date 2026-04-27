#!/usr/bin/env bash
# fzf picker over the current repo's worktrees. Selecting one switches to
# the existing tmux window (matched by window name == branch), or creates
# a new shell window in the worktree dir if no matching window exists.
#
# Designed to be invoked inside `tmux display-popup -E`.

set -euo pipefail

if ! command -v wt >/dev/null 2>&1; then
  echo "wt-picker: worktrunk not installed" >&2
  read -rp "Press enter to close..." _
  exit 1
fi

# One row per worktree: <branch>\t<path>\t<is_main>\t<is_current>
rows=$(wt list --format=json 2>/dev/null \
  | jq -r '.[] | [.branch, .path, (.is_main // false), (.is_current // false)] | @tsv')

if [[ -z "$rows" ]]; then
  echo "wt-picker: no worktrees (are you in a git repo?)" >&2
  read -rp "Press enter to close..." _
  exit 1
fi

# Build the fzf-displayed view. Show a leaf icon, the branch, and a tiny
# tag for main / current. Path stays as a hidden field used only after
# selection.
selection=$(printf '%s\n' "$rows" | awk -F'\t' '
  {
    tag = ""
    if ($3 == "true") tag = tag " [main]"
    if ($4 == "true") tag = tag " ←"
    printf "🌿 %-40s%s\t%s\n", $1, tag, $2
  }' \
  | fzf --delimiter='\t' \
        --with-nth=1 \
        --height=80% \
        --layout=reverse \
        --prompt='🌿 worktree › ' \
        --preview='eza --tree --level=2 --long --icons --git-ignore --color=always {2}' \
        --preview-window=right:60%,border-left)

[[ -z "$selection" ]] && exit 0

branch=$(echo "$selection" | awk -F'\t' '{print $1}' | sed -e 's/^🌿 //' -e 's/  *\[main\].*$//' -e 's/  *←.*$//' -e 's/[[:space:]]*$//')
path=$(echo "$selection" | awk -F'\t' '{print $2}')

# Outside tmux: just print a cd command and let the user paste it (or use it
# via shell function wrapper).
if [[ -z "${TMUX:-}" ]]; then
  printf 'cd %q\n' "$path"
  exit 0
fi

# In tmux: switch to existing window matching the branch name, otherwise
# create a fresh one in the worktree dir.
if tmux list-windows -F '#{window_name}' | grep -Fx -- "$branch" >/dev/null 2>&1; then
  tmux select-window -t "$branch"
else
  tmux new-window -n "$branch" -c "$path"
fi
