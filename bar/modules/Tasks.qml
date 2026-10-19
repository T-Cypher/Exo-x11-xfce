// Bar module: taskbar (every window on the current workspace).
//
// Off by default in config.json — many XFCE users keep the panel for this — but
// it makes Exo a complete panel replacement if you want one.
//   left click   → activate window
//   middle click → close window
//   right click  → toggle maximise
import QtQuick
import Quickshell
import "../../services"
import "../../components"

ModuleTile {
    id: tile

    readonly property var tasks: {
        const out = [];
        const list = X11.windows;
        for (let i = 0; i < list.length; i++) {
            if (list[i].desktop === X11.activeDesktop || list[i].desktop === -1)
                out.push(list[i]);
        }
        return out.slice(0, 12);
    }

    visible: tile.tasks.length > 0

    Loader {
        sourceComponent: Config.bar.vertical ? verticalComponent : horizontalComponent
    }

    Component {
        id: horizontalComponent

        Row {
            spacing: 4

            Repeater {
                model: tile.tasks

                delegate: M3Chip {
                    required property var modelData

                    label: modelData.title.length > 0 ? modelData.title : modelData.class
                    maxLabelWidth: 160
                    selected: modelData.id === X11.activeWindowId
                    onClicked: X11.activateWindow(modelData.id)
                    onMiddleClicked: X11.closeWindow(modelData.id)
                    onRightClicked: X11.toggleMaximizeWindow(modelData.id)
                }
            }
        }
    }

    Component {
        id: verticalComponent

        Column {
            spacing: 3

            Repeater {
                model: tile.tasks

                delegate: M3Chip {
                    required property var modelData

                    label: modelData.class.split(".")[0].substring(0, 2)
                    selected: modelData.id === X11.activeWindowId
                    onClicked: X11.activateWindow(modelData.id)
                }
            }
        }
    }
}
