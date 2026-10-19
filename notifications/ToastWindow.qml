// Exo for XFCE — notification popups.
//
// A small panel window at a screen corner. Two X11 specifics are handled here:
//
//   * The window stays mapped at all times (it collapses to zero height when
//     there is nothing to show). Quickshell's X11 back end recreates the window
//     when it is mapped, and delegates created at that moment would not receive
//     their model data.
//   * The input mask is empty while no toast is visible, so clicks pass through
//     to whatever is underneath.
//
// The popups never take keyboard focus, so they cannot steal focus from the
// application you are using; inline replies are typed in the overlay surface.
import QtQuick
import Quickshell
import "../services"
import "../components"

PanelWindow {
    id: toastWindow

    property var modelData: null // ShellScreen (set by Variants)

    screen: modelData

    readonly property string position: Config.notifications.position
    readonly property bool atTop: position.indexOf("top") === 0
    readonly property int cardWidth: 360

    color: "transparent"
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore

    implicitWidth: cardWidth
    implicitHeight: content.implicitHeight

    anchors.top: atTop
    anchors.bottom: !atTop
    anchors.left: position.indexOf("left") >= 0
    anchors.right: position.indexOf("left") < 0

    margins.top: atTop ? 8 : 0
    margins.bottom: atTop ? 0 : 8
    margins.left: position.indexOf("left") >= 0 ? 8 : 0
    margins.right: position.indexOf("left") >= 0 ? 0 : 8

    mask: Region {
        x: 0
        y: 0
        width: toastWindow.width
        height: toastWindow.visibleHeight
    }
    readonly property real visibleHeight: implicitHeight

    Column {
        id: content
        width: toastWindow.cardWidth
        y: toastWindow.atTop ? 0 : Math.max(0, toastWindow.height - implicitHeight)
        spacing: 8

        Repeater {
            model: Notifs.popups.length

            delegate: Toast {
                required property int index

                width: content.width
                notification: index < Notifs.popups.length ? Notifs.popups[index] : null
            }
        }
    }
}
