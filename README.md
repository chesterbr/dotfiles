Just my dotfiles.　Not much to see here.

- I use [dotbot](https://github.com/anishathalye/dotbot) just so it works semalessly on Mac/Linux/Codespaces
- Couple customizations mostly reflect my dubious taste in colors and shortcuts 😅
- Self-reminders:
  - On a new mac:
    1. Install [Homebrew](https://brew.sh/)
    2. Clone this anywhere (e.g. `~/code/chesterbr/dotfiles`)
    3. Run `./install` - symlinks dotfiles, installs Homebrew packages, and sets up Homebrew bash as default shell (will prompt for password)
    4. `ssh-add --apple-use-keychain ~/.ssh/id_KEYTYPE` to add the ssh key passphrase to the Keychain (only needed once; bash_profile auto-adds ed25519 on new sessions)
  - If you add a new file, edit `install.conf.yaml` to include it
