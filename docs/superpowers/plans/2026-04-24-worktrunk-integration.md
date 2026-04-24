# Worktrunk Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate `worktrunk` (binary `wt`) across the dotfiles: Brewfile install, zsh + nushell shell hooks, two tmux binds (`prefix + W` fire-and-forget, `prefix + w` switch-now), sesh picker mode, starship + tmux status bar modules, which-key menu, and user docs.

**Architecture:** Agent-agnostic (auto-detects `claude` → `opencode`, override via `$WT_AGENT`). One worktree = one tmux session. No Claude Code marketplace plugin (config is shared across machines).

**Tech Stack:** zsh, nushell, tmux + tpm plugins (sesh, tmux-which-key, catppuccin), starship, worktrunk (Rust CLI), homebrew.

**Branch:** work already lives on `feat/worktrunk`. Each task commits independently.

**Reference spec:** `docs/superpowers/specs/2026-04-24-worktrunk-integration-design.md`

**Testing philosophy:** This is a dotfiles repo — no test harness. Each task has manual smoke tests with exact commands and expected output. Config-file syntax is checked where a dry-run exists (`tmux source-file -F`, `zsh -n`, `nu --commands 'source x.nu'`).

---

## Task 1: Install worktrunk via Brewfile

**Files:**
- Modify: `Brewfile:29` (add line between `sesh` and `starship`)

- [ ] **Step 1: Add worktrunk to Brewfile**

Edit `Brewfile`, add the line `brew "worktrunk"` after `brew "starship"` to keep the existing alphabetical-ish ordering broken by the original file (the file is not strictly alphabetical — insert where natural).

Current relevant block (context):
```
brew "sesh"
brew "sevenzip"
brew "starship"
brew "tmux"
```

After edit:
```
brew "sesh"
brew "sevenzip"
brew "starship"
brew "tmux"
brew "worktrunk"
brew "yazi"
```

(Placed after `tmux` to keep the ordering the file already uses: `s…`, `t…`, `w…`, `y…`.)

- [ ] **Step 2: Install via brew bundle**

Run: `brew bundle --file=Brewfile`
Expected: worktrunk downloads and installs. If already installed, brew reports `Using worktrunk`.

- [ ] **Step 3: Verify wt is on PATH**

Run: `wt --version`
Expected: version string (e.g. `worktrunk 0.x.y`). If "command not found", open a fresh terminal to pick up the new PATH.

- [ ] **Step 4: Explore wt for design-time unknowns**

Run these to validate assumptions the spec marked TBD:

```sh
wt list --format=json 2>/dev/null | head -20
wt config shell init nu | head -10
wt config shell init zsh | head -10
```

Expected: JSON array from the first (even if empty `[]`), shell init scripts from the last two. Note any deviation and adjust subsequent tasks inline.

- [ ] **Step 5: Commit**

```bash
git add Brewfile
git commit -m "chore: add worktrunk to Brewfile"
```

---

## Task 2: User-level worktrunk config

**Files:**
- Create: `worktrunk/.config/worktrunk/config.toml`

- [ ] **Step 1: Create config directory and file**

Create `worktrunk/.config/worktrunk/config.toml` with the content below.

```toml
# worktrunk user-level config — see https://github.com/max-sixty/worktrunk
#
# Machine-wide defaults only. Per-project hooks, copy rules, and lifecycle
# settings belong in each repo's .config/wt.toml (checked in).
#
# Uncomment and tune as needed:
#
# [list]
# columns = ["name", "branch", "ci", "summary"]
#
# [commit.generation]
# # defaults for LLM-generated branch summaries
```

- [ ] **Step 2: Run install.sh to create the symlink**

Run: `cd /Users/thibault/dotfiles && ./install.sh`

Expected: somewhere in the output `✓ Linked '.../worktrunk/.config/worktrunk' to '/Users/thibault/.config/worktrunk'`.

- [ ] **Step 3: Verify the symlink resolves**

Run: `readlink ~/.config/worktrunk && ls ~/.config/worktrunk/`

Expected: points at the dotfiles path, lists `config.toml`.

- [ ] **Step 4: Verify wt reads it**

Run: `wt config show 2>&1 | head -20`

