#!/usr/bin/env bash
# Centro de notificaciones portable (fallback sin DMS).
set -euo pipefail

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a notifications "$1" "${2:-}" || true
}

if command -v swaync-client >/dev/null 2>&1; then
    exec swaync-client -t -sw
fi
if command -v makoctl >/dev/null 2>&1; then
    exec makoctl dismiss -a
fi
if command -v dunstctl >/dev/null 2>&1; then
    exec dunstctl close-all
fi

notify "Notificaciones" "Instala swaync, mako o dunst"
exit 1
