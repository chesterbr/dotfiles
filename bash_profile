
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
  eval "$(rbenv init -)"
  export PATH="/usr/local/sbin:$PATH"

  # Had this for hubot-classic and heaven
  # eval "$(nodenv init -)"
else
  ### Linux/Codespaces stuff

  # git-prompt is is needed for __git_ps1 to work
  source /etc/bash_completion.d/git-prompt

  alias dotfiles="cd /workspaces/.codespaces/.persistedshare/dotfiles"
fi

export PS1="\h:\[\e[33m\]\w\[\e[m\] \u\[\033[32m\]\$(__git_ps1)\[\033[00m\]\$ "

# Enable to use https://github.localhost (or don't, who knows?)
# export GH_SSL=1

export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass.txt
export PATH=~/bin/:$PATH

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
