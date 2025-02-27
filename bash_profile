# This file is ran from ~/.bashrc (because Codespaces), so keep it idempotent!
# (although the if below may alleviate that need)

# Don't sweat if you can't find a file (some are OS-specific, some require packages)
# shellcheck disable=SC1091

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

prepend_to_path() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$1${PATH:+":$PATH"}"
  fi
}

# Codespaces bash prompt theme, modified for my prefs
__bash_prompt() {
  # \[\033[0;30m\] = Black - Regular
  # \[\033[0;31m\] = Red
  # \[\033[0;32m\] = Green
  # \[\033[0;33m\] = Yellow
  # \[\033[0;34m\] = Blue
  # \[\033[0;35m\] = Purple
  # \[\033[0;36m\] = Cyan
  # \[\033[0;37m\] = White
  # \[\033[1;30m\] = Black - Bold
  # \[\033[1;31m\] = Red
  # \[\033[1;32m\] = Green
  # \[\033[1;33m\] = Yellow
  # \[\033[1;34m\] = Blue
  # \[\033[1;35m\] = Purple
  # \[\033[1;36m\] = Cyan
  # \[\033[1;37m\] = White
  # \[\033[4;30m\] = Black - Underline
  # \[\033[4;31m\] = Red
  # \[\033[4;32m\] = Green
  # \[\033[4;33m\] = Yellow
  # \[\033[4;34m\] = Blue
  # \[\033[4;35m\] = Purple
  # \[\033[4;36m\] = Cyan
  # \[\033[4;37m\] = White
  # \[\033[40m\]   = Black - Background
  # \[\033[41m\]   = Red
  # \[\033[42m\]   = Green
  # \[\033[43m\]   = Yellow
  # \[\033[44m\]   = Blue
  # \[\033[45m\]   = Purple
  # \[\033[46m\]   = Cyan
  # \[\033[47m\]   = White
  # \[\033[0m\]    = Text Reset
  local hostname="\[\033[0m\]\h\[\033[0m\]"
  #shellcheck disable=SC2016
  local userpart='`export XIT=$? \
        && [ ! -z "${GITHUB_USER}" ] && echo -n "\[\033[0;37m\]@${GITHUB_USER}" || echo -n "\[\033[0;37m\]\u" \
        `'
  #shellcheck disable=SC2016
  local gitbranch='\[\033[0;36m\](\[\033[1;31m\]$(git symbolic-ref --short HEAD 2>/dev/null)\[\033[0;36m\])'
  local yellow='\[\033[0;33m\]'
  local removecolor='\[\033[0m\]'
  PS1="${hostname}:${yellow}\w ${userpart} ${gitbranch}${removecolor}\$ "
  unset -f __bash_prompt
}
__bash_prompt

if [[ "$(uname -s)" == "Darwin" ]]; then
  ### macOS stuff

  # I don't care about your shell-of-the-week, Apple
  export BASH_SILENCE_DEPRECATION_WARNING=1

  # Homebrew (hope they don't change this again)
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # git-prompt is is needed for __git_ps1 to work
  source /usr/local/etc/bash_completion.d/git-prompt.sh

  # shellcheck disable=SC2046
  if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
  fi

  alias dotfiles="cd ~/.dotfiles; git status"

  # Forcing JDK 21 because of miniTruco
  export JAVA_HOME=$(/usr/libexec/java_home -v 21)

  # Ensure ssh key is on ssh-agent (with passphrase from keychain)
  if ! ssh-add -l | grep -q -i "ed25519"; then
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519
  fi

else
  ### Linux/Codespaces stuff

  # git-prompt is is needed for __git_ps1 to work
  source /etc/bash_completion.d/git-prompt

  if [ -n "$CODESPACES" ]; then
    # Just so I can find this easily
    alias dotfiles="cd /workspaces/.codespaces/.persistedshare/dotfiles; git status"

    if ! shopt -oq posix; then
      if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
      elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
      fi
    fi

  fi

  # enable color support of ls and also add handy aliases
  if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
  fi
fi

### OS-neutral stuff

export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass.txt
export PROMPT_DIRTRIM=2

alias m='cd ~/code/chesterbr/minitruco-android'
alias gitup='git co main && git pull && git branch --merged | grep -v main | xargs git branch -d'
alias ml='cd ~/code/chesterbr/private-study/python-ml; git status'
# shellcheck disable=SC2142
alias ghclone='__ghclone() { cd ~/code && gh repo clone "$1" "$1" && cd "$1" ; }; __ghclone'

prepend_to_path ~/bin
prepend_to_path /usr/local/sbin

eval "$(rbenv init - bash)"

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
source "$HOME/.cargo/env"
