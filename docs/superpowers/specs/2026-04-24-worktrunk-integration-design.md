# Worktrunk Integration — Design

**Date:** 2026-04-24
**Scope:** Add `worktrunk` (binary `wt`) to the dotfiles with full integration across Brewfile, shell (zsh + nushell), tmux, sesh, starship, and per-worktree hooks. Agent-agnostic (claude or opencode, auto-detected).

## Goals

1. Install `worktrunk` declaratively via `Brewfile`.
2. Primary workflow (A): spawn AI agents (claude or opencode) in parallel on isolated git worktrees, one worktree per branch, one tmux session per worktree.
3. Secondary workflow (B): fast switching between worktrees of the current repo without stash/checkout churn.
4. Config stays portable across machines — no hard dependency on either `claude` or `opencode` being installed.

## Non-goals

- Claude Code marketplace plugin (`max-sixty/worktrunk`). Skipped because the config is shared across machines where only opencode may be installed.
- Automatic cleanup of orphaned tmux sessions when a worktree is removed. Manual for now.
- Migration of existing branches into worktrees.

## Architecture overview

```
┌─────────────────────────────────────────────────────────────┐
│ interactive zsh  ──eval──▶ wt config shell init zsh         │
│   (host shell)                                              │
│                                                             │
│ tmux sessions ──▶ nushell ──source──▶ worktrunk.nu init     │
│   (inside tmux panes)                                       │
│                                                             │
│ tmux bind prefix+W ──▶ wt-new-session.sh ──▶                │
│                        tmux new-session -d                  │
│                          wt switch --create <br> -x <agent> │
│                                                             │
│ tmux bind prefix+o (sesh picker) ──┬─▶ ctrl-t   tmux        │
│                                    ├─▶ ctrl-w   worktrees   │
│                                    └─▶ ... (existing modes) │
│                                                             │
│ starship ──▶ [custom.worktrunk] ──▶ wt list (count)         │
│ tmux status-right ──▶ ctp_worktrunk.conf ──▶ wt list        │
└─────────────────────────────────────────────────────────────┘
```

Each unit has a single purpose and communicates through well-defined boundaries:

- **Shell hooks** are the only place where `wt switch` can change the current directory. They're scoped to interactive shells.
- **`wt-agent` / `wtx`** helpers centralize agent detection. Any other component that needs to pick an agent calls them instead of re-implementing detection.
- **`wt-new-session.sh`** is the single entry point for "create worktree + spawn tmux session + launch agent". Called by the tmux bind, could be called manually or from other scripts later.
- **Sesh picker** and **prefix + W** are orthogonal: one discovers existing worktrees, the other creates new ones.

## Components

### 1. Brewfile

Add `brew "worktrunk"` to the CLI Tools block, alphabetically placed between `sesh` and `starship`. Nothing else changes.

### 2. Shell integration

#### 2a. Zsh — new file `zsh_configs/worktrunk.zsh`

```zsh
# worktrunk shell integration + agent helpers
# Only load in interactive shells with wt available
if [[ -o interactive ]] && command -v wt >/dev/null 2>&1; then
  eval "$(wt config shell init zsh)"
fi

# Detect which AI agent to use for -x spawns.
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

# Create a worktree and launch the detected agent inside it.
# Interactive use: no initial task — the agent opens, you type.
# For fire-and-forget with a task, use `prefix + W` in tmux.
# Usage: wtx <branch>
wtx() {
  local branch="$1"
  local agent
  if ! agent=$(wt-agent); then
    print -u2 "wtx: no AI agent found (set WT_AGENT, or install claude/opencode)"
    return 1
  fi
  wt switch --create "$branch" -x "$agent"
}
```

Symlinked to `~/.config/zsh/conf.d/worktrunk.zsh` by `install.sh` (existing loop).

#### 2b. Nushell — new file `nushell/.config/nushell/conf.d/worktrunk.nu`

Nushell support in worktrunk is marked experimental. Strategy: cache the init script on first run (the init output may not be idempotent to re-source). Guard the whole file on `wt` being present.

```nushell
# worktrunk shell integration + agent helpers (nushell, experimental)
let wt_init = ($nu.cache-dir | path join "worktrunk" "init.nu")

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

# Usage: wtx feat/foo
# Interactive — no initial task. For fire-and-forget with a task use prefix+W.
def wtx [branch: string] {
  let agent = (wt-agent)
  ^wt switch --create $branch -x $agent
}
```

