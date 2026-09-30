# kdewidgets

Custom KDE Plasma 6 widgets.

Each widget lives in its own folder, named after its Plasma applet id, so it can
be installed, updated or removed on its own without touching the others.

## Widgets

| Widget | Id | Description |
|---|---|---|
| **IP Display** | `org.kde.fir3.ipdisplay` | Shows your LAN and public IP addresses in the panel, with a status dot, VPN detection and a popup with detailed network info (interface, gateway, DNS, traffic counters). |

→ **[Full documentation for IP Display](./org.kde.fir3.ipdisplay/README.md)**

## Requirements

- KDE Plasma 6 (Qt 6). The applet declares `X-Plasma-API-Minimum-Version: 6.0`.
- No `sudo` and no system folders: everything installs under your own `$HOME`.

## Installation

```bash
git clone https://github.com/fir3desert/kdewidgets.git
cd kdewidgets/org.kde.fir3.ipdisplay
./install.sh
```

Then add it to a panel: right-click the panel → *Add Widgets…* → **IP Display**
(under the *System Information* category).

To remove it again:

```bash
./uninstall.sh
```

Installer options: `--no-restart` (skip restarting plasmashell), `--allow-root`
(testing only), `-h` for help.

## A note on the bundled plugin

The applet reads network state through a native QML plugin
(`plugin/libipdisplayplugin.so`) that queries NetworkManager over D-Bus and
resolves public addresses via `api.ipify.org` / `ifconfig.me`.

**This repository ships that plugin prebuilt, and does not include its source
code or a build system**, so it cannot be rebuilt or reproduced from here. The
bundled binary targets a specific architecture and Qt minor version; if it does
not match your machine, `install.sh` says so and keeps going, but the widget's
network functionality will not load until a matching build is available.

The applet folder carries its own `plugin/` directory, which is the path Plasma
uses by default. The installer additionally copies the plugin into
`~/.local/lib/qml/` and sets up the QML import path — belt and braces, so the
widget also works without relying on environment variables.

## Repository layout

```
kdewidgets/
├── LICENSE                              # GPL-3.0
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
