// Convenience wrapper: a square/pill button that only shows an icon.
import QtQuick

M3Button {
    id: root

    property string glyph: ""
    property int glyphSize: 0

    icon: root.glyph
    label: ""
    type: "text"
}
