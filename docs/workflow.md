# A day with this setup

A walkthrough of one normal workday inside this dotfiles config — Kitty,
tmux, sesh, worktrunk, Claude/opencode, Neovim, lazygit, yazi. Each step
introduces a tool naturally as it comes up.

Prefix in tmux is **`Ctrl-s`** (not the usual `Ctrl-b`). Whenever this
doc says `prefix`, it means `Ctrl-s`.

---

## 9:00 — Landing on a project

Open Kitty. Type `tmux` (or it auto-attaches if a server is already
running).

The status bar appears at the top in catppuccin. You see no sessions
yet. Press `prefix + o` to open the **sesh picker**:

```
⚡ C-a all  │ 🪟 C-t tmux │ ⚙️ C-g configs │ 📁 C-z zoxide
🌿 C-w worktrees │ 🔎 C-f find │ ❌ C-x kill │ 🖱️ C-d/u scroll
```

Press `Ctrl-z` to switch to **zoxide** mode. Type a few letters of your
project (e.g. `acm` for `acme-app`), Enter. Sesh creates a tmux session
named after the directory and runs `sesh-startup.sh`, which lays out
three windows:

1. `󰊢 git` — lazygit ready to go
2. `󰅩 IDE` — Neovim on top, a small terminal pane below
3. `󰚩 AI` — a project tree (`lt`), where you can type `claude` or
   `opencode` for an interactive agent session

You land on window 3 by default. The starship prompt shows your branch
in green.

---

## 9:15 — Starting a feature

You want to add a new feature `feat/signup-2fa`. Instead of stashing,
checking out, and breaking your IDE window state, use a **worktree**.

From any window in the session, press `prefix + w`:

```
Branch: feat/signup-2fa
```

Enter. Behind the scenes:

1. `wt switch --create feat/signup-2fa --base=@` creates a new git worktree
   at `~/Develop/acme-app.feat-signup-2fa`. `--base=@` means the new branch
   stacks on top of the current worktree's branch (the "branch off here"
   default for the tmux shortcut). Pass `--base=^` manually via
   `wt switch --create` if you'd rather start from the trunk.
2. Worktrunk's `pre-start` hook builds a dedicated tmux session
   `acme-app/WT/feat-signup-2fa` with the same 3-window layout as the
   parent project (`󰊢 git` / `󰅩 IDE` / `󰚩 AI`).
3. `post-start` runs `wt step copy-ignored` in the background — your
   `.env`, IDE state, `node_modules`, caches… are all reflinked from the
   main worktree (near-instantaneous on APFS).
4. tmux switches you into the new session, on the AI window.

You're sitting in a fresh shell at the worktree path with `lazygit`,
`nvim`, and the AI window all ready. Same muscle memory as the parent
project.

Re-running `prefix + w feat/signup-2fa` later just switches you back —
the session is reused, no duplicate.

---

## 9:30 — A bug interrupt, in parallel

While the agent is working on the feature, your tech lead pings: "Quick
fix for the login CSS, button is misaligned below 400px". You don't
want to stop the feature work.

Press `prefix + W` (uppercase this time):

```
Branch: fix/login-button-align
Task:   center the login button below 400px in /login
```

Enter. A **new session** `acme-app/WT/fix-login-button-align` is created
in the **background** — your focus stays where it is. The agent runs in
the AI window of that session with the task as its first prompt.

You can confirm with the toast notification "🌿 worktree
'fix/login-button-align' running claude in background session". Keep
working on the feature.

```
sessions: │ acme-app │ acme-app/WT/feat-signup-2fa │ acme-app/WT/fix-login-button-align │
```

`prefix + o` won't show the WT sessions (filtered by default). To see
them, press `Ctrl+W` inside the picker — that's the 🌿 worktrees-only
mode.

Mnemonic: lowercase `w` = "I want a worktree, I'll drive";
uppercase `W` = "I want an agent to drive while I do something else".

---

## 10:00 — Reviewing what you (or the agent) did

Back in `feat/signup-2fa`. Whether you typed everything yourself or
let `claude` do the heavy lifting, you want to see what changed.

`prefix + 1` jumps to the `󰊢 git` window — lazygit is already running
there. Stage hunks with `space`, scroll the diff, commit with `c`. `?`
shows the full keymap.

`prefix + 2` is the `󰅩 IDE` window: Neovim on top, a small terminal
pane below. `Ctrl-h/j/k/l` switches between Neovim splits **and** tmux
panes seamlessly — same keybind in both, no mental context-switch.

Need a quick scratchpad without leaving the window? `prefix + f` opens
a **floating terminal** (floax). Run a one-off, hit `prefix + f` again,
it disappears.

---

## 10:30 — Testing

You want to run the test suite. Split the current pane horizontally:
`prefix + |`. Now there's a second pane next to your shell. Run the
tests there:

```sh
npm test -- --watch
```

The tests run continuously. You go back to the left pane (`Ctrl-h`),
keep editing. When tests fail, the right pane shows it instantly.

Need to find a file fast? `Ctrl-t` at any shell prompt opens an
**fzf** picker over the current dir, with bat preview. Pick → path
inserted on the command line. Or `Ctrl-g` for a directory picker
(zoxide-fzf integration).

Forgot a command from yesterday? `Ctrl-r` opens **atuin**, full
fuzzy-searchable history across machines.

---

## 11:00 — Yazi for file browsing

