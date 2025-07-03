Just my dotfiles.　Not much to see here.

- I use [dotbot](https://github.com/anishathalye/dotbot) just so it works semalessly on Mac/Linux/Codespaces
- Couple customizations mostly reflect my dubious taste in colors and shortcuts 😅
- Self-reminders:
  - (wonder if I could automate these) On a new mac, run:
    - `chsh -s /bin/bash` to use bash as default shell
    - `ssh-add -K ~/.ssh/id_KEYTYPE` to add the ssh key passphrase to the Keychain (`KEYTYPE` is RSA, ed25519, etc.)
    - Install [Homebrew](https://brew.sh/), then `git` and `gh` formulas
  - Clone this anywhere (e.g. `~/code/chesterbr/dotfiles` and run `./install` to symlink everything
  - if you add a new file, edit `install.conf.yaml` to include it
