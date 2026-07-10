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

The tools used to manage the rest:

```bash
sudo apt install -y gnome-tweaks
flatpak install -y flathub com.mattjakeman.ExtensionManager
```

## 4. Window controls: traffic lights on the left

macOS puts close/minimize/maximize on the **left**:

```bash
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
```

> This sets the *placement* for native GNOME apps. The colored-circle look for
> the browser is handled by the Firefox theme (§1). Colored circles for *all*
> native apps would additionally need a Mac-style GTK theme (e.g. WhiteSur) —
> not installed here, so leave this out unless you add such a theme.

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
```

For an exact backup/restore of every dock setting (icon size, indicators, etc.):

```bash
# back up
dconf dump /org/gnome/shell/extensions/dash-to-dock/ > dock.dconf
# restore
dconf load /org/gnome/shell/extensions/dash-to-dock/ < dock.dconf
```

---

### Re-capturing after future changes

If you tweak more of these later, refresh the values here from the live system:

```bash
gsettings get org.gnome.desktop.input-sources sources
gsettings get org.gnome.desktop.wm.preferences button-layout
gsettings list-recursively org.gnome.shell.extensions.dash-to-dock
gnome-extensions list --enabled
```
