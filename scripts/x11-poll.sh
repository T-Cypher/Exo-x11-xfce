#!/bin/sh
# Exo for XFCE — fallback X11 state poller.
#
# Emits the same protocol as bin/x11-events (the optional XCB helper) so the QML
# side does not care which one is in use:
#
#   DESKTOP <active>|<count>|<name>|<name>|...
#   ACTIVE <window-id>
#   WINDOWS <id>|<desktop>|<pid>|<wmclass>|<title>;<tab>...  (records separated by tab)
#   FULLSCREEN <0|1>
#
# Usage: x11-poll.sh [interval-ms]

INTERVAL_MS="${1:-1200}"
INTERVAL_S=$(awk "BEGIN { printf \"%.2f\", $INTERVAL_MS / 1000 }")

command -v wmctrl >/dev/null 2>&1 || {
    echo "x11-poll.sh: wmctrl is required (install it, e.g. 'sudo apt install wmctrl')" >&2
    exit 1
}

emit_desktops() {
    # wmctrl -d: "0  * DG: 1920x1080  VP: 0,0  WA: 0,40 1920x1040  Workspace 1"
    # The work-area group is optional and the desktop name may be missing, so
    # the name is whatever is left after the known prefixes are stripped.
    wmctrl -d 2>/dev/null | awk '
        BEGIN { active = 0; names = ""; count = 0 }
        {
            index0 = $1 + 0;
            if ($2 == "*") active = index0;

            line = $0;
            sub(/^[ \t]*[0-9]+[ \t]+[*+-][ \t]*/, "", line);
            sub(/^DG: [^ \t]+[ \t]*/, "", line);
            sub(/^VP: [^ \t]+[ \t]*/, "", line);
            sub(/^WA: [^ \t]+ [^ \t]+[ \t]*/, "", line);
            sub(/[ \t]+$/, "", line);

            name = line;
            if (name == "" || name == "N/A") name = "Workspace " (count + 1);

            names = names (count > 0 ? "|" : "") name;
            count++;
        }
        END { printf "DESKTOP %d|%d|%s\n", active, (count > 0 ? count : 1), names }'
}

emit_windows() {
    printf "WINDOWS "
    # -lxp is one call that gives id, desktop, pid, WM_CLASS and title.
    wmctrl -lxp 2>/dev/null | while read -r id desk pid class host rest; do
        [ -z "$id" ] && continue
        case "$pid" in ''|*[!0-9]*) pid=0 ;; esac
        [ -z "$class" ] && class="N/A"
        # Tabs and pipes would break the record format.
        title=$(printf '%s' "$rest" | tr '\t|' '  ')
        printf '%s|%s|%s|%s|%s\t' "$id" "$desk" "$pid" "$class" "$title"
    done
    printf "\n"
}

emit_active() {
    active=$(xprop -root -notype _NET_ACTIVE_WINDOW 2>/dev/null | sed 's/.*# //; s/,.*//' | tr -d ' ')
    [ -z "$active" ] && active="0x0"
    printf "ACTIVE %s\n" "$active"
}

emit_fullscreen() {
    if [ -n "$active" ] && [ "$active" != "0x0" ] && xprop -id "$active" -notype _NET_WM_STATE 2>/dev/null | grep -q _NET_WM_STATE_FULLSCREEN; then
        printf "FULLSCREEN 1\n"
    else
        printf "FULLSCREEN 0\n"
    fi
}

# xprop is optional: only the active-window and fullscreen lines need it.
HAVE_XPROP=1
command -v xprop >/dev/null 2>&1 || HAVE_XPROP=0

while true; do
    emit_desktops
    if [ "$HAVE_XPROP" -eq 1 ]; then
        emit_active
    else
        echo "ACTIVE 0x0"
    fi
    emit_windows
    if [ "$HAVE_XPROP" -eq 1 ]; then
        emit_fullscreen
    else
        echo "FULLSCREEN 0"
    fi
    sleep "$INTERVAL_S" || break
done
