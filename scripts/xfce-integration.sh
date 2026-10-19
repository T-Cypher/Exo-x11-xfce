#!/bin/sh
# Exo for XFCE — apply the xfwm4 / XFCE settings the shell expects.
#
# Safe to run more than once; every change is written with xfconf-query.
# Pass --shortcuts to (re)install the keyboard bindings, --revert to undo the
# xfwm4 focus tweaks.
set -e

SHORTCUTS=0
REVERT=0
SHELL_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
EXO_BIN="$SHELL_DIR/bin/exo"

for arg in "$@"; do
    case "$arg" in
    --shortcuts) SHORTCUTS=1 ;;
    --revert | --undo) REVERT=1 ;;
    --help | -h)
        echo "usage: xfce-integration.sh [--shortcuts] [--revert]"
        exit 0
        ;;
    esac
done

have() { command -v "$1" >/dev/null 2>&1; }

set_xfconf() {
    # set_xfconf <channel> <property> <type> <value>
    channel="$1"
    prop="$2"
    type="$3"
    value="$4"
    current=$(xfconf-query -c "$channel" -p "$prop" 2>/dev/null || true)
    if [ "$current" = "$value" ]; then
        return 0
    fi
    if [ -z "$current" ]; then
        xfconf-query -c "$channel" -p "$prop" -n -t "$type" -s "$value"
    else
        xfconf-query -c "$channel" -p "$prop" -t "$type" -s "$value"
    fi
    echo "  $channel$prop = $value"
}

set_shortcut() {
    # set_shortcut <keysym-path> <command>
    prop="/commands/custom/$1"
    shift
    cmd="$*"
    if xfconf-query -c xfce4-keyboard-shortcuts -p "$prop" >/dev/null 2>&1; then
        xfconf-query -c xfce4-keyboard-shortcuts -p "$prop" -t string -s "$cmd"
    else
        xfconf-query -c xfce4-keyboard-shortcuts -p "$prop" -n -t string -s "$cmd"
    fi
    echo "  $prop = $cmd"
}

have xfconf-query || {
    echo "xfconf-query not found — this script only applies to XFCE sessions." >&2
    exit 1
}

if [ "$REVERT" -eq 1 ]; then
    echo "Reverting xfwm4 focus settings to XFCE defaults…"
    set_xfconf xfwm4 /general/prevent_focus_stealing int 2
    echo "Done. (Keyboard shortcuts are left in place; remove them in"
    echo "Settings → Keyboard → Application Shortcuts.)"
    exit 0
fi

echo "Applying xfwm4 settings for Exo…"
# The overlay surface (launcher, quick centre, settings) is mapped on demand and
# must be able to take the keyboard, so focus stealing prevention is relaxed to
# the lowest setting and new windows get focus.
set_xfconf xfwm4 /general/prevent_focus_stealing int 0
set_xfconf xfwm4 /general/focus_new bool true
set_xfconf xfwm4 /general/click_to_focus bool true

# The bar follows the WM's workspaces; four desktops is a sane default for the
# workspace module in the bar.
desktops=$(xfconf-query -c xfwm4 -p /general/workspace_count 2>/dev/null || echo "")
if [ -z "$desktops" ]; then
    set_xfconf xfwm4 /general/workspace_count int 4
fi

if [ "$SHORTCUTS" -eq 1 ]; then
    echo "Installing keyboard shortcuts (Super+…):"
    set_shortcut "<Super>space" "$EXO_BIN toggle-launcher"
    set_shortcut "<Super>s" "$EXO_BIN toggle-quick-center"
    set_shortcut "<Super>Escape" "$EXO_BIN toggle-power-menu"
    set_shortcut "<Super>comma" "$EXO_BIN open-settings"
    set_shortcut "<Super>question" "$EXO_BIN toggle-dnd"
    set_shortcut "<Super>KP_Add" "$EXO_BIN volume-up"
    set_shortcut "<Super>KP_Subtract" "$EXO_BIN volume-down"
    set_shortcut "<Super>m" "$EXO_BIN toggle-mute"
    echo
    echo "  Note: XFCE only reads these on session start for some setups;"
    echo "        opening Settings → Keyboard shows them immediately."
fi

echo
echo "xfwm4 applies these instantly; no logout needed."
echo "If you cannot type into the launcher, check"
echo "  Settings → Window Manager Tweaks → Focus → 'Focus stealing prevention'"
echo "and make sure it is set to 'Off'."
