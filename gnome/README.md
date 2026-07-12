# 🍎 Mac-like GNOME desktop (Ubuntu)

Tweaks that make an Ubuntu **GNOME desktop** feel like macOS. These only make
sense on a graphical GNOME session — **not** on Mac, Windows, or headless/remote
Linux boxes — so they live here instead of in `./install`.

Most of it is reproducible with `gsettings`, but a few pieces (Toshy, the manual
Firefox toolbar toggle) need a human. Apply it by hand, or point Claude Code at
this file:

> Set up the Mac-like GNOME desktop per `gnome/README.md` on this machine.

The values below are what's actually configured on my machine (captured with
`gsettings`), not generic suggestions — so they should reproduce the setup 1:1.

---

## 1. Firefox window/tab theme

macOS traffic-light window buttons + right-aligned tab close buttons in Firefox.
Own runbook (it has a manual step): [`firefox/README.md`](firefox/README.md).

## 2. Keyboard: macOS-style shortcuts (Toshy)

[Toshy](https://github.com/RedBearAK/toshy) remaps modifiers so `Cmd`-based
shortcuts (copy/paste, tab switching, etc.) work like macOS.

- Install with Toshy's official bootstrap (this is what was used here — it
  downloads into `~/Downloads/toshy_<timestamp>/` and runs `setup_toshy.py`):

  ```bash
  bash -c "$(curl -L https://raw.githubusercontent.com/RedBearAK/toshy/main/scripts/bootstrap.sh || wget -O - https://raw.githubusercontent.com/RedBearAK/toshy/main/scripts/bootstrap.sh)"
  ```

  It's interactive and sets up systemd user services (`toshy-config.service`
  et al.), autostart entries, and `~/.local/bin/toshy-*` scripts. Config ends up
  in `~/.config/toshy`; the tray/GUI is `toshy-gui`. Installed versions here:
  config `2026.06.21`, keymapper `xwaykeyz 1.23.3` (check with `toshy-versions`).
- **Wayland/GNOME dependency:** Toshy needs a shell extension to read the focused
  window. This machine uses **Window Calls Extended**
  (`window-calls-extended@hseliger.eu`) — install it via Extension Manager (§3)
  and enable it, or Toshy's setup will prompt for it.
- **Mac keyboard layout** (optional — Toshy does the real work; kept for parity):

  ```bash
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us+mac')]"
  ```

## 3. GNOME Tweaks + Extension Manager

The tools used to manage the rest (exact commands used here; installed versions
`gnome-tweaks 49.0-1`, Extension Manager `0.6.5` from Flathub):

```bash
sudo apt install gnome-tweaks

# Extension Manager is a Flatpak — ensure Flathub exists first (already set up here)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.mattjakeman.ExtensionManager
```

## 4. Window controls: traffic lights on the left

macOS puts close/minimize/maximize on the **left**:

```bash
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
```

This sets the *placement* for native GNOME apps. The colored-circle look in the
browser is handled by the Firefox theme (§1).

### Colored circles for native apps (optional — WhiteSur GTK theme)

