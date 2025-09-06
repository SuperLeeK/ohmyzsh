#!/usr/bin/env bash
set -euo pipefail

# 'autojump' 또는 'zoxide'
JUMP_IMPL="${JUMP_IMPL:-autojump}"

REPO_URL="https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main"
REPO_CLONE_URL="https://github.com/SuperLeeK/ohmyzsh.git"
DOTFILES_DIR="$HOME/.dotfiles"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

msg()  { echo -e "\033[1;32m[+] \033[0m$*"; }
warn() { echo -e "\033[1;33m[!] \033[0m$*"; }
err()  { echo -e "\033[1;31m[x] \033[0m$*"; }

require_macos() {
  [[ "$(uname)" == "Darwin" ]] || { err "This installer targets macOS."; exit 1; }
}

install_xcode_cli() {
  if ! xcode-select -p >/dev/null 2>&1; then
    msg "Installing Xcode Command Line Tools..."
    xcode-select --install || true
    until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  fi
}

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    msg "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -d "/opt/homebrew/bin" ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
      echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
}

brew_bundle() {
  if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
    msg "Installing brew packages/apps from Brewfile..."
    brew bundle --file="$DOTFILES_DIR/Brewfile" || warn "Brew bundle finished with warnings"
  fi
}

clone_repo() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    msg "Updating existing dotfiles repo..."
    git -C "$DOTFILES_DIR" pull --rebase --autostash
  else
    msg "Cloning dotfiles repo to $DOTFILES_DIR ..."
    git clone "$REPO_CLONE_URL" "$DOTFILES_DIR" || warn "Failed to clone dotfiles repo"
  fi
}

install_ohmyzsh() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    msg "Installing oh-my-zsh (unattended)..."
    RUNZSH=no CHSH=yes KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    msg "oh-my-zsh already installed."
  fi
}

install_plugins() {
  msg "Installing oh-my-zsh custom plugins..."
  local list_file="$DOTFILES_DIR/plugins.txt"
  [[ -f "$list_file" ]] || { warn "plugins.txt not found. Skipping."; return; }
  while IFS= read -r repo || [[ -n "$repo" ]]; do
    [[ -z "$repo" || "$repo" =~ ^# ]] && continue
    local name=$(basename "$repo" .git)
    local target="$ZSH_CUSTOM_DIR/plugins/$name"
    if [[ -d "$target/.git" ]]; then
      git -C "$target" pull --ff-only || warn "Failed to update $name"
    else
      git clone --depth=1 "$repo" "$target" || warn "Failed to clone $repo"
    fi
  done < "$list_file"
}

install_autojump() {
  msg "Installing autojump..."
  brew list --formula | grep -q '^autojump$' || brew install autojump
}

install_zoxide() {
  msg "Installing zoxide..."
  brew list --formula | grep -q '^zoxide$'  || brew install zoxide
}

link_zshrc() {
  msg "Linking .zshrc ..."
  if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
  fi
  if [[ -f "$DOTFILES_DIR/zsh/.zshrc" ]]; then
    ln -snf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  else
    warn "$DOTFILES_DIR/zsh/.zshrc not found; leaving current ~/.zshrc in place."
  fi
}

set_default_shell() {
  if [[ "$SHELL" != *"/zsh" ]]; then
    msg "Changing default shell to zsh..."
    local zsh_path
    zsh_path="$(command -v zsh)"
    if ! grep -q "$zsh_path" /etc/shells; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$zsh_path"
  fi
}

main() {
  require_macos
  install_xcode_cli
  install_homebrew
  clone_repo
  brew_bundle || true
  install_ohmyzsh
  install_plugins

  case "$JUMP_IMPL" in
    autojump) install_autojump ;;
    zoxide)   install_zoxide ;;
    *) warn "Unknown JUMP_IMPL=$JUMP_IMPL (use 'autojump' or 'zoxide')" ;;
  esac

  link_zshrc
  set_default_shell

  msg "All done! Open a new terminal window (or run 'exec zsh')."
}

main "$@"
