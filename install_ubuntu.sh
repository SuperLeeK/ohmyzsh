#!/usr/bin/env bash
set -euo pipefail

REPO_CLONE_URL="https://github.com/SuperLeeK/ohmyzsh.git"
DOTFILES_DIR="$HOME/.dotfiles"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

msg()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
err()  { echo -e "\033[1;31m[x]\033[0m $*"; }

require_ubuntu() {
  if ! grep -qi "ubuntu" /etc/os-release >/dev/null 2>&1; then
    warn "This installer targets Ubuntu/WSL. Continuing anyway, but some commands might fail."
  fi
}

install_zsh() {
  local packages_to_install=()
  for pkg in zsh wget curl git unzip; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
      packages_to_install+=("$pkg")
    fi
  done

  if [[ ${#packages_to_install[@]} -gt 0 ]]; then
    msg "Installing prerequisites: ${packages_to_install[*]}..."
    sudo apt-get update && sudo apt-get install -y "${packages_to_install[@]}"
  else
    msg "All prerequisites (zsh, wget, curl, git, unzip) are already installed."
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
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
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

link_zshrc() {
  msg "Linking .zshrc and zsh configs..."
  
  # Link .zshrc
  if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
  fi
  if [[ -f "$DOTFILES_DIR/zsh/.zshrc" ]]; then
    ln -snf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  else
    warn "$DOTFILES_DIR/zsh/.zshrc not found; leaving current ~/.zshrc in place."
  fi
  
  # Link extra zsh config files
  local zsh_extras=(".zsh_aliases" ".zsh_functions" ".zsh_env" ".zsh_projects")
  for file in "${zsh_extras[@]}"; do
    if [[ -f "$DOTFILES_DIR/zsh/$file" ]]; then
      ln -snf "$DOTFILES_DIR/zsh/$file" "$HOME/$file"
    fi
  done
}

set_default_shell() {
  if [[ "$SHELL" != *"/zsh" ]]; then
    msg "Changing default shell to zsh..."
    local zsh_path
    zsh_path="$(command -v zsh)"
    if ! grep -q "$zsh_path" /etc/shells; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    sudo chsh -s "$zsh_path" "$USER" || chsh -s "$zsh_path"
  fi
}

main() {
  require_ubuntu
  install_zsh
  clone_repo
  install_ohmyzsh
  install_plugins
  link_zshrc
  set_default_shell

  msg "All done! Open a new terminal window (or run 'exec zsh')."
}

main "$@"