For actual macOS-style colored window buttons across native apps, install the
[WhiteSur](https://github.com/vinceliuice/WhiteSur-gtk-theme) GTK theme. This is
what's on disk here (installed to `~/.themes`), though **it is not currently the
active theme — `Yaru-blue-dark` is** — so treat it as available, not applied:

```bash
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git ~/code/vinceliuice/WhiteSur-gtk-theme
cd ~/code/vinceliuice/WhiteSur-gtk-theme
./install.sh -m -a normal          # -m: monterey-style; -a normal: window-button variant
```

To actually switch to it (via GNOME Tweaks → Appearance, or gsettings):

```bash
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
```

## 5. Dock: bottom + auto-hiding, like the macOS Dock

Ubuntu's built-in dock (`ubuntu-dock@ubuntu.com`) uses the Dash-to-Dock schema.
The keys that move it to the bottom and make it auto-hide:

```bash
S=org.gnome.shell.extensions.dash-to-dock
gsettings set $S dock-position 'BOTTOM'
gsettings set $S dock-fixed false        # let it hide instead of reserving space
gsettings set $S autohide true
gsettings set $S intellihide true
gsettings set $S intellihide-mode 'ALL_WINDOWS'
gsettings set $S extend-height false     # size the dock to its icons + center it (not a full-width bar)
gsettings set $S always-center-icons true  # center icons if you ever flip extend-height back on
```

> `extend-height false` is what makes it a compact, centered, macOS-style dock
> floating at the bottom rather than a bar spanning the whole screen edge.

The commands above are self-contained — they set every key outright, so they
don't depend on Ubuntu's vendor defaults and reproduce the dock reliably on a
fresh box. (A raw `dconf dump` of this path is *not* a good substitute: it only
records keys changed from this machine's defaults — here just `dock-position`,
`dock-fixed`, `extend-height`, `always-center-icons` — and silently leans on the
next box having the same Ubuntu defaults for `autohide`/`intellihide`.)

## 6. Trackpad (Apple bcm5974 clickpad)

This is an old Apple **bcm5974** clickpad — the whole surface is one physical
button. Two concerns: taps, and how physical clicks map to buttons.

**No tap-to-click.** Taps turn light touches into clicks, firing accidental
clicks when you mean to reposition or drag — only a physical press should click.
Also disable tap-and-drag (a tap-then-hold starting a drag):

```bash
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click false
gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag false
```

**Physical clicks via button areas.** libinput's *software button areas* make
the bottom corners behave like real buttons:

```bash
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'areas'
```

- **Left-click:** press the main area / bottom-left.
- **Right-click:** press the **bottom-right corner** (macOS secondary click).
- **Drag:** press-drag with one finger, or press-hold the bottom-left corner
  with your thumb and move another finger. The corner-hold works because a
  finger resting in a button area isn't counted toward pointer/scroll fingers —
  a property only clickpads with `INPUT_PROP_BUTTONPAD` get.

`mouse-button-modifier` is left empty (`''`) on purpose: Toshy maps physical
Control→Super in GUI apps, so GNOME's default `<Super>`+drag window-move would
turn a Ctrl+drag into a window move.

```bash
gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier ''
```

> Earlier this machine used an evdev daemon (`ctrl-rightclick/`) for *Ctrl+press
> = right-click* (macOS Ctrl-click). It was removed in favor of `areas`: the
> daemon had to strip the clickpad's `INPUT_PROP_BUTTONPAD` property to inject a
> right-button, which disables software button areas — and with them the
> press-anywhere-and-drag-with-a-second-finger gesture. The bottom-right corner
> replaces it as the secondary click.

## 7. Terminal: Ghostty (default, and the only one in search)

[Ghostty](https://ghostty.org) is the terminal — it speaks the kitty keyboard
protocol, so Shift+Enter works in Claude Code with no config (Ptyxis/VTE can't).
Its own settings live in [`../ghostty/config`](../ghostty/config) (symlinked to
`~/.config/ghostty/config` by dotbot).

```bash
sudo apt install -y ghostty
```

Make it the default terminal, and stop Ubuntu's built-in **Ptyxis** (whose app
is literally named "Terminal", so it wins the "term" search) from showing up —
**without uninstalling it** (Ubuntu leans on it; removing it can break things):

```bash
# Default terminal for xdg-terminal-exec (what GNOME's default-applications
# terminal already points to) and the Debian x-terminal-emulator alternative:
printf '%s\n' 'com.mitchellh.ghostty.desktop' > ~/.config/xdg-terminals.list
sudo update-alternatives --set x-terminal-emulator /usr/bin/ghostty   # optional

# Hide Ptyxis from the app grid / search via a local override (reversible:
# just delete the file). Ptyxis stays installed and usable.
cp /usr/share/applications/org.gnome.Ptyxis.desktop ~/.local/share/applications/
sed -i '/^\[Desktop Entry\]/a NoDisplay=true' ~/.local/share/applications/org.gnome.Ptyxis.desktop
update-desktop-database ~/.local/share/applications
```

(Search may take a moment or a re-login to drop Ptyxis. `~/.inputrc` in the repo
root also teaches bash's readline to treat Shift+Enter as a newline.)

---

### Re-capturing after future changes

If you tweak more of these later, refresh the values here from the live system:

```bash
gsettings get org.gnome.desktop.input-sources sources
gsettings get org.gnome.desktop.wm.preferences button-layout
gsettings list-recursively org.gnome.shell.extensions.dash-to-dock
gnome-extensions list --enabled
```
