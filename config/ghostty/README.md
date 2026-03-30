# Ghostty Config

Configuration for [Ghostty](https://ghostty.org) — a fast, native macOS terminal.

## Settings

| Key | Value | Why |
|-----|-------|-----|
| `font-family` | JetBrainsMono Nerd Font | Best coding font with full icon support |
| `font-size` | 20 | Comfortable for long sessions |
| `theme` | Catppuccin Mocha | Easy on the eyes, great contrast |
| `shell-integration` | zsh | Enables better prompt, cursor, and title support |
| `macos-option-as-alt` | true | Makes Option key work as Alt (needed for many shell shortcuts) |
| `keybind` | `Cmd+`` → toggle_quick_terminal` | Drop-down terminal from anywhere |

## Install Font

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

## Browse Available Themes

```bash
ls /Applications/Ghostty.app/Contents/Resources/ghostty/themes/
```

## Apply Config

The `install.sh` script symlinks this file to `~/.config/ghostty/config` automatically.
To do it manually:

```bash
mkdir -p ~/.config/ghostty
ln -sf /path/to/yaer-forge/config/ghostty/config ~/.config/ghostty/config
```
