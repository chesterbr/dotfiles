---
name: debloat-fire-tv
description: Debloat an Amazon Fire TV or Fire TV Stick over ADB - disable ad, telemetry and unused Amazon packages, turn off home screen video autoplay and ad personalization, optionally trim caches. Idempotent, so it also re-applies the changes after a Fire OS update undoes them. Use when asked to debloat, clean up, speed up, or remove ads from a Fire TV or stick, or to re-check one already debloated.
license: MIT
---

# Debloat Fire TV

Works on any Fire TV or stick reachable over the network. Everything is reversible (`pm disable-user`,
`settings put`, cache trim). The package knowledge lives in `packages.md` next to this file; read it first.

Read the [Notice and disclaimer](#notice-and-disclaimer) and [Licence](#licence) at the end. Before the
first change on a device, tell the user in two or three lines what the notice says (official ADB only,
no root or exploits, reversible, updates can undo it, their device and their responsibility).

## Hard rules

- Only on a device the user owns or is authorized to manage.
- Use only what Amazon documents or ships: ADB debugging switched on by the owner in Developer options,
  `pm disable-user`, `settings put` and `pm trim-caches`. Never root, never an exploit or vulnerability,
  never a way around a protection. If the OS refuses a change (a protected package), stop there and
  record it; do not look for another way in.
- Never sideload or install apps, and never touch DRM or content protection. This skill removes and
  quiets Amazon's own packages; it does not add anything to the device.
- Never `pm uninstall` and never `pm clear`. Uninstall can break the Home button and HDMI switching;
  `pm clear` wipes app data and signs the user out.
- Never disable anything in the "Do not touch" list of `packages.md`.
- Never disable a package the list doesn't classify without asking, even if its name looks like ads or telemetry.
- This repo is public: never write an IP, advertising ID, account name or full package dump into it.
  Device snapshots go in `~/firetv-debloat/<model>-<date>/`, outside the repo.
- Writing a setting or disabling a package is a change to the user's device. Show the plan and get a yes
  before applying it, unless they already asked for exactly that run.
- The retrospective (step 10) never proposes edits to "Hard rules", "Notice and disclaimer" or "Licence".
  Only the owner edits those.

## Procedure

1. **Connect.** If the user passed an address as an argument, use it (add `:5555` if no port is given).
   Otherwise run `adb devices`: if a Fire TV is already connected, confirm it with the user; if not, ask
   for the IP. Needs `adb` (`brew install android-platform-tools`; if missing, say so and offer, don't
   auto-install). On the TV: Settings > My Fire TV > About, click the device name 7 times, then
   Developer options > ADB debugging on. Get the IP from About > Network, then
   `adb connect <ip>:5555` and have the user accept the prompt on the TV. Use `adb -s <ip>:5555`
   on every call, since other devices may be attached.
2. **Identify.** `getprop ro.product.model`, `ro.build.version.release`, `df /data`, and
   `MemTotal`/`MemAvailable` from `/proc/meminfo`. Search the web for the model code (what product it
   is, Fire OS version, RAM/storage) and for recent debloat reports for it or its closest sibling. A
   cheaper subagent can do the reading. Cite sources, and say so when nothing covers the exact model.
3. **Snapshot.** Save `pm list packages`, `pm list packages -d` and the values of the settings below to
   `~/firetv-debloat/<model>-<date>/`, plus a `restore.sh` that runs `pm enable` for whatever this run
   disables and puts the settings back.
4. **Plan.** Diff `packages.md` against the installed packages. Propose only packages that are installed
   and not already disabled, in tiers: confirmed-on-device first, then candidates, with the reason for
   each. Also list settings whose current value differs from the target. Nothing to do is a valid result.
5. **Apply.** Disable in small batches. A `Cannot disable a protected package` error is expected for some
   packages: record it, move on, and note it in `packages.md` if it is new.
6. **Settings.** Read each key first and write only if it differs (see `packages.md`). Mention that the
   Settings app may keep its own copy, so the user should glance at Preferences > Privacy Settings.
7. **Caches (optional).** Show `df /data`, then `pm trim-caches <bytes>` with a value larger than the free
   space (it frees every app's cache, keeps logins, and can't be limited to one app over ADB), then
   `df /data` again and report the difference. Run it by default when free space is under about 20% or 2 GB
   (old sticks with 8 GB storage slow down badly when full); otherwise offer it. It does not fix a RAM
   shortage, which is what the disabling is for. Cache size alone has little effect on speed (sources
   disagree); a nearly full `/data` and low RAM matter more.
   **If `pm trim-caches` is refused** (`SecurityException ... CLEAR_APP_CACHE`, seen on Fire OS 6.7.1.1),
   that is the OS's rule: stop, don't look for a way around it. Fall back to the menus. Read the biggest
   caches with `dumpsys diskstats` (read-only; snippet in `packages.md`), tell the user which apps hold
   most of it, and have them clear those by hand: Settings > Applications > Manage Installed Applications >
   app > Clear cache (never Clear data, which signs the app out). `am start -n <settings package>/<activity>`
   can open that list for them; find the activity with `dumpsys package <settings package>` (names vary by
   firmware, and a name copied from an article may not exist). Leave the clicking to the user by default. If
   the user asks you to do it, drive the menus with `input keyevent`, but take a screenshot
   (`adb exec-out screencap -p`) before every key press and press Enter or Rewind only when the screen
   names the right app. On 6.7.1.1 the list shows "Press Rewind to clear cache" (keycode 89) with the app's
   cache size, then a dialog "Clear <app> cache?" to confirm with Enter (66). Never press Play/Pause
   (it uninstalls) and never open Clear data. The launcher (`com.amazon.tv.launcher`) isn't in that
   list, so its cache can't be cleared this way. `dumpsys diskstats` is a cached snapshot that stays stale
   after clearing, so measure with `df /data`.
8. **Verify.** Re-list disabled packages and settings. Check that the launcher process is alive
   (`ps | grep com.amazon.tv.launcher`) and `sys.boot_completed` is 1; don't test for "Home in the
   foreground", because the user may be in Settings or an app. Ask the user to restart the TV for real
   (Settings > My Fire TV > Restart, or unplug it for about 10 seconds): standby from the remote is not a
   restart (check `uptime`), and a reboot over ADB skips the real wake path. Then have them check Home,
   Settings, HDMI inputs, Prime Video, Wi-Fi reconnecting and the remote. If something broke, `pm enable`
   the last batch.
9. **Report** what changed, what was refused, and the space and RAM before and after. Offer to add new
   findings (a package confirmed safe, a protected one, a model-specific quirk) to `packages.md`, with
   no device-specific data. Suggest switching ADB debugging off again in Developer options when done,
   and never leaving it on outside a trusted home network.
10. **Retrospective.** This step may never propose edits to the "Hard rules", the "Notice and disclaimer" or
    the "Licence" sections; only the owner edits those. If the run suggests one of them is wrong, say so in
    chat as a note for the owner instead of drafting an edit. After the report, compare what happened in
    this run with what `SKILL.md` and `packages.md` say. List only what was observed in this run (newly
    classified packages, refusals, commands or components that failed or differed, assumptions that proved
    wrong), each with its evidence; if nothing is new, say so in one line. Propose the changes as the exact
    text to add or change, show them, and write them only after the user says yes. Update an existing entry
    instead of adding a near-duplicate. Keep IPs, serials, advertising IDs, account names and full package
    dumps out, since the repo is public. Never commit or push.

## Re-running after an update

Same procedure. Steps 3 and 4 do the work: compare the live disabled list and settings against the last
snapshot and the target values, and re-apply only the drift. Updates can also add new Amazon packages, so
check the plan for ones not yet classified. A re-run also ends with the retrospective (step 10).

## Limits worth stating to the user

- The home screen "featured content" carousel belongs to the launcher (`com.amazon.tv.launcher`), which is
  protected. Autoplay video and sound can be turned off, but the carousel itself can't be removed over ADB.
  Only a custom launcher or DNS blocking could, and neither is confirmed to work on every model.
- There is no model-independent proof that a package is safe: confirmed-on-device means tested on the
  models noted in `packages.md`.

## Notice and disclaimer

This is a personal tool shared as a convenience. Neither its author nor the AI assistant that helped write
it is a lawyer, and nothing here is legal advice.

- **Not affiliated.** Not made, endorsed or supported by Amazon.com, Inc. or Anthropic. Amazon, Fire,
  Fire TV, Alexa and other names are trademarks of their owners and are used only to identify the devices.
- **What it does.** It uses only the ADB debugging that Amazon documents for developers, and turns off
  packages and settings that already exist on the device. It does not use root, exploits or vulnerabilities,
  does not sideload or install anything, and does not touch DRM or content protection. The system itself
  refuses to disable protected packages, and the skill stops there.
- **Reversible, not risk-free.** Disabled packages come back with `pm enable <package>` (the skill saves a
  restore script) and a factory reset restores everything, but a wrong choice can still break a feature
  (the Home screen, HDMI inputs, remote detection, Prime Video). Fire OS updates may re-enable packages or
  reset settings, and may change what is protected. It has been tested only on the models named in
  `packages.md`.
- **Terms and warranty.** At the time of writing, the author found no term that prohibits this use and no
  verifiable report of an account, device or warranty penalty for it. That is not a guarantee: the author
  has not reviewed every Amazon term, terms change, and Amazon may treat modified devices differently.
  Read your own device and service terms and decide for yourself.
- **Good faith.** This is shared in good faith by a device owner, not to harm anyone's business or to get
  around anything. If Amazon, Anthropic or another rights holder believes it breaches their terms or
  rights, please contact me first at <cd@pobox.com> (or through <https://github.com/chesterbr>). I will
  promptly review the request and remove or change the relevant part.
- **Your device, your responsibility.** Run it only on devices you own or are authorized to manage. You
  accept all the risk of using it. Don't leave ADB debugging enabled on untrusted networks.
- **No warranty.** Provided "as is", as set out in the licence below.

## Licence

MIT, see <https://opensource.org/license/mit>. Copyright (c) 2026
[Carlos Duarte Do Nascimento (@chesterbr)](https://github.com/chesterbr/dotfiles/blob/main/claude/skills/debloat-fire-tv/SKILL.md).
This covers the files in this skill's directory (`SKILL.md` and `packages.md`) and nothing else in the
repository.
