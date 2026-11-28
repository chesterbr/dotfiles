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

```bash
sudo systemctl disable t2-cpu-sleep.service
sudo rm /etc/systemd/system/t2-cpu-sleep.service /etc/udev/rules.d/90-bt-wake.rules
sudo systemctl daemon-reload
```

Reboot afterwards.
