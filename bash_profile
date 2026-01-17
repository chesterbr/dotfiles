# shellcheck disable=SC2148 # This will be aliased to .bash_profile, which doesn't need a shebang
# shellcheck disable=SC1091 # Sometimes we won't find (OS/package-specific) files, don't sweat

# Human: This file is ran from ~/.bashrc (because Codespaces), so keep it idempotent!

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

  # Homebrew (yes, they change this according to architecture. Why, god, why?)
  if [[ "$(uname -m)" == "arm64" ]]; then
    # For Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    # For Intel
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  # shellcheck disable=SC2046
  if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
  fi

  alias dotfiles="cd ~/.dotfiles; git status"

  # Forcing JDK 21 because of miniTruco, but only if available
  if command -v /usr/libexec/java_home >/dev/null 2>&1; then
    JAVA_21_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null)
    if [ -n "$JAVA_21_HOME" ]; then
      export JAVA_HOME="$JAVA_21_HOME"
    fi
  fi

  # Ensure ssh key is on ssh-agent (with passphrase from keychain)
  if ! ssh-add -l | grep -q -i "ed25519"; then
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519
  fi

else
  ### Linux stuff

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

  # enable color support of ls and also add handy color-related aliases
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
export COLORTERM=truecolor

# ${CURRENT_JOB} stuff
export DISABLE_SPRING=true
export LEFTHOOK_BIN=bin/lefthook
alias aws-refresh='aws sso logout --profile development && bin/wb aws sso-login'

# General coding stuff
alias m='cd ~/code/chesterbr/minitruco-android'
alias ml='cd ~/code/chesterbr/private-study/python-ml; git status'
# shellcheck disable=SC2142
alias ghclone='__ghclone() { cd ~/code && gh repo clone "$1" "$1" && cd "$1" ; }; __ghclone'
# Updates the main branch (or the current one if you type "gitup this")
# so that your local branch is up to date with the tracked remote, if any
gitup() {
  set -e
  if [ "$1" != "this" ]; then
    git co main
  fi

  branch=$(git rev-parse --abbrev-ref HEAD)
  remote=$(git config branch."$branch".remote 2>/dev/null || echo "origin")
  remote_branch=$(git config branch."$branch".merge 2>/dev/null | sed 's|refs/heads/||')
  echo "== Updating $branch <- $remote/$remote_branch"

  git pull
  git branch --merged | grep -v main | xargs git branch -d

  if [ -x bin/update ]; then
    bin/update
  else
    echo "bin/update not found; not running it"
  fi

  echo "== Done"
}

prepend_to_path ~/bin
prepend_to_path /usr/local/sbin

eval "$(rbenv init - bash)"

if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi
