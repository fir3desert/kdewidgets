# Battery (testing)

Testing edition of the KDE Plasma 6 battery widget. It includes the full
animation catalog and a simulated preview mode for machines without a battery
or when you want to test the appearance without relying on live battery data.
For the stable edition with the same features but without simulated data, see
[Battery](../org.kde.fir3.batterydisplay/README.md).

The panel shows a drawn battery with the percentage inside. Clicking it opens
a summary with the state, remaining time, battery health and per-device power
consumption. State-dependent colors and charging animations can be adjusted
in Settings. Reaching 100 % shows a one-time flash with sparks.

## Charging animations

The selector groups all 25 styles into families:

- **Classic:** Sweep, Double sweep, Moving stripes.
- **Fluid glow:** Breathing, Bright halo, Liquid wave.
- **Electric:** Thunderstorm, Lightning, Heartbeat.
- **Traveling light:** Comet, Twin comet, Snake, Orbit, Spiral, Pendulum,
  Scanner.
- **Outline neon:** Perimeter neon, Twin neon, Neon wave, Perimeter bolt,
  Neon spin.
- **Ambient:** Firefly, Ripple, Aurora, Matrix.

The 100 % celebration is automatic and is skipped when charging animations
are disabled.

## Install

From this directory:

```bash
./install.sh
```

The script installs the widget to:

```text
~/.local/share/plasma/plasmoids/org.kde.fir3.batterydisplay-testing
```

It restarts `plasmashell` when possible so the widget is available; if it
cannot restart the shell, follow the message printed by the script. Pass
`--no-restart` to skip the restart. If `XDG_DATA_HOME` is set, the script
respects it.

Then add it to the panel:

1. Right-click the panel → **Edit Panel**.
2. **Add Widgets…** → search for **Battery (testing)**.
3. Drag it to the panel or press **Add**.

If it does not appear, log out and back in, or restart the Plasma shell:

```bash
plasmashell --replace &
```

## Settings and simulated preview

Right-click the widget → **Configure Battery**, or use the **Settings** button
in the popup. You can:

- enable or disable state-dependent colors;
- change the warning (orange) and critical (red) thresholds;
- enable or disable charging animations and choose their family and style;
- enable simulated data, set its battery level and set whether it is charging.

With simulated preview disabled, the widget displays live battery data. On a
machine without a battery it shows the outline with a dash and the message
"No battery"; enable the preview to try the layout and animation settings.

The testing edition has its own applet ID,
`org.kde.fir3.batterydisplay-testing`. If Plasma shows a duplicate from an
earlier installation, remove the older widget entry and restart the shell.

## Data

When the preview is disabled, the applet uses `BatteryControlModel` from
`org.kde.plasma.private.battery`, the same model as Plasma's official power
applet. Values update automatically; there are no external processes or
periodic polling.

## Files

```text
install.sh
metadata.json
contents/
├── config/
│   ├── config.qml
│   └── main.xml
└── ui/
    ├── AnimationStyles.js  # grouped animation catalog
    ├── BatteryVisual.qml  # battery drawing and animation effects
    ├── configGeneral.qml  # settings page and simulated preview controls
    └── main.qml           # applet, panel and popup
```

## Uninstall

```bash
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/org.kde.fir3.batterydisplay-testing"
```

Then remove the widget from the panel and restart `plasmashell` if it still
appears in the list.

## Note about `kpackagetool6`

Do not use `kpackagetool6 -u` pointing at this same directory: in Plasma 6
that command may delete the package before failing. Use `install.sh`, or
copy the package to another path first and use `-i` on the copy.
