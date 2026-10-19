// One of the bar's three zones (left / centre / right).
//
// The zone lays its modules out in a Row for horizontal bars and a Column for
// vertical ones, loading each module by name from the configuration.
import QtQuick
import Quickshell
import "../services"
import "../components"

Item {
    id: zone

    property var names: []
    property bool vertical: false
    property bool separated: false
    property bool floating: false
    property bool round: false
    property int thickness: 40

    // Modules draw their own hover surface, so separated groups only need a
    // small inset.
    readonly property int groupPad: zone.separated ? 2 : 0

    implicitWidth: (loader.item ? loader.item.implicitWidth : 0) + zone.groupPad * 2
    implicitHeight: (loader.item ? loader.item.implicitHeight : 0) + zone.groupPad * 2

    function moduleUrl(name) {
        switch (name) {
        case "launcher":
            return "modules/LauncherButton.qml";
        case "clock":
            return "modules/Clock.qml";
        case "workspaces":
            return "modules/Workspaces.qml";
        case "tasks":
            return "modules/Tasks.qml";
        case "windowInfo":
            return "modules/WindowInfo.qml";
        case "media":
            return "modules/Media.qml";
        case "statusIcons":
            return "modules/StatusIcons.qml";
        case "tray":
            return "modules/Tray.qml";
        case "battery":
            return "modules/Battery.qml";
        case "quickSettings":
            return "modules/QuickSettings.qml";
        default:
            console.warn("exo: unknown bar module '" + name + "'");
            return "";
        }
    }

    // Exo's "separated" bar style draws each group as its own pill.
    Rectangle {
        visible: zone.separated
        anchors.fill: parent
        color: Theme.colors.surface
        radius: zone.floating ? height / 2 : (zone.round ? Theme.radiusL : Theme.moduleRadius(Config.bar.density))
        border.width: 1
        border.color: Theme.withAlpha(Theme.colors.outlineVariant, 0.5)
    }

    Loader {
        id: loader
        x: zone.groupPad
        y: zone.groupPad
        sourceComponent: zone.vertical ? columnComponent : rowComponent
    }

    Component {
        id: rowComponent

        Row {
            spacing: 4

            Repeater {
                model: zone.names

                delegate: Loader {
                    required property string modelData
                    source: zone.moduleUrl(modelData)
                }
            }
        }
    }

    Component {
        id: columnComponent

        Column {
            spacing: 3

            Repeater {
                model: zone.names

                delegate: Loader {
                    required property string modelData
                    source: zone.moduleUrl(modelData)
                }
            }
        }
    }
}