Expected: command runs without error (even if config is all comments). If worktrunk has no `config show` subcommand, skip — just ensuring the file is syntactically valid via `wt list` still succeeding.

- [ ] **Step 5: Commit**

```bash
git add worktrunk/.config/worktrunk/config.toml
git commit -m "feat(worktrunk): add user-level config.toml"
```

---

## Task 3: Zsh shell integration

**Files:**
- Create: `zsh_configs/worktrunk.zsh`

- [ ] **Step 1: Write the zsh integration file**

Create `zsh_configs/worktrunk.zsh` with:

```zsh
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
```

- [ ] **Step 2: Syntax check**

Run: `zsh -n zsh_configs/worktrunk.zsh`
Expected: no output (success). Any output is a syntax error — fix before proceeding.

- [ ] **Step 3: Re-run install.sh to link it**

Run: `cd /Users/thibault/dotfiles && ./install.sh`
Expected: log line `✓ Linked '.../zsh_configs/worktrunk.zsh' to '/Users/thibault/.config/zsh/conf.d/worktrunk.zsh'`.

- [ ] **Step 4: Smoke test in a fresh zsh**

Run: `zsh -i -c 'type wtx && type wt-agent && wt-agent'`

Expected output (roughly):
```
wtx is a shell function from /Users/thibault/.config/zsh/conf.d/worktrunk.zsh
wt-agent is a shell function from /Users/thibault/.config/zsh/conf.d/worktrunk.zsh
claude    # or opencode, depending on what's installed
```

- [ ] **Step 5: Verify shell-integration hook loaded**

Run: `zsh -i -c 'typeset -f | grep -A2 "^_wt_" | head -20'`

Expected: some function names starting with `_wt_` or similar (whatever `wt config shell init zsh` defines). Non-empty = hook is present. Exact names depend on worktrunk's shell-init output.

- [ ] **Step 6: Commit**

```bash
git add zsh_configs/worktrunk.zsh
git commit -m "feat(zsh): worktrunk shell integration + wtx helper"
```

---

## Task 4: Nushell shell integration

**Files:**
- Create: `nushell/.config/nushell/conf.d/worktrunk.nu`

- [ ] **Step 1: Inspect `wt config shell init nu` output**

Run: `wt config shell init nu`

Expected: nu-formatted code. **If the command errors or prints something that won't source** (nushell is experimental in worktrunk), the integration falls back to just the helpers without the cd hook. Note which case you're in — it affects Step 2.

- [ ] **Step 2: Write the nushell integration file**

Create `nushell/.config/nushell/conf.d/worktrunk.nu` with:

```nushell
# ==============================================================================
# Worktrunk Shell Integration (nushell — experimental upstream)
# ==============================================================================

# Cache the init script on first run — re-sourcing isn't guaranteed idempotent.
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

# Create a worktree and spawn the detected agent interactively.
# Usage: wtx feat/foo
def wtx [branch: string] {
  let agent = (wt-agent)
  ^wt switch --create $branch -x $agent
}
```

**If Step 1 showed `wt config shell init nu` errors:** wrap the `source $wt_init` line like:
```nushell
try { source $wt_init }
```
So the shell keeps loading even if the init script is broken on this worktrunk version.

- [ ] **Step 3: Verify `nu.cache-dir` path on macOS**

Run: `nu -c 'print $nu.cache-dir'`

Expected: something like `/Users/thibault/Library/Caches/nushell`. If it's `null` or errors on your nu version, edit the file to hardcode `~/.cache/worktrunk/init.nu`.

- [ ] **Step 4: Syntax check via nu's parser**

Run: `nu --commands "let x = 'nushell/.config/nushell/conf.d/worktrunk.nu'; ^nu -c $'source ($x)'"`

A cleaner alternative:
```
nu -c "source nushell/.config/nushell/conf.d/worktrunk.nu; wt-agent"
```

Expected: prints the agent name (`claude` or `opencode`) with no errors. A parse error would fail immediately.

- [ ] **Step 5: Re-run install.sh (symlink)**

Run: `cd /Users/thibault/dotfiles && ./install.sh`

