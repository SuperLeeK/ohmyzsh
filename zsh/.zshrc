export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting autojump)

source $ZSH/oh-my-zsh.sh

alias ll='ls -alF'
alias gs='git status'
alias ga='git add'
alias gcm='git commit -m'
alias z='code ~/.zshrc'
alias s='source ~/.zshrc'
