// Bar module: StatusNotifierItem system tray.
//
// Menu handling deserves a note: Quickshell's platform menus are backed by real
// QMenus, which xfwm4 manages like any other override-redirect popup, so the
// usual QsMenuAnchor path works on X11.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../services"
import "../../components"

ModuleTile {
    id: tile

    readonly property var trayItems: SystemTray.items.values

    visible: tile.trayItems.length > 0
    hoverSurface: true

    Row {
        spacing: 4

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayEntry

                required property SystemTrayItem modelData

                width: Theme.moduleIconSize(Config.bar.density) + 6
                height: width

                IconImage {
                    anchors.fill: parent
                    source: trayEntry.modelData.icon
                    implicitSize: width
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            trayEntry.modelData.activate();
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayEntry.modelData.secondaryActivate();
                        } else if (trayEntry.modelData.hasMenu) {
                            trayMenu.targetItem = trayEntry;
                            trayMenu.menu = trayEntry.modelData.menu;
                            trayMenu.open();
                        }
                    }
                    onWheel: wheel => trayEntry.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }

    // One shared anchor, moved to whichever item was right clicked.
    QsMenuAnchor {
        id: trayMenu

        property Item targetItem: null

        menu: null
        anchor.window: Surfaces.barWindow
        anchor.rect.x: trayMenu.targetItem !== null ? trayMenu.targetItem.mapToItem(null, 0, 0).x : 0
        anchor.rect.y: trayMenu.targetItem !== null ? trayMenu.targetItem.mapToItem(null, 0, 0).y + trayMenu.targetItem.height : 0

        onClosed: trayMenu.menu = null
    }
}
