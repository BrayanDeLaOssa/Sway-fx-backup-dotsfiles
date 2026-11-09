#!/usr/bin/env bash
# =====================================================================
#  linux-wallpaperengine · lanzador idempotente para SwayFX + DMS
# =====================================================================
# Uso:
#   wallpaper-engine.sh [--force] [salida] [escena]
#   WE_OUTPUT=eDP-1 WE_SCENE=3403072395 wallpaper-engine.sh
#
# Sin argumentos detecta la salida enfocada y la escena configurada en el
# plugin de DMS (~/.config/dms/plugin_settings.json). Si el plugin está
# activo o ya hay un linux-wallpaperengine en esa salida, no lanza nada:
# así `swaymsg reload` o un `exec_always` nunca duplican procesos.
#
# Variables de entorno:
#   WE_OUTPUT   salida de video (por defecto: la enfocada, luego eDP-1)
#   WE_SCENE    ID del Workshop o ruta absoluta a una escena
#   WE_FPS      FPS (por defecto 60)
#   WE_LAYER    capa wlr-layer-shell (por defecto background)
#   WE_SILENT   1 = silenciar (por defecto), 0 = reproducir audio
#   WE_VOLUME   volumen si WE_SILENT=0 (por defecto 50)
#   WE_SCALING  modo de escalado opcional (fill, fit, stretch...)
#   WE_NO_FULLSCREEN_PAUSE=1  no pausar cuando hay una app a pantalla completa
#   WE_STEAM / WE_ASSETS / WE_WORKSHOP  rutas personalizadas
# =====================================================================
set -euo pipefail

die() { printf 'wallpaper-engine: %s\n' "$*" >&2; exit 1; }

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
    FORCE=1
    shift
fi

STEAM="${WE_STEAM:-$HOME/.local/share/Steam}"
WORKSHOP_ID="${WE_WORKSHOP_ID:-431960}"
ASSETS="${WE_ASSETS:-$STEAM/steamapps/common/wallpaper_engine/assets}"
WORKSHOP="${WE_WORKSHOP:-$STEAM/steamapps/workshop/content/$WORKSHOP_ID}"
SETTINGS="${WE_DMS_SETTINGS:-$HOME/.config/dms/plugin_settings.json}"

# --- Salida de video -------------------------------------------------
OUTPUT="${1:-${WE_OUTPUT:-}}"
if [[ -z "$OUTPUT" ]]; then
    OUTPUT="$(swaymsg -t get_outputs 2>/dev/null \
        | jq -r '[.[] | select(.focused == true)][0].name // empty' 2>/dev/null || true)"
fi
if [[ -z "$OUTPUT" ]]; then
    OUTPUT="$(swaymsg -t get_outputs 2>/dev/null \
        | jq -r '[.[] | select(.active != false)][0].name // empty' 2>/dev/null || true)"
fi
OUTPUT="${OUTPUT:-eDP-1}"

# --- Escena ----------------------------------------------------------
SCENE="${2:-${WE_SCENE:-}}"
if [[ -z "$SCENE" && -f "$SETTINGS" ]]; then
    SCENE="$(jq -r --arg o "$OUTPUT" '
        (.linuxWallpaperEngine.monitorScenes // {}) as $m
        | ($m[$o] // $m["*"] // empty)
    ' "$SETTINGS" 2>/dev/null || true)"
fi
if [[ -z "$SCENE" ]]; then
    SCENE="$(find "$WORKSHOP" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
        | sort | head -n1 || true)"
fi
[[ -n "$SCENE" ]] || die "no pude determinar la escena; pasa un ID o define WE_SCENE"

# Un ID se resuelve contra el Workshop 431960; una ruta absoluta se usa tal cual.
if [[ "$SCENE" == /* ]]; then
    BG="$SCENE"
else
    BG="$WORKSHOP/$SCENE"
fi

# --- Comprobaciones --------------------------------------------------
command -v linux-wallpaperengine >/dev/null 2>&1 || die "linux-wallpaperengine no está en PATH"
[[ -d "$ASSETS" ]] || die "no existe la carpeta de assets: $ASSETS"
[[ -d "$BG" ]] || die "no existe la escena: $BG (¿Steam Workshop descargado?)"

# --- Sin duplicados --------------------------------------------------
# El plugin de DMS es el gestor recomendado: si está cargado, no lanzamos
# una segunda instancia manual.
if [[ $FORCE -eq 0 ]] && command -v dms >/dev/null 2>&1; then
    if [[ "$(dms ipc call plugins status linuxWallpaperEngine 2>/dev/null || true)" == "loaded" ]]; then
        printf 'wallpaper-engine: el plugin de DMS ya gestiona el wallpaper; usa --force para lanzar otro\n' >&2
        exit 0
    fi
fi

if [[ $FORCE -eq 0 ]] && pgrep -f -- "linux-wallpaperengine .*--screen-root ${OUTPUT}( |\$)" >/dev/null; then
    printf 'wallpaper-engine: ya hay un wallpaper en %s; no se lanza otro\n' "$OUTPUT" >&2
    exit 0
fi

# Candado por salida: evita carreras entre dos invocaciones simultáneas
# (login + `exec_always` de una recarga).
LOCK="${XDG_RUNTIME_DIR:-/tmp}/linux-wallpaperengine-${OUTPUT}.lock"
exec 9>"$LOCK"
if ! flock -n 9; then
    printf 'wallpaper-engine: otro lanzador está activo para %s\n' "$OUTPUT" >&2
    exit 0
fi

# --- Argumentos ------------------------------------------------------
# Nota de capas: "background" queda estrictamente por debajo de "bottom",
# que es donde DMS dibuja sus widgets de escritorio. Con la capa por
# defecto del motor ("bottom"), el wallpaper puede tapar los widgets cada
# vez que el proceso se relanza.
ARGS=(
    --assets-dir "$ASSETS"
    --screen-root "$OUTPUT"
    --bg "$BG"
    --layer "${WE_LAYER:-background}"
    --fps "${WE_FPS:-60}"
)

if [[ "${WE_SILENT:-1}" == "1" ]]; then
    ARGS+=(--silent)
else
    ARGS+=(--volume "${WE_VOLUME:-50}")
fi

[[ -n "${WE_SCALING:-}" ]] && ARGS+=(--scaling "$WE_SCALING")
[[ "${WE_NO_FULLSCREEN_PAUSE:-0}" == "1" ]] && ARGS+=(--no-fullscreen-pause)

printf 'wallpaper-engine: %s -> %s (capa %s)\n' "$BG" "$OUTPUT" "${WE_LAYER:-background}" >&2
exec linux-wallpaperengine "${ARGS[@]}"
