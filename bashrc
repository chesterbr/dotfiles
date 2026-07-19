# shellcheck shell=bash # Aliased to .bashrc, so no shebang to infer the shell from

# Yes, I can do this because my ~/.bash_profile is idempotent and fast(ish)
# (mostly b/c vscode starts terminals as login on Codespaces)
# shellcheck source=bash_profile # ~ is unresolvable to shellcheck; point it at the repo copy
source ~/.bash_profile
