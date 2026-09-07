Just my dotfiles.　Not much to see here.

- I use [dotbot](https://github.com/anishathalye/dotbot) just so it works seamlessly on Mac/Linux/Codespaces
- Couple customizations mostly reflect my dubious taste in colors and shortcuts 😅
- Includes my personal [Claude Code](https://claude.com/claude-code) config — see [`claude/README.md`](claude/README.md)
- Self-reminders:
  - On a new mac:
    1. Install [Homebrew](https://brew.sh/)
    2. Clone this anywhere (e.g. `~/code/chesterbr/dotfiles`)
    3. Run `./install` - symlinks dotfiles, installs Homebrew packages, and sets up Homebrew bash as default shell (will prompt for password)
    4. `ssh-add --apple-use-keychain ~/.ssh/id_KEYTYPE` to add the ssh key passphrase to the Keychain (only needed once; bash_profile auto-adds ed25519 on new sessions)
    5. Claude Code: `./install` already symlinked `~/.claude/{settings.json,CLAUDE.md}` and the personal commands. On first Claude run, if official plugins report "marketplace not found", run `/plugin marketplace add anthropics/claude-plugins-official` once. See [`claude/README.md`](claude/README.md).
  - On a new Linux box (e.g. Ubuntu):
    1. Clone this anywhere (e.g. `~/code/chesterbr/dotfiles`)
    2. Copy `~/.ssh/id_ed25519{,.pub}` over from another machine (used for both GitHub auth and commit signing; `gitconfig` sets `commit.gpgsign = true`)
    3. Run `./install` - symlinks dotfiles and apt-installs packages (will prompt for sudo password)
    4. `gh auth login` then `gh auth setup-git`, if `~/.gitconfig`'s `[credential]` blocks aren't already working
    5. (Optional) Apply the Mac-like desktop tweaks (Firefox theme, Toshy keyboard, dock, window controls) — see [`gnome/README.md`](gnome/README.md)
    6. Claude Code: same as the mac step 5 above.
  - If you add a new file, edit `install.conf.yaml` to include it

## Claude Code config

Personal/general Claude Code configuration lives in [`claude/`](claude/) and is symlinked into
`~/.claude` by `./install`. It is the **base**, present on every machine; work (Wrapbook) config
is layered on top only where that repo is checked out, and never lives here.

**To (re)configure Claude on any machine — hand this to a Claude CLI:**

> _"Read `claude/README.md` in this dotfiles repo and set up my personal Claude Code config on
> this machine: run `./install` if the `~/.claude` symlinks aren't in place, confirm
> `~/.claude/settings.json` and `~/.claude/CLAUDE.md` point into `claude/`, register the official
> plugin marketplace if official plugins are missing, and verify a session starts cleanly. This is
> a personal machine, so do NOT set up any Wrapbook/work config."_

Anything private/machine-specific goes in an untracked `~/.claude/CLAUDE.personal.local.md`
(imported automatically, skipped if absent) — never committed to this public repo. Full details,
including the auto-sync and the never-commit list, are in [`claude/README.md`](claude/README.md).
