# Contributing

## Issues

Open an issue for:
- Bugs in `install.sh` or config files
- Tool suggestions (must have 1,000+ GitHub stars — see [Tool Selection](CLAUDE.md#tool-selection-rules))
- Compatibility problems on newer macOS versions

## Pull Requests

1. Fork the repo and create a branch from `main`
2. Test your changes with a clean install: `./install.sh`
3. Keep PRs focused — one change per PR
4. Follow the commit convention used in this repo: `feat:`, `fix:`, `docs:`, `chore:`

## Adding a Tool

1. Add it to `Brewfile` with a brief comment
2. Add any aliases/config to `config/zsh/productivity.zsh`
3. Optionally add cheat entries to `config/navi/cheats/lazyforge.cheat`
4. Update `README.md` if the tool is user-facing

## Neovim Plugins

Add new plugins as files under `config/nvim/lua/plugins/`. LazyVim auto-discovers them. Keep plugin files focused on a single concern.

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
