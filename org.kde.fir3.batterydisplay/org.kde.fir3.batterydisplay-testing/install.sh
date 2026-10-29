#!/usr/bin/env bash
#
# Install this Plasma applet in the user plasmoid directory.
#
# Usage:
#   ./install.sh              # install and restart plasmashell
#   ./install.sh --no-restart # install without restarting plasmashell
#
set -euo pipefail

PLUGIN_ID="org.kde.fir3.batterydisplay-testing"
SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/$PLUGIN_ID"

restart=true

for arg in "$@"; do
    case "$arg" in
        --no-restart)
            restart=false
            ;;
        -h|--help)
            sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Use --help for usage." >&2
            exit 1
            ;;
    esac
done

if [[ ! -f "$SOURCE_DIR/metadata.json" ]]; then
    echo "error: metadata.json not found in $SOURCE_DIR" >&2
    exit 1
fi

if [[ ! -d "$SOURCE_DIR/contents" ]]; then
    echo "error: contents/ not found in $SOURCE_DIR" >&2
    exit 1
fi

# Make sure the package we are about to install is the expected one.
if command -v python3 >/dev/null 2>&1; then
    actual_id="$(python3 - "$SOURCE_DIR/metadata.json" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as fh:
    print(json.load(fh)["KPlugin"]["Id"])
PY
)"
    if [[ "$actual_id" != "$PLUGIN_ID" ]]; then
        echo "error: unexpected plugin id '$actual_id' (expected '$PLUGIN_ID')" >&2
        exit 1
    fi
fi

echo "Installing $PLUGIN_ID"
echo "  from: $SOURCE_DIR"
echo "  to:   $TARGET_DIR"

if [[ -d "$TARGET_DIR" && "$SOURCE_DIR" -ef "$TARGET_DIR" ]]; then
    # Running from the install directory itself: there is nothing to copy.
    echo "Source is already the install location; skipping copy."
else
    rm -rf -- "$TARGET_DIR"
    mkdir -p -- "$TARGET_DIR"

    # Copy everything except VCS data and packaging archives.
    tar -C "$SOURCE_DIR" \
        --exclude=.git \
        --exclude='*.zip' \
        -cf - . | tar -C "$TARGET_DIR" -xf -
fi

echo "Installed."

if $restart; then
    if systemctl --user is-active --quiet plasma-plasmashell.service 2>/dev/null; then
        echo "Restarting plasmashell..."
        systemctl --user restart plasma-plasmashell.service
    elif command -v kquitapp6 >/dev/null 2>&1; then
        kquitapp6 plasmashell >/dev/null 2>&1 || true
        nohup plasmashell >/dev/null 2>&1 &
        echo "plasmashell restarted."
    else
        echo "Restart the Plasma shell to load the widget (for example: plasmashell --replace &)."
    fi
fi

cat <<'EOF'

Next: right-click the panel -> Edit Panel -> Add Widgets... -> "Battery (testing)".
EOF