Symlinked to `~/.config/nushell/conf.d/worktrunk.nu` by `install.sh` (existing `.config/*` loop).

**Verify at implementation time:** exact output format of `wt config shell init nu` and whether nu's `cache-dir` resolves correctly. Fall back to `~/.cache/worktrunk/init.nu` if not.

### 3. Sesh picker — `ctrl-w` worktrees mode

Edit `tmux/.config/tmux/tmux.conf`, inside the existing `bind-key "o" run-shell "sesh connect ..."` block. Add:

```
--bind 'ctrl-w:change-prompt(🌿 )+reload(wt list --format=json 2>/dev/null | jq -r ".[] | \"🌿 \\(.path)\"")'
```

…and update the header line to include `│ 🌿 C-w worktrees`.

`wt list --format=json` emits an array of worktree objects (fields: `branch`, `path`, `is_main`, `is_current`, `commit`, `ci`, `summary`, etc. — see worktrunk docs). We keep only `path` prefixed with a leaf icon so `{2..}` in `sesh connect "{2..}"` resolves to the absolute path (sesh creates/attaches a session keyed on the path).

Optional enrichment (decide during impl if readable enough): include the branch name alongside the path, e.g. `"🌿 \(.branch) → \(.path)"`, and adjust the fzf `{2..}` range to pick the path field. If it gets messy, keep it path-only.

If the jq pipeline becomes complex, extract it to `sesh/.config/sesh/scripts/wt-list-sesh.sh` for readability — same pattern as `claude-preview.sh`.

### 4. Tmux binds — two entry points for worktree creation

Two mnemonic-paired bindings added to `tmux/.config/tmux/tmux.conf`, near the existing `bind c new-window …` line:

```tmux
# prefix + W (uppercase) — fire-and-forget: new worktree in a DETACHED session
# Prompts for a branch AND a task (task is handed to the agent as initial prompt).
bind W command-prompt -p "Branch:,Task:" \
  "run-shell '~/.config/tmux/scripts/wt-new-session.sh \"%1\" \"%2\" \"#{pane_current_path}\"'"

# prefix + w (lowercase) — switch-now: new worktree in the CURRENT pane
# Prompts only for a branch — the agent opens interactively, you type in it.
bind w command-prompt -p "Branch:" "send-keys 'wtx %1' Enter"
```

Mnemonic: lowercase = "light touch, your pane, interactive"; uppercase = "big move, new session, hand off a task". `prefix + w` overrides the default `choose-window` binding — acceptable since sesh (`prefix + o` → `Ctrl-t`) already covers window/session picking far better.

(tmux `command-prompt -p` takes a single comma-separated string for multi-prompt input.)

The switch-now bind is a one-liner: `send-keys` types `wtx <branch>` + Enter into the focused pane. The shell function (zsh or nu) resolves the agent and runs `wt switch --create -x <agent>`, which replaces the pane with the interactive agent. No helper script needed.

**`tmux/.config/tmux/scripts/wt-new-session.sh`** (fire-and-forget) — new file, executable:

```bash
#!/usr/bin/env bash
# Create a new worktree in a detached tmux session, agent spawned inside.
# Usage: wt-new-session.sh <branch> <task> <repo_path>
set -euo pipefail

branch="${1:?missing branch}"
task="${2:-}"
repo_path="${3:?missing repo path}"

cd "$repo_path"

# Agent detection (mirrors wt-agent in zsh/nu)
if [[ -n "${WT_AGENT:-}" ]]; then
  agent="$WT_AGENT"
elif command -v claude >/dev/null 2>&1; then
  agent=claude
elif command -v opencode >/dev/null 2>&1; then
  agent=opencode
else
  tmux display-message "wt-new-session: no AI agent found"
  exit 1
fi

# Sanitize branch name for session name: slashes → underscores
session_name="wt-${branch//\//_}"

if [[ -n "$task" ]]; then
  tmux new-session -d -s "$session_name" -c "$repo_path" \
    "wt switch --create '$branch' -x $agent -- '$task'"
else
  tmux new-session -d -s "$session_name" -c "$repo_path" \
    "wt switch --create '$branch' -x $agent"
fi

tmux display-message "🌿 worktree '$branch' running in session '$session_name'"
```

