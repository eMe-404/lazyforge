# yaer-forge ⚡

> My personal developer productivity setup — terminal tools, shell config, and Ghostty configuration for a fast, modern AI-assisted coding environment on macOS.

One command to go from a fresh Mac to a fully turbocharged terminal.

---

## Quick Install

```bash
git clone https://github.com/yaerdili/yaer-forge.git
cd yaer-forge
chmod +x install.sh
./install.sh
```

---

## What's Inside

### Shell
| Tool | Purpose |
|------|---------|
| [starship](https://starship.rs) | Fast, minimal prompt |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Fish-like command suggestions |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Live command syntax colors |
| [atuin](https://atuin.sh) | Smart shell history with `Ctrl+R` |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart `cd` — `z project` jumps anywhere |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder for files and history |

### Modern CLI Replacements
| Tool | Replaces | What it does |
|------|----------|-------------|
| [eza](https://eza.rocks) | `ls` | Icons, git status, colors |
| [bat](https://github.com/sharkdp/bat) | `cat` | Syntax highlighting, git changes |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `grep` | Blazing fast search |
| [fd](https://github.com/sharkdp/fd) | `find` | Simple, fast file finder |
| [dust](https://github.com/bootandy/dust) | `du` | Visual disk usage tree |
| [duf](https://github.com/muesli/duf) | `df` | Readable disk free output |
| [btop](https://github.com/aristocratos/btop) | `htop` | Beautiful resource monitor |

### Git
| Tool | Purpose |
|------|---------|
| [lazygit](https://github.com/jesseduffield/lazygit) | TUI git client (`lg`) |
| [git-delta](https://github.com/dandavison/delta) | Beautiful diffs, side-by-side |
| [tig](https://github.com/jonas/tig) | Read-only git history browser |
| [gh](https://cli.github.com) | GitHub CLI — PRs, issues, workflows |

### Data & Docs
| Tool | Purpose |
|------|---------|
| [jq](https://stedolan.github.io/jq) | JSON processor |
| [yq](https://github.com/mikefarah/yq) | YAML/TOML/XML processor |
| [fx](https://github.com/antonmedv/fx) | Interactive JSON explorer |
| [glow](https://github.com/charmbracelet/glow) | Render Markdown in terminal |

### File & HTTP
| Tool | Purpose |
|------|---------|
| [yazi](https://yazi-rs.github.io) | TUI file manager with image preview |
| [broot](https://github.com/Canop/broot) | Fuzzy tree navigator |
| [xh](https://github.com/ducaale/xh) | Fast HTTP client (HTTPie-compatible) |

### Docker
| Tool | Purpose |
|------|---------|
| [lazydocker](https://github.com/jesseduffield/lazydocker) | TUI for Docker (`ld`) |

### Productivity
| Tool | Purpose |
|------|---------|
| [zellij](https://zellij.dev) | Modern terminal multiplexer |
| [just](https://github.com/casey/just) | Project command runner (Makefile replacement) |
| [navi](https://github.com/denisidoro/navi) | Interactive cheatsheet tool |
| [tealdeer](https://github.com/dbrgn/tealdeer) | Fast `tldr` — practical command examples |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info display |
| [gping](https://github.com/orf/gping) | Ping with live graph |

### Editor: Neovim + LazyVim
- LazyVim pre-configured base (`lua/config/lazy.lua`)
- Catppuccin Mocha theme (matches Ghostty)
- Local overrides in `lua/config/` and `lua/plugins/`
- Plugins auto-install on first `nvim` launch

### Terminal: Ghostty
- Font: JetBrainsMono Nerd Font, size 20
- Theme: Catppuccin Mocha
- Quick terminal: `Cmd+`` `

---

## Key Aliases

```zsh
ls   → eza --icons --git
ll   → eza -la --icons --git
cat  → bat
lg   → lazygit
ld   → lazydocker
ff   → fastfetch
nv   → nvim (LazyVim)
cc   → claude
ccc  → claude --continue
fif  → fuzzy file finder with bat preview
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | atuin smart history search |
| `Ctrl+T` | fzf file picker with bat preview |
| `z <name>` | zoxide — jump to any frecent directory |
| `Cmd+\`` | Ghostty quick terminal toggle |
| `Cmd+Shift+R` | navi cheatsheet browser |

---

## Repo Structure

```
yaer-forge/
├── install.sh              # automated setup script
├── Brewfile                # all tools in one file
├── config/
│   ├── ghostty/config      # Ghostty terminal config
│   ├── zsh/productivity.zsh  # shell aliases, tools, prompt
│   ├── navi/cheats/
│   │   └── yaer-forge.cheat  # interactive command reference (navi)
│   └── nvim/               # Neovim / LazyVim config
│       ├── init.lua
│       └── lua/
│           ├── config/     # options, keymaps, autocmds, lazy bootstrap
│           └── plugins/    # local plugin specs & overrides
└── git/
    └── gitconfig-delta     # git-delta settings reference
```

---

## Adding New Tools

1. Add the brew formula to `Brewfile`
2. Add any shell config to `config/zsh/productivity.zsh`
3. Update this README
4. Commit and push

---

## License

MIT — use it, fork it, forge your own.