Expected: the `worktrunk.nu` is now visible at `~/.config/nushell/conf.d/worktrunk.nu` via the `nushell/.config/nushell` directory symlink. (No new line from install.sh since it symlinks the parent dir, not individual files.)

- [ ] **Step 6: Smoke test in nu**

Run: `nu -c 'wtx | describe'`

Expected: describes the function (nu built-in `describe` on a command). Or: `nu -c 'wt-agent'` prints the agent name.

- [ ] **Step 7: Commit**

```bash
git add nushell/.config/nushell/conf.d/worktrunk.nu
git commit -m "feat(nushell): worktrunk shell integration + wtx helper"
```

---

## Task 5: Fire-and-forget helper script

**Files:**
- Create: `tmux/.config/tmux/scripts/wt-new-session.sh` (executable)

- [ ] **Step 1: Create the scripts directory**

Run: `mkdir -p tmux/.config/tmux/scripts`

- [ ] **Step 2: Write the script**

Create `tmux/.config/tmux/scripts/wt-new-session.sh` with:

```bash
#!/usr/bin/env bash
# Create a new worktree in a DETACHED tmux session, with the detected AI
# agent spawned inside it. Called by the `prefix + W` bind.
#
# Usage: wt-new-session.sh <branch> <task> <repo_path>

set -euo pipefail

branch="${1:?missing branch}"
task="${2:-}"
repo_path="${3:?missing repo path}"

cd "$repo_path"

# Agent detection — mirrors wt-agent() in zsh_configs/worktrunk.zsh.
if [[ -n "${WT_AGENT:-}" ]]; then
  agent="$WT_AGENT"
elif command -v claude >/dev/null 2>&1; then
  agent=claude
elif command -v opencode >/dev/null 2>&1; then
  agent=opencode
else
  tmux display-message "wt-new-session: no AI agent found (install claude or opencode, or set WT_AGENT)"
  exit 1
fi

# Sanitize branch → tmux session name (slashes illegal in session names).
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

- [ ] **Step 3: Make it executable**

Run: `chmod +x tmux/.config/tmux/scripts/wt-new-session.sh`

- [ ] **Step 4: Shell-syntax check**

Run: `bash -n tmux/.config/tmux/scripts/wt-new-session.sh`

Expected: no output.

- [ ] **Step 5: Dry smoke test — argument parsing only**

Run the script with deliberately missing args to confirm error messages:

```sh
tmux/.config/tmux/scripts/wt-new-session.sh 2>&1 || true
```

Expected: `wt-new-session.sh: line X: 1: missing branch` or similar.

Don't try the full path yet (requires tmux running and a real git repo) — that's Task 6.

- [ ] **Step 6: Commit**

```bash
git add tmux/.config/tmux/scripts/wt-new-session.sh
git commit -m "feat(tmux): add wt-new-session.sh for fire-and-forget worktree spawn"
```

---

## Task 6: Tmux binds — `prefix + W` and `prefix + w`

**Files:**
- Modify: `tmux/.config/tmux/tmux.conf:15` (add two binds after `bind c new-window …`)

- [ ] **Step 1: Edit tmux.conf**

Locate the block starting at line 15 (`bind c new-window -c "#{pane_current_path}"`). After the `bind -r L resize-pane -R 5` line (line 19), insert:

```tmux

# Worktrunk binds — see docs/workflow.md
# prefix + W (uppercase) — fire-and-forget: new worktree in a DETACHED session
bind W command-prompt -p "Branch:,Task:" \
  "run-shell '~/.config/tmux/scripts/wt-new-session.sh \"%1\" \"%2\" \"#{pane_current_path}\"'"

