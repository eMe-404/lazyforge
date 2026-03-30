# Zsh Productivity Config

`productivity.zsh` is a self-contained shell config block sourced from `~/.zshrc`.
It sets up all tools, aliases, and keybindings without touching the rest of your zshrc.

## What It Configures

### Prompt
- **starship** — fast, minimal, context-aware prompt (replaces oh-my-zsh themes)

### Plugins
- **zsh-autosuggestions** — suggests commands as you type based on history
- **zsh-syntax-highlighting** — colors valid commands green, invalid red in real time

### History & Navigation
- **atuin** — replaces `Ctrl+R` with a smart fuzzy history search across sessions
- **zoxide** — replaces `cd` with `z`, learns your most-visited directories
- **fzf** — `Ctrl+T` fuzzy file picker, `Ctrl+R` fallback, tab completion everywhere

### Aliases

| Alias | Expands to | Purpose |
|-------|-----------|---------|
| `ls` | `eza --icons --git` | File list with icons and git status |
| `ll` | `eza -la --icons --git` | Detailed file list |
| `cat` | `bat` | Syntax-highlighted file output |
| `lg` | `lazygit` | TUI git client |
| `ld` | `lazydocker` | TUI Docker client |
| `ff` | `fastfetch` | System info display |
| `cc` | `claude` | Claude Code |
| `ccc` | `claude --continue` | Continue last Claude session |
| `fif` | `rg ... \| fzf ...` | Fuzzy file content search with preview |

### Git
- Sets `delta` as the global git pager for beautiful diffs

## Adding to ~/.zshrc

The `install.sh` script handles this automatically. To do it manually,
add this line before your SDKMAN block:

```zsh
source /path/to/yaer-forge/config/zsh/productivity.zsh
```
