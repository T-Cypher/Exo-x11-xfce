// Small pill chip (workspaces, quick toggles, launcher filters).
import QtQuick
import "../services"

Item {
    id: root

    signal clicked()
    signal middleClicked()
    signal rightClicked()

    property string icon: ""
    property string label: ""
    property bool selected: false
    property bool interactive: true
    property color selectedColour: Theme.colors.secondaryContainer
    property color selectedTextColour: Theme.colors.onSecondaryContainer

    property int maxLabelWidth: -1

    readonly property int glyphSize: Theme.moduleIconSize(Config.bar.density) + 2
    readonly property int padH: 10
    readonly property int padV: 3

    implicitWidth: content.implicitWidth + root.padH * 2
    implicitHeight: Math.max(22, content.implicitHeight + root.padV * 2)

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: height / 2
        color: root.selected ? root.selectedColour : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationShort
            }
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: root.icon.length > 0 && root.label.length > 0 ? 5 : 0

        M3Icon {
            visible: root.icon.length > 0
            name: root.icon
            iconSize: root.glyphSize
            iconColor: root.selected ? root.selectedTextColour : Theme.colors.onSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        M3Text {
            visible: root.label.length > 0
            text: root.label
            role: "label"
            textColor: root.selected ? root.selectedTextColour : Theme.colors.onSurface
            width: root.maxLabelWidth > 0 ? Math.min(implicitWidth, root.maxLabelWidth) : implicitWidth
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // M3 state layer.
    Rectangle {
        anchors.fill: parent
        radius: bg.radius
        color: root.selected ? root.selectedTextColour : Theme.colors.onSurface
        opacity: area.pressed ? 0.12 : (area.containsMouse && root.interactive ? 0.08 : 0.0)
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationShort
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                root.middleClicked();
            else if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
    }
}
