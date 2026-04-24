# ==============================================================================
# Worktrunk Shell Integration (nushell — experimental upstream)
# ==============================================================================

# source requires a parse-time constant path, so we use const here.
# The cache file is generated on first run by the block below.
const wt_init = $nu.cache-dir + "/worktrunk/init.nu"

# Cache the init script on first run — re-sourcing isn't guaranteed idempotent.
if (which wt | is-not-empty) {
  if not ($wt_init | path exists) {
    mkdir ($wt_init | path dirname)
    ^wt config shell init nu | save --force $wt_init
  }
  source $wt_init
}

# Precedence: $env.WT_AGENT > claude > opencode > error
def wt-agent [] {
  if ("WT_AGENT" in $env) and (not ($env.WT_AGENT | is-empty)) {
    $env.WT_AGENT
  } else if (which claude | is-not-empty) {
    "claude"
  } else if (which opencode | is-not-empty) {
    "opencode"
  } else {
    error make { msg: "no AI agent found (set WT_AGENT, or install claude/opencode)" }
  }
}

# Create a worktree and spawn the detected agent interactively.
# Usage: wtx feat/foo
def wtx [branch: string] {
  let agent = (wt-agent)
  ^wt switch --create $branch -x $agent
}
