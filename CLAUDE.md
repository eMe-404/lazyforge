# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

`lazyforge` is a macOS developer productivity setup — a dotfiles/config manager that bootstraps a full terminal environment with a single command. It installs tools via Homebrew and symlinks configs to their expected locations.

## Setup & Installation

```bash
# Full setup from scratch (idempotent)
./install.sh

# Install/update Homebrew packages only
brew bundle install

# Add a new tool to the environment
# 1. Add it to Brewfile
# 2. Run: brew bundle install
# 3. Add aliases/config to config/zsh/productivity.zsh
# 4. Optionally add cheat entries to config/navi/cheats/lazyforge.cheat
```

## How Configs Are Deployed

`install.sh` uses **symlinks**, not copies. Editing files in this repo immediately affects the live environment:

| Repo path | Symlinked to |
|-----------|-------------|
| `config/ghostty/config` | `~/.config/ghostty/config` |
| `config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `config/tmux/tmux-session-new` | `~/.local/bin/tmux-session-new` |
| `config/nvim/` | `~/.config/nvim` |
| `config/navi/cheats/lazyforge.cheat` | `~/.local/share/navi/cheats/lazyforge/lazyforge.cheat` |
| `config/navi/config.yaml` | `~/.config/navi/config.yaml` |

The zsh config (`config/zsh/productivity.zsh`) is **sourced** from `~/.zshrc` via a line injected by install.sh — not symlinked.

The git-delta config (`git/gitconfig-delta`) is applied globally via `git config --global` by install.sh.

## Architecture

```
Brewfile          → defines all tool dependencies
install.sh        → idempotent setup: installs tools, creates symlinks, injects shell config
config/
  ghostty/        → terminal emulator (theme: Catppuccin Mocha, font: JetBrainsMono Nerd Font)
  tmux/           → multiplexer config + auto-session script (every Ghostty tab = independent tmux session)
  zsh/            → shell config: aliases, plugin init (starship, fzf, atuin, zoxide)
  nvim/           → LazyVim-based Neovim (entry: init.lua → lua/config/lazy.lua)
  navi/           → interactive cheatsheets (config.yaml + cheats/*.cheat)
git/              → git-delta reference config (applied globally by install.sh)
docs/             → tool review and roadmap docs
```

## Neovim Config Structure

LazyVim is the base. Customizations live in `config/nvim/lua/`:
- `config/lazy.lua` — plugin bootstrap; sets Catppuccin as default colorscheme
- `config/options.lua`, `config/keymaps.lua`, `config/autocmds.lua` — standard LazyVim overrides
- `plugins/colorscheme.lua` — Catppuccin Mocha with integration flags
- `plugins/editor.lua` — plugin additions/overrides

Add new plugins by creating files under `lua/plugins/`. LazyVim auto-discovers them.

## Adding Cheat Entries (navi)

Cheat entries follow this format in `config/navi/cheats/lazyforge.cheat`:

```
% section-tag, another-tag

# Description of the command
command --with <variable>

$ variable: echo -e "option1\noption2"
```

Run `navi` (or press `Cmd+Shift+R` in Ghostty) to browse interactively.

## Claude Code Hooks

Generic hooks are stored in `config/claude/hooks.json` and merged into `~/.claude/settings.json` globally by `install.sh`. They apply to **all** Claude Code sessions, not just this repo.

Active hooks: macOS notification, dangerous command block (Bash), sensitive file protection (Edit/Write), session git context (SessionStart).

To update hooks: edit `config/claude/hooks.json`, then re-run `./install.sh`.

## Tool Selection Rules

When recommending tools to add to this forge:
- **Minimum 1,000 GitHub stars** — below this threshold indicates insufficient community adoption; skip without exception
- Prefer brew-installable tools from homebrew-core over third-party taps
- Tools must fill a genuine gap — do not add if the existing stack already covers the use case

## Key Aliases (defined in config/zsh/productivity.zsh)

| Alias | Expands to |
|-------|-----------|
| `ls` / `ll` | `eza` with icons and git status |
| `cat` | `bat` |
| `lg` | `lazygit` |
| `ld` | `lazydocker` |
| `nv` | `nvim` |
| `cc` | `claude` |
| `ccc` | `claude --continue` |
| `fif` | ripgrep + fzf with bat preview |
| `cheat` / `?` | `navi` cheatsheet browser |
| `tls` | `tmux list-sessions` |
