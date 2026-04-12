# nvim config

LazyVim-based Neovim setup. Installed to `~/.config/nvim` by `install.sh`.

## Structure

```
nvim/
├── init.lua                  # entry point — loads config.lazy
└── lua/
    ├── config/
    │   ├── lazy.lua          # lazy.nvim bootstrap + LazyVim spec
    │   ├── options.lua       # vim options (loaded before plugins)
    │   ├── keymaps.lua       # key mappings (loaded on VeryLazy)
    │   └── autocmds.lua      # autocommands (loaded on VeryLazy)
    └── plugins/
        ├── colorscheme.lua   # Catppuccin Mocha (matches Ghostty)
        └── editor.lua        # local plugin additions / overrides
```

## Customising

- **New plugin**: add a `.lua` file under `lua/plugins/` returning a lazy.nvim spec table.
- **Override a LazyVim plugin**: return a spec with the same plugin name and new `opts`.
- **Disable a LazyVim plugin**: `{ "plugin/name", enabled = false }`.

## First run

On first `nvim` launch lazy.nvim auto-installs itself and all plugins.
Run `:LazyHealth` to confirm everything is healthy.

## Useful commands

| Command | Action |
|---------|--------|
| `:Lazy` | plugin manager UI |
| `:LazyHealth` | health check |
| `<Space>` | which-key leader menu |
| `<Space>ff` | find files (Telescope) |
| `<Space>gg` | lazygit inside nvim |
