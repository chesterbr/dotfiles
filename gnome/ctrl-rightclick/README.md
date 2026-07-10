# 🖱️ ctrl-rightclick — macOS-style secondary click

Hold physical **Control** and **physically press** the trackpad → **right-click**
(context menu), like macOS Control-click. A small evdev daemon does it; runs as a
systemd **user** service (no sudo at runtime).

This is very specific to this machine (Ubuntu GNOME **Wayland**, on a MacBook with
the Apple `bcm5974` clickpad, with **Toshy** remapping the keyboard). The long
story of *why* it has to work this way is in the docstring at the top of
[`ctrl-rightclick.py`](ctrl-rightclick.py) — worth reading before changing it.

## Why it's built the way it is (short version)

- **Wayland** can't remap clicks in the compositor, and Toshy only *read-monitors*
  the pointer — so we work at the **evdev** layer: grab the clickpad, re-emit it
  through a uinput clone, and turn `BTN_LEFT` into `BTN_RIGHT` while Control is held.
- The physical keyboard is grabbed by Toshy, so we read Control from **Toshy's
  virtual keyboard output**. Toshy remaps Control **per-app**: `LEFTCTRL` in
  terminals, `LEFTMETA` (Super) in GUI apps — the daemon watches **both**.
  Physical **Cmd** (`RIGHTCTRL`) is intentionally *not* watched, so ⌘-click stays
  Linux multi-select / open-in-new-tab.
- The clone **drops `INPUT_PROP_BUTTONPAD`** so libinput honors the injected
  `BTN_RIGHT` (clickpads otherwise derive the button from finger count and ignore
  it), and the right-click is emitted **from the clone** because Wayland-native
  apps (Firefox) drop button events from a device that never moved the pointer.

**Limitations:** only *physical presses* convert (tap-to-click is synthesized
above this layer, so Ctrl+tap stays left); two-finger *physical press* → right is
lost, but two-finger *tap* → right still works.

## Requirements

- Ubuntu **GNOME on Wayland**, **Toshy** installed & running (see [`../README.md`](../README.md)).
- `python3-evdev`, and membership in the `input` group (Toshy's udev setup already
  grants access to `/dev/uinput`):
  ```bash
  sudo apt install -y python3-evdev
  ```

## Required GNOME setting (one-time)

In GUI apps Toshy turns Control into **Super**, and GNOME's `Super+drag`
window-move would eat the click. Disable that modifier (drag windows by their
titlebars instead, like macOS):

```bash
gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier ''
```

(To restore GNOME's default later: set it back to `'<Super>'`.)

## Install / enable

The service unit is symlinked from this repo into the systemd user directory, so
edits here propagate:

```bash
ln -sf ~/code/chesterbr/dotfiles/gnome/ctrl-rightclick/ctrl-rightclick.service \
       ~/.config/systemd/user/ctrl-rightclick.service
systemctl --user daemon-reload
systemctl --user enable --now ctrl-rightclick.service
```

Check it: `systemctl --user status ctrl-rightclick.service`
Logs: `journalctl --user -u ctrl-rightclick.service -f`

## Disable / uninstall

```bash
systemctl --user disable --now ctrl-rightclick.service
rm ~/.config/systemd/user/ctrl-rightclick.service
```
The trackpad grab is released the instant the process stops (systemd stop, crash,
or Ctrl-C when run by hand), so the touchpad always reverts to normal on its own.

## Tuning

- **Test by hand** (foreground, Ctrl-C to stop): `python3 ctrl-rightclick.py`
  — stop the service first (`systemctl --user stop ctrl-rightclick.service`) so
  they don't both grab the trackpad.
- **Change the trigger key:** edit `TRIGGER_KEYS` in `ctrl-rightclick.py`. To find
  what a physical key emits on Toshy's virtual keyboard, read
  `/dev/input/by-id/...` or watch `XWayKeyz (virtual) Keyboard` with `evtest`.