Sometimes you want to actually look at a folder, not just search. Type
`y` — yazi opens. Navigate with `hjkl`, preview is automatic. Press `q`
to exit; whatever directory you were in, your shell `cd`s there
automatically.

---

## 11:30 — Pushing the feature

The feature works. `prefix + 1` to the lazygit window. `P` pushes the
branch (sets the upstream on first push). Switch to the local-branches
panel and use lazygit's create-pull-request command — it shells out to
`gh` and opens the PR in your browser.

Done. The PR is open on GitHub.

---

## 13:30 — After lunch, checking the bug fix

Back from lunch. Where did the bug-fix agent end up?

`prefix + Tab` jumps to your last-used session — but you've moved
around since this morning. Better: press `prefix + g` (go to
worktree). A popup opens with worktrunk's native picker — branch list
on the left, and a preview pane on the right with tabs:

- **HEAD±** — uncommitted changes diff.
- **log** — recent commits.
- **main…±** — what's changed since merge-base with the default branch.
- **remote⇅** — ahead/behind versus upstream.
- **summary** — LLM-generated branch summary (when enabled).

Pick `fix/login-button-align`, Enter. tmux switches into the matching
WT session, AI window. The agent has finished, sitting at a shell
prompt. `prefix + 1` to lazygit, review the diff, push, open the PR —
same flow as this morning.

---

## 14:00 — Cleaning up after the PRs land

Both PRs got reviewed and merged on GitHub. Time to clean up locally.

From inside the worktree session itself, `prefix + X` runs `wt remove`
on the current worktree. Worktrunk prompts if anything looks unsafe
(uncommitted changes, unmerged branch). The `post-remove` hook kills
the matching tmux session, and tmux switches you to another session
automatically — no orphan sessions, no orphan windows.

For a different worktree: `prefix + g`, switch into it, then
`prefix + X`. Or skip the picker entirely:

```sh
wt remove fix/login-button-align
```

The starship `🌿 N` indicator drops back to nothing once everything's
cleaned up.

---

## Reference card

Things you actually use, daily:

| Where | Key | What |
|---|---|---|
| tmux | `prefix + o` | sesh picker (sessions / zoxide / find) |
| tmux | `prefix + Tab` | last session |
| tmux | `prefix + w` | new worktree + session, switch into it (lands on AI window) |
| tmux | `prefix + W` | new worktree + session, agent runs in AI window in background |
| tmux | `prefix + g` | go-to-worktree picker (native `wt switch` with previews) |
| tmux | `prefix + X` | remove current worktree (worktrunk prompts; session is killed) |
| tmux | `prefix + |` / `-` | split pane horizontally / vertically |
| tmux | `Ctrl-h/j/k/l` | navigate panes AND nvim splits (no prefix) |
| tmux | `prefix + f` | floating terminal (floax) |
| tmux | `prefix + Space` | which-key menu (when you forget) |
| shell | `Ctrl-t` | fzf file picker → insert path |
| shell | `Ctrl-g` | zoxide directory picker |
| shell | `Ctrl-r` | atuin history search |
| shell | `cd <fragment>` | zoxide jump (any visited dir) |
| shell | `y` | yazi file manager |
| shell | `lg` | lazygit |
| shell | `v` | nvim |
| shell | `wt remove <br>` | remove worktree (after PR is merged on GitHub) |

---

## Per-machine and per-repo tweaks

**Pin the AI agent on a machine** — by default the helper picks
`claude` then falls back to `opencode`. To force one, set `WT_AGENT`
in the shell that launches tmux. For nushell (the default here), add
to `~/.config/nushell/env.nu`:

```nu
$env.WT_AGENT = "opencode"
```

For zsh, add to `~/.zshrc`:

```sh
export WT_AGENT=opencode
```

**Auto-copy of gitignored files is on by default** — every new worktree
inherits the main worktree's `.env`, IDE state, `node_modules`, caches,
etc. via `wt step copy-ignored` in `[[post-start]]`. APFS reflinks make
this near-free on macOS. To **exclude** specific paths globally, add to
`~/.config/worktrunk/config.toml`:

```toml
[step.copy-ignored]
exclude = ["coverage/", ".turbo/"]
```

Per-repo overrides go in that repo's `.config/wt.toml`.

**Worktrunk shortcuts** that save typing:

| Shortcut | Meaning                                  |
|----------|------------------------------------------|
| `^`      | Default branch (`main` / `master`)       |
| `@`      | Current worktree's branch                |
| `-`      | Previous worktree                        |
| `pr:42`  | GitHub PR #42                            |

Examples:

```sh
wt switch --create hotfix --base=@      # stack on top of current branch
wt switch -                             # back to previous worktree
wt switch pr:42                         # check out PR #42 as a worktree
```

`--base=@` is the canonical way to do **stacked branches** — start a
new feature on top of an in-flight one without waiting for the parent
to merge. The `prefix + w` / `prefix + W` tmux shortcuts already pass
`--base=@` for you, so worktrees created from a session always stack on
the branch you're sitting on. Use `wt switch --create … --base=^` from
the shell when you explicitly want to fork off the trunk instead.

---

## When things go sideways

Most issues are solved by `prefix + r` (reload tmux config). If a
worktree window gets weird, `prefix + &` kills it cleanly. If the
agent doesn't spawn, check that `claude` or `opencode` is on PATH (or
that `WT_AGENT` is set to one of them).

For everything else: `prefix + Space` (which-key) inside tmux.