**Why `-x` works without shell integration:** `wt switch --create ... -x <cmd>` changes directory inside worktrunk before exec'ing `<cmd>`. Shell integration is only needed for `wt switch` bare (where wt tells the parent shell to cd). The detached tmux session runs in a fresh shell that may not have the zsh hook loaded, so we rely on `-x`.

**Caveat for `prefix + w`:** send-keys types into *whatever is in the current pane*. If the user is in nvim or an agent, the keystrokes go there. The binding is user-initiated, so this is accepted behavior — documented in the workflow doc. Future improvement: detect `#{pane_current_command}` and warn if it isn't a known shell.

`install.sh` already symlinks `tmux/.config/tmux/` in full, so `wt-new-session.sh` is picked up. Executable bit must be committed (`chmod +x` before `git add`).

### 5. User-level worktrunk config (machine-wide)

New file `worktrunk/.config/worktrunk/config.toml` — minimal, commented. No machine-wide hooks: hooks are meaningful per-repo (what to copy, what to start) and belong in each repo's `.config/wt.toml`.

```toml
# worktrunk user-level config — see https://github.com/max-sixty/worktrunk
#
# This is for machine-wide defaults only. Per-project hooks, copy rules, and
# lifecycle settings belong in each repo's .config/wt.toml (checked in).
#
# Uncomment and tune as needed:
#
# [list]
# columns = ["name", "branch", "ci", "summary"]
#
# [commit.generation]
# # defaults for LLM-generated branch summaries
```

**Note — native file copying is a per-repo concern, not a dotfiles concern.** worktrunk provides `wt step copy-ignored` as a built-in subcommand. To opt a repo into automatic `.env*` copying, the repo gets:

1. A `.config/wt.toml` with:
   ```toml
   [[post-start]]
   copy = "wt step copy-ignored"
   ```
2. A `.worktreeinclude` at the repo root listing patterns to copy (gitignore-style):
   ```
   .env
   .env.local
   .env.development
   ```

This is documented in the user-facing workflow doc (§8) so the dev knows how to enable it per-project. Nothing in the shared dotfiles forces it globally — that would surprise repos that expect e.g. `node_modules` to stay per-worktree.

`install.sh` already symlinks `worktrunk/.config/worktrunk/` via the generic `.config/*` loop — no install-script change needed.

### 6. Starship module

**`starship/starship.toml`** — add a `[custom.worktrunk]` block:

```toml
[custom.worktrunk]
command = "wt list 2>/dev/null | tail -n +2 | wc -l | tr -d ' '"
when = "git rev-parse --is-inside-work-tree 2>/dev/null"
format = "[🌿$output]($style) "
style = "green"
require_repo = true
ignore_timeout = true
```

Placement: after the `[git_status]` module in the existing format string.

**Verify at implementation time:** `wt list` output format (header line present? count accurate?). If worktrunk offers a machine-readable flag (`--porcelain`, `--count`), prefer it over the `tail | wc` pipeline.

### 6b. Which-key menu integration

`tmux-which-key` (plugin `alexwforsythe/tmux-which-key`, already installed, triggered by `prefix + Space`) builds its menu from a YAML file — it does **not** auto-scan `tmux.conf` bindings. To surface our new keys (and other user bindings that are invisible in the current menu) we ship a `config.yaml`.

**tmux.conf** — two lines added before the plugin loads:

```tmux
# Use our versioned config.yaml instead of the in-plugin default
set -g @tmux-which-key-xdg-enable 1
```

With XDG mode on, the plugin reads `$XDG_CONFIG_HOME/tmux/plugins/tmux-which-key/config.yaml`, i.e. `~/.config/tmux/plugins/tmux-which-key/config.yaml`. Note that TPM clones plugins into `~/.config/tmux/modules/` (configured explicitly earlier in `tmux.conf`), so `~/.config/tmux/plugins/` is a separate, unused path — perfect for our own config without colliding with the plugin clone.

**`tmux/.config/tmux/plugins/tmux-which-key/config.yaml`** — new file. Starts from the upstream `config.example.yaml` (pulled at implementation time from the plugin repo so defaults like window/pane/session ops stay intact), then adds a `+Worktrunk` submenu plus a handful of our user bindings at the top level:

