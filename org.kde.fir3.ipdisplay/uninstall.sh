#!/usr/bin/env bash
# =============================================================================
#  IP Display — uninstaller for the Plasma 6 applet and its QML plugin
#
#  • Removes only what install.sh put inside $HOME (plus ~/.config).
#  • Never uses sudo and never asks for a password.
#  • Tolerates things already being gone, and reports what it cannot delete.
#
#  Usage:  ./uninstall.sh   (or:  bash uninstall.sh)
#  Options:
#    --no-restart   Do not restart plasmashell after removing.
#    --allow-root   Allow running as root (testing only).
#    -h, --help     Show this help
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P || true)"

# Same rule as install.sh: the project folder is named after the applet id, so
# running the uninstaller from that folder removes exactly what was installed.
# Any other folder name (a git clone, say) falls back to the default id.
APP_ID="org.kde.plasma.ipdisplay"
FOLDER_NAME="$(basename -- "${SCRIPT_DIR:-.}")"
if [[ "$FOLDER_NAME" =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_-]+){2,}$ ]]; then
    APP_ID="$FOLDER_NAME"
fi

info()  { printf '%s\n' "$*"; }
ok()    { printf '[OK]    %s\n' "$*"; }
warn()  { printf '[WARN]  %s\n' "$*" >&2; }
die()   { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: $0 [options]

Removes the "IP Display" applet and its QML plugin.

Deletes (your user account only):
  \$XDG_DATA_HOME/plasma/plasmoids/$APP_ID
  ~/.local/lib/qml/org/kde/plasma/ipdisplay
  ~/.config/environment.d/99-$APP_ID.conf
  ~/.config/plasma-workspace/env/ipdisplay.sh

Options:
  --no-restart   Do not restart plasmashell.
  --allow-root   Allow running as root (testing only).
  -h, --help     Show this help.
EOF
}

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
NO_RESTART=0
ALLOW_ROOT=0

for arg in "$@"; do
    case "$arg" in
        --no-restart) NO_RESTART=1 ;;
        --allow-root) ALLOW_ROOT=1 ;;
        -h|--help) usage; exit 0 ;;
        *)
            die "Unknown option: '$arg'. Run '$0 --help'."
            ;;
    esac
done

if [[ $EUID -eq 0 && $ALLOW_ROOT -ne 1 ]]; then
    die "Do not run this script as root.
   Run it as the same user whose ~/.local it was installed into.  bash $0"
fi

if [[ -z "${HOME:-}" || "$HOME" == "/" ]]; then
    die "The HOME variable is not valid ($HOME)."
fi
# On a brand new account ~/.local may not exist: that is checked, not an
# error, since there would be nothing installed anyway.

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

PLASMOID_DIR="$XDG_DATA_HOME/plasma/plasmoids/$APP_ID"
USER_QML_DIR="$HOME/.local/lib/qml"
PLUGIN_DIR="$USER_QML_DIR/org/kde/plasma/ipdisplay"
ENVD_FILE="$XDG_CONFIG_HOME/environment.d/99-$APP_ID.conf"
KDE_ENV_FILE="$XDG_CONFIG_HOME/plasma-workspace/env/ipdisplay.sh"

info ""
info "=== Removing $APP_ID ==="

# ---------------------------------------------------------------------------
# 1) Applet
# ---------------------------------------------------------------------------
if [[ -n "${SCRIPT_DIR:-}" && "$SCRIPT_DIR" == "$PLASMOID_DIR" ]]; then
    warn "You are running the uninstaller FROM the install folder."
    warn "That folder will be deleted too (including this copy of the project)."
fi
if [[ -d "$PLASMOID_DIR" ]]; then
    rm -rf -- "$PLASMOID_DIR" && ok "Applet removed: $PLASMOID_DIR" \
        || warn "Could not remove $PLASMOID_DIR (delete the folder by hand)."
else
    info "Applet was not installed: $PLASMOID_DIR"
fi

# ---------------------------------------------------------------------------
# 2) Local QML plugin
# ---------------------------------------------------------------------------
if [[ -d "$PLUGIN_DIR" ]]; then
    rm -rf -- "$PLUGIN_DIR" && ok "Plugin removed: $PLUGIN_DIR" \
        || warn "Could not remove $PLUGIN_DIR (delete the folder by hand)."
else
    info "Plugin was not installed: $PLUGIN_DIR"
fi

# ---------------------------------------------------------------------------
# 3) Environment variables (persistence files)
# ---------------------------------------------------------------------------
if [[ -f "$ENVD_FILE" ]]; then
    rm -f -- "$ENVD_FILE" && ok "Removed: $ENVD_FILE" \
        || warn "Could not remove $ENVD_FILE."
