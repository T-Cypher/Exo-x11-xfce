// Exo for XFCE — volume / brightness OSD.
import QtQuick
import Quickshell
import "../services"
import "../components"

PanelWindow {
    id: osdWindow

    property var modelData: null // ShellScreen (set by Variants)

    screen: modelData

    readonly property string anchorPoint: Config.osd.anchor
    readonly property bool vertical: Config.osd.vertical

    color: "transparent"
    focusable: false
    aboveWindows: true
    visible: Config.osd.enabled && Osd.shown
    exclusionMode: ExclusionMode.Ignore

    implicitWidth: vertical ? 64 : 260
    implicitHeight: vertical ? 260 : 64

    anchors.top: anchorPoint === "top" || anchorPoint === "top-left" || anchorPoint === "top-right"
    anchors.bottom: anchorPoint === "bottom" || anchorPoint === "bottom-left" || anchorPoint === "bottom-right"
    anchors.left: anchorPoint === "left" || anchorPoint === "top-left" || anchorPoint === "bottom-left"
    anchors.right: anchorPoint === "right" || anchorPoint === "top-right" || anchorPoint === "bottom-right"

    margins.top: anchors.top ? 32 : 0
    margins.bottom: anchors.bottom ? 32 : 0
    margins.left: anchors.left ? 32 : 0
    margins.right: anchors.right ? 32 : 0

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.colors.surfaceContainer
        border.width: 1
        border.color: Theme.withAlpha(Theme.colors.outlineVariant, 0.5)

        opacity: Osd.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationMedium
            }
        }

        // Horizontal: icon + progress bar; vertical: bar then icon.
        Row {
            visible: !osdWindow.vertical
            anchors.centerIn: parent
            spacing: 12

            M3Icon {
                name: Osd.icon
                iconSize: 22
                anchors.verticalCenter: parent.verticalCenter
            }

            M3Slider {
                width: osdWindow.width - 90
                thickness: 12
                showHandle: false
                value: Osd.value
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Column {
            visible: osdWindow.vertical
            anchors.centerIn: parent
            spacing: 12

            M3Slider {
                height: osdWindow.height - 96
                thickness: 12
                showHandle: false
                vertical: true
                value: Osd.value
                anchors.horizontalCenter: parent.horizontalCenter
            }

            M3Icon {
                name: Osd.icon
                iconSize: 22
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
