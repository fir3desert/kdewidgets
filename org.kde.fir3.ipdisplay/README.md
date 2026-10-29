# IP Display - KDE Plasma Widget

**IP Display** is a KDE Plasma applet that shows your system's IP addresses in the
panel, with an interactive popup containing detailed network information.

The installer works per-user without `sudo`. By default it uses locations
under `~/.local` and `~/.config`, and it respects the standard XDG directory
variables where applicable.

## Configuration

Right-click the widget → *Configure…*:

| Setting | Default | Effect |
|---|---|---|
| Auto-update | on | keep the panel data fresh |
| Update interval | 1 s | how often the panel polls the plugin while the popup is closed |
| Show public IP | on | show the **Public** row |
| Show IPv6 | off | show the local **IPv6** row |
| Auto-detect interface | on | let the plugin pick the active interface |
| Interface | — | pin a specific interface (e.g. `wg0`, `eth0`) instead |
| Public IP timeout | 5000 ms | give up on a public-IP endpoint after this long |
| Public IPv4 endpoints | `https://api.ipify.org`, `https://ifconfig.me` | one per line, tried in order |
| Public IPv6 endpoints | `https://api6.ipify.org`, `https://ifconfig.me` | one per line, tried in order |

The **Update interval** is what makes the dot react quickly when a VPN comes up
while the popup is closed. Polling stops while the popup is open, because the
popup refreshes when it opens and long gaps would look stale.

## Features

### Panel (compact view)
- Colored status dot:
  - 🟢 green = online
  - 🟠 orange = no internet
  - 🔴 red = offline
  - 🟣 **purple = VPN active**
- **LAN** IPv4 address — always the LAN one, even while a VPN is up (a tunnel
  usually carries a /32 and does not become the default route, so the panel
  keeps showing your local address). The VPN address is not shown here, and
  neither is the interface name: the purple dot already signals the VPN
- Refreshes at the configured interval (1 second by default, adjustable from
  1 to 30 seconds), so the dot reflects status changes while the popup is
  closed

### VPN support
- **Automatic VPN detection** — works with WireGuard, OpenVPN and friends
- The dot reflects the **real tunnel state**, as reported by NetworkManager.
  Note that toggling a VPN off from the system tray does not always bring the
  interface down: the connection is deactivated but the tunnel can stay up, so
  a purple dot there may well be correct. Use the VPN client's own "down"
  action if you want the interface itself removed
- Shows the **VPN interface name** in the popup's VPN row, in blue, formatted
  as `10.0.32.7 (wg0)` — the name is deliberately kept out of the panel
- Interface names recognised as VPN tunnels:

  | Pattern | Typical client |
  |---|---|
  | `wg`, `wgquick` | WireGuard |
  | `tun`, `tap` | OpenVPN |
  | `ppp`, `utun` | PPP / IKEv2 |
  | `zt` | ZeroTier |
  | `tailscale` | Tailscale |
  | `nordlynx`, `nordvpn` | NordVPN |
  | `cscotun` | Cisco AnyConnect |
  | `ipsec` | IPsec |
  | names containing `vpn` or `tunnel` | `nordvpn-tun`, `mullvad-tun`, … |

  Physical and virtual LAN interfaces (`enp1s0`, `wlan0`, `docker0`, `veth*`,
  `virbr0`, `br-*`, `lo`) are deliberately **not** treated as VPNs, which avoids
  the false positives you get inside virtual machines.

- The interface is resolved from whichever source the plugin reports: the VPN
  interface name, or the main interface when that one is a tunnel — which is the
  usual case for WireGuard, since it becomes the default route.
- If the plugin reports no VPN IP but the tunnel *is* the main interface, the
  interface's own address is shown instead of a blank row.

### Popup (expanded view)
- **LAN** — local IPv4
- **Public** — public **IPv4**, and **IPv6 when there is no IPv4**
- **IPv6** — local IPv6
- **Interface** — active network interface
- **Gateway** — default gateway
- **DNS** — first nameserver
- **VPN** — VPN address and interface (e.g. `10.0.32.7 (wg0)`), in blue, or
  `Inactive`. This is the only place the VPN address and interface name appear
