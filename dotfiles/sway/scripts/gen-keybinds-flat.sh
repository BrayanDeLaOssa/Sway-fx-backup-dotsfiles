#!/usr/bin/env bash
# Genera ~/.config/sway/keybinds.flat.conf para el cheatsheet de DMS.
# DMS no sigue los `include` de Sway, así que necesita un archivo plano.
# Se ejecuta con `exec_always` en cada recarga (ver 00-environment.conf).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$DIR/keybinds.flat.conf"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

BIND_RE='^[[:space:]]*(bindsym|bindcode|unbindsym|unbindcode)[[:space:]]'

{
    echo "# ====================================================================="
    echo "#  ARCHIVO GENERADO AUTOMÁTICAMENTE — NO EDITAR A MANO"
    echo "#  Incluye todos los módulos de config.d/ que tengan atajos."
    echo "#  Regenerar: ~/.config/sway/scripts/gen-keybinds-flat.sh"
    echo "# ====================================================================="
    echo

    # Variables globales (para que DMS resuelva $mod, $left, $term, etc.)
    grep -E '^[[:space:]]*set[[:space:]]' "$DIR/config" || true
    echo

    # Atajos escritos directamente en el archivo principal (si los hubiera)
    if grep -qE "$BIND_RE" "$DIR/config"; then
        echo "# ---------------------------------------------------------------------"
        echo "# config (atajos directos)"
        echo "# ---------------------------------------------------------------------"
        grep -E "$BIND_RE" "$DIR/config" || true
        echo
    fi

    # Módulos con atajos, en orden alfabético (prefijo numérico)
    for f in "$DIR"/config.d/*.conf; do
        [ -f "$f" ] || continue
        if grep -qE "$BIND_RE" "$f"; then
            echo "# ---------------------------------------------------------------------"
            echo "# $(basename "$f")"
            echo "# ---------------------------------------------------------------------"
            cat "$f"
            echo
        fi
    done
} > "$TMP"

mv "$TMP" "$OUT"
