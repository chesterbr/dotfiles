alias g="cd ~/code/github/github"
alias e="cd ~/code/github/enterprise2"
alias update-e2-cert="echo -n | openssl s_client -connect 172.28.128.4:8443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/enterprise.cer ; sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/enterprise.cer ; rm /tmp/enterprise.cer"
alias fix-tls-handshake="killall firefox; sleep 1; cd ~/Library/Application\ Support/Firefox/Profiles/dde02f1s.chester-work; mv cert9.db cert9.db.old; echo All done, just open Firefox again"
# alias atom="atom-beta"

# git-prompt is is needed for __git_ps1 to work
if [[ "$(uname -s)" == "Darwin" ]]
then
  source /usr/local/etc/bash_completion.d/git-prompt.sh
  if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
  fi
  # TODO: Figure out rbenv on codespaces/linux
  eval "$(rbenv init -)"
  export PATH="/usr/local/sbin:$PATH"

  # because hubot-classic and heaven said so
  eval "$(nodenv init -)"

else
  source /etc/bash_completion.d/git-prompt
fi

export PS1="\h:\[\e[33m\]\w\[\e[m\] \u\[\033[32m\]\$(__git_ps1)\[\033[00m\]\$ "
# Do I really need this?
#export GITHUB_PATH="/Users/chesterbr/code/github/github"

# Disabled because of gists
#export GH_SSL=1

# dev-ssh.sh thinks we're "chesterb-default` w/o this ¯\_(ツ)_/¯
export GHE_LXC_NAME=vagrant-default
export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"

export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass.txt

export PATH=~/bin/:$PATH


# airflow-sources wanted it to be here
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