# prefix + w (lowercase) — switch-now: new worktree in the CURRENT pane (overrides default choose-window)
bind w command-prompt -p "Branch:" "send-keys 'wtx %1' Enter"
```

- [ ] **Step 2: Validate tmux syntax**

Run: `tmux -f /dev/null new-session -d -s _syntax_check "echo ok" \; source-file -F tmux/.config/tmux/tmux.conf \; kill-session -t _syntax_check 2>&1 | head -30`

Expected: no parse errors. Warnings about missing plugins (`no such file: tpm/tpm`) are fine — we're just checking syntax of the file itself.

A simpler alternative if the above is flaky: reload inside your running tmux with `prefix + r` and watch for "Config reloaded!" without error popups.

- [ ] **Step 3: Reload config in your live tmux**

Inside tmux press: `prefix + r`
Expected: status bar flashes `Config reloaded!`.

- [ ] **Step 4: Smoke-test `prefix + w` (switch-now)**

Inside a pane that is at a shell prompt in a git repo:

Press: `prefix + w`, type `test/wtx-smoke`, press Enter.

Expected: `wtx test/wtx-smoke` appears in the pane and runs, creating a worktree and launching the agent (claude or opencode).

Clean up: exit the agent, then run `wt remove test/wtx-smoke` from anywhere inside the repo.

- [ ] **Step 5: Smoke-test `prefix + W` (fire-and-forget)**

From any pane inside a git repo:

Press: `prefix + W`, `Branch:` type `test/fireforget-smoke`, `Task:` type `say hi then exit`, Enter.

Expected:
- Status message "🌿 worktree 'test/fireforget-smoke' running in session 'wt-test_fireforget-smoke'"
- Your current pane is unchanged
- `prefix + o` → `Ctrl-t` shows the new session `wt-test_fireforget-smoke`

Clean up: switch to the new session, exit the agent, `wt remove test/fireforget-smoke`, then `tmux kill-session -t wt-test_fireforget-smoke`.

- [ ] **Step 6: Commit**

```bash
git add tmux/.config/tmux/tmux.conf
git commit -m "feat(tmux): add prefix+W (fire-and-forget) and prefix+w (switch-now) binds"
```

---

## Task 7: Sesh picker — `Ctrl-w` worktrees mode

**Files:**
- Modify: `tmux/.config/tmux/tmux.conf:61-76` (inside the `bind-key "o" run-shell "sesh connect ..."` block)

- [ ] **Step 1: Confirm `wt list --format=json` output**

Run: `cd` into a repo with at least one worktree, then:

```sh
wt list --format=json | jq -r '.[] | "🌿 \(.path)"'
```

Expected: one line per worktree, each starting with `🌿 ` followed by an absolute path. If this fails (missing `path` field, invalid JSON), adjust the jq expression before editing tmux.conf. Candidates for the field: `.path`, `.worktree_path`, `.worktree.path` — pick whichever matches the real output from Task 1 step 4.

- [ ] **Step 2: Edit the sesh picker block**

Open `tmux/.config/tmux/tmux.conf` and find the `bind-key "o" run-shell` block (lines 61-76 in the current file). Update two things:

**2a. Update the header line (line 64):**

From:
```
--header $'⚡ C-a all  │ 🪟 C-t tmux │ ⚙️ C-g configs │ 📁 C-z zoxide\n🔎 C-f find │ ❌ C-x kill │ 🖱️ C-d/u scroll' \
```

To:
```
--header $'⚡ C-a all  │ 🪟 C-t tmux │ ⚙️ C-g configs │ 📁 C-z zoxide\n🔎 C-f find │ 🌿 C-w worktrees │ ❌ C-x kill │ 🖱️ C-d/u scroll' \
```

**2b. Add a new `--bind` after the existing `ctrl-f` bind (line 71):**

```
    --bind 'ctrl-w:change-prompt(🌿 )+reload(wt list --format=json 2>/dev/null | jq -r ".[] | \"🌿 \\(.path)\"")' \
```

Place it between the existing `ctrl-f` and `ctrl-x` bindings so the order matches the header.

- [ ] **Step 3: Reload tmux config**

Inside tmux: `prefix + r`.

- [ ] **Step 4: Smoke-test the new picker mode**

Inside a repo with 1+ worktrees, press `prefix + o`, then `Ctrl-w`.

Expected:
- Prompt changes to `🌿 `
- List shows `🌿 <path>` lines from `wt list --format=json`
- Pressing `Enter` on one creates or attaches to a sesh session at that path
- `sesh connect` is happy with the path (it strips the icon via `{2..}` which already matches other binds)

If `{2..}` doesn't resolve correctly, move to a 2-field format where the path is field 2: `--bind 'ctrl-w:...reload(wt list --format=json | jq -r ".[] | \"🌿 \(.path)\"")'` — this already works because `{2..}` = everything from token 2 onwards and the path is token 2. Verify by looking at the selected string.

- [ ] **Step 5: Commit**

```bash
git add tmux/.config/tmux/tmux.conf
git commit -m "feat(sesh): ctrl-w worktrees mode in the prefix+o picker"
```

---

## Task 8: Tmux status-bar module — worktree count

**Files:**
- Create: `tmux/.config/tmux/custom_modules/ctp_worktrunk.conf`
- Modify: `tmux/.config/tmux/tmux.conf:120-137` (source the module + add to status-right)

- [ ] **Step 1: Write the module file**

Create `tmux/.config/tmux/custom_modules/ctp_worktrunk.conf` with:

```tmux
%hidden MODULE_NAME="ctp_worktrunk"

