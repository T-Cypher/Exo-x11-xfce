// Material 3 slider (used by the quick centre and the OSD).
//
// Hand-rolled rather than QtQuick.Controls so the look matches Exo exactly and
// no control styling has to be fought with under X11.
import QtQuick
import "../services"

Item {
    id: root

    signal moved(real value)

    property real value: 0.5
    property bool vertical: false
    property bool showHandle: true
    property color activeColour: Theme.colors.primary
    property color inactiveColour: Theme.colors.surfaceContainerHighest
    property int thickness: 16

    readonly property real handleSize: 20
    readonly property real clamped: Math.max(0, Math.min(1, root.value))

    implicitHeight: root.vertical ? 200 : (root.showHandle ? root.handleSize + 8 : root.thickness)
    implicitWidth: root.vertical ? (root.showHandle ? root.handleSize + 8 : root.thickness) : 200

    Rectangle {
        id: track
        anchors.centerIn: parent
        width: root.vertical ? root.thickness : parent.width
        height: root.vertical ? parent.height : root.thickness
        radius: root.thickness / 2
        color: root.inactiveColour
    }

    Rectangle {
        id: activeTrack
        radius: root.thickness / 2
        color: root.activeColour
        width: root.vertical ? root.thickness : Math.max(root.thickness, track.width * root.clamped)
        height: root.vertical ? Math.max(root.thickness, track.height * root.clamped) : root.thickness
        x: track.x + (track.width - width) / 2
        y: root.vertical ? track.y + track.height - height : track.y + (track.height - height) / 2

        Behavior on width {
            enabled: !area.pressed && !root.vertical
            NumberAnimation {
                duration: Theme.durationShort
            }
        }
        Behavior on height {
            enabled: !area.pressed && root.vertical
            NumberAnimation {
                duration: Theme.durationShort
            }
        }
    }

    Rectangle {
        id: handle
        visible: root.showHandle
        width: root.handleSize
        height: root.handleSize
        radius: root.handleSize / 2
        color: Theme.colors.surfaceContainerHighest
        border.width: 3
        border.color: root.activeColour
        x: root.vertical ? track.x + track.width / 2 - width / 2 : Math.max(0, Math.min(track.width - width, track.width * root.clamped - width / 2)) + track.x
        y: root.vertical ? track.y + Math.max(0, Math.min(track.height - height, track.height * (1 - root.clamped) - height / 2)) : track.y + track.height / 2 - height / 2
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        preventStealing: true
        onPressed: mouse => root.update(mouse)
        onPositionChanged: mouse => {
            if (area.pressed)
                root.update(mouse);
        }
        onWheel: wheel => {
            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.value = Math.max(0, Math.min(1, root.clamped + delta));
            root.moved(root.value);
        }
    }

    function update(mouse) {
        const inside = track.mapFromItem(root, mouse.x, mouse.y);
        const ratio = root.vertical ? (track.height - inside.y) / track.height : inside.x / track.width;
        root.value = Math.max(0, Math.min(1, ratio));
        root.moved(root.value);
    }
}
