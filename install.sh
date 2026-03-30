#!/bin/zsh
# yaer-forge install script
# Sets up a fully productive terminal environment on a fresh macOS machine.
# Usage: ./install.sh

set -e

FORGE_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo "${BLUE}[yaer-forge]${NC} $1"; }
success() { echo "${GREEN}[yaer-forge]${NC} $1"; }

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

# --- zshrc productivity block ---
info "Checking ~/.zshrc..."
MARKER="# yaer-forge"
if ! grep -q "$MARKER" "$HOME/.zshrc"; then
  # Insert before SDKMAN block if it exists, otherwise append
  SDKMAN_MARKER="#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!"
  if grep -q "$SDKMAN_MARKER" "$HOME/.zshrc"; then
    # Insert before SDKMAN line
    sed -i '' "s|$SDKMAN_MARKER|# yaer-forge\nsource $FORGE_DIR/config/zsh/productivity.zsh\n\n$SDKMAN_MARKER|" "$HOME/.zshrc"
  else
    echo "\n# yaer-forge\nsource $FORGE_DIR/config/zsh/productivity.zsh" >> "$HOME/.zshrc"
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

echo ""
success "Done! Open a new terminal tab to activate everything."
echo ""
echo "  Ctrl+R    → atuin smart history"
echo "  Ctrl+T    → fzf file picker"
echo "  z <name>  → zoxide smart jump"
echo "  lg        → lazygit"
echo "  ll        → eza file list"
echo "  cc        → claude"
