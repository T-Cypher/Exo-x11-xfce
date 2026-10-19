// Exo for XFCE — application launcher.
//
// Grid or list of applications with search, keyboard navigation, pinning and a
// context menu (pin/unpin, desktop actions), mirroring Exo's launcher.
import QtQuick
import Quickshell
import "../services"
import "../components"

Item {
    id: launcher

    anchors.fill: parent

    // ---------------------------------------------------------------- search
    property string query: ""
    property int selectedIndex: 0
    property bool pinnedMode: false

    readonly property var results: launcher.pinnedMode ? Pinned.entries : Apps.search(launcher.query)
    readonly property bool gridLayout: Config.launcher.layout === "grid"
    readonly property int columns: Math.max(2, Config.launcher.columns)
    readonly property int itemWidth: launcher.gridLayout ? 132 : Math.min(560, launcher.width - 80)

    function moveSelection(step) {
        const count = launcher.results.length;
        if (count === 0)
            return;
        launcher.selectedIndex = (launcher.selectedIndex + step + count) % count;
        grid.currentIndex = launcher.selectedIndex;
    }

    function activateSelection() {
        const entry = launcher.results[launcher.selectedIndex];
        if (entry === undefined)
            return;
        Apps.launch(entry);
        Surfaces.close();
    }

    function toggleLayout() {
        Config.set("launcherLayout", Config.launcher.layout === "grid" ? "list" : "grid");
    }

    // Viewport keys are handled by the surface that owns the window.
    focus: true

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape:
            Surfaces.close();
            event.accepted = true;
            break;
        case Qt.Key_Down:
            launcher.moveSelection(launcher.gridLayout ? launcher.columns : 1);
            event.accepted = true;
            break;
        case Qt.Key_Up:
            launcher.moveSelection(launcher.gridLayout ? -launcher.columns : -1);
            event.accepted = true;
            break;
        case Qt.Key_Right:
            launcher.moveSelection(1);
            event.accepted = true;
            break;
        case Qt.Key_Left:
            launcher.moveSelection(-1);
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            launcher.activateSelection();
            event.accepted = true;
            break;
        case Qt.Key_Tab:
            launcher.toggleLayout();
            event.accepted = true;
            break;
        default:
            break;
        }
    }

    Scrim {
        anchors.fill: parent
        onClicked: Surfaces.close()
    }

    Rectangle {
        id: card

        width: Math.min(launcher.width - 80, launcher.gridLayout ? 860 : 620)
        height: Math.min(launcher.height - 120, 560)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(24, launcher.height * 0.14)
        radius: Theme.radiusXl
        color: Theme.colors.surfaceContainer

        scale: 0.97
        opacity: 0
        Component.onCompleted: {
            scale = 1;
            opacity = 1;
            searchInput.forceActiveFocus();
        }
        Behavior on scale {
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

        // ------------------------------------------------------------ header
        Row {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 8

            Rectangle {
                width: header.width - layoutToggle.width - 8
                height: 48
                radius: Theme.radiusPill
                color: Theme.colors.surfaceContainerHighest

                M3Icon {
                    id: searchGlyph
                    name: "search"
                    iconSize: 20
                    iconColor: Theme.colors.onSurfaceVariant
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: searchInput
                    anchors.left: searchGlyph.right
                    anchors.right: parent.right
                    anchors.leftMargin: 10
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.colors.onSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeHeadline
                    selectionColor: Theme.colors.primary
                    selectedTextColor: Theme.colors.onPrimary
                    clip: true
                    focus: true

                    onTextChanged: {
                        launcher.query = text;
                        launcher.pinnedMode = false;
                        launcher.selectedIndex = 0;
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search applications…"
                        color: Theme.colors.onSurfaceVariant
                        font: searchInput.font
                        visible: searchInput.text.length === 0
                    }

                    Keys.onEscapePressed: Surfaces.close()
                }
            }

            M3Button {
                id: layoutToggle
                type: "tonal"
                size: "s"
                square: true
                icon: launcher.gridLayout ? "view_list" : "grid_view"
                onClicked: launcher.toggleLayout()
                height: 48
                width: 56
            }
        }

        // -------------------------------------------------------------- list
        Flickable {
            id: view
            anchors.top: header.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top
            anchors.bottomMargin: 8
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            clip: true
            contentHeight: contentFlow.height
            boundsBehavior: Flickable.StopAtBounds

            function currentIndex() {
                return launcher.selectedIndex;
            }

            Flow {
                id: contentFlow
                width: view.width
                spacing: 6

                Repeater {
                    model: ScriptModel {
                        values: launcher.results
                    }

                    delegate: Rectangle {
                        id: appItem

                        required property var modelData
                        required property int index

                        readonly property bool selected: launcher.selectedIndex === index
                        readonly property var entry: modelData
                        readonly property bool pinned: entry !== null && Pinned.isPinned(entry.id)

                        width: launcher.gridLayout ? Math.floor(view.width / launcher.columns) - 6 : view.width
                        height: launcher.gridLayout ? 104 : 56
                        radius: launcher.gridLayout ? Theme.radiusL : Theme.radiusPill
                        color: appArea.containsMouse || appItem.selected ? (appItem.selected ? Theme.colors.secondaryContainer : Theme.colors.surfaceContainerHigh) : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationShort
                            }
                        }

                        function launch() {
                            Apps.launch(appItem.entry);
                            Surfaces.close();
                        }

                        // ------------------------------------------------- grid
                        Column {
                            visible: launcher.gridLayout
                            anchors.centerIn: parent
                            spacing: 6

                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 34
                                height: 34
                                source: Apps.iconSource(appItem.entry)
                                sourceSize.width: width * 2
                                sourceSize.height: height * 2
                                asynchronous: true
                                smooth: true
                            }

                            M3Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: appItem.width - 12
                                text: appItem.entry.name
                                role: "label"
                                horizontalAlignment: Text.AlignHCenter
                                textColor: appItem.selected ? Theme.colors.onSecondaryContainer : Theme.colors.onSurface
                            }
                        }

                        // ------------------------------------------------- list
                        Row {
                            visible: !launcher.gridLayout
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Image {
                                width: 26
                                height: 26
                                source: Apps.iconSource(appItem.entry)
                                sourceSize.width: width * 2
                                sourceSize.height: height * 2
                                asynchronous: true
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                M3Text {
                                    text: appItem.entry.name
                                    role: "title"
                                    textColor: appItem.selected ? Theme.colors.onSecondaryContainer : Theme.colors.onSurface
                                }

                                M3Text {
                                    visible: appItem.entry.comment.length > 0
                                    text: appItem.entry.comment
                                    role: "small"
                                    textColor: Theme.colors.onSurfaceVariant
                                    width: Math.min(implicitWidth, 420)
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Pin indicator
                        M3Icon {
                            visible: appItem.pinned && launcher.gridLayout
                            name: "push_pin"
                            iconSize: 14
                            iconColor: Theme.colors.primary
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                        }

                        MouseArea {
                            id: appArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onEntered: launcher.selectedIndex = appItem.index
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    launcher.selectedIndex = appItem.index;
                                    const items = [
                                        {
                                            "label": appItem.entry.name,
                                            "enabled": false,
                                            "icon": ""
                                        },
                                        {
                                            "separator": true
                                        },
                                        {
                                            "label": appItem.pinned ? "Unpin app" : "Pin app",
                                            "icon": "push_pin",
                                            "trigger": () => Pinned.toggle(appItem.entry.id)
                                        }
                                    ];
                                    const actions = appItem.entry.actions;
                                    if (actions.length > 0)
                                        items.push({
                                            "separator": true
                                        });
                                    for (let i = 0; i < actions.length; i++) {
                                        const action = actions[i];
                                        items.push({
                                            "label": action.name,
                                            "icon": "",
                                            "trigger": () => {
                                                Apps.launchAction(action);
                                                Surfaces.close();
                                            }
                                        });
                                    }
                                    const point = appItem.mapToItem(launcher, 0, 0);
                                    contextMenu.openAt(point.x + 12, point.y + 12);
                                    contextMenu.items = items;
                                } else {
                                    appItem.launch();
                                }
                            }
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------ footer
        Item {
            id: footer
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: 40

            M3Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: launcher.pinnedMode ? "Pinned" : (launcher.results.length === 0 ? "No applications found" : launcher.results.length + (launcher.results.length === 1 ? " result" : " results"))
                role: "small"
                textColor: Theme.colors.onSurfaceVariant
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                M3Button {
                    type: launcher.pinnedMode ? "tonal" : "text"
                    size: "xs"
                    icon: "push_pin"
                    label: "Pinned"
                    onClicked: {
                        launcher.pinnedMode = !launcher.pinnedMode;
                        launcher.selectedIndex = 0;
                    }
                }

                M3Button {
                    type: "text"
                    size: "xs"
                    icon: "close"
                    label: "Close"
                    onClicked: Surfaces.close()
                }
            }
        }
    }

    M3ContextMenu {
        id: contextMenu
        anchors.fill: parent
        onDismissed: launcher.forceActiveFocus()
    }
}
