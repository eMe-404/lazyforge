# lazyforge productivity shell config
# Source this from your ~/.zshrc before the SDKMAN block:
#   source ~/path/to/lazyforge/config/zsh/productivity.zsh

# --- zsh-autosuggestions & zsh-syntax-highlighting ---
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- Starship prompt ---
eval "$(starship init zsh)"

# --- fzf keybindings & completion ---
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# --- atuin (smart shell history) ---
eval "$(atuin init zsh)"

# --- zoxide (smart cd) ---
eval "$(zoxide init zsh)"

# --- mise (runtime manager) ---
eval "$(mise activate zsh)"

# --- Better defaults ---
alias ls="eza --icons --git"
alias ll="eza -la --icons --git"
alias cat="bat"
alias lg="lazygit"
alias ld="lazydocker"
alias ff="fastfetch"

# --- Neovim ---
alias nv="nvim"
export EDITOR="nvim"
export VISUAL="nvim"

# --- Claude Code shortcuts ---
alias cc="claude"
alias ccc="claude --continue"

# --- Repo info ---
alias repo='onefetch'

# --- AI commit messages (opencommit) ---
alias gai='oco'

# --- Log viewing ---
alias logs='tspin'

# --- Structural diff ---
alias dt='difft'


# --- fzf + bat file finder ---
alias fif='rg --files-with-matches "" | fzf --preview "bat --color=always {}"'

# --- navi quick access ---
alias cheat='navi'                           # browse all cheat sheets
alias '?'='navi --query'                     # ? docker  →  search navi for docker

# --- git delta ---
export GIT_PAGER="delta"

# --- tmux copy mode (triggered by Ghostty cmd+shift+c) ---
function tmux-copy() {
  if tmux info &>/dev/null; then
    tmux copy-mode
  else
    tmux new-session
  fi
}

# --- Auto-attach to tmux 'main' session on every new Ghostty tab/split ---
# Each new pane gets its own tmux window inside the 'main' session
if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
  if tmux has-session -t main 2>/dev/null; then
    # Session exists — create a new window in it and attach to that window
    exec tmux new-window -a -t main \; attach-session -t main
  else
    # No session yet — create it (lands in window 0)
    exec tmux new-session -s main
  fi
fi
