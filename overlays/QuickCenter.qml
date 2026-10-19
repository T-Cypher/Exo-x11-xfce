// Exo for XFCE — quick centre (quick toggles, sliders, notifications).
//
// The layout is anchored rather than put in a RowLayout/ColumnLayout on
// purpose: the card has a fixed size, and letting a layout negotiate with a
// flexible ListView inside it can spin the layout engine.
import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import "../services"
import "../components"

Item {
    id: quickCenter

    anchors.fill: parent
    focus: true

    readonly property var sinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property var wifiDevice: {
        const list = Networking.devices.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].type === DeviceType.Wifi)
                return list[i];
        }
        return null;
    }
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool alignLeft: Config.bar.position === "left"

    readonly property var toggles: [
        {
            "icon": "wifi",
            "label": "Wi-Fi",
            "available": quickCenter.wifiDevice !== null,
            "checked": Networking.wifiEnabled,
            "toggle": () => Networking.wifiEnabled = !Networking.wifiEnabled
        },
        {
            "icon": "bluetooth",
            "label": "Bluetooth",
            "available": quickCenter.bluetoothAdapter !== null,
            "checked": quickCenter.bluetoothAdapter !== null && quickCenter.bluetoothAdapter.enabled,
            "toggle": () => {
                if (quickCenter.bluetoothAdapter !== null)
                    quickCenter.bluetoothAdapter.enabled = !quickCenter.bluetoothAdapter.enabled;
            }
        },
        {
            "icon": Surfaces.dnd ? "notifications_off" : "notifications",
            "label": "Do not disturb",
            "available": true,
            "checked": Surfaces.dnd,
            "toggle": () => Surfaces.dnd = !Surfaces.dnd
        },
        {
            "icon": Config.theme.mode === "dark" ? "dark_mode" : "light_mode",
            "label": "Dark mode",
            "available": true,
            "checked": Config.theme.mode === "dark",
            "toggle": () => Config.set("themeMode", Config.theme.mode === "dark" ? "light" : "dark")
        }
    ]

    readonly property int visibleToggleCount: {
        let count = 0;
        for (let i = 0; i < toggles.length; i++) {
            if (Config.quick.showToggles && toggles[i].available)
                count++;
        }
        return count;
    }

    readonly property bool showSliders: Config.quick.showVolume || (Config.quick.showBrightness && Osd.brightnessAvailable)

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

        property bool shown: false

        width: Math.min(Config.quick.width, quickCenter.width - 40)
        height: Math.min(quickCenter.height - 48, 640)
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.radiusXl
        color: Theme.colors.surfaceContainer

        // Slides in from the edge the bar is on.
        x: card.shown ? (quickCenter.alignLeft ? 12 : quickCenter.width - width - 12) : (quickCenter.alignLeft ? -width : quickCenter.width)
        Component.onCompleted: card.shown = true
        Behavior on x {
            NumberAnimation {
                duration: Theme.durationMedium
                easing.type: Theme.easingEmphasized
            }
        }

        // ------------------------------------------------------------- header
        Item {
            id: headerRow

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: 40

            M3Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Quick settings"
                role: "headline"
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                M3Button {
                    type: Surfaces.dnd ? "filled" : "text"
                    size: "xs"
                    icon: "notifications_off"
                    label: "Do not disturb"
                    onClicked: Surfaces.dnd = !Surfaces.dnd
                }

                M3Button {
                    type: "text"
                    size: "xs"
                    icon: "close"
                    onClicked: Surfaces.close()
                }
            }
        }

        // ------------------------------------------------------------ toggles
        Item {
            id: toggleArea

            anchors.top: headerRow.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: Config.quick.showToggles ? Math.ceil(quickCenter.visibleToggleCount / 2) * 68 : 0
            visible: height > 0
            clip: true

            Grid {
                id: toggleGrid
                anchors.fill: parent
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                readonly property int tileWidth: Math.floor((width - columnSpacing) / 2)

                Repeater {
                    model: quickCenter.toggles

                    delegate: Rectangle {
                        id: toggleTile

                        required property var modelData

                        visible: modelData.available
                        width: modelData.available ? toggleGrid.tileWidth : 0
                        height: modelData.available ? 60 : 0
                        radius: Theme.radiusL
                        color: modelData.checked ? Theme.colors.primaryContainer : Theme.colors.surfaceContainerHigh

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            M3Icon {
                                name: toggleTile.modelData.icon
                                iconSize: 22
                                iconColor: toggleTile.modelData.checked ? Theme.colors.onPrimaryContainer : Theme.colors.onSurfaceVariant
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            M3Text {
                                text: toggleTile.modelData.label
                                role: "label"
                                textColor: toggleTile.modelData.checked ? Theme.colors.onPrimaryContainer : Theme.colors.onSurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        M3Switch {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            checked: toggleTile.modelData.checked
                            onToggled: toggleTile.modelData.toggle()
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: 62
                            cursorShape: Qt.PointingHandCursor
                            onClicked: toggleTile.modelData.toggle()
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------ sliders
        Column {
            id: sliderColumn

            anchors.top: toggleArea.bottom
            anchors.topMargin: toggleArea.visible ? 12 : 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 10
            height: implicitHeight
            visible: quickCenter.showSliders

            Row {
                width: parent.width
                spacing: 10
                visible: Config.quick.showVolume

                M3Icon {
                    name: quickCenter.sinkAudio !== null && quickCenter.sinkAudio.muted ? "volume_off" : "volume_up"
                    iconSize: 22
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Osd.volumeToggleMute()
                    }
                }

                M3Slider {
                    width: parent.width - 22 - 34 - 20
                    value: quickCenter.sinkAudio !== null ? quickCenter.sinkAudio.volume : 0
                    anchors.verticalCenter: parent.verticalCenter
                    onMoved: value => {
                        if (quickCenter.sinkAudio !== null) {
                            quickCenter.sinkAudio.muted = false;
                            quickCenter.sinkAudio.volume = value;
                        }
                    }
                }

                M3Text {
                    text: quickCenter.sinkAudio !== null ? Math.round(quickCenter.sinkAudio.volume * 100) + "%" : "—"
                    role: "small"
                    textColor: Theme.colors.onSurfaceVariant
                    width: 34
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                width: parent.width
                spacing: 10
                visible: Config.quick.showBrightness && Osd.brightnessAvailable

                M3Icon {
                    name: "brightness_medium"
                    iconSize: 22
                    anchors.verticalCenter: parent.verticalCenter
                }

                M3Slider {
                    width: parent.width - 22 - 34 - 20
                    value: Osd.brightnessPercent()
                    anchors.verticalCenter: parent.verticalCenter
                    onMoved: value => {
                        Osd.setBrightness(value);
                        Osd.show("brightness_medium", value);
                    }
                }

                M3Text {
                    text: Math.round(Osd.brightnessPercent() * 100) + "%"
                    role: "small"
                    textColor: Theme.colors.onSurfaceVariant
                    width: 34
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // ------------------------------------------------- notification header
        Item {
            id: notificationHeader

            anchors.top: sliderColumn.bottom
            anchors.topMargin: quickCenter.showSliders ? 14 : 4
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 32

            M3Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                role: "title"
            }

            M3Button {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: Notifs.tracked.length > 0
                type: "text"
                size: "xs"
                icon: "clear_all"
                label: "Clear all"
                onClicked: Notifs.clearTracked()
            }
        }

        // ------------------------------------------------------------ bottom bar
        Item {
            id: bottomBar

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: 40

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                M3Button {
                    type: "tonal"
                    size: "s"
                    icon: "power_settings_new"
                    onClicked: Surfaces.open("powermenu")
                }

                M3Button {
                    type: "tonal"
                    size: "s"
                    icon: "settings"
                    onClicked: Surfaces.openSettings(0)
                }
            }

            M3Button {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                type: "text"
                size: "s"
                icon: "close"
                onClicked: Surfaces.close()
            }
        }

        // ------------------------------------------------------ notifications
        ListView {
            id: notificationList

            anchors.top: notificationHeader.bottom
            anchors.topMargin: 4
            anchors.bottom: bottomBar.top
            anchors.bottomMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel {
                values: Notifs.tracked
            }

            M3Text {
                anchors.centerIn: parent
                width: parent.width - 20
                visible: Notifs.tracked.length === 0
                text: "Nothing new"
                role: "small"
                textColor: Theme.colors.onSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
            }

            delegate: Rectangle {
                id: notificationCard

                required property var modelData

                readonly property var notification: modelData

                width: notificationList.width
                height: notificationColumn.implicitHeight + 20
                radius: Theme.radiusL
                color: Theme.colors.surfaceContainerHigh

                Column {
                    id: notificationColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 4

                    Row {
                        width: parent.width
                        spacing: 10

                        Image {
                            width: 20
                            height: 20
                            source: notificationCard.notification && notificationCard.notification.appIcon && notificationCard.notification.appIcon.length > 0 ? Quickshell.iconPath(notificationCard.notification.appIcon, "") : ""
                            sourceSize.width: 40
                            sourceSize.height: 40
                            asynchronous: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        M3Text {
                            text: notificationCard.notification ? (notificationCard.notification.appName.length > 0 ? notificationCard.notification.appName : notificationCard.notification.summary) : ""
                            role: "small"
                            textColor: Theme.colors.onSurfaceVariant
                            width: parent.width - 60
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        M3Icon {
                            name: "close"
                            iconSize: 16
                            iconColor: Theme.colors.onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (notificationCard.notification)
                                        notificationCard.notification.dismiss();
                                }
                            }
                        }
                    }

                    M3Text {
                        width: parent.width
                        text: notificationCard.notification ? notificationCard.notification.summary : ""
                        role: "title"
                        wrapMode: Text.WordWrap
                    }

                    M3Text {
                        visible: notificationCard.notification !== null && notificationCard.notification.body.length > 0
                        width: parent.width
                        text: notificationCard.notification ? notificationCard.notification.body : ""
                        role: "label"
                        textColor: Theme.colors.onSurfaceVariant
                        wrapMode: Text.WordWrap
                        maximumLineCount: 6
                        elide: Text.ElideRight
                    }

                    Row {
                        visible: notificationCard.notification !== null && notificationCard.notification.actions.length > 0
                        spacing: 6
                        topPadding: 4

                        Repeater {
                            model: notificationCard.notification ? notificationCard.notification.actions : []

                            delegate: M3Button {
                                required property var modelData
                                type: "text"
                                size: "xs"
                                label: modelData && modelData.text !== undefined ? modelData.text : ""
                                onClicked: {
                                    if (modelData)
                                        modelData.invoke();
                                    Surfaces.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
