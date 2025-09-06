#!/usr/bin/env bash
set -euo pipefail

# ===== Options =====
# Jump tool: autojump (default) or zoxide
JUMP_IMPL="${JUMP_IMPL:-autojump}"
# Install Homebrew formulae set
WITH_BREW_PACKS="${WITH_BREW_PACKS:-1}"
# Install GUI apps (casks) like iTerm2/VSCode
WITH_CASKS="${WITH_CASKS:-1}"

REPO_URL="https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main"
REPO_CLONE_URL="https://github.com/SuperLeeK/ohmyzsh.git"
DOTFILES_DIR="$HOME/.dotfiles"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ===== Default direct-download URLs (fallbacks) =====
# Rectangle cask 실패 시 사용할 기본 URL (원하면 RECTANGLE_URL 환경변수로 덮어쓰기)
RECTANGLE_URL_DEFAULT="https://github.com/rxhanson/Rectangle/releases/download/v0.90/Rectangle0.90.dmg"
# QtScrcpy는 cask가 없어서 아키텍처에 맞춰 직접 받습니다 (원하면 QTSCRCPY_URL 환경변수로 덮어쓰기)
QTSCRCPY_URL_ARM64="https://github.com/barry-ran/QtScrcpy/releases/download/v3.3.1/QtScrcpy-mac-arm64-Qt6.5.3-v3.3.1.dmg"
QTSCRCPY_URL_X64="https://github.com/barry-ran/QtScrcpy/releases/download/v3.3.1/QtScrcpy-mac-x64-Qt5.15.2-v3.3.1.dmg"

msg()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
err()  { echo -e "\033[1;31m[x]\033[0m $*"; }

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
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
      echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  brew update || true
  brew tap homebrew/cask || true
}

# ---------- Packages you want by default ----------
BREW_FORMULAE=(
  git
  android-platform-tools    # adb/fastboot
  scrcpy                    # Android screen mirror
  ffmpeg
  jq ripgrep fd fzf wget curl tree
  gh                        # GitHub CLI
  openssl
  python@3.12
  gnu-sed coreutils watch
  nvm                       # Node version manager
)

BREW_CASKS=(
  iterm2
  visual-studio-code
  rectangle                 # 실패 시 URL 폴백 사용
)
# -------------------------------------------------

# ------- Direct download installer (DMG/ZIP/TAR.GZ) -------
install_from_url() {
  local name="$1" url="$2"
  [[ -z "$name" || -z "$url" ]] && { warn "install_from_url requires <name> <url>"; return; }
  msg "Installing $name from URL: $url"
  local tmp file mount dir app
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  file="$tmp/${url##*/}"
  curl -L --fail -o "$file" "$url" || { err "download failed for $url"; return; }
  case "$file" in
    *.dmg)
      mount="$(hdiutil attach -nobrowse -quiet "$file" | awk '/\/Volumes\//{print $3; exit}')"
      if [[ -n "$mount" ]]; then
        app="$(find "$mount" -maxdepth 2 -name "*.app" -print -quit)"
        if [[ -n "$app" ]]; then
          cp -R "$app" /Applications/
          xattr -dr com.apple.quarantine "/Applications/$(basename "$app")" || true
        else
          warn "No .app found inside DMG for $name"
        fi
        hdiutil detach "$mount" -quiet || true
      else
        warn "Failed to mount DMG for $name"
      fi
      ;;
    *.zip)
      dir="$tmp/unzip"; mkdir -p "$dir"
      unzip -q "$file" -d "$dir"
      app="$(find "$dir" -maxdepth 3 -name "*.app" -print -quit)"
      if [[ -n "$app" ]]; then
        cp -R "$app" /Applications/
        xattr -dr com.apple.quarantine "/Applications/$(basename "$app")" || true
      else
        warn "No .app found in ZIP for $name"
      fi
      ;;
    *.tar.gz|*.tgz)
      dir="$tmp/untar"; mkdir -p "$dir"
      tar -xzf "$file" -C "$dir"
      app="$(find "$dir" -maxdepth 4 -name "*.app" -print -quit)"
      if [[ -n "$app" ]]; then
        cp -R "$app" /Applications/
        xattr -dr com.apple.quarantine "/Applications/$(basename "$app")" || true
      else
        warn "No .app found in archive for $name"
      fi
      ;;
    *)
      warn "Unsupported file type for $name: $file"
      ;;
  esac
}
# ----------------------------------------------------------

