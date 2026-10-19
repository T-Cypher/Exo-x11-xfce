// Exo for XFCE — settings window.
//
// Quickshell has no floating windows on X11, so this lives in the overlay
// surface: a large centred card with a navigation rail, in the same visual
// language as Exo's own settings app (pill-shaped option groups).
import QtQuick
import Quickshell
import "../services"
import "../components"

Item {
    id: settings

    anchors.fill: parent
    focus: true

    property int tab: Surfaces.settingsTab

    readonly property var tabNames: ["Appearance", "Bar", "Modules", "Launcher", "Services", "Power", "About"]
    readonly property var tabIcons: ["palette", "toolbar", "widgets", "apps", "notifications", "power", "info"]

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            Surfaces.close();
            event.accepted = true;
        }
    }

    function zoneList(zone) {
        if (zone === "Left")
            return Config.adapter.barModulesLeft;
        if (zone === "Center")
            return Config.adapter.barModulesCenter;
        return Config.adapter.barModulesRight;
    }

    function zoneKey(zone) {
        if (zone === "Left")
            return "barModulesLeft";
        if (zone === "Center")
            return "barModulesCenter";
        return "barModulesRight";
    }

    function toggleModule(zone, name) {
        const list = settings.zoneList(zone).slice();
        const index = list.indexOf(name);
        if (index >= 0)
            list.splice(index, 1);
        else
            list.push(name);
        Config.set(settings.zoneKey(zone), list);
    }

    function moveModule(zone, name, direction) {
        const list = settings.zoneList(zone).slice();
        const index = list.indexOf(name);
        const target = index + direction;
        if (index < 0 || target < 0 || target >= list.length)
            return;
        const tmp = list[index];
        list[index] = list[target];
        list[target] = tmp;
        Config.set(settings.zoneKey(zone), list);
    }

    Scrim {
        anchors.fill: parent
        onClicked: Surfaces.close()
    }

    Rectangle {
        id: card

        property bool shown: false

        width: Math.min(settings.width - 80, 980)
        height: Math.min(settings.height - 100, 660)
        anchors.centerIn: parent
        radius: Theme.radiusXl
        color: Theme.colors.surfaceContainer

        scale: card.shown ? 1 : 0.96
        opacity: card.shown ? 1 : 0
        Component.onCompleted: card.shown = true
        Behavior on scale {
            NumberAnimation {
                duration: Theme.durationMedium
                easing.type: Theme.easingEmphasized
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationMedium
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // --------------------------------------------------------- nav rail
            Column {
                width: 180
                spacing: 4

                M3Text {
                    text: "Settings"
                    role: "headline"
                    leftPadding: 12
                    bottomPadding: 8
                }

                Repeater {
                    model: settings.tabNames

                    delegate: M3Button {
                        required property string modelData
                        required property int index

                        width: 180
                        type: settings.tab === index ? "tonal" : "text"
                        size: "s"
                        icon: settings.tabIcons[index]
                        label: modelData
                        onClicked: {
                            settings.tab = index;
                            Surfaces.settingsTab = index;
                        }
                    }
                }

                Item {
                    width: 1
                    height: 12
                }

                M3Button {
                    width: 180
                    type: "text"
                    size: "s"
                    icon: "close"
                    label: "Close"
                    onClicked: Surfaces.close()
                }
            }

            Rectangle {
                width: 1
                height: parent.height
                color: Theme.colors.outlineVariant
            }

            // ----------------------------------------------------------- content
            Flickable {
                width: parent.width - 205
                height: parent.height
                clip: true
                contentHeight: pane.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: pane
                    width: parent.width
                    spacing: 18

                    // ------------------------------------------------ Appearance
                    Column {
                        visible: settings.tab === 0
                        width: parent.width
                        spacing: 14

                        M3Text {
                            text: "Theme"
                            role: "title"
                        }

                        M3Text {
                            width: parent.width
                            text: "Colours follow matugen. Point matugen at ~/.cache/quickshell-exo/colors.json (see config/matugen.toml) to theme the shell from the wallpaper; without it, the built-in Material 3 palettes are used."
                            role: "small"
                            textColor: Theme.colors.onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        Row {
                            spacing: 8

                            Repeater {
                                model: [
                                    {
                                        "label": "Dark",
                                        "value": "dark",
                                        "icon": "dark_mode"
                                    },
                                    {
                                        "label": "Light",
                                        "value": "light",
                                        "icon": "light_mode"
                                    }
                                ]

                                delegate: M3Button {
                                    required property var modelData
                                    type: Config.theme.mode === modelData.value ? "tonal" : "outlined"
                                    size: "xs"
                                    icon: modelData.icon
                                    label: modelData.label
                                    onClicked: Config.set("themeMode", modelData.value)
                                }
                            }
                        }

                        M3Text {
                            text: "Bar density"
                            role: "label"
                        }

                        Row {
                            spacing: 8

                            Repeater {
                                model: [
                                    {
                                        "label": "Default (40px)",
                                        "value": 0
                                    },
                                    {
                                        "label": "Compact (35px)",
                                        "value": 1
                                    },
                                    {
                                        "label": "Compact+ (30px)",
                                        "value": 2
                                    },
                                    {
                                        "label": "Ultra (25px)",
                                        "value": 3
                                    }
                                ]

                                delegate: M3Button {
                                    required property var modelData
                                    type: Config.bar.density === modelData.value ? "tonal" : "outlined"
                                    size: "xs"
                                    label: modelData.label
                                    onClicked: Config.set("barDensity", modelData.value)
                                }
                            }
                        }

                        M3Text {
                            text: "Fonts"
                            role: "label"
                        }

                        Row {
                            spacing: 10

                            Column {
                                spacing: 4

                                M3Text {
                                    text: "Interface font"
                                    role: "small"
                                    textColor: Theme.colors.onSurfaceVariant
                                }

                                Rectangle {
                                    width: 220
                                    height: 36
                                    radius: Theme.radiusS
                                    color: Theme.colors.surfaceContainerHighest

                                    TextInput {
                                        id: fontInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.colors.onSurface
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeBody
                                        text: Config.theme.fontFamily
                                        clip: true
                                        onEditingFinished: Config.set("themeFontFamily", text)
                                    }
                                }
                            }

                            Column {
                                spacing: 4

                                M3Text {
                                    text: "Icon font (Material Symbols)"
                                    role: "small"
                                    textColor: Theme.colors.onSurfaceVariant
                                }

                                Rectangle {
                                    width: 260
                                    height: 36
                                    radius: Theme.radiusS
                                    color: Theme.colors.surfaceContainerHighest

                                    TextInput {
                                        id: iconFontInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.colors.onSurface
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeBody
                                        text: Config.theme.iconFont
                                        clip: true
                                        onEditingFinished: Config.set("themeIconFont", text)
                                    }
                                }
                            }
                        }
                    }

                    // ------------------------------------------------------- Bar
                    Column {
                        visible: settings.tab === 1
                        width: parent.width
                        spacing: 14

                        M3Text {
                            text: "Position"
                            role: "title"
                        }

                        Row {
                            spacing: 8

                            Repeater {
                                model: ["top", "bottom", "left", "right"]

                                delegate: M3Button {
                                    required property string modelData
                                    type: Config.bar.position === modelData ? "tonal" : "outlined"
                                    size: "xs"
                                    icon: {
                                        switch (modelData) {
                                        case "top":
                                            return "arrow_upward";
                                        case "bottom":
                                            return "arrow_downward";
                                        case "left":
                                            return "arrow_back";
                                        default:
                                            return "arrow_forward";
                                        }
                                    }
                                    label: modelData
                                    onClicked: Config.set("barPosition", modelData)
                                }
                            }
                        }

                        M3Text {
                            text: "Style"
                            role: "title"
                        }

                        Row {
                            spacing: 8

                            M3Button {
                                type: Config.bar.floating ? "tonal" : "outlined"
                                size: "xs"
                                icon: "rounded_corner"
                                label: "Floating"
                                onClicked: Config.toggle("barFloating")
                            }

                            M3Button {
                                type: Config.bar.separated ? "tonal" : "outlined"
                                size: "xs"
                                icon: "splitscreen_add"
                                label: "Separated"
                                onClicked: Config.toggle("barSeparated")
                            }

                            M3Button {
                                type: Config.bar.round ? "tonal" : "outlined"
                                size: "xs"
                                icon: "format_rounded"
                                label: "Round"
                                onClicked: Config.toggle("barRound")
                            }

                            M3Button {
                                type: Config.bar.centered ? "tonal" : "outlined"
                                size: "xs"
                                icon: "align_horizontal_center"
                                label: "Centered"
                                onClicked: Config.toggle("barCentered")
                            }
                        }

                        Row {
                            spacing: 12

                            Column {
                                spacing: 4

                                M3Text {
                                    text: "Edge margin: " + Config.bar.margin + "px"
                                    role: "label"
                                }

                                M3Slider {
                                    width: 240
                                    value: Math.min(1, Config.bar.margin / 32)
                                    onMoved: value => Config.set("barMargin", Math.round(value * 32))
                                }
                            }
                        }

                        Row {
                            spacing: 10

                            M3Switch {
                                id: autohideSwitch
                                checked: Config.bar.autoHide
                                onToggled: Config.toggle("barAutoHideFullscreen")
                            }

                            M3Text {
                                text: "Hide the bar while a fullscreen window is focused"
                                role: "label"
                                anchors.verticalCenter: autohideSwitch.verticalCenter
                            }
                        }
                    }

                    // --------------------------------------------------- Modules
                    Column {
                        visible: settings.tab === 2
                        width: parent.width
                        spacing: 16

                        M3Text {
                            text: "Bar modules"
                            role: "title"
                        }

                        M3Text {
                            width: parent.width
                            text: "Toggle a module to add or remove it from a zone. The arrows change its order; the first module sits closest to the bar's edge."
                            role: "small"
                            textColor: Theme.colors.onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        Repeater {
                            model: ["Left", "Center", "Right"]

                            delegate: Column {
                                id: zoneColumn

                                required property string modelData
                                width: pane.width
                                spacing: 8

                                M3Text {
                                    text: zoneColumn.modelData + " zone"
                                    role: "label"
                                }

                                Flow {
                                    width: parent.width
                                    spacing: 6

                                    Repeater {
                                        model: [
                                            "launcher",
                                            "workspaces",
                                            "windowInfo",
                                            "tasks",
                                            "media",
                                            "tray",
                                            "statusIcons",
                                            "battery",
                                            "clock",
                                            "quickSettings"
                                        ]

                                        delegate: Rectangle {
                                            id: moduleCard

                                            required property string modelData

                                            readonly property bool inZone: settings.zoneList(zoneColumn.modelData).indexOf(moduleCard.modelData) >= 0

                                            width: moduleRow.implicitWidth + 12
                                            height: 30
                                            radius: Theme.radiusPill
                                            color: moduleCard.inZone ? Theme.colors.secondaryContainer : Theme.colors.surfaceContainerHigh

                                            Row {
                                                id: moduleRow
                                                anchors.centerIn: parent
                                                spacing: 2

                                                M3Text {
                                                    text: moduleCard.modelData
                                                    role: "small"
                                                    textColor: moduleCard.inZone ? Theme.colors.onSecondaryContainer : Theme.colors.onSurface
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                M3Icon {
                                                    visible: moduleCard.inZone
                                                    name: "chevron_left"
                                                    iconSize: 16
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        anchors.margins: -3
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: settings.moveModule(zoneColumn.modelData, moduleCard.modelData, -1)
                                                    }
                                                }

                                                M3Icon {
                                                    visible: moduleCard.inZone
                                                    name: "chevron_right"
                                                    iconSize: 16
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        anchors.margins: -3
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: settings.moveModule(zoneColumn.modelData, moduleCard.modelData, 1)
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: settings.toggleModule(zoneColumn.modelData, moduleCard.modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // -------------------------------------------------- Launcher
                    Column {
                        visible: settings.tab === 3
                        width: parent.width
                        spacing: 14

                        M3Text {
                            text: "Launcher"
                            role: "title"
                        }

                        Row {
                            spacing: 8

                            Repeater {
                                model: [
                                    {
                                        "label": "Grid",
                                        "value": "grid",
                                        "icon": "grid_view"
                                    },
                                    {
                                        "label": "List",
                                        "value": "list",
                                        "icon": "view_list"
                                    }
                                ]

                                delegate: M3Button {
                                    required property var modelData
                                    type: Config.launcher.layout === modelData.value ? "tonal" : "outlined"
                                    size: "xs"
                                    icon: modelData.icon
                                    label: modelData.label
                                    onClicked: Config.set("launcherLayout", modelData.value)
                                }
                            }
                        }

                        M3Text {
                            text: "Grid columns: " + Config.launcher.columns
                            role: "label"
                        }

                        M3Slider {
                            width: 240
                            value: (Config.launcher.columns - 2) / 8
                            onMoved: value => Config.set("launcherColumns", Math.max(2, Math.round(2 + value * 8)))
                        }

                        M3Text {
                            text: "Terminal command for CLI applications"
                            role: "label"
                        }

                        Rectangle {
                            width: 320
                            height: 36
                            radius: Theme.radiusS
                            color: Theme.colors.surfaceContainerHighest

                            TextInput {
                                id: terminalInput
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.colors.onSurface
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeBody
                                text: Config.launcher.terminal
                                clip: true
                                onEditingFinished: Config.set("launcherTerminal", text)
                            }
                        }

                        M3Text {
                            text: "Example: kitty, alacritty --hold, xfce4-terminal -x"
                            role: "small"
                            textColor: Theme.colors.onSurfaceVariant
                        }
                    }

                    // -------------------------------------------------- Services
                    Column {
                        visible: settings.tab === 4
                        width: parent.width
                        spacing: 14

                        M3Text {
                            text: "Notifications"
                            role: "title"
                        }

                        Row {
                            spacing: 10

                            M3Switch {
                                id: notifSwitch
                                checked: Config.notifications.enabled
                                onToggled: Config.toggle("notificationsEnabled")
                            }

                            M3Text {
                                text: "Show notification popups"
                                role: "label"
                                anchors.verticalCenter: notifSwitch.verticalCenter
                            }
                        }

                        M3Text {
                            text: "Popup timeout: " + Math.round(Config.notifications.timeout / 1000) + "s"
                            role: "label"
                        }

                        M3Slider {
                            width: 240
                            value: Math.min(1, Config.notifications.timeout / 20000)
                            onMoved: value => Config.set("notificationsTimeout", Math.max(1000, Math.round(value * 20000)))
                        }

                        M3Text {
                            text: "OSD"
                            role: "title"
                        }

                        Row {
                            spacing: 10

                            M3Switch {
                                id: osdSwitch
                                checked: Config.osd.enabled
                                onToggled: Config.toggle("osdEnabled")
                            }

                            M3Text {
                                text: "Show the volume/brightness overlay"
                                role: "label"
                                anchors.verticalCenter: osdSwitch.verticalCenter
                            }

                            M3Switch {
                                id: osdVerticalSwitch
                                checked: Config.osd.vertical
                                onToggled: Config.toggle("osdVertical")
                            }

                            M3Text {
                                text: "Vertical"
                                role: "label"
                                anchors.verticalCenter: osdSwitch.verticalCenter
                            }
                        }

                        M3Text {
                            text: "X11 integration"
                            role: "title"
                        }

                        M3Text {
                            width: parent.width
                            text: "Workspaces, the focused window and the taskbar are read from EWMH through wmctrl/xprop. Compile bin/x11-events (scripts/setup.sh) for event driven updates instead of polling."
                            role: "small"
                            textColor: Theme.colors.onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        M3Text {
                            text: "Event helper: " + (X11.helperBuilt ? "active" : "not built (polling every " + Config.x11.pollInterval + " ms)")
                            role: "small"
                            textColor: X11.helperBuilt ? Theme.colors.primary : Theme.colors.onSurfaceVariant
                        }

                        M3Text {
                            text: "Detected workspaces: " + X11.desktopCount + " • Windows: " + X11.windows.length
                            role: "small"
                            textColor: Theme.colors.onSurfaceVariant
                        }
                    }

                    // ----------------------------------------------------- Power
                    Column {
                        visible: settings.tab === 5
                        width: parent.width
                        spacing: 12

                        M3Text {
                            text: "Session commands"
                            role: "title"
                        }

                        M3Text {
                            width: parent.width
                            text: "Defaults target XFCE: xflock4, xfce4-session-logout and systemctl."
                            role: "small"
                            textColor: Theme.colors.onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        Repeater {
                            model: [
                                {
                                    "label": "Lock",
                                    "key": "lockCommand",
                                    "value": Config.power.lock
                                },
                                {
                                    "label": "Log out",
                                    "key": "logoutCommand",
                                    "value": Config.power.logout
                                },
                                {
                                    "label": "Suspend",
                                    "key": "suspendCommand",
                                    "value": Config.power.suspend
                                },
                                {
                                    "label": "Restart",
                                    "key": "rebootCommand",
                                    "value": Config.power.reboot
                                },
                                {
                                    "label": "Shut down",
                                    "key": "shutdownCommand",
                                    "value": Config.power.shutdown
                                }
                            ]

                            delegate: Row {
                                required property var modelData

                                spacing: 10

                                M3Text {
                                    text: modelData.label
                                    role: "label"
                                    width: 90
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 360
                                    height: 36
                                    radius: Theme.radiusS
                                    color: Theme.colors.surfaceContainerHighest

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.colors.onSurface
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeBody
                                        text: modelData.value
                                        clip: true
                                        onEditingFinished: Config.set(modelData.key, text)
                                    }
                                }
                            }
                        }
                    }

                    // ----------------------------------------------------- About
                    Column {
                        visible: settings.tab === 6
                        width: parent.width
                        spacing: 12

                        M3Text {
                            text: "Exo for XFCE"
                            role: "headline"
                        }

                        M3Text {
                            width: parent.width
                            text: "A Material 3 desktop shell built with Quickshell, running on X11 with xfwm4. Inspired by debuggyo's Exo (Ignis/Wayland). Licensed GPL-3.0."
                            role: "small"
                            textColor: Theme.colors.onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        M3Text {
                            text: "Shell directory: " + Quickshell.shellDir
                            role: "small"
                            textColor: Theme.colors.onSurfaceVariant
                        }

                        M3Text {
                            text: "Config file: " + Quickshell.shellPath("config.json")
                            role: "small"
                            textColor: Theme.colors.onSurfaceVariant
                        }

                        Row {
                            spacing: 8

                            M3Button {
                                type: "tonal"
                                size: "xs"
                                icon: "refresh"
                                label: "Reload shell"
                                onClicked: Quickshell.reload(false)
                            }

                            M3Button {
                                type: "outlined"
                                size: "xs"
                                icon: "restart_alt"
                                label: "Hard reload"
                                onClicked: Quickshell.reload(true)
                            }

                            M3Button {
                                type: "outlined"
                                size: "xs"
                                icon: "keyboard"
                                label: "Apply XFCE shortcuts"
                                onClicked: Quickshell.execDetached(["sh", Quickshell.shellPath("scripts/xfce-integration.sh")])
                            }

                            M3Button {
                                type: "outlined"
                                size: "xs"
                                icon: "open_in_new"
                                label: "Config folder"
                                onClicked: Quickshell.execDetached(["xdg-open", Quickshell.shellDir])
                            }
                        }
                    }
                }
            }
        }
    }
}
