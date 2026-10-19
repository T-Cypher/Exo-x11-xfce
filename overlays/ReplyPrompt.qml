// Exo for XFCE — inline notification reply.
//
// Typing needs keyboard focus, and giving the toast window focus would make
// notifications steal focus from the active application, so replies are typed
// in the (focusable) overlay surface instead.
import QtQuick
import Quickshell
import "../services"
import "../components"

Item {
    id: replyPrompt

    anchors.fill: parent
    focus: true

    readonly property var notification: Surfaces.replyNotification

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            Surfaces.close();
            event.accepted = true;
        }
    }

    Scrim {
        anchors.fill: parent
        onClicked: Surfaces.close()
    }

    Rectangle {
        id: card

        width: Math.min(replyPrompt.width - 80, 520)
        height: 168
        anchors.centerIn: parent
        radius: Theme.radiusXl
        color: Theme.colors.surfaceContainer

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            M3Text {
                text: replyPrompt.notification !== null && replyPrompt.notification.appName.length > 0 ? "Reply to " + replyPrompt.notification.appName : "Reply"
                role: "title"
            }

            M3Text {
                width: parent.width
                text: replyPrompt.notification !== null ? replyPrompt.notification.summary + (replyPrompt.notification.body.length > 0 ? " — " + replyPrompt.notification.body : "") : ""
                role: "small"
                textColor: Theme.colors.onSurfaceVariant
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
            }

            Rectangle {
                width: parent.width
                height: 40
                radius: Theme.radiusPill
                color: Theme.colors.surfaceContainerHighest

                TextInput {
                    id: replyInput
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.colors.onSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBody
                    focus: true
                    clip: true
                    onAccepted: replyPrompt.send()
                }

                M3Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    visible: replyInput.text.length === 0
                    text: replyPrompt.notification !== null ? replyPrompt.notification.inlineReplyPlaceholder : "Reply…"
                    role: "label"
                    textColor: Theme.colors.onSurfaceVariant
                }
            }

            Row {
                spacing: 8

                M3Button {
                    type: "filled"
                    size: "xs"
                    icon: "send"
                    label: "Send"
                    onClicked: replyPrompt.send()
                }

                M3Button {
                    type: "text"
                    size: "xs"
                    icon: "close"
                    label: "Cancel"
                    onClicked: Surfaces.close()
                }
            }
        }

        Component.onCompleted: replyInput.forceActiveFocus()
    }

    function send() {
        if (replyPrompt.notification === null) {
            Surfaces.close();
            return;
        }
        replyPrompt.notification.sendInlineReply(replyInput.text);
        Notifs.removePopup(replyPrompt.notification);
        Surfaces.close();
    }
}
