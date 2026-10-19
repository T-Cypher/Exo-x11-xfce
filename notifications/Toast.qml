// A single notification popup.
//
// Every value is funnelled through null-safe derived properties because the
// notification can disappear (expired, dismissed by the sender) between frames.
import QtQuick
import Quickshell
import "../services"
import "../components"

Rectangle {
    id: toast

    property var notification: null

    // ------------------------------------------------------- null-safe values
    readonly property var n: toast.notification
    readonly property string appName: toast.n && toast.n.appName !== undefined ? String(toast.n.appName) : ""
    readonly property string summary: toast.n && toast.n.summary !== undefined ? String(toast.n.summary) : ""
    readonly property string body: toast.n && toast.n.body !== undefined ? String(toast.n.body) : ""
    readonly property string appIcon: toast.n && toast.n.appIcon !== undefined ? String(toast.n.appIcon) : ""
    readonly property string imageSource: toast.n && toast.n.image !== undefined ? String(toast.n.image) : ""
    readonly property var actions: toast.n && toast.n.actions !== undefined ? toast.n.actions : []
    readonly property bool canReply: toast.n ? (toast.n.hasInlineReply === true) : false
    readonly property real expireMs: toast.n && toast.n.expireTimeout > 0 ? toast.n.expireTimeout * 1000 : Config.notifications.timeout

    property bool shown: false

    implicitHeight: column.implicitHeight + 20
    radius: Theme.radiusL
    color: toast.n === null ? "transparent" : Theme.colors.surfaceContainerHigh
    border.width: 1
    border.color: Theme.withAlpha(Theme.colors.outlineVariant, 0.6)

    // Slide in from the screen edge.
    x: toast.shown ? 0 : (Config.notifications.position.indexOf("left") >= 0 ? -(toast.width + 20) : (toast.width + 20))
    opacity: toast.shown ? 1 : 0
    Component.onCompleted: toast.shown = true
    Behavior on x {
        NumberAnimation {
            duration: Theme.durationMedium
            easing.type: Theme.easingEmphasized
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durationMedium
        }
    }

    function close(expire) {
        if (toast.n === null)
            return;
        if (expire)
            Notifs.expire(toast.n);
        else
            Notifs.dismiss(toast.n);
    }

    // Expire once the sender's timeout (or the configured default) runs out.
    Timer {
        interval: Math.max(1000, toast.expireMs)
        running: toast.n !== null
        onTriggered: toast.close(true)
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                toast.close(false);
                return;
            }
            // Left click focuses the sending application (EWMH activation).
            const entry = DesktopEntries.heuristicLookup(toast.appName);
            if (entry !== null && entry.startupClass.length > 0)
                Quickshell.execDetached(["sh", "-c", "wmctrl -x -a " + entry.startupClass + " 2>/dev/null || true"]);
            toast.close(false);
        }
    }

    Row {
        id: leading
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        Item {
            width: 22
            height: 22

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: Theme.colors.surfaceContainerHighest
                visible: icon.status !== Image.Ready
            }

            Image {
                id: icon
                anchors.fill: parent
                source: toast.appIcon.length > 0 ? Quickshell.iconPath(toast.appIcon, "") : ""
                sourceSize.width: 44
                sourceSize.height: 44
                asynchronous: true
            }
        }
    }

    Column {
        id: column

        anchors.left: leading.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 10
        anchors.rightMargin: 34
        anchors.topMargin: 12
        spacing: 3

        M3Text {
            width: parent.width
            visible: toast.appName.length > 0
            text: toast.appName
            role: "small"
            textColor: Theme.colors.onSurfaceVariant
            elide: Text.ElideRight
        }

        M3Text {
            width: parent.width
            visible: toast.summary.length > 0
            text: toast.summary
            role: "title"
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        M3Text {
            width: parent.width
            visible: toast.body.length > 0
            text: toast.body
            role: "label"
            textColor: Theme.colors.onSurfaceVariant
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
        }

        Image {
            visible: toast.imageSource.length > 0
            source: toast.imageSource
            width: parent.width
            height: Math.min(160, width * 0.5)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: width * 2
            sourceSize.height: height * 2
        }

        Row {
            spacing: 6
            visible: toast.actions.length > 0
            topPadding: 4

            Repeater {
                model: toast.actions

                delegate: M3Button {
                    required property var modelData
                    type: "text"
                    size: "xs"
                    label: modelData && modelData.text !== undefined ? modelData.text : ""
                    onClicked: {
                        if (modelData)
                            modelData.invoke();
                        toast.close(false);
                    }
                }
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 2

        M3Button {
            visible: toast.canReply
            type: "text"
            size: "xs"
            icon: "reply"
            onClicked: Surfaces.openReply(toast.n)
        }

        M3Button {
            type: "text"
            size: "xs"
            icon: "close"
            onClicked: toast.close(false)
        }
    }
}
