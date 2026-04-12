# yaer-forge: Tool Review & Recommendations (2025)

> Quick reference: current stack health + tools worth adding.
> Read in terminal: `glow docs/ai-first-review-2025.md`

---

## Current Stack Health

| Category | Tools | Status |
|----------|-------|--------|
| Shell & prompt | starship, autosuggestions, syntax-highlighting | ✅ |
| History & nav | atuin, zoxide, fzf | ✅ |
| Files & search | eza, bat, ripgrep, fd, yazi, broot | ✅ |
| Git | lazygit, git-delta, tig, gh | ✅ |
| Data & HTTP | jq, yq, fx, xh | ✅ |
| Docs & help | glow, tealdeer, navi | ✅ |
| System | btop, dust, duf, gping | ✅ |
| Docker | lazydocker | ✅ |
| Multiplexer | zellij | ⚡ see note |
| Task runner | just | ✅ |
| Editor | neovim + LazyVim + Catppuccin | ✅ |
| AI agent | claude (cc / ccc) | ✅ |
| Inline AI queries | — | ⚠️ gap |
| AI commit messages | — | ⚠️ gap |

**Zellij note**: solid for local work. If you SSH into servers regularly, `tmux` still dominates
for remote workflows — bigger plugin ecosystem, universal availability on servers.

---

## Recommended Additions

All brew-installable. Same pattern as the existing stack.

---

### 1. `mods` — AI Pipe Tool

> Charm's AI tool (same team as `glow`). Pipes any text through an LLM inline.

```zsh
brew install mods
```

**Why it fits**: follows Unix pipe philosophy exactly like the rest of the stack.
No session overhead — one command, one answer.

```zsh
# explain an error
cat error.log | mods "what is causing this"

# summarize a diff
git diff | mods "summarize these changes in one line"

# explain a file
bat config.yaml | mods "explain what this configures"

# quick question without piping
mods "what is the difference between SIGKILL and SIGTERM"
```

**Forge additions:**
```zsh
# productivity.zsh
alias ai='mods'
```
```
# Brewfile
brew "mods"
```
```
# navi cheat: % ai, mods
```

---

### 2. `opencommit` — AI Conventional Commits

> Generates conventional commit messages from staged diffs. One command replaces the
> "what do I write here" friction entirely.

```zsh
npm install -g opencommit
oco config set OCO_AI_PROVIDER=anthropic
oco config set OCO_API_KEY=<your-anthropic-key>
```

**Why it fits**: slots directly into the existing lazygit workflow. Use `oco` after staging
hunks in lazygit, or set it as a git hook so it fires automatically.

```zsh
git add -p     # stage hunks as usual (or via lazygit)
oco            # generates message, opens editor for review
oco --yes      # auto-commits without prompt

# as a hook (fires on every commit)
oco hook set
```

**Output example:**
```
feat(api): add JWT refresh token rotation

- Implement sliding window token expiry
- Add refresh endpoint with rate limiting
```

**Forge additions:**
```zsh
# productivity.zsh
alias gai='oco'
```

---

### 3. `onefetch` — Git Repo Summary

> Like `fastfetch` but for a git repository. Shows language breakdown, commit stats,
> contributors, license — all from the terminal.

```zsh
brew install onefetch
```

```zsh
onefetch           # run at repo root
```

**Why it fits**: natural companion to `ff` (fastfetch). Good for orienting in an unfamiliar repo.

**Forge addition:**
```zsh
# productivity.zsh
alias repo='onefetch'
```

---

### 4. `tokei` — Fast Code Stats

> Counts lines of code by language across the repo. Rust-fast, respects `.gitignore`.

```zsh
brew install tokei
```

```zsh
tokei              # stats for current directory
tokei src/         # stats for a subdirectory
tokei --sort code  # sort by lines of code
```

**Why it fits**: same profile as `dust` (fast, single-purpose, useful at a glance).

---

### 5. `viddy` — Modern `watch`

> Drop-in replacement for `watch` with diff highlighting and a cleaner TUI.

```zsh
brew install viddy
```

```zsh
viddy 'docker ps'                     # watch container state
viddy -d 'kubectl get pods'           # highlight diffs between runs
viddy -n 2 'gh run list --limit 5'    # poll CI every 2s
```

**Why it fits**: same category as gping — monitoring, but for commands rather than network.

---

### 6. `gum` — Interactive Shell Scripts

> Charm's component library for shell scripts. Makes `just` recipes and install scripts
> interactive with prompts, spinners, confirmations, and styled output.

```zsh
brew install gum
```

```zsh
# confirm before destructive action
gum confirm "Reset database?" && reset_db

# pick from a list
TOOL=$(gum choose "lazygit" "tig" "gh")

# styled log output in scripts
gum style --foreground 212 "Deploy complete"

# spinner around a slow command
gum spin --spinner dot --title "Installing..." -- brew bundle install
```

**Why it fits**: enhances `install.sh` and any `Justfile` recipes — makes the forge itself
more polished without adding runtime dependencies to tools.

---

## Roadmap

| Priority | Tool | Install | Daily impact |
|----------|------|---------|--------------|
| 1 | **mods** | `brew install mods` | Every time you'd normally google a flag or paste an error into a browser |
| 2 | **opencommit** | `npm i -g opencommit` | Every commit — eliminates message writing friction |
| 3 | **onefetch** | `brew install onefetch` | Whenever you enter an unfamiliar repo |
| 4 | **tokei** | `brew install tokei` | Code reviews, repo audits |
| 5 | **viddy** | `brew install viddy` | Replaces `watch` in CI monitoring and debugging loops |
| 6 | **gum** | `brew install gum` | Enhancing `install.sh` and `Justfile` scripts |
