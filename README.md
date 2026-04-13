# lazyforge ⚡

> My personal developer productivity setup — terminal tools, shell config, and Ghostty configuration for a fast, modern AI-assisted coding environment on macOS.

One command to go from a fresh Mac to a fully turbocharged terminal.

---

## Prerequisites

- macOS (Apple Silicon or Intel)
- [Ghostty](https://ghostty.org) installed (terminal emulator)
- Node.js + npm *(optional — only needed for `opencommit` AI commits)*

---

## Quick Install

```bash
git clone https://github.com/eMe-404/lazyforge.git
cd lazyforge
chmod +x install.sh
./install.sh
```

The script is idempotent — safe to run again after updates.

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
| [mise](https://mise.jdx.dev) | Polyglot runtime manager (Node, Python, Go, Ruby…) |

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
| [tailspin](https://github.com/bensadeh/tailspin) | `tail`/`cat` on logs | Zero-config log highlighter |

### Git
| Tool | Purpose |
|------|---------|
| [lazygit](https://github.com/jesseduffield/lazygit) | TUI git client (`lg`) |
| [git-delta](https://github.com/dandavison/delta) | Beautiful diffs, side-by-side |
| [difftastic](https://github.com/Wilfred/difftastic) | Structural diff — syntax-tree aware (`dt`) |
| [tig](https://github.com/jonas/tig) | Read-only git history browser |
| [gh](https://cli.github.com) | GitHub CLI — PRs, issues, workflows |
| [opencommit](https://github.com/di-sukharev/opencommit) | AI-generated conventional commit messages (`gai`) |

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
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info display (`ff`) |
| [gping](https://github.com/orf/gping) | Ping with live graph |
| [onefetch](https://github.com/o2sh/onefetch) | Git repo summary (`repo`) |
| [tokei](https://github.com/XAMPPRocky/tokei) | Fast code statistics by language |
| [viddy](https://github.com/sachaos/viddy) | Modern `watch` with diff highlighting |
| [gum](https://github.com/charmbracelet/gum) | Interactive components for shell scripts |
| [vhs](https://github.com/charmbracelet/vhs) | Record terminal sessions to GIF/HTML |

### Editor: Neovim + LazyVim
- LazyVim pre-configured base (`lua/config/lazy.lua`)
- Catppuccin Mocha theme (matches Ghostty)
- Language extras: TypeScript/JS, Python, JSON, YAML — LSP, formatting, linting auto-installed via Mason
- Local overrides in `lua/config/` and `lua/plugins/`
- Plugins auto-install on first `nvim` launch

### Terminal: Ghostty
- Font: JetBrainsMono Nerd Font, size 20
- Theme: Catppuccin Mocha
- Subtle transparency + blur, hidden titlebar, padding
- Quick terminal: `Cmd+\``
- Reload config: `Cmd+Shift+,`

---

## Key Aliases

```zsh
ls / ll  → eza --icons --git
cat      → bat
lg       → lazygit
ld       → lazydocker
ff       → fastfetch
nv       → nvim (LazyVim)
cc       → claude
ccc      → claude --continue
repo     → onefetch (git repo summary)
gai      → oco (AI commit message)
logs     → tspin (log highlighter)
dt       → difft (structural diff)
fif      → fuzzy file search with bat preview
cheat/?  → navi cheatsheet browser
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
| `Cmd+Shift+,` | Reload Ghostty config live |

---

## Repo Structure

```
lazyforge/
├── install.sh              # automated setup script
├── Brewfile                # all tools in one file
├── config/
│   ├── ghostty/config      # Ghostty terminal config
│   ├── zsh/productivity.zsh  # shell aliases, tools, prompt
│   ├── opencommit/         # opencommit provider config (no API key)
│   ├── navi/cheats/
│   │   └── lazyforge.cheat  # interactive command reference (navi)
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
3. Add cheat entries to `config/navi/cheats/lazyforge.cheat`
4. Update this README
5. Commit and push

---

## Notes for Sharing

- **opencommit** requires a DeepSeek API key (prompted during install). Skip it by pressing Enter — you can configure it later by editing `~/.opencommit`.
- **Neovim LSP servers** (TypeScript, Python, bash, etc.) are installed automatically by Mason on first `nvim` launch.
- **mise** manages runtime versions per project via `.tool-versions` or `.mise.toml` files.

---

## License

MIT — use it, fork it, forge your own.
