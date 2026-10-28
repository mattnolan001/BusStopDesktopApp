# Bus Stop

A small macOS menu bar app that shows live departures from a Lothian Buses stop in Edinburgh.

- Click the **bus icon** in the menu bar for a drop-down list of the next departures.
- Double-click the **app** to open the same list in a window.
- Each row shows the bus number, destination and time until departure ("Due", "4 min", or a clock time for buses more than an hour away). A **green dot** means the bus is being tracked live; otherwise the time is from the timetable.
- To save battery and network, the app **sleeps** until you look at it. Opening the menu or window (or clicking Refresh) fetches the latest times and keeps updating every 30 seconds for 5 minutes, then pauses again.

The default stop is **Royal Hospital for Children & Young People (Stop IE), south-west bound**. You can switch to any Edinburgh-area stop with **Change Stop…**.

## Download

Requires macOS 13 (Ventura) or later. Runs natively on Apple Silicon and Intel Macs.

1. Download **BusStop-x.y.z.zip** from the [latest release](https://github.com/mattnolan001/BusStopDesktopApp/releases/latest) and double-click it to unzip.
2. Drag **BusStop.app** into your **Applications** folder. (Run it from Applications, not Downloads, or macOS runs it from a hidden temporary copy.)
3. Double-click **BusStop** in Applications. A window with departures opens, and a bus icon appears in the menu bar. The app has no Dock icon.

### First launch: "Apple could not verify…"

The first time you open it, macOS shows a warning and won't open the app. This is because the app isn't notarised by Apple (that needs a paid developer account). The full source code is in this repository if you'd like to check it. To allow it, once:

1. Click **Done** on the warning.
2. Open **System Settings → Privacy & Security** and scroll down to the Security section.
3. Next to *"BusStop" was blocked to protect your Mac*, click **Open Anyway**, then confirm with your password or Touch ID.

After that it opens normally. Alternatively, in Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/BusStop.app
```

### Start automatically at login (optional)

Open **System Settings → General → Login Items** and add **BusStop** under "Open at Login". When started this way it stays quietly in the menu bar without opening a window.

## Build from source

If you'd rather compile it yourself, you need Apple's command line developer tools (free; full Xcode is not needed). If you don't have them, open Terminal and run:

```sh
xcode-select --install
```

1. Download the code. In Terminal:

   ```sh
   git clone https://github.com/mattnolan001/BusStopDesktopApp.git
   cd BusStopDesktopApp
   ```

   (Or on GitHub, click **Code → Download ZIP**, unzip it, and `cd` into the folder.)

2. Build the app:

   ```sh
   ./build-app.sh
   ```

   This creates `BusStop.app` in the same folder. It takes under a minute.

3. Drag `BusStop.app` into your **Applications** folder (or run `mv BusStop.app /Applications/`).

4. Double-click **BusStop** in Applications. A self-built app opens without the first-launch warning.

## Using the app

| To… | Do this |
| --- | --- |
| See departures quickly | Click the bus icon in the menu bar |
| Open the window | Double-click the app, or choose **Open Window** from the menu |
| Get fresh times | Open the menu or window, or click the ↻ button |
| Change stop | Choose **Change Stop…** and search by stop name, bus number or stop code |
| Quit | Choose **Quit** from the menu bar drop-down |

The footer shows **Last updated** with the time of the most recent successful check, and **Paused** when the app is asleep.

### Finding a stop

In **Change Stop…** you can type part of the stop name (e.g. `Princes Street`), a bus number (e.g. `24`), or a stop code. Results show which buses serve each stop, and the direction buses travel from it (e.g. `SW`). Many stops have a twin on the other side of the road heading the opposite way, so check the direction.

You can also find a stop on [bustimes.org](https://bustimes.org): the number at the end of the stop's page address (e.g. `bustimes.org/stops/6200251020`) is its stop code.

## Troubleshooting

**I can't see the bus icon in the menu bar.**
On MacBooks with a camera notch, macOS hides menu bar icons that don't fit. Quit a few other menu bar apps, or hold **⌘** and drag icons off the menu bar to make room. On macOS 26, also check **System Settings → Menu Bar** that BusStop is allowed. You can always use the app by double-clicking it to open the window.

**`./build-app.sh: Permission denied`**
Run `chmod +x build-app.sh` and try again.

**`xcrun: error: invalid active developer path` or `swiftc: command not found`**
The developer tools aren't installed. Run `xcode-select --install`.

**It says "Bus data server returned HTTP …" or "The request timed out."**
The live data service may be briefly unavailable. Click **Retry** or try again in a minute.

## Uninstall

Quit the app from its menu, delete **BusStop** from Applications, and optionally remove its saved stop choice:

```sh
defaults delete com.mattnolan001.BusStop
```

## Data source

Departure times come from [bustimes.org](https://bustimes.org), a volunteer-run site that combines bus timetables with live vehicle tracking. This app isn't affiliated with bustimes.org or Lothian Buses. Times may occasionally be missing or inaccurate, so allow a little slack when catching a bus.

## For developers

The app is plain SwiftUI/AppKit with no dependencies. `build-app.sh` compiles `Sources/BusStop/*.swift` with `swiftc` and assembles an ad-hoc signed universal (Apple Silicon + Intel) `.app` bundle using `Resources/Info.plist`.

To publish a new version, commit your changes and run `./release.sh 1.1.0` (with the new version number). It sets the version in `Info.plist`, builds and checks the app, zips it to `dist/`, commits and tags `v1.1.0`, pushes, and creates a GitHub Release with the zip attached. It needs the [GitHub CLI](https://cli.github.com) (`gh`) logged in.

| File | Purpose |
| --- | --- |
| `BusStopApp.swift` | App entry point and menu bar drop-down |
| `AppDelegate.swift` | Opens the window on launch / double-click |
| `DeparturesStore.swift` | Fetching, sleep/wake and 30 s auto-refresh, saved stop |
| `BusService.swift` | bustimes.org API calls |
| `Models.swift` | JSON decoding for departures and stops |
| `DeparturesView.swift` | The departures list (shared by menu and window) |
| `StopPickerView.swift` | Change Stop search |
| `build-app.sh` | Builds `BusStop.app` |
| `release.sh` | Builds and publishes a GitHub Release |

## License

Copyright © 2026 Matt Nolan <mattnolan001@gmail.com>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See [LICENSE](LICENSE) for the full text.
