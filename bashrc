# Yes, I can do this because my ~/.bash_profile is idempotent and fast(ish)
# (mostly b/c vscode starts terminals as login on Codespaces)
source ~/.bash_profile
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
source /opt/homebrew/opt/chruby/share/chruby/auto.sh
export DISABLE_SPRING=true
export LEFTHOOK_BIN=bin/lefthook
