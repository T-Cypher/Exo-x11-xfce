// Wrapper for every bar module: padding, hover surface and input handling that
// follow the bar density from the configuration.
//
// The MouseArea is declared *before* the content item on purpose, so that
// interactive widgets inside a module (buttons, tray icons) sit on top of it.
import QtQuick
import "../services"

Item {
    id: root

    default property alias content: inner.data

    property bool interactive: true
    property bool selected: false
    property bool hoverSurface: true
    property bool vertical: false
    property int hPadding: Theme.modulePadding(Config.bar.density)
    property int vPadding: Math.max(2, Theme.modulePadding(Config.bar.density) - 3)

    readonly property alias hovered: area.containsMouse
    readonly property alias pressed: area.pressed

    signal clicked()
    signal middleClicked()
    signal rightClicked()
    signal scrolled(int delta)

    // The tile sizes itself from its single visual child. Modules with a
    // different layout per bar orientation use a Loader, which forwards the
    // size of whichever component is active — sizing from childrenRect would
    // wrongly include the unused (hidden) variant.
    readonly property Item item: inner.children.length > 0 ? inner.children[0] : null

    implicitWidth: item ? item.implicitWidth + root.hPadding * 2 : 0
    implicitHeight: item ? item.implicitHeight + root.vPadding * 2 : 0

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.moduleRadius(Config.bar.density)
        color: root.hoverSurface && (area.containsMouse || root.selected) ? Theme.colors.surfaceContainerHigh : "transparent"
        Behavior on color {
            ColorAnimation {
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
        onWheel: wheel => {
            root.scrolled(wheel.angleDelta.y);
            wheel.accepted = true;
        }
    }

    Item {
        id: inner
        x: root.hPadding
        y: root.vPadding
    }
}
