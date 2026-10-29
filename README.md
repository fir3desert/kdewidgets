# kdewidgets

Custom KDE Plasma 6 widgets.

Each applet can be installed and removed independently. The Battery packages
are grouped under `org.kde.fir3.batterydisplay/`.

## Widgets

| Widget | Id | Description |
|---|---|---|
| **Battery** | `org.kde.fir3.batterydisplay` | Battery status applet with 25 charging animation styles, color thresholds and a detailed popup. |
| **IP Display** | `org.kde.fir3.ipdisplay` | Shows your LAN and public IP addresses in the panel, with a status dot, VPN detection and a popup with detailed network info (interface, gateway, DNS, traffic counters). |

Battery has a main edition, a testing edition, and an archived earlier version:

- **Main:** [Battery](./org.kde.fir3.batterydisplay/org.kde.fir3.batterydisplay-firstversion/README.md) — the full animation catalog and live battery data. Its Plasma ID is `org.kde.fir3.batterydisplay`.
- **Testing:** [Battery (testing)](./org.kde.fir3.batterydisplay/org.kde.fir3.batterydisplay-testing/README.md) — the same animation catalog plus simulated battery data and preview controls.
- **Archived:** [Original battery applet](./org.kde.fir3.batterydisplay/org.kde.fir3.batterydisplay/README.md) — the earlier, simpler version; use the main or testing edition for new installations.

→ **[Full documentation for IP Display](./org.kde.fir3.ipdisplay/README.md)**

## Requirements

- KDE Plasma 6 (Qt 6). The applet declares `X-Plasma-API-Minimum-Version: 6.0`.
- No `sudo` or system-wide installation is required; widgets install per-user.

## Install Battery

```bash
git clone https://github.com/fir3desert/kdewidgets.git
cd kdewidgets/org.kde.fir3.batterydisplay/org.kde.fir3.batterydisplay-firstversion
./install.sh
```

Then add the applet to a panel: right-click the panel → *Add Widgets…* →
**Battery**.

For simulated battery data and preview controls, install the testing edition by
running `install.sh` from
`kdewidgets/org.kde.fir3.batterydisplay/org.kde.fir3.batterydisplay-testing`.

## Install IP Display

Run this from the repository root:

```bash
cd kdewidgets/org.kde.fir3.ipdisplay
./install.sh
```

Then add it to a panel: right-click the panel → *Add Widgets…* → **IP Display**
(under the *System Information* category).

To remove IP Display:

```bash
./uninstall.sh
```

Installer options for IP Display: `--no-restart` (skip restarting
plasmashell), `--allow-root` (testing only), `-h` for help. See each widget's
README for its uninstall instructions and other options.

## A note on the bundled plugin

The applet reads network state through a native QML plugin
(`plugin/libipdisplayplugin.so`) that queries NetworkManager over D-Bus and
uses configurable public-IP endpoints (by default, `api.ipify.org` and
`ifconfig.me`).

**This repository ships that plugin prebuilt, and does not include its source
code or a build system**, so it cannot be rebuilt or reproduced from here. The
bundled binary targets a specific architecture and Qt minor version; if it does
not match your machine, the installer reports the mismatch; network
functionality may not load until a compatible build is available.

The applet folder carries its own `plugin/` directory, which is the path Plasma
uses by default. The installer additionally copies the plugin into
`~/.local/lib/qml/` and sets up the QML import path — belt and braces, so the
widget also works without relying on environment variables.

## Repository layout

```
kdewidgets/
├── README.md                            # repository overview
├── LICENSE                              # GPL-3.0
├── org.kde.fir3.batterydisplay/
│   ├── org.kde.fir3.batterydisplay-firstversion/ # main edition (canonical applet ID)
│   ├── org.kde.fir3.batterydisplay-testing/      # testing edition with simulation
│   └── org.kde.fir3.batterydisplay/              # archived original edition
└── org.kde.fir3.ipdisplay/
    ├── metadata.json                    # Plasma applet metadata
    ├── install.sh                       # per-user installer, no sudo
    ├── uninstall.sh                     # per-user uninstaller
    ├── README.md                        # full docs for this widget
    ├── contents/
    │   ├── code/Network.js              # byte formatting + IP masking helpers
    │   ├── config/main.xml              # applet configuration schema
    │   └── ui/
    │       ├── main.qml                 # panel + popup UI, VPN detection, polling
    │       ├── InfoRow.qml              # a single label/value row (click to copy)
    │       ├── ConfigGeneral.qml        # configuration dialog
    │       └── components/              # InfoRow as a versioned QML module
    └── plugin/                          # prebuilt native plugin (see note above)
        ├── libipdisplayplugin.so
        ├── ipdisplayplugin.qmltypes
        ├── kde-qmlmodule.version
        └── qmldir
```

## License

Copyright © 2026 fir3desert

Licensed under the **GNU General Public License version 3 or later
(GPL-3.0-or-later)**. See [LICENSE](./LICENSE) for the full text.
