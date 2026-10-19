// Exo for XFCE — entry point.
//
//     qs -c exo
//
// One bar per screen, one shared overlay surface (Quickshell's X11 back end has
// no popup/floating windows), one OSD and one notification stack.
//@ pragma UseQApplication
//@ pragma DropExpensiveFonts
import QtQuick
import QtQml
import Quickshell
import Quickshell.Io
import "services"
import "bar"
import "overlays"
import "notifications"

ShellRoot {
    id: shell

    readonly property var primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    // -------------------------------------------------------------- theming
    Binding {
        target: Theme
        property: "darkMode"
        value: Config.theme.mode === "dark"
    }

    Binding {
        target: Theme
        property: "colorsPath"
        value: Config.theme.colorsPath
    }

    Binding {
        target: Theme
        property: "fontFamily"
        value: Config.theme.fontFamily
    }

    Binding {
        target: Theme
        property: "iconFont"
        value: Config.theme.iconFont
    }

    // Cache directory for matugen output.
    Process {
        running: true
        command: ["mkdir", "-p", Config.xdgCache + "/quickshell-exo"]
    }

    // Warn (once) when the Material Symbols font is missing: the shell still
    // runs, but icon glyphs will be blank.
    Process {
        running: true
        command: ["sh", "-c", "fc-list 2>/dev/null | grep -qi 'Material Symbols' || echo missing"]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "missing") {
                    console.warn("exo: the Material Symbols font was not found; icon glyphs will be missing.");
                    console.warn("exo: install it with scripts/install-font.sh or your package manager.");
                }
            }
        }
    }

    ExoIpc {}

    // ------------------------------------------------------------------ bars
    Variants {
        model: Quickshell.screens

        Bar {
            screen: modelData
        }
    }

    // ------------------------------------------------------- overlays &c
    OverlaySurface {
        screen: shell.primaryScreen
    }

    OsdWindow {
        screen: shell.primaryScreen
    }

    ToastWindow {
        screen: shell.primaryScreen
    }
}
