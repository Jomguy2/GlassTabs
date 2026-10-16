# GlassTabs

Native iOS app: Timer, Stopwatch, and on-device Notes under one Liquid Glass roof. Built on Windows with [xtool](https://github.com/xtool-org/xtool), installed via SideStore with a free Apple account.

## Install (iPhone)

Add this source in SideStore (Sources → Add Source, paste URL):

```
https://raw.githubusercontent.com/<user>/GlassTabs/main/Glasstabs.json
```

Then install GlassTabs from the source. Updates appear in SideStore automatically.

## Versioning

- `0.x` — beta builds (currently `0.9.0`)
- `1.0.0` — first final
- `1.0.x` — small fixes
- `1.x.0` — bigger features

## Tabs

1. **Timer** — preset chips (1/5/10/15/25 min) + custom length, 5 built-in sounds + vibration, finishes in the background via local notification.
2. **Stopwatch** — start/stop/reset, lap list with splits, keeps true time in the background.
3. **Notes** — title + description, add/edit/delete, newest first, stored as local JSON in the app sandbox. No iCloud, works fully offline.

## Build (Windows + WSL2)

Requires the `glasstabs` WSL2 distro with Swift ≥ the Apple Swift that built the Darwin SDK, plus `xtool sdk install`:

```sh
cp -r /mnt/c/Users/Jom_g/projects/glasstabs-app /root/gt-build
cd /root/gt-build
xtool dev build --configuration release --ipa
```

Unsigned IPA lands in `xtool/GlassTabs.ipa`; SideStore signs it on install with the free 7-day cert.

## Layout

- `Package.swift` — SwiftPM, single `GlassTabs` library, iOS 17+
- `xtool.yml` — bundle `com.jomg.glasstabs`
- `App-Info.plist` — marketing/build version overlay (merged over xtool defaults)
- `Sources/GlassTabs/` — `GlassTabsApp`, `ContentView`, `GlassStyle`, `TimerView`, `StopwatchView`, `NotesView`
- `Glasstabs.json` — SideStore source (points at release IPA assets)
