#!/usr/bin/env bash
set -e

# === helper ===
log() { printf "\n\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[WARN]\033[0m %s\n" "$*"; }

if [[ "$OSTYPE" != "darwin"* ]]; then
  warn "This script is designed for macOS."
  exit 1
fi

# --- Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
  log "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d /usr/local/Homebrew ]]; then
    eval "$(/usr/local/Homebrew/bin/brew shellenv)"
  fi
else
  log "Homebrew already installed."
fi

# --- brew packages ---
log "Installing packages via Homebrew..."

brew update

brew list --cask ghostty &>/dev/null || [ -d "/Applications/Ghostty.app" ] || brew install --cask ghostty
brew list --cask font-meslo-lg-nerd-font &>/dev/null || brew install --cask font-meslo-lg-nerd-font

brew install zsh tmux fzf ripgrep bat fd eza git gh podman python3
brew install romkatv/powerlevel10k/powerlevel10k
brew install zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search

# --- Git global config ---
log "Configuring git..."
CURRENT_GIT_NAME=$(git config --global user.name 2>/dev/null || true)
CURRENT_GIT_EMAIL=$(git config --global user.email 2>/dev/null || true)

if [[ -z "$CURRENT_GIT_NAME" ]]; then
  read -rp "  Enter your git user name: " GIT_NAME < /dev/tty
  git config --global user.name "$GIT_NAME"
else
  log "Git user.name already set: $CURRENT_GIT_NAME"
fi

if [[ -z "$CURRENT_GIT_EMAIL" ]]; then
  read -rp "  Enter your git email: " GIT_EMAIL < /dev/tty
  git config --global user.email "$GIT_EMAIL"
else
  log "Git user.email already set: $CURRENT_GIT_EMAIL"
fi

git config --global init.defaultBranch main
git config --global credential.helper osxkeychain

# --- Ghostty config ---
log "Writing Ghostty config..."
mkdir -p "$HOME/.config/ghostty"
cat > "$HOME/.config/ghostty/config" << 'EOF'
font-family = MesloLGS NF
font-size = 13
theme = catppuccin-mocha
EOF

# --- Oh My Zsh ---
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "Oh My Zsh already installed."
fi

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# --- fzf-tab (not in Homebrew, clone manually) ---
log "Installing fzf-tab plugin..."
if [[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]]; then
  git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"
fi

# --- fzf shell integration ---
log "Configuring fzf..."
if [[ -d "$(brew --prefix)/opt/fzf" ]]; then
  yes | "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc
fi

# --- NVM ---
if [[ ! -d "$HOME/.nvm" ]]; then
  log "Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
  log "NVM already installed."
fi

log "Installing Node.js LTS via NVM..."
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default lts/*

# --- Claude Code ---
read -rp "  Install Claude Code (requires Node.js)? [y/N] " INSTALL_CLAUDE < /dev/tty
if [[ "$INSTALL_CLAUDE" =~ ^[Yy]$ ]]; then
  log "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
  log "Claude Code installed. Run 'claude' to get started."
else
  log "Skipping Claude Code installation."
fi

# --- Claude Code plugins / skills ---
if command -v claude >/dev/null 2>&1; then
  read -rp "  Install Claude Code skills & statusline? [y/N] " INSTALL_SKILLS < /dev/tty
  if [[ "$INSTALL_SKILLS" =~ ^[Yy]$ ]]; then
    # 1) Download: register plugin marketplaces
    log "Adding Claude plugin marketplaces..."
    claude plugin marketplace add anthropics/claude-plugins-official \
      || warn "claude-plugins-official marketplace already added or failed."
    claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill \
      || warn "ui-ux-pro-max-skill marketplace already added or failed."

    # 2) Install plugins from those marketplaces
    log "Installing Claude plugins..."
    claude plugin install mattpocock-skills@claude-plugins-official \
      || warn "Failed to install mattpocock-skills."
    claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill \
      || warn "Failed to install ui-ux-pro-max."

    # 3) ccstatusline (interactive configurator, writes ~/.claude/settings.json)
    log "Launching ccstatusline configurator..."
    npx -y ccstatusline@latest < /dev/tty \
      || warn "ccstatusline setup failed. Run later: npx -y ccstatusline@latest"
  else
    log "Skipping Claude Code skills."
  fi
fi

# --- Podman machine (VM for containers on macOS) ---
if podman machine inspect >/dev/null 2>&1; then
  log "Podman machine already exists. Start it with: podman machine start"
else
  read -rp "  Create and start Podman machine now (downloads ~1GB)? [y/N] " INIT_PODMAN < /dev/tty
  if [[ "$INIT_PODMAN" =~ ^[Yy]$ ]]; then
    log "Initializing Podman machine..."
    podman machine init && podman machine start \
      || warn "Podman machine setup failed. Run later: podman machine init && podman machine start"
  else
    log "Skipping Podman machine. Run later: podman machine init && podman machine start"
  fi
fi

# --- .zshrc ---
log "Updating ~/.zshrc..."

ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

if grep -q "Custom terminal setup (generated by setup.sh)" "$ZSHRC"; then
  log "Custom block already present in ~/.zshrc, skipping."
else
cat << 'EOF' >> "$ZSHRC"

# ===== Custom terminal setup (generated by setup.sh) =====
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="af-magic"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Powerlevel10k (sourced directly; overrides ZSH_THEME at runtime)
source "$(brew --prefix)/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme"

# Plugins (sourced directly from Homebrew)
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh"

# fzf-tab
source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab/fzf-tab.plugin.zsh"

# fzf shell integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Homebrew PATH
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Aliases
alias python='python3'
alias cat='bat'
alias ls='eza'
alias ll='eza -l'
alias la='eza -la'

# Powerlevel10k config (run `p10k configure` to generate)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# ===== End custom terminal setup =====
EOF
fi

# --- tmux.conf ---
log "Creating/updating ~/.tmux.conf..."

cat > "$HOME/.tmux.conf" << 'EOF'
setw -g mode-keys vi
set -g mouse on
EOF

log "Done! Next steps:"
echo "  1) Open Ghostty — font MesloLGS NF is already set in ~/.config/ghostty/config."
echo "  2) Restart terminal, then run: p10k configure"
echo "  3) Start tmux with: tmux"
echo "  4) Log in to GitHub CLI: gh auth login"
echo "  5) Podman: podman machine init (once), then podman machine start"
