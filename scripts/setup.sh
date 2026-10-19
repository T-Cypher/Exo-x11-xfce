#!/bin/sh
# Exo for XFCE — one-shot setup.
#
#     1. checks that the required tools are present
#     2. builds bin/x11-events (optional: instant workspace/window updates)
#     3. installs the Material Symbols icon font if it is missing
#     4. applies the xfwm4 settings the shell needs
#     5. symlinks this checkout into ~/.config/quickshell/exo
#     6. adds an XFCE autostart entry
#
# Nothing is installed system-wide and every step is optional — pass flags to
# skip parts, e.g. `./scripts/setup.sh --no-font --no-autostart`.
set -e

SHELL_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SHELL_ID="exo"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET="$CONFIG_HOME/quickshell/$SHELL_ID"

DO_HELPER=1
DO_FONT=1
DO_INTEGRATION=1
DO_LINK=1
DO_AUTOSTART=1

for arg in "$@"; do
    case "$arg" in
    --no-helper) DO_HELPER=0 ;;
    --no-font) DO_FONT=0 ;;
    --no-integration) DO_INTEGRATION=0 ;;
    --no-link) DO_LINK=0 ;;
    --no-autostart) DO_AUTOSTART=0 ;;
    --help | -h)
        sed -n '2,20p' "$0"
        exit 0
        ;;
    *)
        echo "setup.sh: unknown option '$arg'" >&2
        exit 2
        ;;
    esac
done

say() { printf '\033[1m==>\033[0m %s\n' "$1"; }
ok() { printf '    \033[32mok\033[0m  %s\n' "$1"; }
warn() { printf '    \033[33mwarn\033[0m %s\n' "$1"; }
missing() { printf '    \033[31mmissing\033[0m %s\n' "$1"; }

# --------------------------------------------------------------- 1. checks
say "Checking for required tools"
HAVE_MISSING=0

check() {
    if command -v "$1" >/dev/null 2>&1; then
        ok "$1"
    else
        missing "$1${2:+ — $2}"
        HAVE_MISSING=1
    fi
}

check qs "quickshell 0.3 or newer"
check wmctrl "workspace/window control (exo also works without it, just with less info)"
check xdotool "optional: focuses the launcher so you can type"
check xprop "used to read window state (x11-utils)"
check notify-send "used by 'exo notify' and for testing"

if [ "$HAVE_MISSING" -eq 1 ]; then
    echo
    echo "    Install the missing packages, then run this script again. On Debian/Ubuntu:"
    echo "      sudo apt install wmctrl xdotool x11-utils libnotify-bin"
    echo "    (quickshell is not packaged on Debian; build it from source or use the"
    echo "     upstream binaries — see https://quickshell.org/docs/master/guide/install/)"
    echo
fi

# --------------------------------------------------------------- 2. helper
if [ "$DO_HELPER" -eq 1 ]; then
    say "Building the X11 event helper (optional)"
    if command -v cc >/dev/null 2>&1 && pkg-config --exists xcb 2>/dev/null; then
        mkdir -p "$SHELL_DIR/bin"
        if cc -O2 -o "$SHELL_DIR/bin/x11-events" "$SHELL_DIR/scripts/x11-events.c" $(pkg-config --cflags --libs xcb) 2>/dev/null; then
            ok "bin/x11-events built — workspace and window changes are now event driven"
        else
            warn "compilation failed; the shell will poll with wmctrl instead"
        fi
    else
        warn "compiler or libxcb headers not found; the shell will poll with wmctrl instead"
        warn "on Debian/Ubuntu: sudo apt install build-essential libxcb1-dev"
    fi
fi

# ------------------------------------------------------------------ 3. font
if [ "$DO_FONT" -eq 1 ]; then
    say "Checking for the Material Symbols font"
    if fc-list 2>/dev/null | grep -qi "Material Symbols"; then
        ok "already installed"
    else
        warn "not installed — running scripts/install-font.sh"
        sh "$SHELL_DIR/scripts/install-font.sh" || warn "font installation failed; icon glyphs will be missing"
    fi
fi

# ----------------------------------------------------------- 4. xfwm4 setup
if [ "$DO_INTEGRATION" -eq 1 ]; then
    say "Applying xfwm4 settings"
    if command -v xfconf-query >/dev/null 2>&1; then
        sh "$SHELL_DIR/scripts/xfce-integration.sh" --shortcuts || warn "xfce-integration.sh failed; see its output above"
    else
        warn "xfconf-query not found (not an XFCE session?) — skipping"
    fi
fi

# --------------------------------------------------------------- 5. symlink
if [ "$DO_LINK" -eq 1 ]; then
    say "Linking the shell into $TARGET"
    mkdir -p "$CONFIG_HOME/quickshell"
    if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
        warn "$TARGET exists and is not a symlink; moving it to $TARGET.bak"
        mv "$TARGET" "$TARGET.bak"
    fi
    ln -sfn "$SHELL_DIR" "$TARGET"
    ok "qs -c $SHELL_ID  →  $SHELL_DIR"
fi

# ------------------------------------------------------------- 6. autostart
if [ "$DO_AUTOSTART" -eq 1 ]; then
    say "Installing the XFCE autostart entry"
    mkdir -p "$CONFIG_HOME/autostart"
    cat >"$CONFIG_HOME/autostart/exo.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Exo (Material 3 shell)
Comment=Material 3 desktop shell for XFCE on X11
Exec=qs -c $SHELL_ID
TryExec=qs
Terminal=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=2
OnlyShowIn=XFCE;
EOF
    ok "$CONFIG_HOME/autostart/exo.desktop"
fi

cat <<EOF

Setup finished.

  Start the shell now:      qs -c $SHELL_ID
  Or in the background:     qs -c $SHELL_ID & disown
  Configuration file:       $SHELL_DIR/config.json
  Key bindings:             exo toggle-launcher          ($SHELL_DIR/bin/exo)
                            exo toggle-quick-center
                            exo toggle-power-menu
                            exo open-settings

Add $SHELL_DIR/bin to PATH to use the 'exo' command everywhere:
  export PATH="$SHELL_DIR/bin:\$PATH"
EOF