```yaml
# (abridged — full file is the upstream example + these additions)

items:
  # ... upstream defaults ...

  - separator: true
  - name: +Worktrunk
    key: W
    menu:
      - name: New worktree (switch-now → current pane)
        key: w
        command: 'command-prompt -p "Branch:" "send-keys ''wtx %%'' Enter"'
      - name: New worktree (fire-and-forget → detached session)
        key: W
        command: 'command-prompt -p "Branch:,Task:" "run-shell ''~/.config/tmux/scripts/wt-new-session.sh \"%1\" \"%2\" \"#{pane_current_path}\"''"'
      - separator: true
      - name: List worktrees (wt list)
        key: l
        command: 'display-popup -E -w 90% -h 80% "wt list"'
        transient: true

  - name: Sesh picker
    key: o
    command: 'run-shell "sesh connect ..."'  # same shell command as the bind-key "o"

  - name: Floating terminal (floax)
    key: f
    command: 'run-shell "#{TMUX_PLUGIN_MANAGER_PATH}/tmux-floax/scripts/floax.sh"'
    transient: true

  - name: URL picker
    key: u
    command: 'run-shell "#{TMUX_PLUGIN_MANAGER_PATH}/tmux-fzf-url/fzf-url.sh"'

  - name: Thumbs copy
    key: T
    command: 'run-shell "#{TMUX_PLUGIN_MANAGER_PATH}/tmux-thumbs/scripts/tmux-thumbs.sh"'
```

