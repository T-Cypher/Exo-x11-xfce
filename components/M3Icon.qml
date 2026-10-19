// Material Symbols icon glyph.
//
// Icons are plain text in the Material Symbols font (as in Exo).  If the font
// is not installed the glyph will be missing — scripts/install-font.sh installs
// it, and `qs log` gets a warning at startup.
import QtQuick
import "../services"

Text {
    id: root

    property string name: ""
    property int iconSize: 18
    property color iconColor: Theme.colors.onSurface

    text: root.name
    color: root.iconColor
    font.family: Theme.iconFont
    font.pixelSize: root.iconSize
    renderType: Text.QtRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
    // Icons should never stretch their parent unexpectedly.
    width: Math.ceil(contentWidth)
    height: Math.ceil(contentHeight)
}
