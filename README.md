# MacBook Notch App

A free, original Dynamic Island-style notch overlay for MacBook with a notch.
Hover over the notch to expand it into a media panel, or leave it collapsed and
it shows the clock and battery. No license, no account, no network calls, and
nothing to ever update.

This is an independent project written from scratch. It is not a copy of, and
is not affiliated with, any commercial notch app.

## Features

- Fills the MacBook notch with a black capsule that blends into the notch
- Hover (or click) the notch to expand it with a spring animation
- Now Playing panel: album art, title, artist, progress bar, elapsed time
- Playback controls: previous, play/pause, next — works with Apple Music,
  Spotify, browsers, podcasts, and any app that reports Now Playing info
- Collapsed state shows the song title with animated equalizer bars while
  music plays, or the clock and battery percentage when idle
- Menu bar item to quit; no Dock icon
- Works on Macs without a notch too (shows a floating pill instead)
- 100% offline, no telemetry, no licensing, nothing to update

## Requirements

- A Mac running macOS 13 Ventura or later
- Xcode (free from the Mac App Store) — needed once, to build the app

## Build it (2 minutes)

### Option A — Xcode (easiest)

1. Copy the whole `MacBookNotchApp` folder to your Mac (e.g. Downloads).
2. Double-click `MacBookNotchApp.xcodeproj` to open it in Xcode.
3. Press Cmd+R (Run). The app builds and the notch overlay appears.

### Option B — Terminal (also builds the .dmg)

Open Terminal, cd into the folder, and run:

```bash
bash build-and-make-dmg.sh
```

This compiles the app and produces **MacBook Notch App.dmg**. To install,
open the .dmg and drag the app into Applications, then launch it. The very
first launch, macOS may ask you to confirm opening it — right-click the app
and choose Open if Gatekeeper is cautious.

## How it works

- The overlay is a borderless, always-on-top panel positioned exactly over
  the notch (it reads the screen's safe-area insets, so it fits any notched
  MacBook automatically).
- Media info comes from the system MediaRemote framework — the same
  mechanism macOS itself uses for media keys and Now Playing. It's loaded at
  runtime and needs no permissions or entitlements.
- Battery percentage comes from IOKit power sources.

## Customizing

Everything is in a handful of small, commented Swift files:

- `NotchView.swift` — sizes, colors, layout, animation speed, what shows when
- `NotchController.swift` — window placement and the menu bar item
- `NowPlaying.swift` — media info and playback commands
- `Battery.swift` — battery reading

For example, to change the expanded width, edit `expandedWidth` in
`NotchView.swift` and build again.

## Notes

- If macOS ever changes how the private MediaRemote framework works in a
  future release, music info may stop updating — the notch, clock, and
  battery would keep working. Since the app is self-contained with no update
  mechanism, that's the one thing outside its control; a rebuild with a
  small fix is all it would take.
- On external displays without a notch the app shows the floating pill
  version, anchored below the menu bar.

## License

Do whatever you want with this code — it's yours. Built as an original
work for personal use.
