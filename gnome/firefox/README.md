# 🦊 Firefox macOS window theme (Linux only)

Makes Firefox on Linux/GNOME feel like the Mac: real macOS traffic-light window
buttons (red/yellow/green circles, correct order) and tab close buttons on the
right. Purely cosmetic, applied through Firefox's `userChrome.css` mechanism.

- [`chrome/userChrome.css`](chrome/userChrome.css) — the actual styling
- [`user.js`](user.js) — prefs applied on startup: load `userChrome.css`, and
  stop a lone Alt/Option tap from opening the menu bar
  (`ui.key.menuAccessKeyFocuses`)

This is **not** part of `./install` — Firefox stores profiles in a randomized
directory, so it can't be a plain dotbot symlink, and it needs a manual toolbar
step at the end. Apply it by hand (or point Claude Code at this file — see the
bottom).

## Apply it

Two files get linked into the *active* Firefox profile. The tricky parts on
Linux are (a) Firefox may be a **snap** (the Ubuntu default), an apt/`.deb`, or a
**flatpak**, each with a different data dir, and (b) the profile folder name is
randomized (e.g. `nhhsznfg.default-1783701094882`). This block figures both out:

```bash
# Point at your dotfiles clone (adjust if you cloned elsewhere)
REPO_FF="$HOME/code/chesterbr/dotfiles/gnome/firefox"

# 1. Locate the Firefox data dir: snap (Ubuntu default), then apt/.deb, then flatpak
for d in \
  "$HOME/snap/firefox/common/.mozilla/firefox" \
  "$HOME/.mozilla/firefox" \
  "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"; do
  [ -f "$d/profiles.ini" ] && FF_DIR="$d" && break
done
[ -z "$FF_DIR" ] && { echo "No Firefox profile found — is it installed & launched once?"; }
echo "Firefox data dir: $FF_DIR"

# 2. Find the default profile: [Install] Default=, else a [Profile] with Default=1, else first Path=
REL=$(awk -F= '
  /^\[Install/{ins=1;prof=0;next}
  /^\[Profile/{ins=0;prof=1;p="";next}
  /^\[/       {ins=0;prof=0}
  ins && $1=="Default"                {print $2; done=1; exit}
  prof && $1=="Path"                  {p=$2; if(!first) first=p}
  prof && $1=="Default" && $2=="1"    {print p; done=1; exit}
  END{if(!done && first) print first}   # exit still runs END, so guard on done
' "$FF_DIR/profiles.ini")
case "$REL" in /*) PROFILE="$REL";; *) PROFILE="$FF_DIR/$REL";; esac
echo "Profile: $PROFILE"

# 3. Symlink the customizations in (so future edits in the repo just propagate)
mkdir -p "$PROFILE/chrome"
ln -sf "$REPO_FF/user.js"               "$PROFILE/user.js"
ln -sf "$REPO_FF/chrome/userChrome.css" "$PROFILE/chrome/userChrome.css"
echo "✅ Linked into $PROFILE — now do the manual step below, then restart Firefox."
```

> **Note:** if you already have a `user.js` with other prefs, the `ln -sf` above
> replaces it. Back it up first, or add the one `user_pref` line manually instead.

## Manual step (can't be scripted)

The styling only renders once the native title bar is off, and that toggle lives
in Firefox's UI:

1. Open Firefox, right-click any blank space on the tab bar → **Customize Toolbar…**
2. Bottom-left corner: **uncheck Title Bar** (make sure it's OFF).
3. Click **Done** and restart Firefox.

You should see the red/yellow/green traffic-light buttons and right-aligned tab
close buttons.

## Applying via Claude Code

The commands above are deterministic, but if something's off (unusual install,
multiple profiles, snap confinement blocking the symlink), just tell Claude Code:

> Apply the Firefox theme per `firefox/README.md` on this machine.

It can detect the real profile, adapt snap/apt/flatpak paths, fall back to
copying instead of symlinking if confinement blocks the link, and confirm the
result — then remind you about the manual Title Bar toggle.