**Verify at implementation time:**
- Pull the current `config.example.yaml` from the plugin repo as a base (so defaults don't regress when the plugin evolves)
- Exact plugin-internal script paths for floax / fzf-url / thumbs — use `#{TMUX_PLUGIN_MANAGER_PATH}` to stay portable across machines
- Plugin's YAML quoting rules for nested single quotes in `command-prompt` — may need a reference to a `macros:` block instead of inline if escaping gets ugly

Python 3 is a runtime requirement of the plugin's build step — available by default on macOS.

### 7. Tmux status-bar module — worktree count

**`tmux/.config/tmux/custom_modules/ctp_worktrunk.conf`** — new file, follows the pattern of the existing `ctp_cpu.conf`, `ctp_memory.conf`, `primary_ip.conf` modules.

Reads the worktree count from `wt list` for the repo containing `#{pane_current_path}`. Formats as a catppuccin-styled segment (leaf icon + count). Renders empty string if not in a git repo.

Wired into `tmux.conf` by adding:
```tmux
source -F '#{d:current_file}/custom_modules/ctp_worktrunk.conf'
```
…alongside the existing three, and:
```tmux
set -agF status-right '#{E:@catppuccin_status_ctp_worktrunk}'
```
…inserted before `catppuccin_status_date_time`.

**Verify at implementation time:** exact format expected by catppuccin for custom modules. Copy the structure from `ctp_cpu.conf` verbatim and adapt.

### 8. Workflow documentation (`docs/workflow.md`)

New file: a hands-on walkthrough for a developer who knows basic vim motions (hjkl, modes, `:w`, `:q`) but hasn't touched this dotfiles setup before. Covers:

- **Starting the day**: `tmux`, `prefix + o` (sesh picker), the 6 picker modes (`C-a` all / `C-t` tmux / `C-g` configs / `C-z` zoxide / `C-f` find / `C-w` worktrees)
- **Inside a session**: the auto-layout (git / IDE / AI windows), vim-tmux-navigator (`C-hjkl` across panes and vim splits), yazi (`y`), lazygit (`lg`), splits (`|`, `-`)
- **Quick ref for tmux keybinds** table (prefix is `C-s`)
- **Worktrunk workflow** — the A+B primary use cases:
  - `wtx feat/foo "do the thing"` — switch to a new worktree now, agent running
  - `prefix + W` — queue an agent on a new worktree in the background, stay where you are
  - `prefix + o` → `ctrl-w` — switch to an existing worktree
  - `wt list` / `wt remove` / `wt merge` basics
  - `WT_AGENT` env var to pin the agent per-machine
- **Per-repo `.env` auto-copy** — how to enable in a repo via `.config/wt.toml` + `.worktreeinclude`
- **Worked example**: "you're on `main`, PR feedback asks for two independent fixes" — shows how to fan out two `prefix + W` calls, let agents work in parallel, switch between them, merge back

Tone: concrete, command-first, no fluff. Each section includes an actual command you can copy-paste. Assumes zsh/nushell basics but explains tmux/sesh/worktrunk concepts.

Also update the root `README.md`: a small "Worktrunk" line in "Tools and Integrations" pointing at `docs/workflow.md` for the full walkthrough.

## Data flow

**Creating a new worktree via `prefix + W` (fire-and-forget):**
1. User types branch + optional task at command prompt
2. `run-shell` invokes `wt-new-session.sh` with `%1`, `%2`, `#{pane_current_path}`
3. Script detects agent, sanitizes session name, calls `tmux new-session -d`
4. New session's shell runs `wt switch --create <branch> -x <agent> -- "<task>"`
5. worktrunk creates the worktree (per-repo `post-start` hook runs in the background if configured)
6. worktrunk execs `<agent>` with the task; agent starts in the worktree dir
7. User sees a `display-message` confirmation; session visible via `prefix + o` → `ctrl-t` and `ctrl-w`

**Creating a new worktree via `prefix + w` (switch-now):**
1. User types a branch name at the command prompt (no task)
2. tmux `send-keys` types `wtx <branch>` + Enter into the current pane
3. The pane's shell (zsh or nushell, function defined in §2) resolves `wtx`, detects the agent, calls `wt switch --create <branch> -x <agent>`
4. worktrunk spawns the agent interactively in the new worktree; the original pane is now the agent session

**Switching to an existing worktree:**
1. `prefix + o` opens the sesh picker
2. User presses `ctrl-w` → picker reloads with `wt list` output
3. User selects a row; `sesh connect "{2..}"` creates or switches to a tmux session for that worktree path

**Interactive shell session (not via tmux bind):**
1. `eval "$(wt config shell init zsh)"` loads the hook on shell startup
2. User runs `wt switch <branch>` or `wtx <branch> <task>`
3. Hook intercepts the `WORKTRUNK_DIRECTIVE_FILE` and cd's the shell

## Error handling

- Missing `wt` binary → shell hooks no-op (gated on `command -v wt`). No errors surfaced.
- Missing `claude` AND `opencode` → `wtx` prints error to stderr and returns 1. `wt-new-session.sh` calls `tmux display-message` and exits 1.
- Invalid branch name, existing branch conflicts, etc. → surfaced by worktrunk itself. We don't pre-validate.
- Per-repo `post-start` hooks (when the user opts in to `wt step copy-ignored`) fail in the background without blocking worktree creation — worktrunk semantics, not ours.

## Testing

Manual smoke tests after install:

1. `brew bundle --file=Brewfile` → `wt` available on PATH
2. Open new zsh → `wt --version` works; `wtx` is a function
3. Inside tmux → nushell loads worktrunk init without error; `wt-agent` returns the right agent
4. In a repo, press `prefix + W`, enter branch "test/sandbox" and a task → detached session `wt-test_sandbox` appears with the agent running inside the worktree
5. `prefix + o` → `ctrl-w` → lists the new worktree; selecting it attaches
6. Starship prompt shows 🌿1 in the repo
7. Remove worktree via `wt remove` → 🌿 segment disappears, tmux session can be killed manually
8. Unset `WT_AGENT`, uninstall both agents → `wtx foo` fails cleanly; non-agent `wt` commands still work

No automated tests — dotfiles repo doesn't have a test harness.

## Open questions / to verify during implementation

These are marked `**Verify at implementation time:**` inline above. Summary:

1. `wt config shell init nu` output format and whether re-sourcing is safe
2. `nu.cache-dir` location on macOS (should be `~/Library/Caches/nushell`)
3. Exact fzf display format for worktrees (path-only vs branch+path) — decide by eye

All resolvable post-install. No blocking design issues.

## Out of scope

- Claude Code marketplace plugin
- Automatic orphan-session cleanup
- Per-project `wt.toml` templates
- Integration with lazygit worktree view
- Atuin filtering by worktree

## Files changed summary

**Modified:**
- `Brewfile`
- `tmux/.config/tmux/tmux.conf`
- `starship/starship.toml`
- `README.md`

**Created:**
- `zsh_configs/worktrunk.zsh`
- `nushell/.config/nushell/conf.d/worktrunk.nu`
- `tmux/.config/tmux/scripts/wt-new-session.sh` (+ `chmod +x`)
- `tmux/.config/tmux/custom_modules/ctp_worktrunk.conf`
- `tmux/.config/tmux/plugins/tmux-which-key/config.yaml`
- `worktrunk/.config/worktrunk/config.toml`
- `docs/workflow.md`

`install.sh` is unchanged — the generic `.config/*` symlink loop and the `zsh_configs/*.zsh` loop already cover everything.
