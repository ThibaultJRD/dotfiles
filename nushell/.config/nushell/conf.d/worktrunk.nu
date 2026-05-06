# ==============================================================================
# Worktrunk Shell Integration (nushell — experimental upstream)
# ==============================================================================
# Loads worktrunk's shell hook so `wt switch` can cd the parent shell.
# Binary: wt. The actual workflow lives in tmux bindings (prefix + w/W/g).

# `source` requires a parse-time constant path, so we use const here.
# The cache file is generated on first run by the block below — re-sourcing
# the live `wt config shell init` output isn't guaranteed idempotent.
const wt_init = $nu.cache-dir + "/worktrunk/init.nu"

if (which wt | is-not-empty) {
  if not ($wt_init | path exists) {
    mkdir ($wt_init | path dirname)
    ^wt config shell init nu | save --force $wt_init
  }
  source $wt_init
}