else
    info "Did not exist: $ENVD_FILE"
fi
if [[ -f "$KDE_ENV_FILE" ]]; then
    rm -f -- "$KDE_ENV_FILE" && ok "Removed: $KDE_ENV_FILE" \
        || warn "Could not remove $KDE_ENV_FILE."
else
    info "Did not exist: $KDE_ENV_FILE"
fi

# Clean our own entry out of the current session's variables
strip_prefix() {
    local var="$1" prefix="$2"
    local val="${!var:-}"
    [[ -n "$val" ]] || return 0
    if [[ "$val" == "$prefix" ]]; then
        export "$var="
    elif [[ "$val" == "$prefix:"* ]]; then
        export "$var=${val#"$prefix":}"
    fi
}
strip_prefix QML2_IMPORT_PATH "$USER_QML_DIR"
strip_prefix QML_IMPORT_PATH "$USER_QML_DIR"

if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active --quiet default.target 2>/dev/null; then
    systemctl --user set-environment \
        QML2_IMPORT_PATH="${QML2_IMPORT_PATH:-}" \
        QML_IMPORT_PATH="${QML_IMPORT_PATH:-}" &>/dev/null \
        && ok "Variables updated in systemd --user." \
        || warn "Could not clean the variables in systemd --user (resolved at next login)."
fi

# ---------------------------------------------------------------------------
# 4) Leftovers from older installs (done with sudo) — report only
# ---------------------------------------------------------------------------
for sys_dir in /usr/lib/*/qt6/qml/org/kde/plasma/ipdisplay /usr/lib/qt6/qml/org/kde/plasma/ipdisplay; do
    if [[ -d "$sys_dir" ]]; then
        if [[ -z "$(ls -A "$sys_dir" 2>/dev/null || true)" ]]; then
            info "An empty system folder is left over ($sys_dir); ignoring it."
        else
            warn "There is a copy of the plugin installed as root: $sys_dir"
            warn "To remove it (optional):  sudo rm -rf '$sys_dir'"
        fi
        break
    fi
done

# ---------------------------------------------------------------------------
# 5) Restart plasmashell (tolerant chain, same as install.sh)
# ---------------------------------------------------------------------------
info ""
info "=== Restarting plasmashell ==="

if [[ $NO_RESTART -eq 1 ]]; then
    info "--no-restart: skipping the restart. The change applies at login."
    exit 0
fi

if ! pgrep -x plasmashell >/dev/null 2>&1; then
    info "plasmashell is not running; nothing to restart."
else
    RESTART_OK=0
    if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active --quiet default.target 2>/dev/null; then
        for unit in plasma-plasmashell.service plasmashell.service; do
            if systemctl --user list-unit-files "$unit" --no-legend 2>/dev/null | grep -q "$unit"; then
                info "Restarting via systemd: $unit"
                if systemctl --user restart "$unit" 2>/dev/null \
                   && systemctl --user is-active --quiet "$unit" 2>/dev/null; then
                    ok "plasmashell restarted ($unit)."
                    RESTART_OK=1
                fi
                break
            fi
        done
    fi

    if [[ $RESTART_OK -eq 0 ]]; then
        info "Restarting plasmashell manually..."
        old_pids="$(pgrep -x plasmashell 2>/dev/null || true)"
        if command -v kquitapp6 >/dev/null 2>&1; then
            kquitapp6 plasmashell >/dev/null 2>&1 || true
        fi
        if [[ -n "$old_pids" ]]; then
            sleep 1
            still="$(pgrep -x plasmashell 2>/dev/null || true)"
            if [[ -n "$still" ]]; then
                for p in $still; do kill "$p" 2>/dev/null || true; done
                for _ in $(seq 1 8); do
                    pgrep -x plasmashell >/dev/null 2>&1 || break
                    sleep 1
                done
            fi
        fi
        if command -v plasmashell >/dev/null 2>&1; then
            log_file="$XDG_CACHE_HOME/${APP_ID}/plasmashell.log"
            mkdir -p -- "$(dirname -- "$log_file")" 2>/dev/null || true
            {
                printf '\n== restart (uninstall) %s ==\n' "$(date '+%F %T')"
                nohup plasmashell
            } >> "$log_file" 2>&1 &
            sleep 4
            pgrep -x plasmashell >/dev/null 2>&1 \
                && ok "plasmashell restarted." \
                || warn "Could not start plasmashell; check it or log back in."
        else
            warn "'plasmashell' is not in PATH; it will load at login."
        fi
    fi
fi

info ""
info "Uninstall finished."
exit 0
