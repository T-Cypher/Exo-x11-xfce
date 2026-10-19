#!/bin/sh
# Exo for XFCE — give keyboard focus to the full-screen overlay surface.
#
# xfwm4 normally focuses a newly mapped window by itself. When "focus stealing
# prevention" is raised, that can be refused, and then typing in the launcher
# would go to whatever window is focused instead. Qt sets WM_CLASS from the
# application name ("quickshell"), so the overlay is the quickshell window whose
# geometry matches the screen exactly.
#
# Usage: focus-overlay.sh [tries]

TRIES="${1:-6}"

command -v xdotool >/dev/null 2>&1 || exit 0
command -v xdpyinfo >/dev/null 2>&1 || exit 0

SCREEN_W=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ { split($2, d, "x"); print d[1]; exit }')
SCREEN_H=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ { split($2, d, "x"); print d[2]; exit }')
[ -z "$SCREEN_W" ] && exit 0

i=0
while [ "$i" -lt "$TRIES" ]; do
    for win in $(xdotool search --class quickshell 2>/dev/null); do
        eval "$(xdotool getwindowgeometry --shell "$win" 2>/dev/null)"
        if [ "$WIDTH" = "$SCREEN_W" ] && [ "$HEIGHT" = "$SCREEN_H" ]; then
            xdotool windowfocus --sync "$win" 2>/dev/null && exit 0
        fi
    done
    i=$((i + 1))
    sleep 0.1
done

exit 0
