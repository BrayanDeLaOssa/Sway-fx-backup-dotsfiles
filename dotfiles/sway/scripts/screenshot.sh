#!/usr/bin/env bash
# Capturas de pantalla portables. Uso: screenshot.sh full|region
set -euo pipefail

mode="${1:-region}"
dir="${XDG_PICTURES_DIR:-$HOME/Pictures}"
mkdir -p "$dir"
file="$dir/Screenshot-$(date +%Y%m%d-%H%M%S).png"

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a screenshot "$1" "${2:-}" || true
}

if ! command -v grim >/dev/null 2>&1; then
    notify "Captura" "Instala grim"
    exit 1
fi

case "$mode" in
    full)
        grim "$file"
        ;;
    region)
        if ! command -v slurp >/dev/null 2>&1; then
            notify "Captura" "Instala slurp para seleccionar una región"
            exit 1
        fi
        grim -g "$(slurp)" "$file"
        ;;
    *)
        printf 'Uso: %s full|region\n' "$0" >&2
        exit 2
        ;;
esac

notify "Captura guardada" "$file"
