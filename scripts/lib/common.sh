#!/usr/bin/env bash
# =====================================================================
#  Utilidades comunes del instalador
# =====================================================================
# Se carga con `source`; no se ejecuta directamente.
# =====================================================================

# Evita cargar dos veces.
[[ -n "${SWAYFX_COMMON_LOADED:-}" ]] && return 0
SWAYFX_COMMON_LOADED=1

# ---------------------------------------------------------------------
# Rutas del proyecto
# ---------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO_ROOT
# shellcheck disable=SC2034  # se usa desde adapt.sh
readonly DOTFILES_DIR="$REPO_ROOT/dotfiles"

# ---------------------------------------------------------------------
# Opciones globales (las rellena install.sh)
# ---------------------------------------------------------------------
: "${DRY_RUN:=0}"
: "${ASSUME_YES:=0}"
: "${VERBOSE:=0}"
: "${FORCE:=0}"
: "${NO_DEPS:=0}"
: "${NO_VALIDATE:=0}"
: "${NO_BACKUP:=0}"
: "${NO_DMS:=0}"
: "${INSTALL_DMS_CONFIG:=0}"
: "${INSTALL_WALLPAPER:=0}"
: "${INSTALL_BROWSER:=0}"
: "${ACTION:=install}"

# ---------------------------------------------------------------------
# Colores / salida
# ---------------------------------------------------------------------
if [[ -t 2 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'
    C_CYAN=$'\033[36m'
else
    C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_CYAN=''
fi
readonly C_RESET C_BOLD C_DIM C_RED C_GREEN C_YELLOW C_BLUE C_CYAN

log()     { printf '%s::%s %s\n' "$C_CYAN" "$C_RESET" "$*" >&2; }
ok()      { printf '%s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*" >&2; }
warn()    { printf '%s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()     { printf '%s✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
debug()   { (( VERBOSE )) && printf '%s…%s %s\n' "$C_DIM" "$C_RESET" "$*" >&2 || true; }
section() { printf '\n%s%s== %s ==%s\n' "$C_BOLD" "$C_BLUE" "$*" "$C_RESET" >&2; }

die() {
    err "$*"
    exit 1
}

# Confirmación interactiva. Con --yes devuelve siempre 0.
confirm() {
    local prompt="${1:-¿Continuar?}" default="${2:-n}" answer
    (( ASSUME_YES )) && return 0
    [[ -t 0 ]] || return 1
    local hint='[s/N]'
    [[ "$default" == "s" ]] && hint='[S/n]'
    printf '%s %s ' "$prompt" "$hint" >&2
    read -r answer || return 1
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[sSyY]$ ]]
}

# Ejecuta respetando --dry-run.
run() {
    if (( DRY_RUN )); then
        log "[dry-run] $*"
        return 0
    fi
    "$@"
}

# Ejecuta como root (sudo solo si hace falta).
as_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

have() { command -v "$1" >/dev/null 2>&1; }

need_cmd() {
    have "$1" || die "Falta el comando '$1'. Instálalo y vuelve a intentar."
}

# Comprueba si un paquete está instalado según la distro.
pkg_installed() {
    local p="$1" status
    case "${PKG_MGR:-}" in
        pacman) pacman -Qq "$p" >/dev/null 2>&1 ;;
        apt)
            status="$(dpkg-query -W -f='${Status}' "$p" 2>/dev/null || true)"
            [[ "$status" == *"install ok installed"* ]]
            ;;
        dnf)    rpm -q "$p" >/dev/null 2>&1 ;;
        *)      return 1 ;;
    esac
}

# ---------------------------------------------------------------------
# Utilidades de texto / ficheros
# ---------------------------------------------------------------------
escape_sed_pattern() {
    printf '%s' "$1" | sed 's/[][\\.^$*+?(){}|]/\\&/g'
}

escape_sed_replacement() {
    printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

# Sustitución literal (no interpreta regex) en un archivo.
replace_fixed() {
    local file="$1" old="$2" new="$3"
    [[ -f "$file" ]] || return 0
    local old_esc new_esc
    old_esc="$(escape_sed_pattern "$old")"
    new_esc="$(escape_sed_replacement "$new")"
    sed -i "s|${old_esc}|${new_esc}|g" "$file"
}

# Añade una línea si no existe ya (comparación literal).
append_once() {
    local file="$1" line="$2"
    grep -Fqx -- "$line" "$file" 2>/dev/null || printf '%s\n' "$line" >>"$file"
}

# Comprueba si una fuente está instalada.
font_available() {
    have fc-list || return 1
    local list
    list="$(fc-list 2>/dev/null || true)"
    grep -qi -- "$1" <<<"$list"
}

# Comprueba si existe un tema de cursor.
cursor_available() {
    [[ -d "$HOME/.icons/$1" || -d "$HOME/.local/share/icons/$1" || -d "/usr/share/icons/$1" ]]
}

# Elige el primer comando disponible de una lista.
first_cmd() {
    local c
    for c in "$@"; do
        have "$c" && { printf '%s' "$c"; return 0; }
    done
    return 1
}

# Elige el primer tema de cursor disponible.
first_cursor() {
    local t
    for t in "$@"; do
        cursor_available "$t" && { printf '%s' "$t"; return 0; }
    done
    return 1
}

# Limpia archivos temporales al salir.
TMP_DIRS=()
cleanup_tmp() {
    local d
    for d in "${TMP_DIRS[@]:-}"; do
        [[ -n "$d" && -d "$d" ]] && rm -rf -- "$d"
    done
    return 0
}
make_tmp() {
    local d
    d="$(mktemp -d "${TMPDIR:-/tmp}/swayfx-dotfiles.XXXXXX")"
    TMP_DIRS+=("$d")
    printf '%s' "$d"
}

# Igual que make_tmp, pero deja la ruta en NEW_TMP y registra la limpieza
# en el proceso actual (make_tmp dentro de $(...) pierde TMP_DIRS).
NEW_TMP=""
new_tmp_dir() {
    NEW_TMP="$(mktemp -d "${TMPDIR:-/tmp}/swayfx-dotfiles.XXXXXX")"
    TMP_DIRS+=("$NEW_TMP")
}
trap cleanup_tmp EXIT

# Muestra un comando sugerido.
suggest() {
    printf '   %s%s%s\n' "$C_DIM" "$*" "$C_RESET" >&2
}
