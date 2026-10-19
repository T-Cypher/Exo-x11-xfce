// Exo for XFCE — pinned launcher entries (persisted in state.json).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: pinned

    FileView {
        id: file
        path: Quickshell.shellPath("state.json")
        onLoadFailed: Qt.callLater(() => file.writeAdapter())
        onAdapterUpdated: Qt.callLater(() => file.writeAdapter())

        adapter: JsonAdapter {
            id: a
            property list<string> pinned: []
            property string brightnessDevice: ""
        }
    }

    readonly property var ids: a.pinned

    readonly property var entries: {
        const out = [];
        for (let i = 0; i < a.pinned.length; i++) {
            const entry = DesktopEntries.byId(a.pinned[i]);
            if (entry)
                out.push(entry);
        }
        return out;
    }

    function isPinned(id) {
        return a.pinned.indexOf(id) >= 0;
    }

    function toggle(id) {
        const list = a.pinned.slice();
        const index = list.indexOf(id);
        if (index >= 0)
            list.splice(index, 1);
        else
            list.push(id);
        a.pinned = list;
        Qt.callLater(() => file.writeAdapter());
    }

    readonly property string rememberedBrightnessDevice: a.brightnessDevice

    function rememberBrightnessDevice(name) {
        if (a.brightnessDevice === name)
            return;
        a.brightnessDevice = name;
        Qt.callLater(() => file.writeAdapter());
    }
}
