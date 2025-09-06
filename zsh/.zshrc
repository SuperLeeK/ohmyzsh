export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# 기본 플러그인
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# autojump가 설치되어 있으면 플러그인 추가 (설치 안돼 있으면 경고 방지)
if command -v brew >/dev/null 2>&1; then
  AJ_SH="$(brew --prefix 2>/dev/null)/etc/profile.d/autojump.sh"
  [[ -s "$AJ_SH" ]] && plugins+=("autojump")
fi

source $ZSH/oh-my-zsh.sh

# ===== Jump (zoxide 우선, 없으면 autojump) =====
if command -v zoxide >/dev/null 2>&1; then
  # 'j' 명령으로 zoxide 사용 (habit 호환)
  eval "$(zoxide init zsh --cmd j)"
else
  if command -v brew >/dev/null 2>&1; then
    AJ_SH="$(brew --prefix 2>/dev/null)/etc/profile.d/autojump.sh"
    [[ -s "$AJ_SH" ]] && . "$AJ_SH"
  fi
fi
# ==============================================

# Common aliases
alias ll='ls -alF'
alias gs='git status'
alias ga='git add'
alias gcm='git commit -m'
alias z='code ~/.zshrc'
alias s='source ~/.zshrc'
