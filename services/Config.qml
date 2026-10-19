// Exo for XFCE — user configuration.
//
// All settings live in one flat JSON file (see config/config.example.json).
// The file is created with defaults on first run and rewritten whenever a
// setting changes, either from the Settings UI or over IPC.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: config

    readonly property string home: Quickshell.env("HOME") ? Quickshell.env("HOME") : "/home"
    readonly property string xdgConfig: Quickshell.env("XDG_CONFIG_HOME") ? Quickshell.env("XDG_CONFIG_HOME") : (config.home + "/.config")
    readonly property string xdgCache: Quickshell.env("XDG_CACHE_HOME") ? Quickshell.env("XDG_CACHE_HOME") : (config.home + "/.cache")
    readonly property string xdgState: Quickshell.env("XDG_STATE_HOME") ? Quickshell.env("XDG_STATE_HOME") : (config.home + "/.local/state")

    readonly property string defaultColorsPath: config.xdgCache + "/quickshell-exo/colors.json"

    FileView {
        id: file
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()
        // No config yet: write the defaults so the user has a file to edit.
        onLoadFailed: Qt.callLater(() => file.writeAdapter())
        onAdapterUpdated: Qt.callLater(() => file.writeAdapter())

        adapter: JsonAdapter {
            id: a

            // -------------------------------------------------------------------- bar
            property string barPosition: "top" // top | bottom | left | right
            property bool barFloating: false
            property bool barSeparated: false
            property bool barCentered: false
            property bool barRound: false
            property bool barVertical: false
            property bool barAutoHideFullscreen: false
            property int barDensity: 0 // 0..3 -> 40/35/30/25 px
            property int barMargin: 4
            property list<string> barModulesLeft: ["launcher", "workspaces", "windowInfo"]
            property list<string> barModulesCenter: ["clock"]
            property list<string> barModulesRight: ["media", "statusIcons", "tray", "battery", "quickSettings"]

            // --------------------------------------------------------------- launcher
            property int launcherColumns: 5
            property string launcherLayout: "grid" // grid | list
            property string launcherTerminal: "kitty"
            property int launcherMaxResults: 60

            // ------------------------------------------------------------------ clock
            property bool clockMilitary: false
            property bool clockDayMonthSwapped: false
            property bool clockSwapVertical: true

            // ----------------------------------------------------------- quick center
            property bool quickShowVolume: true
            property bool quickShowBrightness: true
            property bool quickShowToggles: true
            property int quickWidth: 400

            // -------------------------------------------------------------------- osd
            property bool osdEnabled: true
            property int osdTimeout: 2000
            property string osdAnchor: "center" // center | top | bottom | left | right | top-left | …
            property bool osdVertical: false

            // ---------------------------------------------------------- notifications
            property bool notificationsEnabled: true
            property int notificationsTimeout: 5000
            property string notificationsPosition: "top-right"
            property int notificationsMaxVisible: 3

            // ------------------------------------------------------------------ theme
            property string themeMode: "dark" // dark | light
            property string themeColorsPath: ""
            property string themeIconFont: "Material Symbols Rounded"
            property string themeFontFamily: "Inter"

            // -------------------------------------------------------------- x11 extra
            property int x11PollInterval: 1200
            property bool x11EventHelper: true

            // --------------------------------------------------------------- services
            property bool showBattery: true
            property string batteryDevice: ""
            property string brightnessDevice: ""
            property int windowInfoMaxWidth: 320

            // ------------------------------------------------------------- power menu
            property string lockCommand: "xflock4"
            property string logoutCommand: "xfce4-session-logout --logout"
            property string suspendCommand: "systemctl suspend"
            property string rebootCommand: "systemctl reboot"
            property string shutdownCommand: "systemctl poweroff"
        }
    }

    readonly property var adapter: file.adapter

    // Reactive grouped views so QML can bind to e.g. `Config.bar.position`.
    readonly property var bar: ({
            "position": a.barPosition,
            "floating": a.barFloating,
            "separated": a.barSeparated,
            "centered": a.barCentered,
            "round": a.barRound,
            "vertical": a.barVertical || a.barPosition === "left" || a.barPosition === "right",
            "autoHide": a.barAutoHideFullscreen,
            "density": a.barDensity,
            "margin": a.barMargin,
            "modulesLeft": a.barModulesLeft,
            "modulesCenter": a.barModulesCenter,
            "modulesRight": a.barModulesRight
        })

    readonly property var launcher: ({
            "columns": a.launcherColumns,
            "layout": a.launcherLayout,
            "terminal": a.launcherTerminal,
            "maxResults": a.launcherMaxResults
        })

    readonly property var clock: ({
            "military": a.clockMilitary,
            "dayMonthSwapped": a.clockDayMonthSwapped,
            "swapVertical": a.clockSwapVertical
        })

    readonly property var quick: ({
            "showVolume": a.quickShowVolume,
            "showBrightness": a.quickShowBrightness,
            "showToggles": a.quickShowToggles,
            "width": a.quickWidth
        })

    readonly property var osd: ({
            "enabled": a.osdEnabled,
            "timeout": a.osdTimeout,
            "anchor": a.osdAnchor,
            "vertical": a.osdVertical
        })

    readonly property var notifications: ({
            "enabled": a.notificationsEnabled,
            "timeout": a.notificationsTimeout,
            "position": a.notificationsPosition,
            "maxVisible": a.notificationsMaxVisible
        })

    readonly property var theme: ({
            "mode": a.themeMode,
            "colorsPath": a.themeColorsPath.length > 0 ? a.themeColorsPath : config.defaultColorsPath,
            "iconFont": a.themeIconFont,
            "fontFamily": a.themeFontFamily
        })

    readonly property var x11: ({
            "pollInterval": a.x11PollInterval,
            "eventHelper": a.x11EventHelper
        })

    readonly property var misc: ({
            "showBattery": a.showBattery,
            "batteryDevice": a.batteryDevice,
            "brightnessDevice": a.brightnessDevice,
            "windowInfoMaxWidth": a.windowInfoMaxWidth
        })

    readonly property var power: ({
            "lock": a.lockCommand,
            "logout": a.logoutCommand,
            "suspend": a.suspendCommand,
            "reboot": a.rebootCommand,
            "shutdown": a.shutdownCommand
        })

    // ------------------------------------------------------------------ writing
    function set(key, value) {
        if (a[key] === value)
            return;
        a[key] = value;
        Qt.callLater(() => file.writeAdapter());
    }

    function toggle(key) {
        set(key, !a[key]);
    }

    function reload() {
        file.reload();
    }
}
