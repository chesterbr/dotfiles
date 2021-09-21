# This file is ran from ~/.bashrc (because Codespaces), so keep it idempotent!

prepend_to_path()
{
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
      PATH="$1${PATH:+":$PATH"}"
  fi
}

if [[ "$(uname -s)" == "Darwin" ]]
then
  ### macOS stuff

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

  # git-prompt is is needed for __git_ps1 to work
  source /etc/bash_completion.d/git-prompt

  alias dotfiles="cd /workspaces/.codespaces/.persistedshare/dotfiles"
fi

### OS-neutral stuff


export PS1="\h:\[\e[33m\]\w\[\e[m\] \u\[\033[32m\]\$(__git_ps1)\[\033[00m\]\$ "
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass.txt

prepend_to_path /usr/local/opt/mysql@5.7/bin
prepend_to_path ~/bin
prepend_to_path /usr/local/sbin

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# Enable to use https://github.localhost (or don't, who knows?)
# export GH_SSL=1
