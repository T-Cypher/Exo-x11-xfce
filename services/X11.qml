// Exo for XFCE — X11 / xfwm4 integration.
//
// Wayland shells talk to their compositor over a socket; under X11 the
// equivalent source of truth is EWMH, read here through `wmctrl` and `xprop`.
//
// Two interchangeable back ends feed the same event lines:
//
//   * bin/x11-events — a small XCB client (scripts/x11-events.c, built by
//     scripts/setup.sh) that reacts instantly to window manager changes.
//   * scripts/x11-poll.sh — a wmctrl/xprop polling loop used automatically
//     when the helper is not built, so nothing beyond wmctrl + x11-utils is
//     strictly required.
//
// Event lines: see scripts/x11-poll.sh.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: x11

    property bool helperBuilt: false

    // ------------------------------------------------------------------ state
    property int activeDesktop: 0
    property int desktopCount: 1
    property var desktopNames: []
    property string activeWindowId: "0x0"
    property bool fullscreenWindow: false
    // [ { "id": "0x03400007", "desktop": 0, "class": "firefox", "title": "…" } ]
    property var windows: []
    // Ids of the shell's own toplevels (bar, overlay, OSD, toasts).  They are
    // kept out of `windows` so the task list never shows the shell itself.
    property var selfWindowIds: []
    // Recently focused external windows, newest first: while one of our own
    // surfaces holds the keyboard the bar keeps showing the app that had focus
    // instead of blanking out.
    property var recentExternalIds: []

    // The shell's own surfaces carry no WM_CLASS, so they are recognised by
    // _NET_WM_PID; the class test is kept as a fallback for odd toolkits.
    function isSelfClass(cls) {
        return String(cls).toLowerCase().indexOf("quickshell") >= 0;
    }

    function isSelfPid(pid) {
        const value = parseInt(pid);
        return !isNaN(value) && value > 0 && value === Quickshell.processId;
    }

    readonly property bool shellHasFocus: {
        if (selfWindowIds.indexOf(activeWindowId) >= 0)
            return true;
        const list = windows;
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === activeWindowId)
                return isSelfClass(list[i].class) || isSelfPid(list[i].pid);
        }
        return false;
    }

    readonly property var activeWindow: {
        const list = windows;
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === activeWindowId && !isSelfClass(list[i].class)
                    && !isSelfPid(list[i].pid))
                return list[i];
        }
        if (shellHasFocus) {
            for (let r = 0; r < recentExternalIds.length; r++) {
                for (let i = 0; i < list.length; i++) {
                    if (list[i].id === recentExternalIds[r])
                        return list[i];
                }
            }
        }
        return null;
    }

    readonly property var desktopModel: {
        const out = [];
        for (let i = 0; i < desktopCount; i++) {
            out.push({
                "index": i,
                "name": i < desktopNames.length ? desktopNames[i] : "Desktop " + (i + 1)
            });
        }
        return out;
    }

    // ------------------------------------------------------------- event input
    Process {
        id: events
        running: true
        command: x11.command()

        stdout: SplitParser {
            onRead: data => x11.handleLine(data)
        }
    }

    Component.onCompleted: helperCheck.running = true

    Process {
        id: helperCheck
        running: false
        command: ["sh", "-c", "test -x \"$1\" && echo yes", "sh", Quickshell.shellPath("bin/x11-events")]
        stdout: SplitParser {
            onRead: data => x11.helperBuilt = data.trim() === "yes" && Config.x11.eventHelper
        }
    }

    onHelperBuiltChanged: {
        events.running = false;
        events.running = true;
    }

    function command() {
        if (helperBuilt)
            return [Quickshell.shellPath("bin/x11-events")];
        return ["sh", Quickshell.shellPath("scripts/x11-poll.sh"), String(Config.x11.pollInterval)];
    }

    // wmctrl prints "0x00a0000c" while xprop prints "0xa0000c", so ids have to
    // be normalised before they can be compared.
    function normalizeId(id) {
        let value = String(id).toLowerCase().trim();
        if (value.indexOf("0x") === 0) {
            value = "0x" + value.substring(2).replace(/^0+/, "");
            if (value === "0x")
                value = "0x0";
        }
        return value;
    }

    function handleLine(line) {
        if (!line)
            return;

        if (line.startsWith("DESKTOP ")) {
            const parts = line.substring(8).split("|");
            const active = parseInt(parts[0]);
            const count = parseInt(parts[1]);
            x11.activeDesktop = isNaN(active) ? 0 : active;
            x11.desktopCount = isNaN(count) || count < 1 ? 1 : count;
            x11.desktopNames = parts.slice(2).filter(n => n !== "");
            return;
        }

        if (line.startsWith("ACTIVE ")) {
            const id = x11.normalizeId(line.substring(7));
            x11.activeWindowId = id;
            if (id !== "0x0" && x11.selfWindowIds.indexOf(id) < 0 && !x11.ownerIsSelf(id)) {
                x11.recentExternalIds = [id].concat(x11.recentExternalIds.filter(v => v !== id)).slice(0, 8);
            }
            return;
        }

        if (line.startsWith("WINDOWS ")) {
            const raw = line.substring(8);
            const out = [];
            const records = raw.split("\t");
            for (let i = 0; i < records.length; i++) {
                const rec = records[i];
                if (rec.trim().length === 0)
                    continue;
                const f = rec.split("|");
                out.push({
                    "id": x11.normalizeId(f[0]),
                    "desktop": parseInt(f[1]) || 0,
                    "pid": parseInt(f[2]) || 0,
                    "class": f[3] || "",
                    "title": f.length > 4 ? f.slice(4).join("|") : ""
                });
            }
            // Split the shell's own windows out of the task list.
            const external = [];
            const selfIds = [];
            for (let i = 0; i < out.length; i++) {
                if (x11.isSelfClass(out[i].class) || x11.isSelfPid(out[i].pid))
                    selfIds.push(out[i].id);
                else
                    external.push(out[i]);
            }
            x11.selfWindowIds = selfIds;
            x11.windows = external;
            return;
        }

        if (line.startsWith("FULLSCREEN ")) {
            x11.fullscreenWindow = line.substring(11).trim() === "1";
        }
    }

    // ---------------------------------------------------------------- controls
    function switchDesktop(index) {
        if (index < 0 || index >= desktopCount)
            return;
        Quickshell.execDetached(["wmctrl", "-s", String(index)]);
    }

    function activateWindow(id) {
        if (!id)
            return;
        Quickshell.execDetached(["wmctrl", "-i", "-a", id]);
    }

    function closeWindow(id) {
        if (!id)
            return;
        Quickshell.execDetached(["wmctrl", "-i", "-c", id]);
    }

    function toggleMaximizeWindow(id) {
        if (!id)
            return;
        Quickshell.execDetached(["wmctrl", "-i", "-r", id, "-b", "toggle,maximized_vert,maximized_horz"]);
    }

    function minimizeWindow(id) {
        if (!id)
            return;
        Quickshell.execDetached(["wmctrl", "-i", "-r", id, "-b", "add,hidden"]);
    }

    function toggleFullscreenWindow(id) {
        if (!id)
            return;
        Quickshell.execDetached(["wmctrl", "-i", "-r", id, "-b", "toggle,fullscreen"]);
    }

    // Shell surfaces are identified by WM_CLASS (Qt sets it to the application
    // name), used to avoid dismissing an overlay when its own surface is the
    // window that took focus.
    function isOwnWindow(id) {
        if (!id)
            return false;
        return selfWindowIds.indexOf(normalizeId(id)) >= 0 || ownerIsSelf(normalizeId(id));
    }

    // Same question, but answered from the raw window list: needed right after an
    // overlay maps, before the refreshed list has been parsed.
    function ownerIsSelf(id) {
        const list = windows;
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === id)
                return isSelfClass(list[i].class) || isSelfPid(list[i].pid);
        }
        return false;
    }

    // Ask xfwm4 to give keyboard focus to a shell surface. Qt maps its windows
    // without a title, so match the full-screen sized quickshell window.
    function focusShellSurface() {
        Quickshell.execDetached(["sh", Quickshell.shellPath("scripts/focus-overlay.sh")]);
    }
}
