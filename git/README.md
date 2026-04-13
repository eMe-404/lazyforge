# Git Config: delta

[git-delta](https://github.com/dandavison/delta) replaces the default git pager
with syntax-highlighted, side-by-side diffs.

## Settings

| Key | Value | Why |
|-----|-------|-----|
| `core.pager` | `delta` | Use delta for all git output |
| `interactive.diffFilter` | `delta --color-only` | Colors in `git add -p` interactive mode |
| `delta.navigate` | `true` | `n`/`N` to jump between diff sections |
| `delta.side-by-side` | `true` | Show old and new code side by side |

## Apply

The `install.sh` script runs these automatically. To apply manually:

```bash
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
```

Or include `gitconfig-delta` from your `~/.gitconfig`:

```ini
[include]
    path = /path/to/lazyforge/git/gitconfig-delta
```
