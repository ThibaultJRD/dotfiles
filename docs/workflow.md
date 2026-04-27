# Daily Workflow

This is the hands-on guide to working inside this dotfiles setup. It assumes
you know basic vim motions (`hjkl`, insert/normal mode, `:w`, `:q`) but
haven't used tmux, sesh, or worktrunk before.

The shell on the host is **zsh**. Inside tmux every pane runs **nushell**
(it's the default command in `tmux.conf`). You can always type `nu` or `zsh`
to switch manually, but in practice you never need to.

---

## 1. Starting the day

Open your terminal (Kitty). Then:

```
tmux          # start tmux — or attach if a server is already running
```

Prefix key in tmux is **`Ctrl-s`** (not the usual `Ctrl-b`). Everywhere in
this doc, `prefix` means `Ctrl-s`.

The tmux status bar should appear at the top (catppuccin-macchiato). If it's
your first tmux launch, TPM installs all the plugins automatically — wait a
few seconds.

---

## 2. Sesh picker — your session launcher

Press `prefix + o` to open the **sesh picker**. This is the single entry
point for jumping into anything: existing tmux sessions, zoxide-known
directories, and config files.

```
⚡ C-a all  │ 🪟 C-t tmux │ ⚙️ C-g configs │ 📁 C-z zoxide
🔎 C-f find │ ❌ C-x kill │ 🖱️ C-d/u scroll
```

While the picker is open:

- Type to fuzzy-filter
- `Tab` / `Shift-Tab` to move down/up in the list
- `Ctrl-a` → all sessions (tmux + sesh configs + zoxide)
- `Ctrl-t` → only running tmux sessions
- `Ctrl-g` → config shortcuts (see `sesh.toml`: `neovim`, `tmux`, `claude`)
- `Ctrl-z` → zoxide directories (visited dirs)
- `Ctrl-f` → `fd` search in `~`
- `Ctrl-x` → kill the highlighted session
- `Ctrl-d` / `Ctrl-u` → scroll the preview pane
- `Enter` → attach / create the session
- `Esc` → cancel

**First time in a repo?** `Ctrl-z`, type part of the path, Enter. Sesh
creates a new tmux session whose name is the basename of the directory.
`sesh-startup.sh` kicks in automatically and builds 3 windows:

1. `󰊢 git` — lazygit
2. `󰅩 IDE` — nvim on top (75%), a blank terminal below (25%)
3. `󰚩 AI` — a project tree to orient yourself; type `claude` or `opencode`
   here when you want an interactive agent session

Non-git directories just get a single pane with `lt` (project tree).

**Already been here?** `Ctrl-t`, pick the session, Enter. Tmux re-attaches
and your windows are exactly as you left them.

Press `prefix + Tab` to jump to the **last used** session (round-trip).

---

## 3. Moving around inside tmux

### Across panes and nvim splits

This setup has **vim-tmux-navigator** wired up, so the same key moves you
through tmux panes and Neovim splits seamlessly — no mental context switch.

| Key | Action |
|-----|--------|
| `Ctrl-h` | focus pane / split to the **left** |
| `Ctrl-j` | focus pane / split **below** |
| `Ctrl-k` | focus pane / split **above** |
| `Ctrl-l` | focus pane / split to the **right** |

No prefix, no modifier dance.

### Splits, windows, resizing

| Key | Action |
|-----|--------|
| `prefix + \|` | split pane vertically (left/right), current dir |
| `prefix + -` | split pane horizontally (top/bottom), current dir |
| `prefix + c` | new window, current dir |
| `prefix + n` / `prefix + p` | next / previous window |
| `prefix + 1`…`9` | jump to window N |
| `prefix + <` / `prefix + >` | swap current window left / right |
| `prefix + H J K L` (uppercase, repeat) | resize pane by 5 cells |
| `prefix + z` | zoom the current pane (toggle) |
| `prefix + d` | detach — tmux keeps running in the background |
| `prefix + &` | kill the current window (asks for confirm) |
| `prefix + x` | kill the current pane (asks for confirm) |

### Selecting, copying, scrolling

Press `prefix + [` to enter **copy mode** (vi keys). Use `hjkl`, `gg`, `G`,
`/search` to navigate. `v` starts a selection, `y` yanks to the system
clipboard (tmux-yank handles the OS clipboard on macOS).

`q` or `Esc` exits copy mode.

### Power features

| Key | Action |
|-----|--------|
| `prefix + Space` | **which-key** — a menu of all tmux bindings. Great when you forget. |
| `prefix + f` | **floax** — a floating terminal (80% size) overlaid on the current session. Toggle it with `prefix + f` again. Good for quick commands without leaving the window. |
| `prefix + u` | **fzf-url** — pick any URL visible on screen and open it in the browser |
| `prefix + T` | **tmux-thumbs** — vimium-style hints, select any word on screen and copy to clipboard |
| `prefix + W` | **new worktree window (background)** — see §5 below |
| `prefix + r` | reload `tmux.conf` |

---

## 4. Common tools

| Command | What it is |
|---------|------------|
| `y` | **yazi** — TUI file manager. `q` exits, `Enter` opens file, navigate with `hjkl`. Exiting in a directory auto-`cd`s there. |
| `lg` | **lazygit** — TUI git client. Best way to stage, commit, diff, rebase. Use `?` for per-panel help. |
| `v` | alias for `nvim` |
| `lt` | tree view of the current directory (`eza --tree`) |
| `ls` / `la` / `ll` | `eza` variants — `la` shows hidden, `ll` groups directories first |
| `cat` | aliased to **bat** (syntax-highlighted) |
| `cd <fuzzy>` | aliased to **zoxide** — type any part of a previously-visited path |
| `Ctrl-g` (in shell) | interactive zoxide picker (fzf) for directories |
| `Ctrl-t` (in shell) | interactive fzf file picker — inserts the path into your command line |
| `Ctrl-r` (in shell) | **atuin** — fuzzy search your shell history across machines |
| `glow <file.md>` | render markdown in the terminal |

---

## 5. Worktrunk — parallel branches, parallel agents

Worktrunk (`wt`) is how you juggle multiple branches and AI agents at once
without context-switching pain. It wraps `git worktree` with shell hooks and
agent spawning.

The mental model: **one branch = one worktree = one tmux window** inside your
current project session. You never stash, you never checkout, and you never
leave your session. Each worktree shows up as an extra window in the status
bar alongside your existing `git/IDE/AI` windows.

### The two tmux entry points

There are two ways to create a new worktree from inside tmux, and they have
different purposes:

#### `prefix + w` — **switch-now**

A one-field prompt appears:

```
Branch: feat/signup
```

Enter. A new window named `feat/signup` is created **and immediately focused**.
The agent starts inside the worktree. You type your first request once it's up.

When the agent exits (Ctrl-D or `/quit`), the window stays open as a plain
shell sitting in the worktree directory. You can keep working — run `wt list`,
`wt merge`, or relaunch the agent — without losing the window. Type `exit` to
close the window when you're done.

Use this when you want to **go work in the new branch right now**.

#### `prefix + W` — **fire-and-forget**

A two-field prompt appears:

```
Branch: feat/api-retry
Task:   add exponential backoff to the http client
```

Enter. A new window is created **in the background** — you stay on your current
window. The agent starts with the task as its first message.

Mnemonic: uppercase `W` = background work, you stay put.

Use this when you want to **queue an agent and keep working**.

### `wtx <branch>` — shell function

Works at any shell prompt (zsh or nushell), inside or outside tmux. Runs
`wt switch --create <branch> -x <agent>` under the hood: creates the worktree,
`cd`s into it, and launches the agent interactively.

```sh
wtx feat/signup
```

Use this when you're not in tmux, or when you want to create a worktree
without any window dance.

### Finding and switching worktrees

Worktrees live as windows in your current session — navigate with the usual
window keys:

- `prefix + n` / `prefix + p` — next / previous window
- `prefix + 1`…`9` — jump to window by number
- `prefix + s` — tmux `choose-tree` picker (built-in, shows all sessions and
  their windows)

`prefix + o` → `Ctrl-t` shows tmux **sessions** (your projects), not windows,
so it is still the right way to jump between repos. Worktrees are simply
windows inside those sessions; they don't appear as separate sessions anymore.

From the shell: `wt list` shows a table with branch, path, CI status, and
diffstats. It's a report, not a picker.

### Lifecycle

```sh
wt list                   # show worktrees + status
wt switch <branch>        # create or switch (no agent)
wt remove <branch>        # delete the worktree (prompts if dirty)
wt merge <branch>         # merge-and-remove back into main
wt squash <branch>        # squash-merge variant
```

`wt --help` lists every subcommand.

### Pin the agent per machine

By default the helper tries `claude`, then `opencode`. To force one on a
given machine, add this to `~/.zshrc.local` (which is **not** versioned):

```sh
export WT_AGENT=opencode
```

### Per-repo `.env` auto-copy

Worktrunk has a built-in subcommand for this — it's **per-repo**, not in
the global dotfiles, so each project chooses what to copy. To enable:

Create `.config/wt.toml` in the repo:

```toml
[[post-start]]
copy = "wt step copy-ignored"
```

Create `.worktreeinclude` at the repo root, listing gitignored files that
should be copied into every new worktree:

```
.env
.env.local
.env.development
```

Now every worktree you create gets its own `.env*` copied from the main
worktree — agents spawn with full credentials. Both files are safe to
commit.

### A worked example

You're in your project's tmux session. It has three windows: `git`, `IDE`,
`AI`. A PR review asks for two unrelated fixes: one in the auth middleware,
one in the CSS of a login page. You don't want to do them in sequence.

```
# press capital W twice — both stay in the background:
prefix + W
  Branch: fix/auth-middleware
  Task:   tighten the bearer token validation in auth/middleware.ts

prefix + W
  Branch: fix/login-css
  Task:   fix the centered layout breaking below 400px on /login
```

Your session now has **five windows**: `git`, `IDE`, `AI`,
`fix/auth-middleware`, `fix/login-css`. Two agents are grinding in parallel.

You keep working in your original windows (reviewing the PR in `AI`,
checking diffs in `git`). When you want to check on an agent:

```
prefix + 4   # jump to fix/auth-middleware
prefix + 5   # jump to fix/login-css
```

When an agent finishes, the window drops into a shell in that worktree. Review
with `lg`, run any cleanup, then back in any window:

```sh
wt merge fix/auth-middleware
wt merge fix/login-css
```

Gone. No stash, no checkout jank, no session juggling.

---

## 6. Cheat sheet

**Tmux (prefix = `Ctrl-s`):**

| | |
|---|---|
| `prefix + o` | sesh picker (all sessions / zoxide / find) |
| `prefix + Tab` | jump to last session |
| `prefix + w` | new worktree **window**, focused (switch-now) |
| `prefix + W` | new worktree **window**, background (fire-and-forget) |
| `prefix + Space` | which-key menu |
| `prefix + f` | floating terminal |
| `prefix + \|` / `-` | split pane |
| `Ctrl-h/j/k/l` | navigate panes AND vim splits (no prefix) |
| `prefix + z` | zoom pane |
| `prefix + [` | copy mode (vi keys) |
| `prefix + d` | detach |

**Shell:**

| | |
|---|---|
| `Ctrl-t` | fzf file picker → paste path |
| `Ctrl-g` | zoxide directory picker |
| `Ctrl-r` | atuin history search |
| `cd <query>` | zoxide jump |
| `y` | yazi |
| `lg` | lazygit |
| `v` | nvim |
| `wtx <br>` | create worktree + agent, switch into it (interactive) |
| `wt list` | list worktrees |
| `wt merge <br>` | merge worktree back into main |
