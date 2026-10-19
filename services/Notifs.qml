// Exo for XFCE — notifications.
//
// Wraps Quickshell's NotificationServer with the state Exo needs: a queue of
// popups (toasts) plus the full tracked list shown in the quick centre.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: notifs

    Component.onCompleted: notifs.server = serverComponent.createObject(notifs)

    property var server: null

    Component {
        id: serverComponent

        NotificationServer {
            id: srv
            keepOnReload: true
            bodySupported: true
            bodyMarkupSupported: true
            bodyHyperlinksSupported: true
            imageSupported: true
            actionsSupported: true
            actionIconsSupported: true
            inlineReplySupported: true

            onNotification: notification => Notifs.handleNotification(notification)
        }
    }

    readonly property var tracked: server !== null ? server.trackedNotifications.values : []
    readonly property bool bodyMarkup: server !== null && server.bodyMarkupSupported

    // Newest first; a notification leaves the list when it is dismissed, expires
    // or is removed from the tracked list by an application.
    property var popups: []

    readonly property bool hasInlineReply: {
        for (let i = 0; i < popups.length; i++) {
            if (popups[i].hasInlineReply)
                return true;
        }
        return false;
    }

    readonly property int urgencyOfHighest: 0

    function handleNotification(notification) {
        if (!Config.notifications.enabled) {
            notification.dismiss();
            return;
        }

        if (!notification.transient)
            notification.tracked = true;

        if (Surfaces.dnd) {
            notification.expire();
            return;
        }

        const list = popups.slice();
        list.unshift(notification);
        popups = list;

        // Keep the stack short.
        const max = Math.max(1, Config.notifications.maxVisible);
        while (popups.length > max + 2)
            popups = popups.slice(0, popups.length - 1);
    }

    function removePopup(notification) {
        popups = popups.filter(n => n !== notification);
    }

    function dismiss(notification) {
        removePopup(notification);
        notification.dismiss();
    }

    function expire(notification) {
        removePopup(notification);
        notification.expire();
    }

    function dismissAll() {
        const list = popups.slice();
        for (let i = 0; i < list.length; i++)
            list[i].dismiss();
        popups = [];
    }

    function clearTracked() {
        const list = tracked.slice();
        for (let i = 0; i < list.length; i++)
            list[i].dismiss();
    }
}
