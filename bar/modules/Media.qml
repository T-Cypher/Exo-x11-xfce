// Bar module: MPRIS media player (title, artist, art, transport controls).
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../services"
import "../../components"

ModuleTile {
    id: tile

    readonly property var player: {
        const list = Mpris.players.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying)
                return list[i];
        }
        return list.length > 0 ? list[0] : null;
    }

    visible: tile.player !== null
    interactive: true

    onClicked: {
        if (tile.player !== null && tile.player.canTogglePlaying)
            tile.player.togglePlaying();
    }
    onScrolled: delta => {
        if (tile.player === null || !tile.player.volumeSupported)
            return;
        const step = delta > 0 ? 0.05 : -0.05;
        tile.player.volume = Math.max(0, Math.min(1, tile.player.volume + step));
    }

    Row {
        spacing: 7

        // Album art, falling back to a music glyph.
        Item {
            width: Theme.moduleIconSize(Config.bar.density) + 6
            height: width
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: Theme.colors.surfaceContainerHighest
                visible: art.status !== Image.Ready
            }

            Image {
                id: art
                anchors.fill: parent
                source: tile.player !== null ? String(tile.player.trackArtUrl) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: width * 2
                sourceSize.height: height * 2
                visible: status === Image.Ready
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -2

            M3Text {
                text: tile.player !== null ? String(tile.player.trackTitle) : ""
                role: "label"
                width: Math.min(implicitWidth, 180)
                elide: Text.ElideRight
            }

            M3Text {
                visible: Config.bar.density === 0 && tile.player !== null && String(tile.player.trackArtist).length > 0
                text: tile.player !== null ? String(tile.player.trackArtist) : ""
                role: "small"
                textColor: Theme.colors.onSurfaceVariant
                width: Math.min(implicitWidth, 180)
                elide: Text.ElideRight
            }
        }

        // Transport controls appear on hover, like the M3 media widget.
        Row {
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            visible: tile.hovered

            M3IconButton {
                visible: tile.player !== null && tile.player.canGoPrevious
                glyph: "skip_previous"
                size: "xs"
                onClicked: tile.player.previous()
            }

            M3IconButton {
                visible: tile.player !== null && tile.player.canTogglePlaying
                glyph: tile.player !== null && tile.player.isPlaying ? "pause" : "play_arrow"
                size: "xs"
                onClicked: tile.player.togglePlaying()
            }

            M3IconButton {
                visible: tile.player !== null && tile.player.canGoNext
                glyph: "skip_next"
                size: "xs"
                onClicked: tile.player.next()
            }
        }
    }
}
