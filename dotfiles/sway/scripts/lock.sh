#!/usr/bin/env bash
# Bloqueo de sesión portable (fallback sin DMS).
set -euo pipefail

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a lock "$1" "${2:-}" || true
}

if command -v swaylock >/dev/null 2>&1; then
    exec swaylock -f -c 000000
fi
if command -v loginctl >/dev/null 2>&1; then
    exec loginctl lock-session
fi

notify "Bloqueo" "Instala swaylock o loginctl"
exit 1
