#!/usr/bin/env bash
# Lanzador de aplicaciones portable.
# Se usa solo en el modo sin DMS (el instalador reemplaza el atajo de DMS).
set -euo pipefail

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a launcher "$1" "${2:-}" || true
}

for cmd in \
    "wofi --show drun" \
    "fuzzel" \
    "rofi -show drun" \
    "bemenu-run" \
    "tofi-drun"; do
    bin=${cmd%% *}
    if command -v "$bin" >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        exec $cmd
    fi
done

notify "Lanzador" "Instala wofi, fuzzel, rofi o bemenu"
exit 1
