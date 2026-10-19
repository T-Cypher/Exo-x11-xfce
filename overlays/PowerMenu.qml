// Exo for XFCE — power menu.
//
// Destructive actions ask for a second click (the button turns red for a few
// seconds), and every command is configurable in config.json so XFCE users can
// swap xflock4 / xfce4-session-logout for whatever they prefer.
import QtQuick
import Quickshell
import "../services"
import "../components"

Item {
    id: powerMenu

    anchors.fill: parent
    focus: true

    property string pendingAction: ""

    readonly property var actions: [
        {
            "key": "lock",
            "icon": "lock",
            "label": "Lock",
            "command": Config.power.lock,
            "confirm": false
        },
        {
            "key": "logout",
            "icon": "logout",
            "label": "Log out",
            "command": Config.power.logout,
            "confirm": true
        },
        {
            "key": "suspend",
            "icon": "bedtime",
            "label": "Suspend",
            "command": Config.power.suspend,
            "confirm": false
        },
        {
            "key": "reboot",
            "icon": "restart_alt",
            "label": "Restart",
            "command": Config.power.reboot,
            "confirm": true
        },
        {
            "key": "shutdown",
            "icon": "power_settings_new",
            "label": "Shut down",
            "command": Config.power.shutdown,
            "confirm": true
        }
    ]

    Timer {
        id: pendingReset
        interval: 4000
        onTriggered: powerMenu.pendingAction = ""
    }

    function activate(action) {
        if (action.confirm && powerMenu.pendingAction !== action.key) {
            powerMenu.pendingAction = action.key;
            pendingReset.restart();
            return;
        }
        Surfaces.close();
        Quickshell.execDetached(["sh", "-c", action.command]);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            Surfaces.close();
            event.accepted = true;
        }
    }

    Scrim {
        anchors.fill: parent
        onClicked: Surfaces.close()
    }

    Rectangle {
        id: card

        property bool shown: false

        width: Math.min(powerMenu.width - 80, 640)
        height: 190
        anchors.centerIn: parent
        radius: Theme.radiusXl
        color: Theme.colors.surfaceContainer

        scale: card.shown ? 1 : 0.94
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

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            M3Text {
                text: powerMenu.pendingAction !== "" ? "Click again to confirm" : "Session"
                role: "headline"
                textColor: powerMenu.pendingAction !== "" ? Theme.colors.error : Theme.colors.onSurface
            }

            Row {
                spacing: 10
                width: parent.width

                Repeater {
                    model: powerMenu.actions

                    delegate: Rectangle {
                        required property var modelData

                        readonly property bool pending: powerMenu.pendingAction === modelData.key

                        width: Math.floor((parent.width - 40) / 5)
                        height: 96
                        radius: Theme.radiusL
                        color: pending ? Theme.colors.errorContainer : (area.containsMouse ? Theme.colors.surfaceContainerHighest : Theme.colors.surfaceContainerHigh)

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationShort
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            M3Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                name: modelData.icon
                                iconSize: 26
                                iconColor: pending ? Theme.colors.onErrorContainer : Theme.colors.primary
                            }

                            M3Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: pending ? "Confirm" : modelData.label
                                role: "label"
                                textColor: pending ? Theme.colors.onErrorContainer : Theme.colors.onSurface
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: powerMenu.activate(modelData)
                        }
                    }
                }
            }

            Row {
                spacing: 8

                M3Text {
                    text: powerMenu.pendingAction !== "" ? "Press Escape to cancel" : ""
                    role: "small"
                    textColor: Theme.colors.onSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
