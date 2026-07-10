#!/usr/bin/env python3
"""
ctrl-rightclick — macOS-style secondary click on Wayland.

Hold physical **Control** and *physically press* the trackpad -> right-click.

Why this exists: on Wayland you can't remap clicks in the compositor, and
Toshy/xwaykeyz only read-monitors the pointer. So we work at the evdev layer:

  * Read Toshy's virtual keyboard (the physical keyboard is grabbed by Toshy,
    so we watch its *output*) to know when Control is held. Toshy remaps
    physical Control PER-APP: it emits KEY_LEFTCTRL in terminals but
    KEY_LEFTMETA (Super) in GUI apps -- so we watch BOTH faces. Physical Cmd
    emits KEY_RIGHTCTRL, which we deliberately do NOT watch, so Cmd-click stays
    Linux multi-select / open-in-new-tab. NOTE: because the GUI face is Super,
    GNOME's Super+drag window-move must be disabled (mouse-button-modifier '')
    or GNOME eats the click.
  * Grab the Apple 'bcm5974' clickpad and re-emit it through a uinput clone,
    turning BTN_LEFT into BTN_RIGHT while Control is held.

Why we DROP INPUT_PROP_BUTTONPAD on the clone: a clickpad reports one physical
button, so libinput derives left/right/middle from finger count ("clickfinger")
and ignores any button code we inject. Without the buttonpad property libinput
treats the clone as a touchpad with real hardware buttons and honors our
BTN_RIGHT directly. Emitting from the clone itself (rather than a second virtual
mouse) also matters: Wayland-native apps like Firefox drop button events from a
pointer device that never sent motion, but they trust the touchpad clone.

Trade-offs:
  * Only *physical* presses convert; tap-to-click is synthesized by libinput
    above this layer, so Ctrl+tap stays a left-click.
  * Two-finger *physical press* -> right-click is lost (no clickfinger), but
    two-finger *tap* -> right-click still works (independent tap-button-map).

No sudo needed at runtime: reading /dev/input and writing /dev/uinput work via
the `input` group (already set up by Toshy's udev rules).
"""
import sys
import time
import selectors

import evdev
from evdev import ecodes, InputDevice, UInput

TRACKPAD_NAME = "bcm5974"
KEYBOARD_NAME = "XWayKeyz (virtual) Keyboard"   # Toshy's virtual output device
TRIGGER_KEYS  = {ecodes.KEY_LEFTCTRL,           # physical Control in terminals
                 ecodes.KEY_LEFTMETA}           # physical Control in GUI apps (Toshy -> Super)
                                                # (physical Cmd = RIGHTCTRL is intentionally excluded)


def find_device(name):
    for path in evdev.list_devices():
        try:
            dev = InputDevice(path)
        except OSError:
            continue
        if dev.name == name:
            return dev
    return None


def wait_for_device(name, timeout=90):
    """Wait for a device to appear (e.g. Toshy's virtual keyboard on login)."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        dev = find_device(name)
        if dev is not None:
            return dev
        time.sleep(1.0)
    return None


def build_clone(tp):
    """A uinput clone of the trackpad: BTN_RIGHT added, BUTTONPAD dropped.

    Keeping the ABS multitouch axes preserves tap / scroll / gestures; dropping
    INPUT_PROP_BUTTONPAD is what lets libinput honor an injected BTN_RIGHT.
    """
    caps = tp.capabilities()
    caps.pop(ecodes.EV_SYN, None)                       # UInput manages SYN itself
    keys = set(caps.get(ecodes.EV_KEY, []))
    keys.add(ecodes.BTN_RIGHT)                          # clickpad advertises only BTN_LEFT
    caps[ecodes.EV_KEY] = sorted(keys)

    kwargs = dict(
        events=caps,
        name="ctrl-rightclick trackpad (bcm5974 clone)",
        vendor=tp.info.vendor, product=tp.info.product,
        version=tp.info.version, bustype=tp.info.bustype,
    )
    # Keep input properties EXCEPT INPUT_PROP_BUTTONPAD (see docstring). Older
    # python-evdev may not expose input_props at all.
    try:
        props = [p for p in tp.input_props() if p != ecodes.INPUT_PROP_BUTTONPAD]
        if props:
            kwargs["input_props"] = props
    except (AttributeError, OSError):
        pass
    return UInput(**kwargs)


def main():
    tp = wait_for_device(TRACKPAD_NAME)
    kbd = wait_for_device(KEYBOARD_NAME)
    if tp is None or kbd is None:
        print(f"!! device not found (trackpad={tp}, keyboard={kbd}); is Toshy running?",
              file=sys.stderr)
        return 1

    ui = build_clone(tp)
    tp.grab()
    print("ctrl-rightclick active: hold Control + press the trackpad = right-click.")
    print(f"  trackpad : {tp.path} ({tp.name})")
    print(f"  keyboard : {kbd.path} ({kbd.name})")

    ctrl_held = set()
    remap_click = False     # is the in-progress physical click being sent as RIGHT?

    sel = selectors.DefaultSelector()
    sel.register(kbd.fd, selectors.EVENT_READ, "kbd")
    sel.register(tp.fd, selectors.EVENT_READ, "tp")

    try:
        while True:
            for key, _ in sel.select():
                dev = kbd if key.data == "kbd" else tp
                try:
                    events = list(dev.read())
                except BlockingIOError:
                    continue
                except OSError:
                    # A device vanished (e.g. Toshy restarted). Exit; the systemd
                    # service restarts us and we re-find the new device.
                    print("device went away; exiting to be restarted", file=sys.stderr)
                    return 1
                for e in events:
                    if key.data == "kbd":
                        if e.type == ecodes.EV_KEY and e.code in TRIGGER_KEYS:
                            if e.value == 1:
                                ctrl_held.add(e.code)
                            elif e.value == 0:
                                ctrl_held.discard(e.code)
                        # keyboard events already reach the compositor; don't forward
                        continue
                    # --- trackpad stream ---
                    if e.type == ecodes.EV_KEY and e.code == ecodes.BTN_LEFT:
                        if e.value == 1 and ctrl_held:
                            remap_click = True
                        if remap_click:
                            # Emit the right button ON THE CLONE (not the physical left)
                            ui.write(ecodes.EV_KEY, ecodes.BTN_RIGHT, e.value)
                            if e.value == 0:
                                remap_click = False
                        else:
                            ui.write(ecodes.EV_KEY, ecodes.BTN_LEFT, e.value)
                    else:
                        ui.write(e.type, e.code, e.value)
    except KeyboardInterrupt:
        pass
    finally:
        try:
            tp.ungrab()
        except OSError:
            pass
        ui.close()
        print("\nctrl-rightclick stopped; trackpad released.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
