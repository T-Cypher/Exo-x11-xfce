// Exo for XFCE — theme tokens and Material 3 colour roles.
//
// Colours come from a matugen-generated JSON file (see config/matugen.toml).
// When that file is missing the built-in Material 3 palettes below are used, so
// the shell looks right out of the box.
//
// Note: the roles live in `Theme.colors` rather than as top level `on*`
// properties, because QML reserves the `on<Capital>` prefix for signal handlers.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme

    // ---------------------------------------------------------------- palette
    readonly property var fallbackDark: ({
            "background": "#111318",
            "onBackground": "#e0e2e8",
            "surface": "#111318",
            "surfaceContainerLowest": "#0c0e13",
            "surfaceContainerLow": "#191c20",
            "surfaceContainer": "#1d2024",
            "surfaceContainerHigh": "#282a2f",
            "surfaceContainerHighest": "#33353a",
            "onSurface": "#e0e2e8",
            "onSurfaceVariant": "#c4c6ce",
            "outline": "#8e9099",
            "outlineVariant": "#44474e",
            "primary": "#a9c7ff",
            "onPrimary": "#003062",
            "primaryContainer": "#2f4875",
            "onPrimaryContainer": "#d7e2ff",
            "secondary": "#bfc7dc",
            "onSecondary": "#293041",
            "secondaryContainer": "#3f4759",
            "onSecondaryContainer": "#dbe2f9",
            "tertiary": "#ddbce0",
            "onTertiary": "#3f2844",
            "tertiaryContainer": "#573e5c",
            "onTertiaryContainer": "#fad8fd",
            "error": "#ffb4ab",
            "onError": "#690005",
            "errorContainer": "#93000a",
            "onErrorContainer": "#ffdad6",
            "shadow": "#000000",
            "scrim": "#000000"
        })

    readonly property var fallbackLight: ({
            "background": "#f9f9ff",
            "onBackground": "#1a1b20",
            "surface": "#f9f9ff",
            "surfaceContainerLowest": "#ffffff",
            "surfaceContainerLow": "#f3f3fa",
            "surfaceContainer": "#ededf4",
            "surfaceContainerHigh": "#e8e7ef",
            "surfaceContainerHighest": "#e2e2e9",
            "onSurface": "#1a1b20",
            "onSurfaceVariant": "#44474e",
            "outline": "#74777f",
            "outlineVariant": "#c4c6cf",
            "primary": "#415f91",
            "onPrimary": "#ffffff",
            "primaryContainer": "#d6e3ff",
            "onPrimaryContainer": "#001b3e",
            "secondary": "#565f71",
            "onSecondary": "#ffffff",
            "secondaryContainer": "#dae2f9",
            "onSecondaryContainer": "#131c2b",
            "tertiary": "#705575",
            "onTertiary": "#ffffff",
            "tertiaryContainer": "#fad8fd",
            "onTertiaryContainer": "#28132e",
            "error": "#ba1a1a",
            "onError": "#ffffff",
            "errorContainer": "#ffdad6",
            "onErrorContainer": "#410002",
            "shadow": "#000000",
            "scrim": "#000000"
        })

    // Palette keys as written by matugen / Material 3 (snake_case).
    readonly property var snakeToCamel: ({
            "background": "background",
            "on_background": "onBackground",
            "surface": "surface",
            "surface_container_lowest": "surfaceContainerLowest",
            "surface_container_low": "surfaceContainerLow",
            "surface_container": "surfaceContainer",
            "surface_container_high": "surfaceContainerHigh",
            "surface_container_highest": "surfaceContainerHighest",
            "on_surface": "onSurface",
            "on_surface_variant": "onSurfaceVariant",
            "outline": "outline",
            "outline_variant": "outlineVariant",
            "primary": "primary",
            "on_primary": "onPrimary",
            "primary_container": "primaryContainer",
            "on_primary_container": "onPrimaryContainer",
            "secondary": "secondary",
            "on_secondary": "onSecondary",
            "secondary_container": "secondaryContainer",
            "on_secondary_container": "onSecondaryContainer",
            "tertiary": "tertiary",
            "on_tertiary": "onTertiary",
            "tertiary_container": "tertiaryContainer",
            "on_tertiary_container": "onTertiaryContainer",
            "error": "error",
            "on_error": "onError",
            "error_container": "errorContainer",
            "on_error_container": "onErrorContainer",
            "shadow": "shadow",
            "scrim": "scrim"
        })

    property bool darkMode: true
    property var externalDark: ({})
    property var externalLight: ({})
    property string colorsPath: ""

    // Merge: built-in palette, then the raw matugen palette, then the normalised
    // matugen palette (so camelCase and snake_case keys both work).
    readonly property var colors: {
        const base = Object.assign({}, theme.darkMode ? theme.fallbackDark : theme.fallbackLight);
        const ext = theme.darkMode ? theme.externalDark : theme.externalLight;
        return Object.assign(base, ext || {});
    }

    FileView {
        id: darkFile
        path: theme.colorsPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: theme.externalDark = theme.parse(text)
        onLoadFailed: theme.externalDark = ({})
    }

    FileView {
        id: lightFile
        path: theme.colorsPath.length > 0 ? theme.colorsPath.replace(/\.json$/, "-light.json") : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: theme.externalLight = theme.parse(text)
        onLoadFailed: theme.externalLight = ({})
    }

    // Accepts matugen's `-j` output, i.e. {"colors": {"primary": {"dark": "#…"}}},
    // plain {"colors": {"primary": "#…"}} or a bare object of the same shapes.
    function parse(raw) {
        try {
            const data = JSON.parse(raw);
            const source = data.colors !== undefined ? data.colors : data;
            const out = ({});

            for (const key in source) {
                const value = source[key];
                const name = theme.snakeToCamel[key] !== undefined ? theme.snakeToCamel[key] : key;

                if (typeof value === "string") {
                    out[name] = value;
                    continue;
                }
                if (value === null || typeof value !== "object")
                    continue;

                // matugen JSON template output nests the value per mode.
                const pick = theme.darkMode ? (value.dark !== undefined ? value.dark : value.default) : (value.light !== undefined ? value.light : value.default);
                if (typeof pick === "string")
                    out[name] = pick;
                else if (pick !== null && typeof pick === "object" && typeof pick.hex === "string")
                    out[name] = pick.hex;
            }
            return out;
        } catch (e) {
            console.log("exo: could not parse the colour file: " + e);
            return ({});
        }
    }

    // -------------------------------------------------------------- utilities
    // Linear blend of two colours (M3 state layers).
    function mix(first, second, amount) {
        const t = amount === undefined ? 0.5 : amount;
        return Qt.rgba(first.r + (second.r - first.r) * t, first.g + (second.g - first.g) * t, first.b + (second.b - first.b) * t, first.a + (second.a - first.a) * t);
    }

    function withAlpha(colour, alpha) {
        return Qt.rgba(colour.r, colour.g, colour.b, alpha);
    }

    function hover(base, state) {
        return mix(base, state, 0.08);
    }

    function press(base, state) {
        return mix(base, state, 0.12);
    }

    // ------------------------------------------------------------------- type
    // Note: the icon font is loaded lazily on purpose — an uninstalled font name
    // is harmless, but Qt logs a warning every time it is first used otherwise.
    property string fontFamily: "Inter"
    property string iconFont: "Material Symbols Rounded"

    readonly property int fontSizeSmall: 9
    readonly property int fontSizeBody: 10
    readonly property int fontSizeTitle: 11
    readonly property int fontSizeHeadline: 14
    readonly property int fontSizeDisplay: 20

    // ------------------------------------------------------------------ shape
    readonly property int radiusXs: 8
    readonly property int radiusS: 12
    readonly property int radiusM: 16
    readonly property int radiusL: 20
    readonly property int radiusXl: 28
    readonly property int radiusPill: 999

    // ----------------------------------------------------------------- motion
    readonly property int durationShort: 150
    readonly property int durationMedium: 250
    readonly property int durationLong: 400
    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingEmphasized: Easing.OutQuint

    // ------------------------------------------------------------------ scale
    function barHeight(density) {
        switch (density) {
        case 1:
            return 35;
        case 2:
            return 30;
        case 3:
            return 25;
        default:
            return 40;
        }
    }

    function barPadding(density) {
        switch (density) {
        case 1:
            return 3;
        case 2:
            return 2;
        case 3:
            return 1;
        default:
            return 4;
        }
    }

    function modulePadding(density) {
        switch (density) {
        case 1:
            return 5;
        case 2:
            return 4;
        case 3:
            return 3;
        default:
            return 7;
        }
    }

    function moduleIconSize(density) {
        switch (density) {
        case 1:
            return 16;
        case 2:
            return 14;
        case 3:
            return 13;
        default:
            return 18;
        }
    }

    function moduleRadius(density) {
        switch (density) {
        case 1:
            return 12;
        case 2:
            return 10;
        case 3:
            return 8;
        default:
            return 14;
        }
    }
}
