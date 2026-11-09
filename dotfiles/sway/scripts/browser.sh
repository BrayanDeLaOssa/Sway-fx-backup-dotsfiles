#!/usr/bin/env bash
# Abre el navegador por defecto (fallback cuando no hay un navegador conocido).
set -euo pipefail

if command -v xdg-open >/dev/null 2>&1; then
    exec xdg-open "https://duckduckgo.com"
fi
if command -v gio >/dev/null 2>&1; then
    exec gio open "https://duckduckgo.com"
fi
command -v notify-send >/dev/null 2>&1 \
    && notify-send -a browser "Navegador" "Instala un navegador o xdg-utils"
exit 1
