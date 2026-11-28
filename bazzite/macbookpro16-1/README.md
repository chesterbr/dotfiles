# Bazzite on a MacBookPro16,1 (T2): sleep and wake

For this model only. These are system files, so `./install` does not link them.

| File | Goes in | What it does |
|---|---|---|
| `90-bt-wake.rules` | `/etc/udev/rules.d/` | Lets a paired Bluetooth controller wake the machine. The internal adapter is on a serial port, so USB wake rules don't apply. |
| `t2-cpu-sleep.service` | `/etc/systemd/system/` | Takes secondary CPUs offline before sleep and brings them back after. |

Without the service, bringing the CPUs back during resume took about 48 s. In one test, the time
from a controller button press to a picture went from about 73 s to 23 s. See
[The resume that took a minute](https://kait2en.org/blog/the-resume-that-took-a-minute.html).
A kernel fix may make the service unnecessary.

## Thunderbolt driver (optional)

With the CPU fix in place, the two Thunderbolt controllers were the largest remaining delay. The
kernel argument `modprobe.blacklist=thunderbolt` removed a wait of about 5 s for their host
interfaces (NHI). Their PCIe bridges still take about 11 s. Total times vary: two tests without
the driver took 19 s and 24 s from button press to picture (the second had an unexplained delay
in a later stage).

Trade-off: devices that need Thunderbolt may stop working. Ethernet through the USB-C dock and
video output kept working here.

A `blacklist thunderbolt` file in `/etc/modprobe.d/` was not enough: the driver still loaded
early in boot.

Changing kernel arguments creates a new deployment, which can drop the older one from the list.
To keep it, pin it first: find its index in `rpm-ostree status` (the first entry is 0), then run
`sudo ostree admin pin <index>`. On this machine, version 43.20260420 is pinned.

```bash
sudo rpm-ostree kargs --append-if-missing=modprobe.blacklist=thunderbolt
```

Reboot to apply. To check: `lsmod | grep '^thunderbolt '` should print nothing.

To undo, run this and reboot:

```bash
sudo rpm-ostree kargs --delete-if-present=modprobe.blacklist=thunderbolt
```

## Install

From this directory, on the MacBook:

```bash
sudo cp 90-bt-wake.rules /etc/udev/rules.d/
sudo cp t2-cpu-sleep.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable t2-cpu-sleep.service
```

Reboot to apply the udev rule. The controller must be paired and allowed to wake the system
(`bluetoothctl info <address>` shows `WakeAllowed: yes`). After waking, press the button again
to connect it.

To check: `cat /sys/bus/serial/devices/serial0-0/power/wakeup` should print `enabled`, and after
a resume `cat /sys/devices/system/cpu/online` should list all CPUs.

## Uninstall

For the wake rule and the CPU service (the kernel argument is undone as shown above):

```bash
sudo systemctl disable t2-cpu-sleep.service
sudo rm /etc/systemd/system/t2-cpu-sleep.service /etc/udev/rules.d/90-bt-wake.rules
sudo systemctl daemon-reload
```

Reboot afterwards.
