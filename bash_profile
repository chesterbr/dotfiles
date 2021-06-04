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
  if [[ ":$PATH:" != *"rbenv/shims:"* ]]; then
    eval "$(rbenv init -)"
  fi

  # Had this for hubot-classic and heaven
  # eval "$(nodenv init -)"
else
  ### Linux/Codespaces stuff

  # GitHub
  alias g="cd ~/code/github/github"

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

  # If this is an xterm set the title to user@host:dir
  case "$TERM" in
  xterm*|rxvt*)
      PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
      ;;
  *)
      ;;
  esac

fi

### OS-neutral stuff

export PS1="\h:\[\e[33m\]\w\[\e[m\] \u\[\033[32m\]\$(__git_ps1)\[\033[00m\]\$ "
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass.txt
export PROMPT_DIRTRIM=2

prepend_to_path /usr/local/opt/mysql@5.7/bin
prepend_to_path ~/bin
prepend_to_path /usr/local/sbin

# airflow-sources wanted it to be here
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# Enable to use https://github.localhost (or don't, who knows?)
# export GH_SSL=1
