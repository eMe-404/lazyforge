#!/bin/zsh
# forge-notify install
# Compiles the Swift binary and wires up the Claude Code Notification hook.
# Run independently — not called by the root install.sh.
# Usage: ./tools/forge-notify/install.sh

set -e

TOOL_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo "${BLUE}[forge-notify]${NC} $1"; }
success() { echo "${GREEN}[forge-notify]${NC} $1"; }
error()   { echo "${RED}[forge-notify]${NC} $1" >&2; }

# --- Check dependencies ---
if ! command -v swiftc &>/dev/null; then
  error "swiftc not found. Install Xcode Command Line Tools:"
  error "  xcode-select --install"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  error "jq not found. Install it first:"
  error "  brew install jq"
  exit 1
fi

# --- Compile ---
# Info.plist is embedded so macOS grants window-server access to the subprocess.
info "Compiling forge-notify..."
mkdir -p "$BIN_DIR"
swiftc "$TOOL_DIR/forge-notify.swift" -o "$BIN_DIR/forge-notify" \
  -Xlinker -sectcreate \
  -Xlinker __TEXT \
  -Xlinker __info_plist \
  -Xlinker "$TOOL_DIR/Info.plist"
success "Binary installed → $BIN_DIR/forge-notify"

# --- Merge Notification hook into Claude Code settings ---
# Replaces any existing Notification array so the pill is the sole handler.
info "Installing Claude Code Notification hook..."
mkdir -p "$(dirname "$CLAUDE_SETTINGS")"

if [ -f "$CLAUDE_SETTINGS" ]; then
  jq -s '
    (.[0] // {}) as $s |
    (.[1].hooks.Notification) as $new |
    $s | .hooks.Notification = $new
  ' "$CLAUDE_SETTINGS" "$TOOL_DIR/hooks.json" > /tmp/fn_merged.json \
    && mv /tmp/fn_merged.json "$CLAUDE_SETTINGS"
else
  cp "$TOOL_DIR/hooks.json" "$CLAUDE_SETTINGS"
fi

success "Hook installed → $CLAUDE_SETTINGS"
echo ""
success "Done. Claude Code will show a pill when it needs your attention."
echo ""
echo "  Dismiss / Return / Escape  → close pill"
echo "  Auto-dismisses after 8s"
echo ""
echo "  To uninstall: ./tools/forge-notify/uninstall.sh"
