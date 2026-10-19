// Exo for XFCE — application catalogue for the launcher.
//
// Quickshell has no launcher service of its own: freedesktop desktop entries
// are provided by the core `DesktopEntries` singleton, which this service
// wraps with search, pinning and launching helpers.
pragma Singleton

import QtQuick
import Quickshell

Item {
    id: apps

    // Every installed application that wants to be shown.
    readonly property var all: {
        const entries = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        entries.sort((x, y) => String(x.name).localeCompare(String(y.name)));
        return entries;
    }

    function byId(id) {
        return DesktopEntries.byId(id);
    }

    function search(query) {
        const text = String(query).trim().toLowerCase();
        if (text.length === 0)
            return all.slice(0, Config.launcher.maxResults);

        const terms = text.split(/\s+/);
        const scored = [];

        for (let i = 0; i < all.length; i++) {
            const entry = all[i];
            const name = String(entry.name).toLowerCase();
            const generic = String(entry.genericName).toLowerCase();
            const comment = String(entry.comment).toLowerCase();
            const keywords = entry.keywords.join(" ").toLowerCase();
            const categories = entry.categories.join(" ").toLowerCase();

            let score = -1;
            let matchedAll = true;

            for (let t = 0; t < terms.length; t++) {
                const term = terms[t];
                let termScore = 99;
                if (name.indexOf(term) === 0)
                    termScore = 0;
                else if (name.indexOf(term) > 0)
                    termScore = 1;
                else if (keywords.indexOf(term) >= 0)
                    termScore = 2;
                else if (generic.indexOf(term) >= 0)
                    termScore = 3;
                else if (categories.indexOf(term) >= 0)
                    termScore = 4;
                else if (comment.indexOf(term) >= 0)
                    termScore = 5;

                if (termScore === 99)
                    matchedAll = false;
                score = Math.min(score === -1 ? termScore : score, termScore);
            }

            if (matchedAll)
                scored.push({
                    "entry": entry,
                    "score": score
                });
        }

        scored.sort((x, y) => x.score - y.score || String(x.entry.name).localeCompare(String(y.entry.name)));
        return scored.slice(0, Config.launcher.maxResults).map(s => s.entry);
    }

    // Launch an entry. `runInTerminal` apps are started inside the terminal
    // configured in config.json (Exo uses kitty the same way).
    function launch(entry) {
        if (!entry)
            return;
        if (entry.runInTerminal) {
            const terminal = String(Config.launcher.terminal).split(" ").filter(s => s.length > 0);
            const command = terminal.concat(entry.command);
            if (command.length > terminal.length) {
                Quickshell.execDetached(command);
                return;
            }
        }
        entry.execute();
    }

    function launchAction(action) {
        if (action)
            action.execute();
    }

    function iconSource(entry) {
        if (!entry)
            return Quickshell.iconPath("application-x-executable");
        return Quickshell.iconPath(entry.icon, "application-x-executable");
    }
}
