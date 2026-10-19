// Surface container used by the quick centre, settings and popups.
import QtQuick
import "../services"

Rectangle {
    id: root

    default property alias content: inner.data

    property int padding: 12
    property color cardColour: Theme.colors.surfaceContainer
    property bool outlined: false

    color: root.cardColour
    radius: Theme.radiusL
    border.width: root.outlined ? 1 : 0
    border.color: Theme.colors.outlineVariant
    implicitWidth: inner.childrenRect.width + root.padding * 2
    implicitHeight: inner.childrenRect.height + root.padding * 2

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
