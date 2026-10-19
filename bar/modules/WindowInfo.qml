// Bar module: the focused window (title + icon).
//
// This is the X11 equivalent of Exo's window info widget: the data comes from
// EWMH (_NET_ACTIVE_WINDOW) rather than a compositor socket.
//   left click   → minimise the focused window
//   middle click → close it
//   right click  → toggle maximise
import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../services"
import "../../components"

ModuleTile {
    id: tile

    readonly property var win: X11.activeWindow
    readonly property string title: tile.win !== null ? tile.win.title : ""

    // wmctrl reports the X11 class as "instance.Class" (e.g. "xterm.XTerm"), so
    // both halves are tried against the desktop entry database.
    readonly property var entry: {
        if (tile.win === null)
            return null;
        const parts = tile.win.class.split(".");
        const candidates = [tile.win.class, parts[0], parts.length > 1 ? parts[1] : ""];
        for (let i = 0; i < candidates.length; i++) {
            if (candidates[i].length === 0)
                continue;
            const found = DesktopEntries.heuristicLookup(candidates[i]);
            if (found !== null)
                return found;
        }
        return null;
    }

    readonly property string iconSource: tile.entry !== null ? Quickshell.iconPath(tile.entry.icon, "") : ""

    visible: tile.win !== null && tile.title.length > 0
    hoverSurface: true

    onClicked: {
        if (tile.win !== null)
            X11.minimizeWindow(tile.win.id);
    }
    onMiddleClicked: {
        if (tile.win !== null)
            X11.closeWindow(tile.win.id);
    }
    onRightClicked: {
        if (tile.win !== null)
            X11.toggleMaximizeWindow(tile.win.id);
    }

    Loader {
        sourceComponent: Config.bar.vertical ? verticalComponent : horizontalComponent
    }

    Component {
        id: horizontalComponent

        Row {
            spacing: 7

            IconImage {
                visible: tile.iconSource !== ""
                source: tile.iconSource
                implicitSize: Theme.moduleIconSize(Config.bar.density)
                anchors.verticalCenter: parent.verticalCenter
            }

            M3Text {
                text: tile.title
                role: "label"
                width: Math.min(implicitWidth, Config.misc.windowInfoMaxWidth)
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Component {
        id: verticalComponent

        IconImage {
            visible: tile.iconSource !== ""
            source: tile.iconSource
            implicitSize: Theme.moduleIconSize(Config.bar.density)
        }
    }
}
