#!/usr/bin/env bash
# Control de audio portable. Uso: audio.sh up|down|mute|micmute
set -euo pipefail

action="${1:-}"
step="${AUDIO_STEP:-3}"

die_usage() {
    printf 'Uso: %s up|down|mute|micmute\n' "$0" >&2
    exit 2
}

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a audio "$1" "${2:-}" || true
}

# wpctl (WirePlumber) o pactl (PulseAudio/PipeWire).
if command -v wpctl >/dev/null 2>&1; then
    case "$action" in
        up)      wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%+" ;;
        down)    wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%-" ;;
        mute)    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
        micmute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
        *) die_usage ;;
    esac
elif command -v pactl >/dev/null 2>&1; then
    case "$action" in
        up)      pactl set-sink-volume @DEFAULT_SINK@ "+${step}%" ;;
        down)    pactl set-sink-volume @DEFAULT_SINK@ "-${step}%" ;;
        mute)    pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
        micmute) pactl set-source-mute @DEFAULT_SOURCE@ toggle ;;
        *) die_usage ;;
    esac
else
    notify "Audio" "No se encontró wpctl ni pactl"
    exit 1
fi
