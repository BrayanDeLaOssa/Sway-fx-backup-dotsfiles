#!/usr/bin/env bash
# Control de brillo portable. Uso: brightness.sh up|down
set -euo pipefail

action="${1:-}"
step="${BRIGHTNESS_STEP:-5}"

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a brightness "$1" "${2:-}" || true
}

if ! command -v brightnessctl >/dev/null 2>&1; then
    notify "Brillo" "Instala brightnessctl"
    exit 1
fi

case "$action" in
    up)   exec brightnessctl set "${step}%+" ;;
    down) exec brightnessctl set "${step}%-" ;;
    *)    printf 'Uso: %s up|down\n' "$0" >&2; exit 2 ;;
esac
