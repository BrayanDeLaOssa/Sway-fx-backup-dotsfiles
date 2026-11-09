#!/usr/bin/env bash
# =====================================================================
#  Prueba de humo del instalador (no toca tu HOME real)
# =====================================================================
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAKE="$(mktemp -d "${TMPDIR:-/tmp}/swayfx-test.XXXXXX")"
cleanup() { rm -rf -- "$FAKE"; }
trap cleanup EXIT

pass() { printf '\033[32m✓\033[0m %s\n' "$*"; }
fail() { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

echo "== Prueba 1: dry-run no modifica nada =="
mkdir -p "$FAKE/dry/.config"
HOME="$FAKE/dry" XDG_STATE_HOME="$FAKE/dry/.local/state" \
    "$REPO_ROOT/install.sh" --dry-run --no-deps -y --minimal --no-dms \
    >"$FAKE/dry.log" 2>&1 || fail "dry-run falló (ver $FAKE/dry.log)"
[[ ! -e "$FAKE/dry/.config/sway/config" ]] || fail "dry-run creó archivos"
pass "dry-run limpio"

echo "== Prueba 2: instalación + desinstalación =="
mkdir -p "$FAKE/home/.config/sway"
printf '# CONFIG ORIGINAL\nset $mod Mod4\n' >"$FAKE/home/.config/sway/config"

HOME="$FAKE/home" XDG_STATE_HOME="$FAKE/home/.local/state" \
    "$REPO_ROOT/install.sh" --no-deps -y --minimal --no-dms \
    >"$FAKE/install.log" 2>&1 || fail "instalación falló (ver $FAKE/install.log)"

[[ -f "$FAKE/home/.config/sway/config" ]] || fail "no se instaló la config"
[[ -f "$FAKE/home/.config/sway/config.d/50-keybinds.conf" ]] || fail "faltan módulos"
[[ -f "$FAKE/home/.config/sway/keybinds.flat.conf" ]] || fail "faltan atajos planos"
[[ -f "$FAKE/home/.local/state/swayfx-dotfiles/manifest.tsv" ]] || fail "falta el manifiesto"
grep -q 'launcher.sh' "$FAKE/home/.config/sway/config.d/50-keybinds.conf" \
    || fail "el modo portable no se aplicó"
grep -q 'include config.d/\*.conf' "$FAKE/home/.config/sway/config" \
    || fail "el include modular no está"
pass "instalación con modo portable"

echo "== Prueba 3: la config instalada no tiene variables rotas =="
grep -q 'set \$mod Mod4' "$FAKE/home/.config/sway/config" || fail "variable \$mod rota"
grep -q 'set \$term ' "$FAKE/home/.config/sway/config" || fail "variable \$term rota"
pass "variables de Sway intactas"

HOME="$FAKE/home" XDG_STATE_HOME="$FAKE/home/.local/state" \
    "$REPO_ROOT/install.sh" uninstall -y \
    >"$FAKE/uninstall.log" 2>&1 || fail "desinstalación falló (ver $FAKE/uninstall.log)"

[[ "$(cat "$FAKE/home/.config/sway/config")" == *"CONFIG ORIGINAL"* ]] \
    || fail "no se restauró la config original"
[[ ! -e "$FAKE/home/.config/sway/config.d/50-keybinds.conf" ]] \
    || fail "no se eliminaron los módulos instalados"
[[ ! -e "$FAKE/home/.config/sway/keybinds.flat.conf" ]] \
    || fail "no se eliminó el cheatsheet generado"
pass "desinstalación y restauración"

echo
pass "Todas las pruebas pasaron."
