export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Ensure Homebrew path in interactive shells too
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# autojump 플러그인은 설치되어 있을 때만 추가 (경고 방지)
if command -v brew >/dev/null 2>&1; then
  AJ_SH="$(brew --prefix 2>/dev/null)/etc/profile.d/autojump.sh"
  [[ -s "$AJ_SH" ]] && plugins+=(autojump)
fi

source $ZSH/oh-my-zsh.sh

# Jump: zoxide 우선, 없으면 autojump
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd j)"
else
  if command -v brew >/dev/null 2>&1; then
    AJ_SH="$(brew --prefix 2>/dev/null)/etc/profile.d/autojump.sh"
    [[ -s "$AJ_SH" ]] && . "$AJ_SH"
  fi
fi

# nvm (brew) 초기화
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"
[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && . "$(brew --prefix nvm)/etc/bash_completion.d/nvm"

# Common aliases
alias ll='ls -alF'
alias gs='git status'
alias ga='git add'
alias gcm='git commit -m'
alias z='code ~/.zshrc'
alias ㅋ='z'
alias s='source ~/.zshrc'
alias ㄴ='s'

alias ㅓ="j"