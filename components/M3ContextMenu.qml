// In-surface context menu.
//
// Quickshell's X11 back end has no PopupWindow, so menus are rendered inside the
// overlay surface instead of as separate X windows.  Put this as the last child
// of a full-area Item and call openAt(x, y) in that item's coordinates.
pragma ComponentBehavior: Bound

import QtQuick
import "../services"

Item {
    id: root

    // [ { "label": "…", "icon": "…", "enabled": true, "separator": false, "trigger": fn } ]
    property var items: []
    property bool opened: false
    property int menuWidth: 230
    property real menuX: 0
    property real menuY: 0

    signal dismissed()

    function openAt(x, y) {
        root.menuX = x;
        root.menuY = y;
        root.opened = true;
    }

    function close() {
        if (root.opened) {
            root.opened = false;
            root.dismissed();
        }
    }

    visible: opacity > 0
    opacity: root.opened ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durationShort
        }
    }

    // Click outside closes the menu.
    MouseArea {
        anchors.fill: parent
        enabled: root.opened
        onClicked: root.close()
        onWheel: wheel => wheel.accepted = true
    }

    Rectangle {
        id: card
        width: root.menuWidth
        height: column.implicitHeight + 10
        x: Math.max(4, Math.min(root.width - width - 4, root.menuX))
        y: Math.max(4, Math.min(root.height - height - 4, root.menuY))
        radius: Theme.radiusS
        color: Theme.colors.surfaceContainerHigh
        border.width: 1
        border.color: Theme.colors.outlineVariant
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.96
        transformOrigin: Item.TopLeft

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationShort
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.durationShort
                easing.type: Theme.easingEmphasized
            }
        }

        // Swallow clicks so they do not reach the dismiss area.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: 5
            spacing: 0

            Repeater {
                model: root.items

                delegate: Item {
                    id: entry
                    required property var modelData
                    width: entry.parent ? entry.parent.width : 0
                    height: entry.modelData.separator === true ? 9 : 34

                    Rectangle {
                        visible: entry.modelData.separator === true
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: 1
                        color: Theme.colors.outlineVariant
                    }

                    Rectangle {
                        id: entryBg
                        visible: entry.modelData.separator !== true
                        anchors.fill: parent
                        radius: Theme.radiusXs
                        color: entryArea.containsMouse && entry.modelData.enabled !== false ? Theme.colors.surfaceContainerHighest : "transparent"
                    }

                    Row {
                        visible: entry.modelData.separator !== true
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        M3Icon {
                            visible: entry.modelData.icon !== undefined && entry.modelData.icon !== ""
                            name: entry.modelData.icon !== undefined ? entry.modelData.icon : ""
                            iconSize: 16
                            iconColor: entry.modelData.enabled === false ? Theme.colors.onSurfaceVariant : Theme.colors.onSurface
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        M3Text {
                            text: entry.modelData.label !== undefined ? entry.modelData.label : ""
                            role: "label"
                            textColor: entry.modelData.enabled === false ? Theme.colors.onSurfaceVariant : Theme.colors.onSurface
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: entryArea
                        visible: entry.modelData.separator !== true
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: entry.modelData.enabled !== false
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.close();
                            if (entry.modelData.trigger !== undefined)
                                entry.modelData.trigger();
                        }
                    }
                }
            }
        }
    }
}
