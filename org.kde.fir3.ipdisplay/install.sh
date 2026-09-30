#!/usr/bin/env bash
# =============================================================================
#  IP Display — installer for the Plasma 6 applet and its QML plugin
#
#  • Installs everything inside the $HOME of the user running the script.
#  • Never asks for a password: no sudo, no system folders are touched.
#  • Fault tolerant: if something in the environment fails it warns and
#    carries on, rather than leaving a half-installed widget behind.
#  • Can be run from any directory of the downloaded/cloned project.
#
#  Usage:  ./install.sh            (or:  bash install.sh)
#  Options:
#    --no-restart   Do not restart plasmashell (the widget loads at login)
#    --allow-root   Allow running as root (testing / containers only)
#    -h, --help     Show this help
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Project location and applet id
#
# The folder the project lives in is normally named after the applet id, and
# that is what the widget is installed as. So unpacking this project into
# ~/.local/share/plasma/plasmoids/<something.id> and running ./install.sh from
# there installs it under that same name, with no renaming needed. Only when
# the folder name does not look like a Plasma applet id (for example when the
# project is still a git clone called "ipdisplay-widget") does the fallback id
# below apply.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

APP_ID_FALLBACK="org.kde.plasma.ipdisplay"
FOLDER_NAME="$(basename -- "$SCRIPT_DIR")"

# A Plasma applet id is a dotted name: no spaces, at least two dots, starting
# with a letter (e.g. org.kde.fir3.ipdisplay).
if [[ "$FOLDER_NAME" =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_-]+){2,}$ ]]; then
    APP_ID="$FOLDER_NAME"
else
    APP_ID="$APP_ID_FALLBACK"
fi

