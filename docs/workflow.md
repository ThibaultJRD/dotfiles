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
🔎 C-f find │ ❌ C-x kill │ 🖱️ C-d/u scroll
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

1. `wt switch --create feat/signup-2fa` creates a new git worktree at
   `~/Develop/acme-app.feat-signup-2fa`
2. tmux opens a new window named `feat/signup-2fa`, focused, cwd set
   to the worktree

You're now in a plain shell sitting inside the new worktree. From
here, do whatever — open `nvim`, run `lg`, type `claude` to start an
interactive agent session, or just hack manually. The window is
yours.

If you re-run `prefix + w feat/signup-2fa` later (typo, habit,
whatever), it just jumps to the existing window — no duplicate.

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

Enter. A **new window** is created in the **background** (your focus
stays where it is). An agent is spawned in that window with the task as
its first prompt. You keep working.

```
windows: │ 󰊢 git │ 󰅩 IDE │ 󰚩 AI │ feat/signup-2fa │ fix/login-button-align │
```

Check on it later via `prefix + 5` (or `prefix + n` for next, `prefix +
p` for previous).

Mnemonic: lowercase `w` = "I want a worktree window, I'll drive";
uppercase `W` = "I want an agent to drive while I do something else".

---

## 10:00 — Reviewing what you (or the agent) did

Back in `feat/signup-2fa`. Whether you typed everything yourself or
let `claude` do the heavy lifting, you're now at a shell prompt in
the worktree dir. Time to see what changed.

Type `lg` for **lazygit**. You get a TUI showing the staged/unstaged
diff. Use `?` for help, `space` to stage hunks, `c` to commit. Or, to
just eyeball the diff:

```sh
git diff main..HEAD
```

If something looks off, open Neovim with `v <file>` (alias for `nvim`),
edit, save. Use `Ctrl-h/j/k/l` to switch between Neovim splits **and**
tmux panes seamlessly — the keybind works in both. No mental
context-switch.

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

The feature works. From your `feat/signup-2fa` window (still in the
worktree dir):

```sh
git push -u origin feat/signup-2fa
gh pr create --fill
```

Done. The PR is open on GitHub.

---

## 13:30 — After lunch, checking the bug fix

Back from lunch. Where did the bug-fix agent end up?

`prefix + Tab` jumps to your last-used window — but you've moved
around since this morning. Better: press `prefix + g` (go to
worktree). An fzf popup appears with every worktree of the current
repo:

```
🌿 worktree ›
🌿 main                              [main]
🌿 feat/signup-2fa                   ←
🌿 fix/login-button-align
```

Type a fragment, Enter — tmux switches to the matching window (or
creates one in the worktree dir if you'd somehow lost it).

You land in `fix/login-button-align`. The agent is done, sitting at a
shell prompt. You review with `lg`, run the visual tests, push:

```sh
git push -u origin fix/login-button-align
gh pr create --fill
```

---

## 14:00 — Cleaning up after the PRs land

Both PRs got reviewed and merged on GitHub. Time to clean up locally.
From any window inside the project session:

```sh
wt list                              # see all worktrees + CI status + diffstats
wt remove feat/signup-2fa
wt remove fix/login-button-align
```

The starship `🌿 N` indicator drops back to nothing. Close the
corresponding tmux windows with `prefix + &` (asks for confirm).

---

## 17:30 — Detaching for the day

You're done. From any pane:

```
prefix + d
```

tmux detaches. The session keeps running in the background. Tomorrow,
`tmux` reattaches you, all your windows exactly where you left them.

---

## Reference card

Things you actually use, daily:

| Where | Key | What |
|---|---|---|
| tmux | `prefix + o` | sesh picker (sessions / zoxide / find) |
| tmux | `prefix + Tab` | last session |
| tmux | `prefix + w` | new worktree, focus the window |
| tmux | `prefix + W` | new worktree, leave it in the background |
| tmux | `prefix + g` | go-to-worktree picker (fzf over `wt list`) |
| tmux | `prefix + |` / `-` | split pane vertically / horizontally |
| tmux | `Ctrl-h/j/k/l` | navigate panes AND nvim splits (no prefix) |
| tmux | `prefix + f` | floating terminal (floax) |
| tmux | `prefix + d` | detach |
| tmux | `prefix + Space` | which-key menu (when you forget) |
| shell | `Ctrl-t` | fzf file picker → insert path |
| shell | `Ctrl-g` | zoxide directory picker |
| shell | `Ctrl-r` | atuin history search |
| shell | `cd <fragment>` | zoxide jump (any visited dir) |
| shell | `y` | yazi file manager |
| shell | `lg` | lazygit |
| shell | `v` | nvim |
| shell | `wt list` | list worktrees of current repo |
| shell | `wt remove <br>` | remove worktree (after PR is merged on GitHub) |

---

## Per-machine and per-repo tweaks

**Pin the AI agent on a machine** — by default the helper picks
`claude` then falls back to `opencode`. If you want to force one, add
to `~/.zshrc.local` (not versioned):

```sh
export WT_AGENT=opencode
```

**Auto-copy `.env` files into new worktrees** — opt in per-repo. Add
to the repo's `.config/wt.toml`:

```toml
[[post-start]]
copy = "wt step copy-ignored"
```

And a `.worktreeinclude` at the repo root listing what to copy:

```
.env
.env.local
```

Now every `prefix + w` / `prefix + W` automatically copies your env
files into the new worktree — agents start with full credentials.

---

## When things go sideways

Most issues are solved by `prefix + r` (reload tmux config). If a
worktree window gets weird, `prefix + &` kills it cleanly. If the
agent doesn't spawn, check that `claude` or `opencode` is on PATH (or
that `WT_AGENT` is set to one of them).

For everything else: `prefix + Space` (which-key) inside tmux.
