// Exo for XFCE — the single overlay surface.
//
// Quickshell's X11 back end implements panel windows only (no floating or popup
// windows), so every modal UI is hosted here: one full-screen, click-through
// PanelWindow that is only mapped while something is open. The input mask is the
// whole screen while open so clicking outside a card dismisses it, exactly like
// a Wayland layer-shell overlay.
import QtQuick
import Quickshell
import "../services"

PanelWindow {
    id: overlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: Surfaces.anyOpen
    color: "transparent"
    focusable: true
    aboveWindows: true
    // Never reserve screen space for the overlay.
    exclusionMode: ExclusionMode.Ignore
    mask: Region {
        x: 0
        y: 0
        width: overlay.width
        height: overlay.height
    }

    // Mapping a new window is enough for xfwm4 to focus it under its default
    // "new window focus" policy; this nudges it in case focus stealing
    // prevention gets in the way.
    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => X11.focusShellSurface());
    }

    Loader {
        anchors.fill: parent
        active: Surfaces.anyOpen
        sourceComponent: {
            if (Surfaces.launcherOpen)
                return launcherComponent;
            if (Surfaces.quickCenterOpen)
                return quickCenterComponent;
            if (Surfaces.powerMenuOpen)
                return powerMenuComponent;
            if (Surfaces.replyOpen)
                return replyComponent;
            return settingsComponent;
        }
    }

    Component {
        id: launcherComponent
        Launcher {}
    }

    Component {
        id: quickCenterComponent
        QuickCenter {}
    }

    Component {
        id: powerMenuComponent
        PowerMenu {}
    }

    Component {
        id: settingsComponent
        Settings {}
    }

    Component {
        id: replyComponent
        ReplyPrompt {}
    }
}
