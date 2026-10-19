// Bar module: clock and date.
//
// Left click opens the quick centre (notifications and sliders), right click
// opens the settings window.
import QtQuick
import Quickshell
import "../../services"
import "../../components"

ModuleTile {
    id: tile

    onClicked: Surfaces.toggle("quickcenter")
    onRightClicked: Surfaces.openSettings(0)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string timeText: Config.clock.military ? Qt.formatDateTime(clock.date, "HH:mm") : Qt.formatDateTime(clock.date, "h:mm AP")
    readonly property string dateText: Qt.formatDateTime(clock.date, Config.clock.dayMonthSwapped ? "ddd dd MMM" : "ddd MMM d")

    Loader {
        sourceComponent: Config.bar.vertical ? verticalComponent : horizontalComponent
    }

    Component {
        id: horizontalComponent

        Row {
            spacing: 6

            M3Text {
                text: tile.timeText
                role: "title"
                anchors.verticalCenter: parent.verticalCenter
            }

            M3Text {
                text: "•"
                role: "label"
                textColor: Theme.colors.onSurfaceVariant
                visible: tile.dateText.length > 0
                anchors.verticalCenter: parent.verticalCenter
            }

            M3Text {
                text: tile.dateText
                role: "label"
                textColor: Theme.colors.onSurfaceVariant
                visible: Config.bar.density < 3
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // A vertical bar is only as wide as the bar is thick, so the clock stacks
    // its fields (hours / minutes / day / month) the way Exo does.
    readonly property string hours: Qt.formatDateTime(clock.date, Config.clock.military ? "HH" : "h")
    readonly property string minutes: Qt.formatDateTime(clock.date, "mm")
    readonly property string dayText: Qt.formatDateTime(clock.date, "dd")
    readonly property string monthText: Qt.formatDateTime(clock.date, "MMM")

    Component {
        id: verticalComponent

        Column {
            spacing: -3

            M3Text {
                text: Config.clock.swapVertical ? tile.hours : tile.dayText
                role: "title"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            M3Text {
                text: Config.clock.swapVertical ? tile.minutes : tile.monthText
                role: "small"
                textColor: Theme.colors.onSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }

            M3Text {
                text: Config.clock.swapVertical ? tile.dayText : tile.hours
                role: "small"
                textColor: Theme.colors.onSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }

            M3Text {
                text: Config.clock.swapVertical ? tile.monthText : tile.minutes
                role: "small"
                textColor: Theme.colors.onSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
