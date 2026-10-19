// Exo for XFCE — the panel bar.
//
// One PanelWindow per screen. On X11 a PanelWindow becomes an EWMH dock window
// and `exclusiveZone` is translated into _NET_WM_STRUT(_PARTIAL), which is how
// xfwm4 keeps maximised windows out of the bar.
import QtQuick
import Quickshell
import "../services"
import "../components"

PanelWindow {
    id: bar

    property var modelData: null // ShellScreen (set by Variants)

    screen: modelData

    readonly property var cfg: Config.bar
    readonly property bool vertical: cfg.vertical
    readonly property int density: cfg.density
    readonly property int thickness: Theme.barHeight(density)
    readonly property bool floating: cfg.floating
    readonly property bool separated: cfg.separated
    readonly property bool round: cfg.round
    readonly property bool centered: cfg.centered
    readonly property int edgeMargin: floating ? cfg.margin : 0
    readonly property bool autoHidden: cfg.autoHide && X11.fullscreenWindow
    readonly property int padding: Theme.barPadding(density)

    color: "transparent"
    focusable: false
    aboveWindows: true
    visible: !autoHidden
    Component.onCompleted: Surfaces.barWindow = bar
    Component.onDestruction: {
        if (Surfaces.barWindow === bar)
            Surfaces.barWindow = null;
    }
    // Reserve screen space for the bar unless it is hidden or floating.
    exclusiveZone: autoHidden ? 0 : thickness + (floating ? cfg.margin : 0)

    anchors.top: cfg.position === "top"
    anchors.bottom: cfg.position === "bottom"
    anchors.left: !centered && cfg.position !== "right"
    anchors.right: !centered && cfg.position !== "left"

    margins.top: cfg.position === "top" ? edgeMargin : 0
    margins.bottom: cfg.position === "bottom" ? edgeMargin : 0
    margins.left: !centered && cfg.position !== "right" ? (vertical ? edgeMargin : (cfg.position === "left" ? edgeMargin : 0)) : 0
    margins.right: !centered && cfg.position !== "left" ? (vertical ? edgeMargin : (cfg.position === "right" ? edgeMargin : 0)) : 0

    implicitWidth: vertical ? thickness : (layout.item ? layout.item.implicitWidth : 0)
    implicitHeight: vertical ? (layout.item ? layout.item.implicitHeight : 0) : thickness

    // -------------------------------------------------------------- background
    // A "round" bar is drawn one radius taller (or wider) than its window, so
    // the corners touching the screen edge are clipped away and only the inner
    // corners stay rounded.
    Rectangle {
        id: barBg
        visible: !bar.separated
        x: bar.round && !bar.floating && bar.vertical && bar.cfg.position === "left" ? -Theme.radiusL : 0
        y: bar.round && !bar.floating && !bar.vertical && bar.cfg.position === "top" ? -Theme.radiusL : 0
        width: bar.vertical && bar.round && !bar.floating ? parent.width + Theme.radiusL : parent.width
        height: !bar.vertical && bar.round && !bar.floating ? parent.height + Theme.radiusL : parent.height
        radius: bar.floating ? (bar.round ? Theme.radiusL : height / 2) : (bar.round ? Theme.radiusL : 0)
        color: Theme.colors.surface
        border.width: bar.floating ? 1 : 0
        border.color: Theme.withAlpha(Theme.colors.outlineVariant, 0.5)
    }

    Loader {
        id: layout
        anchors.fill: parent
        sourceComponent: {
            if (bar.vertical)
                return bar.centered ? verticalCenteredComponent : verticalComponent;
            return bar.centered ? horizontalCenteredComponent : horizontalComponent;
        }
    }

    // --------------------------------------------------- horizontal, full width
    Component {
        id: horizontalComponent

        Item {
            anchors.fill: parent

            Zone {
                anchors.left: parent.left
                anchors.leftMargin: bar.padding
                anchors.verticalCenter: parent.verticalCenter
                names: bar.cfg.modulesLeft
                vertical: false
                separated: bar.separated
                floating: bar.floating
                round: bar.round
                thickness: bar.thickness
            }

            Zone {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                names: bar.cfg.modulesCenter
                vertical: false
                separated: bar.separated
                floating: bar.floating
                round: bar.round
                thickness: bar.thickness
            }

            Zone {
                anchors.right: parent.right
                anchors.rightMargin: bar.padding
                anchors.verticalCenter: parent.verticalCenter
                names: bar.cfg.modulesRight
                vertical: false
                separated: bar.separated
                floating: bar.floating
                round: bar.round
                thickness: bar.thickness
            }

            implicitWidth: bar.modelData ? bar.modelData.width : 1920
            implicitHeight: bar.thickness
        }
    }

    // ------------------------------------------------------ horizontal, centred
    Component {
        id: horizontalCenteredComponent

        Item {
            anchors.fill: parent

            Row {
                id: centeredRow
                anchors.centerIn: parent
                spacing: bar.padding * 2

                Zone {
                    names: bar.cfg.modulesLeft
                    vertical: false
                    separated: bar.separated
                    floating: bar.floating
                    round: bar.round
                    thickness: bar.thickness
                }

                Zone {
                    names: bar.cfg.modulesCenter
                    vertical: false
                    separated: bar.separated
                    floating: bar.floating
                    round: bar.round
                    thickness: bar.thickness
                }

                Zone {
                    names: bar.cfg.modulesRight
                    vertical: false
                    separated: bar.separated
                    floating: bar.floating
                    round: bar.round
                    thickness: bar.thickness
                }
            }

            implicitWidth: centeredRow.implicitWidth + bar.padding * 2
            implicitHeight: bar.thickness
        }
    }

    // ------------------------------------------------------- vertical, full size
    Component {
        id: verticalComponent

        Item {
            anchors.fill: parent

            Zone {
                anchors.top: parent.top
                anchors.topMargin: bar.padding
                anchors.horizontalCenter: parent.horizontalCenter
                names: bar.cfg.modulesLeft
                vertical: true
                separated: bar.separated
                floating: bar.floating
                round: bar.round
                thickness: bar.thickness
            }

            Zone {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                names: bar.cfg.modulesCenter
                vertical: true
                separated: bar.separated
                floating: bar.floating
                round: bar.round
                thickness: bar.thickness
            }

            Zone {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: bar.padding
                anchors.horizontalCenter: parent.horizontalCenter
                names: bar.cfg.modulesRight
                vertical: true
                separated: bar.separated
                floating: bar.floating
                round: bar.round
                thickness: bar.thickness
            }

            implicitWidth: bar.thickness
            implicitHeight: bar.modelData ? bar.modelData.height : 1080
        }
    }

    // -------------------------------------------------------- vertical, centred
    Component {
        id: verticalCenteredComponent

        Item {
            anchors.fill: parent

            Column {
                id: centeredColumn
                anchors.centerIn: parent
                spacing: bar.padding * 2

                Zone {
                    names: bar.cfg.modulesLeft
                    vertical: true
                    separated: bar.separated
                    floating: bar.floating
                    round: bar.round
                    thickness: bar.thickness
                }

                Zone {
                    names: bar.cfg.modulesCenter
                    vertical: true
                    separated: bar.separated
                    floating: bar.floating
                    round: bar.round
                    thickness: bar.thickness
                }

                Zone {
                    names: bar.cfg.modulesRight
                    vertical: true
                    separated: bar.separated
                    floating: bar.floating
                    round: bar.round
                    thickness: bar.thickness
                }
            }

            implicitWidth: bar.thickness
            implicitHeight: centeredColumn.implicitHeight + bar.padding * 2
        }
    }
}
