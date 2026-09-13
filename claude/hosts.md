# Hosts

Machines I run and how to reach them. General/personal, so it lives here and imports into every
project via `CLAUDE.md`. This repo is **public**: no IPs, MACs, keys, or anything secret here.

## Two different "Bazzite" boxes

I have two separate machines running Bazzite (the Fedora-based gaming distro). They are NOT the
same host. Both may advertise themselves as `bazzite.local` on their own LAN, so never assume which
one is meant: identify by location/hardware, and ask if it's ambiguous.

- **Canada** = a Windows laptop I partitioned.
- **Brazil** = a 16-inch MacBook.

### Bazzite (Canada) — partitioned Windows laptop

- **Reach:** mDNS `bazzite.local` on its LAN (dynamic IP). Chassis reports as a laptop.
- **SSH:** user `ksa`, key auth via the 1Password SSH agent (first connect may need a desktop
  approval; if signing fails, retry without `BatchMode`). `ksa` is in `wheel` but sudo requires a
  password, so there's no non-interactive root: for root changes, hand me the commands to run in a
  root shell (or paste them there) rather than expecting passwordless sudo.
- **Wake-on-controller** (custom setup so a Bluetooth controller wakes it from suspend; all files
  live on the box, not in this repo):
  - `/etc/udev/rules.d/90-ax201-bt-wake.rules` — USB remote-wakeup on the Intel AX201 BT radio.
    This is the actual wake source and fires on *any* BT reconnect.
  - `bt-wake-allowed.service` + `systemd-suspend.service.d/bt-wake-allowed-hook.conf`
    (`ExecStartPost`) + `/usr/local/bin/bt-wake-allowed-restore.sh` — re-apply BlueZ
    `WakeAllowed=true` on known controllers at boot and after each resume (BlueZ keeps resetting it).
  - `systemd-suspend.service.d/bt-disconnect-hook.conf` (`ExecStartPre`) +
    `/usr/local/bin/bt-disconnect-controllers.sh` (added 2026-09-12) — cleanly disconnect connected
    `Icon: input-gaming` controllers before suspend, so a still-powered pad doesn't immediately
    auto-reconnect and wake the box back up. Wake stays armed, so a deliberate button press still
    wakes it. Confirmed working.

### Bazzite (Brazil) — MacBook 16"

- A separate Bazzite install on a 16-inch MacBook, kept in Brazil. Set up locally from the machine
  itself and not yet synced into these dotfiles, so its specifics (login, tweaks) aren't captured
  here yet.
