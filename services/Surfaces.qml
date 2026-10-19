// Exo for XFCE — which overlay is currently open.
//
// Quickshell's X11 back end has no floating/popup windows, so every menu-like
// UI (launcher, quick centre, power menu, settings) lives inside one full-screen
// overlay surface: overlays/OverlaySurface.qml. This singleton is the single
// source of truth for what it should show.
pragma Singleton

import QtQuick

Item {
    id: surfaces

    // "" | "launcher" | "quickcenter" | "powermenu" | "settings" | "reply"
    property string overlay: ""
    property int settingsTab: 0

    // The bar PanelWindow, used by platform menus (QsMenuAnchor) and dialogs.
    property var barWindow: null

    // Notification currently being replied to (see overlays/ReplyPrompt.qml).
    property var replyNotification: null

    // Runtime-only quick setting (Exo's notification centre toggle).
    property bool dnd: false

    readonly property bool anyOpen: overlay !== ""
    readonly property bool launcherOpen: overlay === "launcher"
    readonly property bool quickCenterOpen: overlay === "quickcenter"
    readonly property bool powerMenuOpen: overlay === "powermenu"
    readonly property bool settingsOpen: overlay === "settings"
    readonly property bool replyOpen: overlay === "reply"

    function open(name) {
        overlay = name;
    }

    function close() {
        overlay = "";
        replyNotification = null;
    }

    function toggle(name) {
        overlay = overlay === name ? "" : name;
    }

    function openSettings(tab) {
        settingsTab = tab;
        overlay = "settings";
    }

    function openReply(notification) {
        replyNotification = notification;
        overlay = "reply";
    }
}
