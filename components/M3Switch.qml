// Material 3 switch.
import QtQuick
import "../services"

Item {
    id: root

    signal toggled()

    property bool checked: false
    property bool interactive: true

    implicitWidth: 52
    implicitHeight: 32

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.colors.primary : Theme.colors.surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Theme.colors.outline

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationMedium
            }
        }
    }

    Rectangle {
        id: thumb
        width: root.checked ? 24 : 16
        height: width
        radius: width / 2
        color: root.checked ? Theme.colors.onPrimary : Theme.colors.outline
        x: root.checked ? parent.width - width - 4 : 8
        anchors.verticalCenter: parent.verticalCenter

        Behavior on x {
            NumberAnimation {
                duration: Theme.durationMedium
                easing.type: Theme.easingEmphasized
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Theme.durationMedium
                easing.type: Theme.easingEmphasized
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Theme.durationMedium
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled();
        }
    }
}