choose_qtscrcpy_url() {
  # 환경변수로 강제 지정하면 그걸 사용
  if [[ -n "${QTSCRCPY_URL:-}" ]]; then
    echo "$QTSCRCPY_URL"; return
  fi
  local arch="$(uname -m)"
  if [[ "$arch" == "arm64" ]]; then
    echo "$QTSCRCPY_URL_ARM64"
  else
    # Rosetta가 있더라도 바이너리는 x64 빌드 사용
    echo "$QTSCRCPY_URL_X64"
  fi
}

install_qtscrcpy() {
  [[ "$WITH_CASKS" == "1" ]] || { msg "Skip QtScrcpy (casks disabled)"; return; }
  if [[ -d "/Applications/QtScrcpy.app" ]]; then
    msg "✔ QtScrcpy already installed"
    return
  fi
  local url; url="$(choose_qtscrcpy_url)"
  install_from_url "QtScrcpy" "$url"
}

brew_install_formulae() {
  [[ "$WITH_BREW_PACKS" == "1" ]] || { msg "Skip brew formulae set"; return; }
  msg "Installing Homebrew formulae..."
  for f in "${BREW_FORMULAE[@]}"; do
    if brew list --formula | grep -qx "$f"; then
      msg "✔ $f already installed"
    else
      brew install "$f" || warn "Failed to install $f"
    fi
  done
  if brew list --formula | grep -qx fzf; then
    "$(brew --prefix)"/opt/fzf/install --all --no-bash --no-fish >/dev/null 2>&1 || true
  fi
}

brew_install_casks() {
  [[ "$WITH_CASKS" == "1" ]] || { msg "Skip casks"; return; }
  msg "Installing Homebrew casks (GUI apps)..."
  for c in "${BREW_CASKS[@]}"; do
    if brew list --cask | grep -qx "$c"; then
      msg "✔ $c already installed"
    else
      if ! brew install --cask "$c"; then
        warn "Failed to install cask $c"
        if [[ "$c" == "rectangle" ]]; then
          local url="${RECTANGLE_URL:-$RECTANGLE_URL_DEFAULT}"
          install_from_url "Rectangle" "$url"
        fi
      fi
    fi
  done
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

ensure_nvm_in_zshrc() {
  local line1='export NVM_DIR="$HOME/.nvm"'
  local line2='[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"'
  local line3='[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && . "$(brew --prefix nvm)/etc/bash_completion.d/nvm"'

  if [[ -f "$DOTFILES_DIR/zsh/.zshrc" ]]; then
    grep -Fq "$line1" "$DOTFILES_DIR/zsh/.zshrc" || printf "\n%s\n" "$line1" >> "$DOTFILES_DIR/zsh/.zshrc"
    grep -Fq "$line2" "$DOTFILES_DIR/zsh/.zshrc" || printf "%s\n" "$line2" >> "$DOTFILES_DIR/zsh/.zshrc"
    grep -Fq "$line3" "$DOTFILES_DIR/zsh/.zshrc" || printf "%s\n" "$line3" >> "$DOTFILES_DIR/zsh/.zshrc"
  fi
}

install_nvm_node_stack() {
  # nvm (brew), Node LTS via nvm, npm/yarn/ts-node
  brew list --formula | grep -qx nvm || brew install nvm || warn "nvm install failed"
  mkdir -p "$HOME/.nvm"
  export NVM_DIR="$HOME/.nvm"
  local nvm_sh
  nvm_sh="$(brew --prefix nvm 2>/dev/null)/nvm.sh"
  if [[ -s "$nvm_sh" ]]; then
    . "$nvm_sh"
    if ! command -v node >/dev/null 2>&1; then
      msg "Installing Node LTS via nvm..."
      nvm install --lts || warn "nvm install LTS failed"
      nvm alias default 'lts/*' || true
    fi
    # npm은 node에 포함. yarn/ts-node 설치
    if command -v corepack >/dev/null 2>&1; then
      corepack enable || true
      corepack prepare yarn@stable --activate || npm i -g yarn || true
    else
      npm i -g yarn || true
    fi
    npm i -g ts-node || true
  else
    warn "nvm.sh not found; open a new shell and rerun to install Node/yarn/ts-node via nvm."
  fi
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
  brew_install_formulae
  brew_install_casks
  install_qtscrcpy

  install_ohmyzsh
  install_plugins
  ensure_nvm_in_zshrc
  install_nvm_node_stack

  link_zshrc
  set_default_shell
  msg "All done! Open a new terminal window (or run 'exec zsh')."
}

main "$@"