set -gq "@catppuccin_${MODULE_NAME}_icon" '🌿 '
set -gqF "@catppuccin_${MODULE_NAME}_color" '#{E:@thm_green}'
set -gq "@catppuccin_${MODULE_NAME}_text" ' #(cd "#{pane_current_path}" 2>/dev/null && wt list --format=json 2>/dev/null | jq "length" 2>/dev/null)'

source -F '#{TMUX_PLUGIN_MANAGER_PATH}/tmux/utils/status_module.conf'
```

This mirrors `ctp_cpu.conf` / `primary_ip.conf` structurally. The text is a tmux `#(shell)` call that returns empty string when not in a git repo — catppuccin will still render the icon, which is acceptable. If the always-visible icon becomes annoying, iterate later with an `if -F` guard.

- [ ] **Step 2: Source the module in tmux.conf**

Find the existing block (line 120-122):
```tmux
source -F '#{d:current_file}/custom_modules/ctp_cpu.conf'
source -F '#{d:current_file}/custom_modules/ctp_memory.conf'
source -F '#{d:current_file}/custom_modules/primary_ip.conf'
```

Add a fourth line after the third:
```tmux
source -F '#{d:current_file}/custom_modules/ctp_worktrunk.conf'
```

- [ ] **Step 3: Add the module to `status-right`**

Find the `set -ag status-right '#{E:@catppuccin_status_date_time}'` line (line 137). Insert this line **before** it:

```tmux
set -agF status-right '#{E:@catppuccin_status_ctp_worktrunk}'
```

Final relevant block shape:
```tmux
set -agF status-right '#{E:@catppuccin_status_ctp_cpu}'
set -agF status-right '#{E:@catppuccin_status_ctp_memory}'
if 'test -r /sys/class/power_supply/BAT*' {
  set -agF status-right '#{E:@catppuccin_status_battery}'
}
set -agF status-right '#{E:@catppuccin_status_ctp_worktrunk}'
set -ag status-right '#{E:@catppuccin_status_date_time}'
```

- [ ] **Step 4: Reload tmux config**

Inside tmux: `prefix + r`.

- [ ] **Step 5: Verify the module appears**

Look at the top status bar. In a pane sitting in a git repo you should see something like `🌿 2` (count of worktrees). In a non-repo directory the segment should render `🌿 ` with no number.

If the count is wrong or blank in a repo, run the inner shell command by hand from that directory to debug:
```sh
cd "$PWD" && wt list --format=json 2>/dev/null | jq "length"
```

- [ ] **Step 6: Commit**

```bash
git add tmux/.config/tmux/custom_modules/ctp_worktrunk.conf tmux/.config/tmux/tmux.conf
git commit -m "feat(tmux): add worktree count module to status bar"
```

---

## Task 9: Starship module — worktree count

**Files:**
- Modify: `starship/.config/starship/starship.toml:3-27` (format string) and append a new `[custom.worktrunk]` block

- [ ] **Step 1: Add the custom module definition**

Append to `starship/.config/starship/starship.toml` (after `[character]`, at the end of the file):

```toml
[custom.worktrunk]
command = "wt list --format=json 2>/dev/null | jq 'length' 2>/dev/null"
when = "command -v wt >/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1"
description = "Number of worktrees in the current repo"
format = '[[ 🌿 $output ](fg:base bg:green)]($style)'
style = "bg:green"
require_repo = true
ignore_timeout = true
```

