// Styled text following the Material 3 type scale (simplified).
import QtQuick
import "../services"

Text {
    id: root

    // display | headline | title | body | label | small
    property string role: "body"
    property color textColor: Theme.colors.onSurface

    color: root.textColor
    font.family: Theme.fontFamily
    font.pixelSize: {
        switch (root.role) {
        case "display":
            return Theme.fontSizeDisplay;
        case "headline":
            return Theme.fontSizeHeadline;
        case "title":
            return Theme.fontSizeTitle;
        case "label":
            return Theme.fontSizeBody;
        case "small":
            return Theme.fontSizeSmall;
        default:
            return Theme.fontSizeBody;
        }
    }
    font.weight: root.role === "title" || root.role === "headline" ? Font.DemiBold : Font.Normal
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
