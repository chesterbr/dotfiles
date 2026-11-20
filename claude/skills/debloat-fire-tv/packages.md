# Fire TV debloat: package and settings knowledge

Reference for the `debloat-fire-tv` skill. Update it when a run finds something new.
No device-specific data here (IPs, IDs, full package dumps): this repo is public.

Tested so far: **AFTTI43** (Fire TV 4-Series, 2021; Android 9 / Fire OS 7; 1.7 GB RAM, 11 GB `/data`),
2026-11-20. Disabled everything in the first table, rebooted and power-cycled, everything stayed
disabled and the device worked normally.

Also tested: **AFTBAMR311** (Toshiba HD Fire TV Edition, 2018 to 2020, per Amazon's device table as seen in a
search result; Fire OS 6.7.1.1 / Android 7.1.2; 964 MB RAM, 4.3 GB `/data`), 2026-11-20. The OS accepted every
package in the first table (except `com.amazon.tv.acr`, which isn't installed there) and the seven
candidates marked below as "accepted on AFTBAMR311". It rejected nothing as protected. After a full restart
(not just standby) everything checked out: Home, Settings, remote, HDMI input switching, Prime Video, Netflix
and Pluto TV (still signed in), and Wi-Fi reconnected by itself with `wifilocker` disabled.

Disable with `adb shell pm disable-user --user 0 <pkg>`, undo with `adb shell pm enable <pkg>`.

## Disable (confirmed on AFTTI43)

| Package | What it is | Outside evidence |
|---|---|---|
| `com.amazon.tv.acr` | Automatic content recognition (tracks what is on screen) | Disabled on an AFTTIFF43 (noted.lol); on every list at debloattv.com |
| `com.amazon.shoptv.client` | Shopping on TV | debloattv.com, all lists |
| `com.amazon.hybridadidservice` | Advertising ID service | Likely; sources don't name the package |
| `com.amazon.shoptv.firetv.client` | Shopping on TV (Fire TV client) | None found |
| `com.amazon.ftv.screensaver` | Screensaver (ad and promo content) | None found by name |
| `com.amazon.minitv.android.app` | Amazon miniTV | None found |
| `com.amazon.tv.democontent.provider` | Demo content | None found |
| `com.amazon.bueller.music`, `com.amazon.bueller.photos` | Amazon Music, Photos | Optional in community lists |
| `com.amazon.gamehub` | Games hub | None found |

## Candidates (installed on AFTTI43, not yet disabled; ask first)

| Package | Note |
|---|---|
| `com.amazon.wirelessmetrics.service`, `com.amazon.perfcollection`, `com.amazon.dp.logger` | Telemetry; marked safe at debloattv.com |
| `com.amazon.tv.ftvambient` | Ambient Experience (name suggests it; no source). Try if an ad shows before the screensaver |
| `com.amazon.neo.minerva` | Minerva telemetry (noted.lol). Not the same as `com.amazon.minerva.client.api`, which is protected |
| `com.amazon.wifilocker` | Disabled by noted.lol; loses Wi-Fi password sync |
| `com.amazon.recess`, `com.amazon.ceviche`, `com.amazon.sneakpeek` | Single or unclear sources |
| `com.amazon.device.software.ota`, `com.amazon.settings.systemupdates` | Sources conflict. Disabling blocks system updates: the user's call |

## Protected (the OS refuses; harmless to try)

`com.amazon.ftvads.deeplinking` (refused on AFTTI43), `com.amazon.tv.csapp`, `com.amazon.minerva.client.api`,
`com.amazon.device.logmanager`, `com.amazon.device.crashmanager`, `com.amazon.diode`,
`com.fireos.usagestats.proxy` (last five refused on a Fire TV Stick Lite, Fire OS 7.7.1.7, per eteen12).

## Do not touch

| Package | Why |
|---|---|
| `com.amazon.tv.launcher` | Home and Settings UI; also hosts the featured carousel |
| `com.amazon.firebat` | Prime Video; disabling breaks playback |
| `com.amazon.vizzini` | Alexa; disabling breaks remote detection |
| `com.amazon.imp` | Home went black on a 4K Max when disabled |
| `com.amazon.tv.oobe` | Needed for factory reset |
| `com.amazon.venezia` | Appstore |
| `com.amazon.tv.ime` | Keyboard |
| `com.amazon.tv.livetv`, `com.mediatek.tvinput`, `com.amazon.tv.inputpreference.service` | HDMI and Live TV inputs |
| `com.amazon.tv.settings.*`, `com.amazon.dcp` | Settings and device control |

## Settings (read first, write only if different)

| Namespace and key | Target | Meaning |
|---|---|---|
| `global com.amazon.tv.settings.featured_item_video_enabled` | `0` | Home featured video autoplay (this is the ad that plays when the TV turns on). `featured_item_video_volume` is left alone |
| `secure advertisingIdApp:interestBasedAds:value` | `0` | Interest-based ads |
| `secure USAGE_METRICS_UPLOAD_ENABLED` | `0` | Usage metrics upload |

Read with `adb shell settings get <ns> <key>`, write with `adb shell settings put <ns> <key> <value>`.
Not touched, but related: `secure amz_limit_ad_tracking` (0 = tracking allowed).

## Findings

- The startup ad runs inside the launcher's `HomeActivity_vNext`, not in a separate package, so disabling
  packages does not remove it. The `featured_item_video_enabled` switch does.
- Wake from sleep got much faster once the Home stopped loading video.
- `pm trim-caches` works on Fire OS 7 (freed about 1 GB on AFTTI43). It clears every app's cache and
  keeps logins.
- Updates may re-enable packages or reset settings (sources disagree), so re-run after a Fire OS update.

### Older Fire OS (6.x, Android 7.1.2)

- Accepted on AFTBAMR311: `com.amazon.wirelessmetrics.service`, `com.amazon.perfcollection`,
  `com.amazon.dp.logger`, `com.amazon.ceviche`, `com.amazon.sneakpeek` (promo autoplay on Home, per
  dumbtv.org/blocked), `com.amazon.recess`, `com.amazon.wifilocker`.
- The three settings keys above exist on Fire OS 6.7.1.1 with the same defaults (`1`).
- `pm trim-caches` exists but the shell user is refused: `SecurityException ... CLEAR_APP_CACHE`. It can't be
  worked around without root, so don't try. `pm disable-user` is allowed.
- Caches can still be sized with `dumpsys diskstats` (read-only). On AFTBAMR311 about 650 MB of cache sat in
  16 apps, and 72% of it in three: the launcher, a free streaming app and Netflix. Clearing those by hand
  (Settings > Applications > Manage Installed Applications > app > Clear cache) is the fallback.
- On 6.7.1.1 that list has a per-app shortcut: with an app highlighted, the side panel shows its cache size
  and "Press Rewind to clear cache" (also "Press Play/Pause to uninstall": avoid). Rewind opens a
  "Clear <app> cache?" dialog that states the size it will free. Clearing two apps this way freed about
  260 MB (`/data` from 79% to 73% used), with data and logins untouched. The launcher isn't listed there,
  so its cache (the largest, 210 MB on that unit) stays.
- Free space came back down by about 50 MB within half an hour of that clearing and a restart (caches
  regrowing is the likely cause). Clearing helps when storage is nearly full, not as a routine speed step.
- The settings app's package is `com.amazon.tv.settings.v2` there. The apps list opens with
  `am start -n com.amazon.tv.settings.v2/.tv.applications.ApplicationsActivity`. The component name in an
  AFTVnews article (`.tv.AllApplicationsSettingsActivity`) does not exist on that firmware.
- On some Fire OS builds the system clears caches of apps unused for 30 days when storage is low (Amazon
  help page). Not confirmed for this model.

Read the biggest caches (python3 with `-I`, run on the computer):

```
adb -s <ip>:5555 shell dumpsys diskstats | python3 -I -c '
import sys, json
t = sys.stdin.read()
def arr(label):
    for line in t.splitlines():
        if line.startswith(label + ": ["):
            return json.loads(line.split(": ", 1)[1])
names, cache = arr("Package Names"), arr("Cache Sizes")
for c, n in sorted(zip(cache, names), reverse=True)[:12]: print(f"{c/1048576:7.1f} MB  {n}")'
```

## Sources

- debloattv.com/fire-tv-debloat
- noted.lol/i-debloated-my-fire-tv
- github.com/roy9611/firetv-safe-debloat, github.com/eteen12/firetv-stick-aftss-cleanup
- velmo.one/guides/debloat-fire-tv
- androidauthority.com, "Amazon Fire TV auto-play fullscreen ads" (2023-11-24): the official autoplay switch
- aftvnews.com on custom launchers being blocked (2022-02-21) and the exploit patch in 7.7.0.6 (2025-10-06)
