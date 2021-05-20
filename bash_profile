# alias atom="atom-beta"
# This was needed after mojave for __git_ps1 to work
source /usr/local/etc/bash_completion.d/git-prompt.sh
export PS1="\h:\[\e[33m\]\w\[\e[m\] \u\[\033[32m\]\$(__git_ps1)\[\033[00m\]\$ "

# team-sync stuff
export TEAM_SYNC_APP_ID=1
# Disabled because of gists
#export GH_SSL=1

if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

eval "$(rbenv init -)"
export PATH="/usr/local/sbin:$PATH"

# dev-ssh.sh thinks we're "chesterb-default` w/o this ¯\_(ツ)_/¯
export GHE_LXC_NAME=vagrant-default
export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"

export ANSIBLE_VAULT_PASSWORD_FILE=/Users/chesterbr/.ansible_vault_pass.txt

export PATH="/Users/chesterbr/bin/:$PATH"

complete -C /Users/chesterbr/bin/hubbers hubbers

# because hubot-classic and heaven said so
eval "$(nodenv init -)"

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
