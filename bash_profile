# This file is ran from ~/.bashrc (because Codespaces), so keep it idempotent!
# (although the if below may alleviate that need)

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

prepend_to_path()
{
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
    local userpart='`export XIT=$? \
        && [ ! -z "${GITHUB_USER}" ] && echo -n "\[\033[0;37m\]@${GITHUB_USER}" || echo -n "\[\033[0;37m\]\u" \
        `'
    local gitbranch='\[\033[0;36m\](\[\033[1;31m\]$(git symbolic-ref --short HEAD 2>/dev/null)\[\033[0;36m\])'
    local yellow='\[\033[0;33m\]'
    local removecolor='\[\033[0m\]'
    PS1="${hostname}:${yellow}\w ${userpart} ${gitbranch}${removecolor}\$ "
    unset -f __bash_prompt
}
__bash_prompt

if [[ "$(uname -s)" == "Darwin" ]]
then
  ### macOS stuff

  # GitHub
  alias g="cd ~/code/github/github"
  alias e="cd ~/code/github/enterprise2"
  alias update-e2-cert="echo -n | openssl s_client -connect 172.28.128.4:8443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/enterprise.cer ; sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/enterprise.cer ; rm /tmp/enterprise.cer"
  alias fix-tls-handshake="killall firefox; sleep 1; cd ~/Library/Application\ Support/Firefox/Profiles/dde02f1s.chester-work; mv cert9.db cert9.db.old; echo All done, just open Firefox again"

  # I don't care about your shell-of-the-week, Apple
  export BASH_SILENCE_DEPRECATION_WARNING=1

  # git-prompt is is needed for __git_ps1 to work
  source /usr/local/etc/bash_completion.d/git-prompt.sh

  if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
  fi
  # TODO: Figure out rbenv on codespaces/linux
  # (and maybe also if macOS doesn't have it installed)
  eval "$(rbenv init -)"

  # Had this for hubot-classic and heaven
  # eval "$(nodenv init -)"

  alias dotfiles="cd ~/.dotfiles"
else
  ### Linux/Codespaces stuff

  # GitHub
  alias g="cd /workspaces/github"

  # git-prompt is is needed for __git_ps1 to work
  source /etc/bash_completion.d/git-prompt

  # Just so I can find this easily
  alias dotfiles="cd /workspaces/.codespaces/.persistedshare/dotfiles"

  if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
      . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
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

# GitHub
alias dotcom="GITHUB_CODESPACES_CUSTOM_PORT=1 bin/server --debug"
alias t="bin/rails test"
alias ta="TEST_ALL_FEATURES=1 bin/rails test"
# Will try this again when it matures a bit
# alias ghdebug="BYEBUGDAP=1 bin/server --debug"

# Codespaces default profile had this
export NVS_HOME="$HOME/.nvs"
[ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh"

export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass.txt
export PROMPT_DIRTRIM=2

prepend_to_path /usr/local/opt/mysql@5.7/bin
prepend_to_path ~/bin
prepend_to_path /usr/local/sbin

# airflow-sources wanted it to be here
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# Enable to use https://github.localhost (or don't, who knows?)
# export GH_SSL=1