- [ ] **Step 2: Insert the module in the `format` string**

Find the `format` block at lines 3-27. Locate:

```
$git_branch\
$git_status\
[](fg:green bg:teal)\
```

Replace with:

```
$git_branch\
$git_status\
${custom.worktrunk}\
[](fg:green bg:teal)\
```

The module sits on the green segment alongside `$git_branch` and `$git_status`, so the color transition at `](fg:green bg:teal)` stays correct.

- [ ] **Step 3: Reload starship**

Open a new terminal window (simplest). Or: `exec zsh` in the current window.

- [ ] **Step 4: Verify — inside a repo with worktrees**

`cd` into a repo that has at least one worktree (run `wt list` to confirm). Prompt should show `🌿 N` on the green segment next to the git info.

- [ ] **Step 5: Verify — outside a repo**

`cd` to `/tmp`. Prompt should show no worktree segment (the `when` guard excludes it).

- [ ] **Step 6: Commit**

```bash
git add starship/.config/starship/starship.toml
git commit -m "feat(starship): worktree count module in prompt"
```

---

## Task 10: Which-key integration

**Files:**
- Modify: `tmux/.config/tmux/tmux.conf` (add XDG flag before plugins load, roughly near line 38 where the plugin is declared)
- Create: `tmux/.config/tmux/plugins/tmux-which-key/config.yaml`

- [ ] **Step 1: Enable XDG config mode for tmux-which-key**

Edit `tmux/.config/tmux/tmux.conf`. Find the line:
```tmux
set -g @plugin 'alexwforsythe/tmux-which-key'  # prefix + space
```

Add **above** it (before the `set -g @plugin …` line):
```tmux
# Read our versioned config.yaml from $XDG_CONFIG_HOME/tmux/plugins/tmux-which-key/
set -g @tmux-which-key-xdg-enable 1
```

- [ ] **Step 2: Seed config.yaml from upstream example**

The plugin's default menu is valuable; we only want to **add** entries. Fetch the current `config.example.yaml`:

```sh
mkdir -p tmux/.config/tmux/plugins/tmux-which-key
curl -fsSL https://raw.githubusercontent.com/alexwforsythe/tmux-which-key/main/config.example.yaml \
  -o tmux/.config/tmux/plugins/tmux-which-key/config.yaml
```

Verify the download:
```sh
head -30 tmux/.config/tmux/plugins/tmux-which-key/config.yaml
```

Expected: YAML starting with `name:` or similar top-level config, then an `items:` block.

- [ ] **Step 3: Add the Worktrunk submenu and user bindings**

Open `tmux/.config/tmux/plugins/tmux-which-key/config.yaml`. Locate the top-level `items:` list. At the **end** of that list, append (indentation matching existing entries, usually 2 spaces):

```yaml
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
  - separator: true
  - name: Sesh picker
    key: o
    command: 'run-shell "sesh connect \"$(sesh list --icons | fzf-tmux -p 80%,70% --no-sort --ansi)\""'
  - name: Floating terminal (floax)
    key: f
    command: 'run-shell "#{TMUX_PLUGIN_MANAGER_PATH}/tmux-floax/scripts/floax.sh"'
    transient: true
  - name: URL picker (fzf-url)
    key: u
    command: 'run-shell "#{TMUX_PLUGIN_MANAGER_PATH}/tmux-fzf-url/fzf-url.sh"'
  - name: Thumbs (copy anything on screen)
    key: T
    command: 'run-shell "#{TMUX_PLUGIN_MANAGER_PATH}/tmux-thumbs/scripts/tmux-thumbs.sh"'
```

- [ ] **Step 4: Verify plugin-internal script paths**

Run: `ls ~/.config/tmux/modules/tmux-floax/scripts/ ~/.config/tmux/modules/tmux-fzf-url/ ~/.config/tmux/modules/tmux-thumbs/scripts/`

Expected: `floax.sh`, `fzf-url.sh`, `tmux-thumbs.sh`. If any path is different (upstream may rename), update the YAML entry. `#{TMUX_PLUGIN_MANAGER_PATH}` resolves to `~/.config/tmux/modules/` per the dotfiles' custom TPM path.

