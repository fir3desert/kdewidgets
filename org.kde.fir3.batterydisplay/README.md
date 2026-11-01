# Battery

Stable edition of the KDE Plasma 6 battery widget. It has the same features
and animation catalog as [Battery (testing)](../WidgetTesting/org.kde.fir3.batterydisplay-testing/README.md),
but it always uses live battery data. A **Preview animation** switch in Settings
forces the charging animation on so you can try styles without plugging in the charger.

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

## What's new in 1.3.0

- Charging detection no longer depends on the QML enum (numeric fallback).
- Only the canvas of the selected animation exists (one `Loader` each), and
  animations stop while the item is hidden or desktop animations are off.
- Unknown or empty style values fall back to Sweep.
- Texts go through `i18n()`; a Spanish translation is included
  (`po/es.po`, compiled into `contents/locale/es/LC_MESSAGES/`).
- "Idle" is now "Plugged in, not charging" (e.g. a charge limit is reached).
- Family/style selectors stay in sync after changing either one.

## Languages

Translations: Spanish, Catalan, Basque, Galician, French, German, Portuguese,
Italian and Japanese (`po/*.po`, compiled into
`contents/locale/<lang>/LC_MESSAGES/`). They were machine-written; corrections
are welcome. To add a language, copy `po/es.po` to `po/<lang>.po`, translate the
`msgstr` lines and compile it with `msgfmt` into the matching `contents/locale`
folder.

## Install

From this directory:

```bash
./install.sh
```

The script installs the widget to:

```text
~/.local/share/plasma/plasmoids/org.kde.fir3.batterydisplay
```

It restarts `plasmashell` when possible so the widget is available; if it
cannot restart the shell, follow the message printed by the script. Pass
`--no-restart` to skip the restart. If `XDG_DATA_HOME` is set, the script
respects it.

Then add it to the panel:

1. Right-click the panel → **Edit Panel**.
2. **Add Widgets…** → search for **Battery**.
3. Drag it to the panel or press **Add**.

If it does not appear, log out and back in, or restart the Plasma shell:

```bash
plasmashell --replace &
```

## Settings

Right-click the widget → **Configure Battery**, or use the **Settings** button
in the popup. You can:

- enable or disable state-dependent colors;
- change the warning (orange) and critical (red) thresholds;
- enable or disable charging animations and choose their family and style.

On a machine without a battery the widget shows the outline with a dash and
the message "No battery". The testing edition adds a simulated preview so the
layout and animations can be tried without a battery.

## Data

The applet uses `BatteryControlModel` from
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
    ├── BatteryVisual.qml   # battery drawing and animation effects
    ├── configGeneral.qml   # settings page
    └── main.qml            # applet, panel and popup
```

## Troubleshooting

If the animation does not start while charging, watch the state the widget
receives:

```bash
journalctl --user -f | grep fir3.batterydisplay
```

Each line shows `chargeState` (1 = charging), `percent`, `pluggedIn` and
`charging`.

## Uninstall

```bash
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/org.kde.fir3.batterydisplay"
```

Then remove the widget from the panel and restart `plasmashell` if it still
appears in the list.

## Note about `kpackagetool6`

Do not use `kpackagetool6 -u` pointing at this same directory: in Plasma 6
that command may delete the package before failing. Use `install.sh`, or copy
the package to another path first and use `-i` on the copy.
