# yaer-forge productivity shell config
# Source this from your ~/.zshrc before the SDKMAN block:
#   source ~/path/to/yaer-forge/config/zsh/productivity.zsh

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

# --- AI inline queries (mods) ---
alias ai='mods'

# --- Repo info ---
alias repo='onefetch'

# --- AI commit messages (opencommit) ---
alias gai='oco'

# --- fzf + bat file finder ---
alias fif='rg --files-with-matches "" | fzf --preview "bat --color=always {}"'

# --- navi quick access ---
alias cheat='navi'                           # browse all cheat sheets
alias '?'='navi --query'                     # ? docker  →  search navi for docker

# --- git delta ---
export GIT_PAGER="delta"
