#!/bin/zsh
# lazyforge install script
# Sets up a fully productive terminal environment on a fresh macOS machine.
# Usage: ./install.sh

set -e

FORGE_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo "${BLUE}[lazyforge]${NC} $1"; }
success() { echo "${GREEN}[lazyforge]${NC} $1"; }

# --- Homebrew ---
info "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
success "Homebrew ready"

# --- oh-my-zsh ---
info "Checking oh-my-zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
success "oh-my-zsh ready"

# --- Brew bundle ---
info "Installing tools from Brewfile..."
brew bundle install --file="$FORGE_DIR/Brewfile"
success "All tools installed"

# --- fzf keybindings ---
info "Setting up fzf keybindings..."
"$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash
success "fzf keybindings ready"

# --- Ghostty config ---
info "Linking Ghostty config..."
mkdir -p "$HOME/.config/ghostty"
ln -sf "$FORGE_DIR/config/ghostty/config" "$HOME/.config/ghostty/config"
success "Ghostty config linked"

# --- tmux config ---
info "Linking tmux config..."
mkdir -p "$HOME/.config/tmux"
ln -sf "$FORGE_DIR/config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
success "tmux config linked"

# --- navi config + cheat sheets ---
info "Linking navi config and cheat sheets..."
NAVI_CHEATS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/navi/cheats"
NAVI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/navi"
mkdir -p "$NAVI_CHEATS_DIR" "$NAVI_CONFIG_DIR"
ln -sf  "$FORGE_DIR/config/navi/config.yaml" "$NAVI_CONFIG_DIR/config.yaml"
ln -sfn "$FORGE_DIR/config/navi/cheats"      "$NAVI_CHEATS_DIR/lazyforge"
success "navi ready — run 'navi' or '? <topic>' to search"

# --- Neovim / LazyVim config ---
info "Linking Neovim config..."
if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  info "~/.config/nvim exists and is not a symlink — backing up to ~/.config/nvim.bak"
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
fi
ln -sfn "$FORGE_DIR/config/nvim" "$HOME/.config/nvim"
success "Neovim config linked (LazyVim will install plugins on first launch)"

# --- zshrc productivity block ---
info "Checking ~/.zshrc..."
MARKER="# lazyforge"
if ! grep -q "$MARKER" "$HOME/.zshrc"; then
  # Insert before SDKMAN block if it exists, otherwise append
  SDKMAN_MARKER="#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!"
  if grep -q "$SDKMAN_MARKER" "$HOME/.zshrc"; then
    # Insert before SDKMAN line
    sed -i '' "s|$SDKMAN_MARKER|# lazyforge\nsource $FORGE_DIR/config/zsh/productivity.zsh\n\n$SDKMAN_MARKER|" "$HOME/.zshrc"
  else
    echo "\n# lazyforge\nsource $FORGE_DIR/config/zsh/productivity.zsh" >> "$HOME/.zshrc"
  fi
  success "productivity.zsh sourced in ~/.zshrc"
else
  info "productivity.zsh already sourced in ~/.zshrc, skipping"
fi

# --- git-delta global config ---
info "Configuring git-delta..."
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
success "git-delta configured"

# --- difftastic git integration ---
info "Configuring difftastic..."
git config --global diff.tool difftastic
git config --global difftool.difftastic.cmd 'difft "$LOCAL" "$REMOTE"'
git config --global difftool.prompt false
success "difftastic configured as git difftool (use: git difftool)"

# --- opencommit (npm) ---
info "Checking opencommit..."
if ! command -v oco &>/dev/null; then
  if command -v npm &>/dev/null; then
    info "Installing opencommit..."
    npm install -g opencommit
    success "opencommit installed"
  else
    info "npm not found — skipping opencommit (install Node.js then: npm i -g opencommit)"
  fi
else
  success "opencommit already installed"
fi

# --- opencommit config ---
info "Configuring opencommit..."
OCO_CONFIG="$HOME/.opencommit"
if [ ! -f "$OCO_CONFIG" ]; then
  cp "$FORGE_DIR/config/opencommit/config.env" "$OCO_CONFIG"
  success "opencommit config written to ~/.opencommit (provider: deepseek)"
  echo ""
  printf "  ${BLUE}[lazyforge]${NC} Enter your DeepSeek API key (leave blank to skip): "
  read -r OCO_KEY
  if [ -n "$OCO_KEY" ]; then
    sed -i '' "s/OCO_API_KEY=/OCO_API_KEY=$OCO_KEY/" "$OCO_CONFIG"
    success "DeepSeek API key saved to ~/.opencommit"
  else
    info "Skipped — add your key later: echo 'OCO_API_KEY=<key>' >> ~/.opencommit"
  fi
else
  info "~/.opencommit already exists, skipping"
fi

# --- Claude Code skills ---
info "Installing Claude Code skills..."
SKILLS_SRC="$FORGE_DIR/config/claude/skills"
SKILLS_DEST="$HOME/.claude/skills"
mkdir -p "$SKILLS_DEST"
for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name=$(basename "$skill_dir")
  ln -sfn "$skill_dir" "$SKILLS_DEST/$skill_name"
done
success "Claude Code skills linked (~/.claude/skills/)"

# --- OpenCode skills (shares same SKILL.md files) ---
if command -v opencode &>/dev/null; then
  info "OpenCode detected — linking skills to ~/.config/opencode/skills/..."
  OC_SKILLS_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills"
  mkdir -p "$OC_SKILLS_DEST"
  for skill_dir in "$SKILLS_SRC"/*/; do
    skill_name=$(basename "$skill_dir")
    ln -sfn "$skill_dir" "$OC_SKILLS_DEST/$skill_name"
  done
  success "OpenCode skills linked (~/.config/opencode/skills/)"
else
  info "opencode not found — skipping OpenCode skills (re-run install.sh after installing opencode)"
fi

# --- Claude Code global hooks ---
info "Applying Claude Code hooks..."
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
HOOKS_TEMPLATE="$FORGE_DIR/config/claude/hooks.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
  jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" "$HOOKS_TEMPLATE" > /tmp/claude_settings_merged.json \
    && mv /tmp/claude_settings_merged.json "$CLAUDE_SETTINGS"
  success "Claude Code hooks merged into ~/.claude/settings.json"
else
  cp "$HOOKS_TEMPLATE" "$CLAUDE_SETTINGS"
  success "Claude Code settings created with hooks"
fi

echo ""
success "Done! Open a new terminal tab to activate everything."
echo ""
echo "  Ctrl+R    → atuin smart history"
echo "  Ctrl+T    → fzf file picker"
echo "  z <name>  → zoxide smart jump"
echo "  lg        → lazygit"
echo "  ll        → eza file list"
echo "  cc        → claude"
echo "  nv        → neovim (LazyVim)"
echo "  gai       → oco (AI commit messages)"
echo "  repo      → onefetch (repo summary)"
echo "  logs      → tailspin (log highlighter)"
echo "  dt        → difft (structural diff)"