- **RX / TX** — traffic counters with human-readable units (B, KB, MB, GB, TB)
- **Last update** — timestamp of the last refresh
- **Refresh** button to update manually
- Click any value to copy it to the clipboard

## Installation

1. **From KDE Plasma**: right-click the panel → *Add Widgets…* → find
   **IP Display** under the *System Information* category.

2. **With the installer** (recommended) — installs per-user, without `sudo`
   or a password prompt. It refuses to run as root by default:
   ```bash
   ./install.sh          # or: bash install.sh
   ./uninstall.sh        # to remove it again
   ```
   Useful flags: `--no-restart` (skip restarting the panel),
   `--allow-root` (testing only), `-h` for help.

3. Keep the project directory named `org.kde.fir3.ipdisplay` when running the
   installer. It derives the install-directory name from that folder; if the
   folder has a non-applet name, the install directory falls back to
   `org.kde.plasma.ipdisplay`.

4. **Reload Plasma** so the changes are picked up (the installer does this
   unless `--no-restart` was passed):
   ```bash
   systemctl --user restart plasma-plasmashell.service
   ```

### What the installer writes

By default, the installer writes to per-user locations and does not require
elevated permissions. It respects `XDG_DATA_HOME`, `XDG_CONFIG_HOME` and
`XDG_CACHE_HOME` where applicable:

| Path | Purpose |
|---|---|
| `${XDG_DATA_HOME:-~/.local/share}/plasma/plasmoids/org.kde.fir3.ipdisplay/` | the applet (QML, metadata, plugin) |
| `~/.local/lib/qml/org/kde/plasma/ipdisplay/` | QML plugin copy, for the import path |
| `${XDG_CONFIG_HOME:-~/.config}/environment.d/99-org.kde.fir3.ipdisplay.conf` | import path, uses `$HOME` so it survives being moved |
| `${XDG_CONFIG_HOME:-~/.config}/plasma-workspace/env/ipdisplay.sh` | import path fallback for non-systemd sessions |

The applet folder carries its own `plugin/` directory, which is the path Plasma
uses by default, so the widget works even without the environment variables. The
`~/.local/lib/qml` copy and the environment files are belt-and-braces.

To uninstall, run `./uninstall.sh`. It removes the files it installed and
leaves empty parent directories behind, which is harmless.

## Project layout

```
org.kde.fir3.ipdisplay/
├── metadata.json              # Plasma applet metadata
├── install.sh                 # per-user installer, no sudo
├── uninstall.sh               # per-user uninstaller
├── contents/
│   ├── code/Network.js        # byte formatting + IP masking helpers
│   ├── config/main.xml        # applet configuration schema
│   └── ui/
│       ├── main.qml           # panel + popup UI, VPN detection, polling
│       ├── InfoRow.qml        # a single label/value row (click to copy)
│       ├── ConfigGeneral.qml  # configuration dialog
│       └── components/
│           ├── InfoRow.qml
│           └── qmldir
└── plugin/
    ├── libipdisplayplugin.so  # native NetworkInfo backend
    ├── ipdisplayplugin.qmltypes
    ├── kde-qmlmodule.version
    └── qmldir
```

The native plugin (`org.kde.plasma.ipdisplay`) exposes `NetworkInfo` with
`localIpv4`, `localIpv6`, `publicIpv4`, `publicIpv6`, `interfaceName`,
`gateway`, `dnsList`, `vpnActive`, `vpnIfaceName`, `vpnIp`, `status`,
`rxBytes`, `txBytes` and `lastUpdate`. It queries public addresses through
`api.ipify.org` / `ifconfig.me` (and `api6.ipify.org` for IPv6), and tracks
NetworkManager over D-Bus for status and VPN changes.

## License

Copyright © 2026 fir3desert

This project is licensed under the **GNU General Public License
version 3 or later (GPL-3.0-or-later)**.

You are free to use, study, modify, and redistribute this software
under the terms of the GNU GPL v3 or later.

When redistributing this software or a modified version, you must
preserve the applicable original copyright and license notices and
clearly indicate any modifications made to the original work.

See [LICENSE](../LICENSE) for the full license text.
