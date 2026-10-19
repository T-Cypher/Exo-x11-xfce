// Bar module: xfwm4 workspaces (EWMH desktops).
//
// Wayland compositor modules query their compositor over IPC; on X11 the
// desktops come from X11.qml (wmctrl) and a click calls `wmctrl -s N`, so this
// behaves exactly like the workspace switcher in the XFCE panel.
import QtQuick
import Quickshell
import "../../services"
import "../../components"

ModuleTile {
    id: tile

    visible: X11.desktopCount > 1
    hoverSurface: true

    Loader {
        sourceComponent: Config.bar.vertical ? verticalComponent : horizontalComponent
    }

    Component {
        id: horizontalComponent

        Row {
            spacing: 3

            Repeater {
                model: X11.desktopModel

                delegate: M3Chip {
                    required property var modelData

                    label: String(modelData.index + 1)
                    selected: X11.activeDesktop === modelData.index
                    onClicked: X11.switchDesktop(modelData.index)
                }
            }
        }
    }

    Component {
        id: verticalComponent

        Column {
            spacing: 3

            Repeater {
                model: X11.desktopModel

                delegate: M3Chip {
                    required property var modelData

                    label: String(modelData.index + 1)
                    selected: X11.activeDesktop === modelData.index
                    onClicked: X11.switchDesktop(modelData.index)
                }
            }
        }
    }
}
