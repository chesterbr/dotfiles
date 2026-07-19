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

- **External Ergodox EZ:** Toshy types keyboards per-device and adapts its
  modifier remapping to each. The MacBook's built-in keyboard matches its
  `Apple` list, but the Ergodox matches nothing and falls through to the
  `Windows` default — which swaps Alt↔Super so the key *innermost* to the
  spacebar acts as Cmd. My [Oryx layout](../keyboards/README.md) already puts
  Cmd/Super in the Mac position, so that swap flips Cmd and Option. Fix is to
  declare it an Apple keyboard in `~/.config/toshy/toshy_config.py`, inside the
  `SLICE_MARK_START: kbtype_override` marks so it survives Toshy upgrades:

  ```python
  keyboards_UserCustom_dct = {
      # Exact match (casefolded), not regex — hence both names it exposes
      'ZSA Technology Labs Ergodox EZ': 'Apple',
      'ZSA Technology Labs Ergodox EZ Keyboard': 'Apple',
  }
  ```

  Then `systemctl --user restart toshy-config.service`. Device names come from
  `toshy-devices` (or `grep Name /proc/bus/input/devices`) — check them if a
  firmware flash renames the board.

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

## 8. Window tiling: Magnet-style shortcuts

Reproduces the [Magnet](https://magnet.crowdcafe.com/) shortcuts I use on macOS,
on the same physical keys. All of it runs on **Tiling Assistant**
(`tiling-assistant@ubuntu.com`), which Ubuntu preinstalls and enables — no extra
extension to add.

| Magnet | Physical keys | What GNOME binds |
| --- | --- | --- |
| Left / right half | `Ctrl`+`Option`+`←`/`→` | `<Super><Alt>Left` / `Right` |
| Top / bottom half | `Ctrl`+`Option`+`↑`/`↓` | `<Super><Alt>Up` / `Down` |
| Quarters (TL/TR/BL/BR) | `Ctrl`+`Option`+`U`/`I`/`J`/`K` | `<Super><Alt>u`/`i`/`j`/`k` |
| Maximize | `Ctrl`+`Option`+`Return` | `<Super><Alt>Return` |
| Center | `Ctrl`+`Option`+`C` | `<Super><Alt>c` |
| Move to other display | `Ctrl`+`Option`+`Cmd`+`←`/`→` | `<Super><Alt><Control>Left` / `Right` |

The binding strings look unrelated to the keys pressed because Toshy remaps
modifiers first — **in GUI apps only** (in `toshy_config.py` the `GUI - Mac kbd`
modmap is gated `not ctx_app_is_terminal`):

| Physical | GNOME sees (GUI apps) | GNOME sees (terminals) |
| --- | --- | --- |
| `Ctrl` | `Super` | `Ctrl` (unchanged) |
| `Option` | `Alt` | `Alt` |
| `Cmd` | `Ctrl` | `Ctrl` |

> **Don't use mutter's native tiling for this.** `org.gnome.mutter.keybindings
> toggle-tiled-left`/`-right` look like the obvious choice, but Tiling Assistant
> deliberately takes those over: it sets `org.gnome.mutter edge-tiling false` and
> clears `toggle-tiled-*` back to `@as []`. Setting them appears to work, then
> silently reverts (on shell reload / next login). An earlier version of this
> section documented that dead end. Everything below goes through Tiling
> Assistant's own schema instead.

### 8a. Shortcuts

```bash
TA=org.gnome.shell.extensions.tiling-assistant
gsettings set $TA tile-left-half           "['<Super>Left', '<Super>KP_4', '<Super><Alt>Left']"
gsettings set $TA tile-right-half          "['<Super>Right', '<Super>KP_6', '<Super><Alt>Right']"
gsettings set $TA tile-top-half            "['<Super>KP_8', '<Super><Alt>Up']"
gsettings set $TA tile-bottom-half         "['<Super>KP_2', '<Super><Alt>Down']"
gsettings set $TA tile-maximize            "['<Super>Up', '<Super>KP_5', '<Super><Alt>Return']"
gsettings set $TA tile-topleft-quarter     "['<Super>KP_7', '<Super><Alt>u']"
gsettings set $TA tile-topright-quarter    "['<Super>KP_9', '<Super><Alt>i']"
gsettings set $TA tile-bottomleft-quarter  "['<Super>KP_1', '<Super><Alt>j']"
gsettings set $TA tile-bottomright-quarter "['<Super>KP_3', '<Super><Alt>k']"
gsettings set $TA center-window            "['<Super><Alt>c']"

# Move to other display is plain GNOME, not the extension. <Super><Shift> arrows
# are the stock binding, kept; the <Super><Alt><Control> one is the Magnet parity.
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left  "['<Super><Shift>Left', '<Super><Alt><Control>Left']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right "['<Super><Shift>Right', '<Super><Alt><Control>Right']"
```

### 8b. Conflicts that must be cleared

`shift-overview-up`/`-down` ship on `<Super><Alt>Up`/`Down` and win over the
tiling shortcuts — the symptom is top half working while **bottom half silently
does nothing**. (It's the app-grid zoom; unused here.)

```bash
gsettings set org.gnome.shell.keybindings shift-overview-up   "@as []"
gsettings set org.gnome.shell.keybindings shift-overview-down "@as []"
```

`switch-to-workspace-left`/`right` also have to give up their `<Super><Alt>`
arrows — the exact combo Magnet wants. They keep `<Super>Page_Up`/`Down` and
`<Control><Alt>` arrows, the latter being physical `Cmd`+`Option`+arrow.

```bash
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left  "['<Super>Page_Up', '<Super>KP_Prior', '<Control><Alt>Left']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>Page_Down', '<Super>KP_Next', '<Control><Alt>Right']"
```

### 8c. Behavior: make it act like Magnet

Out of the box Tiling Assistant is more opinionated than Magnet. Magnet moves
exactly the window you asked for and ignores everything else:

```bash
TA=org.gnome.shell.extensions.tiling-assistant
# Tiling popup: after tiling, offers other windows to fill the free space, and
# swallows the next keypress. Very confusing when driving purely by keyboard.
gsettings set $TA enable-tiling-popup false
# Tile groups: makes tiling adapt to already-tiled neighbours instead of just
# taking the half/quarter asked for, and raises tiled windows together.
gsettings set $TA disable-tile-groups true
gsettings set $TA enable-raise-tile-group false
```

### 8d. Toshy keymap (required — the bindings alone don't work)

Two problems gsettings cannot solve:

1. Toshy's own `GenGUI overrides: Ubuntu` keymap matches `Super-Left`/`Right` and
   rewrites them to a workspace switch. It fires even with `Alt` also held, and
   `[bind,...]` keeps `Alt` down, so GNOME receives `Super+Alt+Page_Down` — bound
   to nothing. The arrows just die.
2. In terminals the modmap is disabled, so `Ctrl` never becomes `Super` and GNOME
   never sees the combos at all.

Both are fixed by claiming the combos earlier in the chain. Add this inside the
`SLICE_MARK_START: user_apps` marks in `~/.config/toshy/toshy_config.py`, in the
`User hardware keys` keymap — that slice is evaluated before the overrides,
xwaykeyz is first-match-wins, and the marks survive Toshy upgrades:

```python
    # GUI apps  - Ctrl is modmapped to Super, so pass the combo through intact.
    C("Super-Alt-Left"):        C("Super-Alt-Left"),        # Tile left half
    C("Super-Alt-Right"):       C("Super-Alt-Right"),       # Tile right half
    C("Super-Alt-Up"):          C("Super-Alt-Up"),          # Tile top half
    C("Super-Alt-Down"):        C("Super-Alt-Down"),        # Tile bottom half
    # Terminals - GUI modmap is disabled there, so Ctrl arrives as Ctrl.
    C("LC-Alt-Left"):           C("Super-Alt-Left"),        # Tile left half
    C("LC-Alt-Right"):          C("Super-Alt-Right"),       # Tile right half
    C("LC-Alt-Up"):             C("Super-Alt-Up"),          # Tile top half
    C("LC-Alt-Down"):           C("Super-Alt-Down"),        # Tile bottom half
    C("LC-Alt-U"):              C("Super-Alt-U"),           # Tile top-left quarter
    C("LC-Alt-I"):              C("Super-Alt-I"),           # Tile top-right quarter
    C("LC-Alt-J"):              C("Super-Alt-J"),           # Tile bottom-left quarter
    C("LC-Alt-K"):              C("Super-Alt-K"),           # Tile bottom-right quarter
    C("LC-Alt-C"):              C("Super-Alt-C"),           # Center window
    C("LC-Alt-Enter"):          C("Super-Alt-Enter"),       # Maximize
    C("LC-Alt-RC-Left"):        C("Super-Alt-C-Left"),      # Move to left display
    C("LC-Alt-RC-Right"):       C("Super-Alt-C-Right"),     # Move to right display
```

Then `systemctl --user restart toshy-config.service`.

**Always test in both a GUI app and a terminal.** They take different code paths,
and a change can work in one while doing nothing in the other — that asymmetry is
the single biggest time sink in this section.

### 8e. Known issue

On the external monitor (HDMI-2, fractional scale 1.25) the half/quarter
shortcuts sometimes leave the window centered and unmoved, while the built-in
display works correctly. Unresolved — fractional scaling is the suspect but has
not been confirmed.

---

### Re-capturing after future changes

If you tweak more of these later, refresh the values here from the live system:

```bash
gsettings get org.gnome.desktop.input-sources sources
gsettings get org.gnome.desktop.wm.preferences button-layout
gsettings list-recursively org.gnome.shell.extensions.dash-to-dock
gnome-extensions list --enabled
```
