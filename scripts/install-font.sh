#!/bin/sh
# Exo for XFCE — install the Material Symbols icon font.
#
# The shell uses Material Symbols for every icon (as Exo does on Wayland).
# This downloads the variable font into ~/.local/share/fonts and refreshes the
# font cache. Nothing is installed system-wide.
set -e

FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
FONT_FILE="$FONT_DIR/MaterialSymbolsRounded.ttf"
URL="https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"

if fc-list 2>/dev/null | grep -qi "Material Symbols"; then
    echo "Material Symbols is already installed."
    exit 0
fi

mkdir -p "$FONT_DIR"

if command -v curl >/dev/null 2>&1; then
    echo "Downloading Material Symbols Rounded…"
    curl -fL --progress-bar -o "$FONT_FILE" "$URL"
elif command -v wget >/dev/null 2>&1; then
    echo "Downloading Material Symbols Rounded…"
    wget -q --show-progress -O "$FONT_FILE" "$URL"
else
    echo "install-font.sh: neither curl nor wget is available." >&2
    echo "Install the font manually as 'Material Symbols Rounded', e.g.:" >&2
    echo "  sudo pacman -S ttf-material-symbols-variable   # Arch" >&2
    echo "  sudo dnf install google-material-symbols-fonts # Fedora (may be unavailable)" >&2
    exit 1
fi

if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$FONT_DIR" >/dev/null
fi

echo "Installed to $FONT_FILE"
fc-list 2>/dev/null | grep -i "Material Symbols" | head -3 || true
