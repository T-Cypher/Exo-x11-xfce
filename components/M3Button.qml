// Material 3 button. Ported from Exo's `m3-button` SCSS (types elevated /
// filled / tonal / outlined / text, sizes xs..xl).
import QtQuick
import "../services"

Item {
    id: root

    signal clicked()

    // elevated | filled | tonal | outlined | text
    property string type: "tonal"
    // xs | s | m | l | xl
    property string size: "s"
    property string icon: ""
    property string label: ""
    property bool square: false
    property bool active: false // selected state (Exo's `.active`)
    property bool horizontal: true

    readonly property bool iconOnly: root.icon.length > 0 && root.label.length === 0
    readonly property int pad: {
        switch (root.size) {
        case "xs":
            return root.iconOnly ? 8 : 12;
        case "m":
            return root.iconOnly ? 16 : 24;
        case "l":
            return root.iconOnly ? 32 : 48;
        case "xl":
            return root.iconOnly ? 48 : 64;
        default:
            return root.iconOnly ? 10 : 16;
        }
    }
    readonly property int iconPx: {
        switch (root.size) {
        case "xs":
            return 18;
        case "m":
            return 24;
        case "l":
            return 32;
        case "xl":
            return 40;
        default:
            return 20;
        }
    }
    readonly property int gap: root.label.length > 0 && root.icon.length > 0 ? (root.size === "xs" ? 6 : 8) : 0

    implicitWidth: (root.horizontal ? content.implicitWidth : content.implicitHeight) + root.pad * 2
    implicitHeight: (root.horizontal ? content.implicitHeight : content.implicitWidth) + root.pad * 2

    function _background() {
        if (root.type === "filled")
            return Theme.colors.primary;
        if (root.type === "tonal" || root.active)
            return Theme.colors.secondaryContainer;
        if (root.type === "outlined" || root.type === "text")
            return "transparent";
        return Theme.colors.surfaceContainer;
    }

    function _stateColour() {
        if (root.type === "filled")
            return Theme.colors.onPrimary;
        if (root.type === "tonal" || root.active)
            return Theme.colors.onSecondaryContainer;
        return Theme.colors.primary;
    }

    function _labelColour() {
        if (root.type === "filled")
            return Theme.colors.onPrimary;
        if (root.type === "tonal" || root.active)
            return Theme.colors.onSecondaryContainer;
        return Theme.colors.primary;
    }

    readonly property int corner: {
        if (root.square) {
            switch (root.size) {
            case "xs":
                return Theme.radiusS;
            case "m":
                return Theme.radiusM;
            case "l":
            case "xl":
                return Theme.radiusXl;
            default:
                return Theme.radiusS;
            }
        }
        return Theme.radiusPill;
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.corner
        color: root._background()
        border.width: root.type === "outlined" ? 1 : 0
        border.color: root.type === "outlined" ? Theme.colors.outlineVariant : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationShort
            }
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        visible: root.horizontal
        spacing: root.gap

        M3Icon {
            visible: root.icon.length > 0
            name: root.icon
            iconSize: root.iconPx
            iconColor: root.active ? Theme.colors.onPrimary : root._labelColour()
            anchors.verticalCenter: parent.verticalCenter
        }

        M3Text {
            visible: root.label.length > 0
            text: root.label
            role: root.size === "l" || root.size === "xl" ? "headline" : root.size === "m" ? "title" : "label"
            textColor: root.active ? Theme.colors.onPrimary : root._labelColour()
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Column {
        anchors.centerIn: parent
        visible: !root.horizontal
        spacing: root.gap

        M3Icon {
            visible: root.icon.length > 0
            name: root.icon
            iconSize: root.iconPx
            iconColor: root._labelColour()
            anchors.horizontalCenter: parent.horizontalCenter
        }

        M3Text {
            visible: root.label.length > 0
            text: root.label
            role: "label"
            textColor: root._labelColour()
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    // M3 state layers.
    Rectangle {
        anchors.fill: parent
        radius: bg.radius
        color: root._stateColour()
        opacity: !area.pressed ? (area.containsMouse ? 0.08 : 0.0) : 0.12
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationShort
            }
        }
    }
}
