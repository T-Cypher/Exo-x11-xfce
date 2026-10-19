// Dimmed click-away layer used behind overlays.
import QtQuick
import "../services"

Rectangle {
    id: root

    signal clicked()

    color: Qt.rgba(0, 0, 0, 0.45)

    property bool active: true

    MouseArea {
        anchors.fill: parent
        enabled: root.active
        onClicked: root.clicked()
        onWheel: wheel => wheel.accepted = true
    }

    NumberAnimation on opacity {
        from: 0
        to: 1
        duration: Theme.durationMedium
        easing.type: Theme.easingStandard
    }
}