# ---------------------------------------------------------------------------
# Message helpers
# ---------------------------------------------------------------------------
info()  { printf '%s\n' "$*"; }
ok()    { printf '[OK]    %s\n' "$*"; }
warn()  { printf '[WARN]  %s\n' "$*" >&2; }
die()   { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: $0 [options]

Installs the "IP Display" applet and its QML plugin for Plasma 6.

Locations (always inside your own user account):
  \$XDG_DATA_HOME/plasma/plasmoids/$APP_ID   (defaults to ~/.local/share/...)
  ~/.local/lib/qml/org/kde/plasma/ipdisplay  (QML plugin, via QML2_IMPORT_PATH)

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

# ---------------------------------------------------------------------------
# Safety checks
# ---------------------------------------------------------------------------
if [[ $EUID -eq 0 && $ALLOW_ROOT -ne 1 ]]; then
    die "Do not run this script as root.
   The installer is per-user (it installs into ~/.local) and must run as the
   same user that uses Plasma. Run:  bash $0"
fi

if [[ -z "${HOME:-}" || "$HOME" == "/" ]]; then
    die "The HOME variable is not valid ($HOME). Run it as your normal user."
fi
if [[ ! -d "$HOME" ]]; then
    # Not an error: on a brand new account ~/.local may not exist yet, which is
    # exactly when you need to be able to install something.
    mkdir -p -- "$HOME" 2>/dev/null \
        && info "Created the HOME directory ($HOME)." \
        || die "The HOME directory ($HOME) does not exist and could not be created."
fi
[[ -w "$HOME" ]] || die "You do not have write permission in $HOME. Run it as your normal user."

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

PLASMOID_DIR="$XDG_DATA_HOME/plasma/plasmoids/$APP_ID"
USER_QML_DIR="$HOME/.local/lib/qml"
PLUGIN_DIR="$USER_QML_DIR/org/kde/plasma/ipdisplay"
CACHE_DIR="$XDG_CACHE_HOME/$APP_ID"
LOG_FILE="$CACHE_DIR/plasmashell.log"

# Create the base folders first, so there is somewhere to write logs.
mkdir -p "$XDG_DATA_HOME/plasma/plasmoids" \
         "$USER_QML_DIR" \
         "$CACHE_DIR" || die "Could not create the base folders under ~/.local."

# ---------------------------------------------------------------------------
# Check that the required files are there
# ---------------------------------------------------------------------------
[[ -n "${SCRIPT_DIR:-}" && -d "$SCRIPT_DIR" ]] || die "Could not work out the project folder."

REQUIRED_FILES=(
    "$SCRIPT_DIR/metadata.json"
    "$SCRIPT_DIR/contents/ui/main.qml"
    "$SCRIPT_DIR/contents/code/Network.js"
    "$SCRIPT_DIR/plugin/qmldir"
)

MISSING=0
for f in "${REQUIRED_FILES[@]}"; do
    [[ -f "$f" ]] || { warn "Missing file: $f"; MISSING=1; }
done
[[ $MISSING -eq 0 ]] || die "The project is incomplete. Download the whole folder and try again."

# The plugin .so (generic name in case it changes in the future)
mapfile -t SO_CANDIDATES < <(find "$SCRIPT_DIR/plugin" -maxdepth 1 -name 'lib*.so' 2>/dev/null || true)
[[ ${#SO_CANDIDATES[@]} -gt 0 ]] || die "No 'lib*.so' found in $SCRIPT_DIR/plugin."
PLUGIN_SO="${SO_CANDIDATES[0]}"

# ---------------------------------------------------------------------------
# Environment detection (informational only; never blocks the install)
# ---------------------------------------------------------------------------
QML_DIR_DETECTED=""
if command -v pkg-config >/dev/null 2>&1; then
    QML_DIR_DETECTED="$(pkg-config --variable=plugindir Qt6Qml 2>/dev/null || true)"
fi
if [[ -z "$QML_DIR_DETECTED" ]] && command -v qmake6 >/dev/null 2>&1; then
    QML_DIR_DETECTED="$(qmake6 -query QT_INSTALL_QML 2>/dev/null || true)"
fi
if [[ -z "$QML_DIR_DETECTED" ]] && command -v qmake >/dev/null 2>&1; then
    QML_DIR_DETECTED="$(qmake -query QT_INSTALL_QML 2>/dev/null || true)"
fi
if [[ -z "$QML_DIR_DETECTED" ]]; then
    for d in /usr/lib/*/qt6/qml /usr/lib/qt6/qml /usr/lib64/qt6/qml /usr/local/lib/qt6/qml; do
        if [[ -d "$d" ]]; then QML_DIR_DETECTED="$d"; break; fi
    done
fi

# --- Architecture -----------------------------------------------------------
MACHINE_ARCH="$(uname -m 2>/dev/null || true)"
PLUGIN_ARCH="$(file -b "$PLUGIN_SO" 2>/dev/null | grep -oE 'x86-64|aarch64|ARM|riscv64|ppc64le|s390x|i386 / 32-bit' | head -1 || true)"

normalize_arch() {
    case "$1" in
        x86-64|amd64) printf 'x86_64' ;;
        arm64) printf 'aarch64' ;;
        i386|i686) printf 'i386' ;;
        armv7*) printf 'armhf' ;;
        *) printf '%s' "$1" ;;
    esac
}

if [[ -n "${PLUGIN_ARCH:-}" ]]; then
    PLUGIN_ARCH_N="$(normalize_arch "$PLUGIN_ARCH")"
    MACHINE_ARCH_N="$(normalize_arch "$MACHINE_ARCH")"
    if [[ "$PLUGIN_ARCH_N" != "$MACHINE_ARCH_N" ]]; then
        warn "The bundled plugin is built for $PLUGIN_ARCH_N but this machine is $MACHINE_ARCH_N."
        warn "The widget will install, but the network functionality will NOT load on this machine."
    fi
else
    warn "Could not read the plugin architecture ('file' may be missing). Continuing anyway."
fi

# --- Qt compatibility --------------------------------------------------------
# The plugin wants a Qt_6.x symbol; compare it against the installed Qt.
qt_installed=""
for f in /usr/lib/*/libQt6Core.so.* /usr/lib/libQt6Core.so.* \
         /usr/lib64/libQt6Core.so.* /usr/lib64/*/libQt6Core.so.*; do
    [[ -e "$f" ]] || continue
    b="$(basename "$f")"
    case "$b" in
        libQt6Core.so.6.*)
            minor="${b#libQt6Core.so.6.}"; minor="${minor%%.*}"
            qt_installed="6.$minor"
            break
            ;;
    esac
done
if [[ -z "$qt_installed" ]]; then
    hv="$(grep -h -m1 -oE 'QT_VERSION_STR[^0-9]*[0-9.]+' \
            /usr/include/*/qt6/QtCore/qglobal.h 2>/dev/null \
          | grep -oE '[0-9.]+' | head -1 || true)"
    [[ -n "$hv" ]] && qt_installed="$hv"
fi

qt_required=""
if command -v objdump >/dev/null 2>&1; then
    qt_required="$(objdump -p "$PLUGIN_SO" 2>/dev/null | grep -oE 'Qt_6(\.[0-9]+)*' | sed 's/Qt_//' | sort -u | tail -1 || true)"
fi

if [[ -n "$qt_required" && -n "$qt_installed" ]]; then
    req_minor="${qt_required#6.}";  req_minor="${req_minor%%.*}"
    have_minor="${qt_installed#6.}"; have_minor="${have_minor%%.*}"
    if [[ "${have_minor:-0}" -lt "${req_minor:-0}" ]]; then
        warn "The plugin needs Qt 6.$req_minor or newer, but this system has Qt $qt_installed."
        warn "Installing anyway; if the widget reports errors you will need a plugin rebuilt against your Qt."
    fi
fi

# --- Missing shared libraries -------------------------------------------------
if command -v ldd >/dev/null 2>&1; then
    MISSING_LIBS="$(ldd "$PLUGIN_SO" 2>/dev/null | grep -i 'not found' || true)"
    if [[ -n "$MISSING_LIBS" ]]; then
        warn "The plugin has unresolved libraries, so it will probably not load:"
        printf '%s\n' "$MISSING_LIBS" >&2
    fi
fi

# ---------------------------------------------------------------------------
# 1) Install the applet (the Plasma package)
# ---------------------------------------------------------------------------
info ""
info "=== 1/4  Installing the applet ==="

if [[ "$SCRIPT_DIR" == "$PLASMOID_DIR" ]]; then
    info "The project already lives in its install location ($PLASMOID_DIR)."
    info "Skipping the copy, so the folder you are running from is not deleted."
else
    OVERWRITE_MODE=0
    OLD_DIR=""
    if [[ -e "$PLASMOID_DIR" ]]; then
        if [[ -w "$PLASMOID_DIR" ]]; then
            OLD_DIR="$PLASMOID_DIR.old.$RANDOM"
            if mv -- "$PLASMOID_DIR" "$OLD_DIR" 2>/dev/null; then
                info "Previous installation moved aside temporarily."
            else
                warn "Could not move the previous installation aside ($PLASMOID_DIR)."
                OVERWRITE_MODE=1
            fi
        else
            warn "The folder $PLASMOID_DIR is not writable by your user; overwriting what we can."
            OVERWRITE_MODE=1
        fi
    fi
    if [[ $OVERWRITE_MODE -eq 0 ]]; then
        mkdir -p -- "$PLASMOID_DIR" \
            || die "Could not create $PLASMOID_DIR. Check the permissions on ~/.local/share/plasma/plasmoids."
        cp -a -- "$SCRIPT_DIR/contents" "$PLASMOID_DIR/" \
            || die "Could not copy 'contents' to $PLASMOID_DIR."
        cp -a -- "$SCRIPT_DIR/metadata.json" "$PLASMOID_DIR/" \
            || die "Could not copy 'metadata.json' to $PLASMOID_DIR."
        # The plugin travels inside the applet too: that is the route Plasma
        # uses by default, and it makes the widget work without relying on
        # environment variables or on a copy of the .so in ~/.local/lib/qml.
        cp -a -- "$SCRIPT_DIR/plugin" "$PLASMOID_DIR/" \
            || warn "Could not copy 'plugin' to $PLASMOID_DIR (the copy in ~/.local/lib/qml will be used)."
        # Docs and scripts inside the installation, so it can be updated or
        # removed without downloading the project again.
        for extra in README.md install.sh uninstall.sh; do
            [[ -f "$SCRIPT_DIR/$extra" ]] && cp -a -- "$SCRIPT_DIR/$extra" "$PLASMOID_DIR/" || true
        done
    else
        cp -a -- "$SCRIPT_DIR/contents" "$PLASMOID_DIR/" \
            || warn "Could not update 'contents' in $PLASMOID_DIR."
        cp -a -- "$SCRIPT_DIR/metadata.json" "$PLASMOID_DIR/" \
            || warn "Could not update 'metadata.json' in $PLASMOID_DIR."
        cp -a -- "$SCRIPT_DIR/plugin" "$PLASMOID_DIR/" \
            || warn "Could not update 'plugin' in $PLASMOID_DIR."
    fi
    if [[ -n "$OLD_DIR" ]]; then
        rm -rf -- "$OLD_DIR" 2>/dev/null \
            && ok "Previous copy removed." \
            || warn "Could not delete the previous copy: $OLD_DIR (you can remove it by hand)."
    fi
fi
ok "Applet at:  $PLASMOID_DIR"

# ---------------------------------------------------------------------------
# 2) Install the QML plugin into ~/.local/lib/qml
# ---------------------------------------------------------------------------
info ""
info "=== 2/4  Installing the QML plugin ==="

mkdir -p -- "$PLUGIN_DIR"
cp -a -- "$PLUGIN_SO" "$PLUGIN_DIR/"       || die "Could not copy the plugin to $PLUGIN_DIR."
cp -a -- "$SCRIPT_DIR/plugin/qmldir" "$PLUGIN_DIR/" || warn "Missing 'plugin/qmldir' (the module will not be registered)."
cp -a -- "$SCRIPT_DIR/plugin/ipdisplayplugin.qmltypes" "$PLUGIN_DIR/" 2>/dev/null || true
cp -a -- "$SCRIPT_DIR/plugin/kde-qmlmodule.version" "$PLUGIN_DIR/" 2>/dev/null || true
ok "Plugin at:  $PLUGIN_DIR"

# ---------------------------------------------------------------------------
# 3) Make the plugin visible to plasmashell (environment variables)
# ---------------------------------------------------------------------------
info ""
info "=== 3/4  Configuring the QML import paths ==="

# Prepend $USER_QML_DIR to the existing value, without duplicates.
join_qml_path() {
    local prefix="$1" current="${2:-}" entry out
    out="$prefix"
    if [[ -n "$current" ]]; then
        local IFS=':'
        for entry in $current; do
            [[ -n "$entry" && "$entry" != "$prefix" ]] || continue
            case ":$out:" in *":$entry:"*) continue ;; esac
            out="$out:$entry"
        done
    fi
    printf '%s' "$out"
}
QML2_JOIN="$(join_qml_path "$USER_QML_DIR" "${QML2_IMPORT_PATH:-}")"
QML_JOIN="$(join_qml_path "$USER_QML_DIR" "${QML_IMPORT_PATH:-}")"

export QML2_IMPORT_PATH="$QML2_JOIN"
export QML_IMPORT_PATH="$QML_JOIN"

# 3a) systemd user (persists across restarts and for user services)
if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active --quiet default.target 2>/dev/null; then
    systemctl --user set-environment QML2_IMPORT_PATH="$QML2_JOIN" QML_IMPORT_PATH="$QML_JOIN" \
        && ok "Variables applied to the session manager (systemd --user)." \
        || warn "Could not apply the environment to systemd --user (retried at next login)."
else
    warn "systemd --user is not managing this session; the variables apply when plasmashell restarts."
fi

# 3b) environment.d (persistence for the next login)
ENVD_DIR="$XDG_CONFIG_HOME/environment.d"
ENVD_FILE="$ENVD_DIR/99-$APP_ID.conf"
install_environment_d() {
    mkdir -p -- "$ENVD_DIR"
    # Replace the user's HOME with $HOME so the file stays valid if the widget
    # is copied to another user or another machine.
    local qml2="${QML2_JOIN//"$HOME"/\$HOME}"
    local qml="${QML_JOIN//"$HOME"/\$HOME}"
    cat > "$ENVD_FILE" <<EOF
# Generated by $APP_ID (install.sh). Delete this file to revert.
QML2_IMPORT_PATH=$qml2
QML_IMPORT_PATH=$qml
EOF
}
if install_environment_d 2>/dev/null; then
    ok "Persistence 1/2: $ENVD_FILE"
else
    warn "Could not write $ENVD_FILE (the change applies to this session only)."
fi

# 3c) Plasma startup script (persistence for sessions without systemd)
KDE_ENV_DIR="$XDG_CONFIG_HOME/plasma-workspace/env"
KDE_ENV_FILE="$KDE_ENV_DIR/ipdisplay.sh"
install_kde_env() {
    mkdir -p -- "$KDE_ENV_DIR"
    cat > "$KDE_ENV_FILE" <<'EOF'
#!/bin/sh
# Generated by org.kde.plasma.ipdisplay (install.sh). Delete this file to revert.
__ipd_qml_dir="$HOME/.local/lib/qml"
export QML2_IMPORT_PATH="${__ipd_qml_dir}${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
export QML_IMPORT_PATH="${__ipd_qml_dir}${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
unset __ipd_qml_dir
EOF
    chmod +x "$KDE_ENV_FILE" 2>/dev/null || true
}
if install_kde_env 2>/dev/null; then
    ok "Persistence 2/2: $KDE_ENV_FILE"
else
    warn "Could not write $KDE_ENV_FILE (the change applies to this session only)."
fi

# ---------------------------------------------------------------------------
# 4) Restart plasmashell (chain of fallbacks, fault tolerant)
# ---------------------------------------------------------------------------
info ""
info "=== 4/4  Restarting plasmashell ==="

if [[ $NO_RESTART -eq 1 ]]; then
    info "--no-restart: skipping the restart. Log out and back in, or run without this flag to see the widget."
    info "To add the widget: right-click the panel -> Add Widgets -> look for 'IP Display'."
    exit 0
fi

if ! pgrep -x plasmashell >/dev/null 2>&1; then
    info "plasmashell is not running; it will load the widget at login."
else
    # Attempt 1: the user systemd unit
    RESTART_OK=0
    if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active --quiet default.target 2>/dev/null; then
        for unit in plasma-plasmashell.service plasmashell.service; do
            if systemctl --user list-unit-files "$unit" --no-legend 2>/dev/null | grep -q "$unit"; then
                info "Restarting via systemd: $unit"
                if systemctl --user restart "$unit" 2>/dev/null \
                   && systemctl --user is-active --quiet "$unit" 2>/dev/null; then
                    ok "plasmashell restarted ($unit)."
                    RESTART_OK=1
                    break
                fi
                warn "$unit could not be restarted via systemd; trying the manual method."
            fi
        done
    fi

    # Attempt 2: manual (kquitapp6 / killall, then relaunch)
    if [[ $RESTART_OK -eq 0 ]]; then
        info "Restarting plasmashell manually..."
        old_pids="$(pgrep -x plasmashell 2>/dev/null || true)"
        if command -v kquitapp6 >/dev/null 2>&1; then
            kquitapp6 plasmashell >/dev/null 2>&1 || true
        fi
        if [[ -n "$old_pids" ]]; then
            # If kquitapp6 did not close it (no DBus, etc.), force TERM
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
        if pgrep -x plasmashell >/dev/null 2>&1; then
            warn "plasmashell did not exit completely; a new one will be started anyway."
        fi
        if command -v plasmashell >/dev/null 2>&1; then
            {
                printf '\n== restart %s ==\n' "$(date '+%F %T')"
                env QML2_IMPORT_PATH="$QML2_IMPORT_PATH" QML_IMPORT_PATH="$QML_IMPORT_PATH" nohup plasmashell
            } >> "$LOG_FILE" 2>&1 &
        else
            warn "'plasmashell' is not in PATH; it will load at login."
        fi

        sleep 4
        if pgrep -x plasmashell >/dev/null 2>&1; then
            ok "plasmashell restarted (log: $LOG_FILE)"
        else
            warn "Could not start plasmashell. Check $LOG_FILE, or log out and back in."
        fi
    fi

    # Optional check: QML module errors in the log
    if [[ -f "$LOG_FILE" ]]; then
        MODULE_ERRORS="$(grep -iE 'org\.kde\.plasma\.ipdisplay|NetworkInfo|is not installed' "$LOG_FILE" | tail -5 || true)"
        if [[ -n "$MODULE_ERRORS" ]]; then
            warn "The plasmashell log shows possible problems with the module:"
            printf '%s\n' "$MODULE_ERRORS" >&2
        else
            ok "No 'ipdisplay' errors in the plasmashell log."
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
info ""
info "Installation finished."
info "  • Applet : $PLASMOID_DIR"
info "  • Plugin : $PLUGIN_DIR"
info "  • Import : QML2_IMPORT_PATH=$QML2_JOIN"
info ""
info "To use it: right-click the panel -> Add Widgets -> look for 'IP Display'."
info "If you cannot see it, log out and back in (the environment variables are saved)."
exit 0