- [ ] **Step 5: Reload tmux**

Inside tmux: `prefix + r`. The plugin's Python build runs silently and regenerates its `init.tmux`. If there's a YAML parse error, it shows up on reload — check `~/.config/tmux/modules/tmux-which-key/plugin/init.tmux.log` or reload manually with `prefix + I` (TPM install) to see output.

- [ ] **Step 6: Smoke test the menu**

Press `prefix + Space`.

Expected:
- Menu overlay appears
- Scroll down to the added entries at the bottom: `W → +Worktrunk`, `o → Sesh picker`, `f → Floating terminal`, `u → URL picker`, `T → Thumbs`
- Pressing `W` opens the Worktrunk submenu with `w`, `W`, `l`
- Pressing `l` opens a popup running `wt list`

Close with `Esc`. Fix YAML quoting if any submenu command fails silently.

- [ ] **Step 7: Commit**

```bash
git add tmux/.config/tmux/tmux.conf tmux/.config/tmux/plugins/tmux-which-key/config.yaml
git commit -m "feat(tmux): which-key config with Worktrunk submenu + user bindings"
```

---

## Task 11: README link + final smoke test

**Files:**
- Modify: `README.md` (add a Worktrunk line in Tools and Integrations + link to docs/workflow.md)

Note: `docs/workflow.md` was already committed during the design phase (commits `d29d55d`, `18a9133`, `b3371a7`). No new workflow content needed here — just the link-in.

- [ ] **Step 1: Add a Worktrunk entry in README "Tools and Integrations"**

Open `README.md`. Find the block `**Core Tools:**` (around the middle of the Tools section). After the `Fuzzy Finder: fzf` / `Shell History: Atuin` lines, add:

```markdown
- Worktrees + AI agents: **worktrunk** (`wt`) — see [`docs/workflow.md`](docs/workflow.md#5-worktrunk---parallel-branches-parallel-agents)
```

- [ ] **Step 2: Add a top-level pointer to the workflow doc**

Near the top of `README.md` (right after the overview paragraph / before "Architecture"), add a one-liner:

```markdown
**New to this setup?** Start with [`docs/workflow.md`](docs/workflow.md) — a hands-on guide for tmux, sesh, and worktrunk.
```

- [ ] **Step 3: Verify links render**

Run: `grep -n 'workflow.md' README.md`

Expected: two matches on the lines you just edited.

- [ ] **Step 4: Full end-to-end smoke test**

Walk through the minimal happy path in a fresh terminal:

```sh
# New zsh — wtx function exists
zsh -i -c 'type wtx'

# wt knows where it is
wt --version
```

In tmux, inside a git repo:

```
prefix + Space           → which-key menu shows "+Worktrunk"
Esc
prefix + W  → Branch: test/final-smoke  Task: "hi then exit"  → confirmation message
prefix + o → Ctrl-w       → lists 2+ worktrees including test/final-smoke
prefix + o → Ctrl-t       → shows wt-test_final-smoke session
```

Starship: in the main worktree the prompt shows 🌿 (with count). Tmux status bar: 🌿 N at the top.

Clean up:
```sh
tmux kill-session -t wt-test_final-smoke 2>/dev/null || true
wt remove test/final-smoke 2>/dev/null || true
```

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: link workflow guide + add worktrunk to tools list"
```

- [ ] **Step 6: Final verification — complete feat/worktrunk branch diff**

Run: `git log --oneline main..feat/worktrunk`

Expected ~11 commits (spec docs + each task's impl commit).

Run: `git diff --stat main..feat/worktrunk`

Expected: matches the spec's "Files changed summary" section — 4 modified (`Brewfile`, `tmux/.config/tmux/tmux.conf`, `starship/.config/starship/starship.toml`, `README.md`) + 7 created (2 docs, 5 config/script). No surprises.

---

## Follow-ups (out of plan)

The spec lists these as explicit **out of scope** — do NOT add them now:

- Claude Code marketplace plugin
- Automatic orphan-session cleanup when a worktree is removed
- Per-project `wt.toml` templates
- Lazygit worktree view integration
- Atuin filtering by worktree

If the user decides any of these matter later, they become a new spec → plan cycle.
