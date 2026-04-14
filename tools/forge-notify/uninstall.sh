#!/bin/zsh
# forge-notify uninstall
# Removes the binary and its Claude Code hooks.
# Usage: ./tools/forge-notify/uninstall.sh

set -e

CLAUDE_SETTINGS="$HOME/.claude/settings.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo "${BLUE}[forge-notify]${NC} $1"; }
success() { echo "${GREEN}[forge-notify]${NC} $1"; }

# --- Remove binary ---
info "Removing binary..."
rm -f "$HOME/.local/bin/forge-notify"
success "Binary removed"

# --- Remove hooks ---
if [ -f "$CLAUDE_SETTINGS" ]; then
  info "Removing hooks from Claude Code settings..."
  jq '.hooks.PreToolUse = [
    .hooks.PreToolUse[]?
    | select(.hooks | map(.command) | any(test("forge-notify")) | not)
  ]' "$CLAUDE_SETTINGS" > /tmp/fn_clean.json \
    && mv /tmp/fn_clean.json "$CLAUDE_SETTINGS"
  success "Hooks removed"
fi

echo ""
success "Done. forge-notify uninstalled."
