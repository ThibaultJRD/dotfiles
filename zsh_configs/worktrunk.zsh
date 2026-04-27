# ==============================================================================
# Worktrunk Shell Integration
# ==============================================================================
# Git worktree manager with AI-agent spawning. Binary: wt.
#
# - Shell hook: enables `wt switch` to cd the parent shell.
# - Helpers: wt-agent (auto-detect claude/opencode), wtx (switch-now).

# Only load in interactive shells with wt available.
if [[ -o interactive ]] && command -v wt >/dev/null 2>&1; then
  eval "$(wt config shell init zsh)"
fi

# Detect which AI agent to spawn inside a new worktree.
# Precedence: $WT_AGENT > claude > opencode > error
wt-agent() {
  if [[ -n "$WT_AGENT" ]]; then
    print -- "$WT_AGENT"
  elif command -v claude >/dev/null 2>&1; then
    print -- claude
  elif command -v opencode >/dev/null 2>&1; then
    print -- opencode
  else
    return 1
  fi
}

# Create a worktree and launch the detected agent inside it interactively.
# Usage: wtx <branch>
wtx() {
  local branch="$1"
  local agent
  if [[ -z "$branch" ]]; then
    print -u2 "wtx: branch name required"
    return 1
  fi
  if ! agent=$(wt-agent); then
    print -u2 "wtx: no AI agent found (set WT_AGENT, or install claude/opencode)"
    return 1
  fi
  wt switch --create "$branch" -x "$agent"
}
