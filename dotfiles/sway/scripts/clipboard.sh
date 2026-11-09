#!/usr/bin/env bash
# Historial de portapapeles portable (fallback sin DMS).
# Requiere cliphist + wl-clipboard y un menú (wofi/fuzzel/rofi).
set -euo pipefail

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a clipboard "$1" "${2:-}" || true
}

if ! command -v cliphist >/dev/null 2>&1; then
    notify "Portapapeles" "Instala cliphist para usar el historial"
    exit 1
fi
if ! command -v wl-copy >/dev/null 2>&1; then
    notify "Portapapeles" "Instala wl-clipboard"
    exit 1
fi

if command -v wofi >/dev/null 2>&1; then
    cliphist list | wofi --dmenu | cliphist decode | wl-copy
elif command -v fuzzel >/dev/null 2>&1; then
    cliphist list | fuzzel --dmenu | cliphist decode | wl-copy
elif command -v rofi >/dev/null 2>&1; then
    cliphist list | rofi -dmenu | cliphist decode | wl-copy
else
    notify "Portapapeles" "Instala wofi, fuzzel o rofi"
    exit 1
fi
