#!/usr/bin/env bash
# =====================================================================
#  SwayFX dotfiles · instalador automático
#  https://github.com/BrayanDeLaOssa/Sway-fx-backup-dotsfiles
# =====================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/scripts/lib/common.sh"
# shellcheck source=scripts/lib/distro.sh
source "$SCRIPT_DIR/scripts/lib/distro.sh"
# shellcheck source=scripts/lib/packages.sh
source "$SCRIPT_DIR/scripts/lib/packages.sh"
# shellcheck source=scripts/lib/backup.sh
source "$SCRIPT_DIR/scripts/lib/backup.sh"
# shellcheck source=scripts/lib/adapt.sh
source "$SCRIPT_DIR/scripts/lib/adapt.sh"
# shellcheck source=scripts/lib/doctor.sh
source "$SCRIPT_DIR/scripts/lib/doctor.sh"

readonly VERSION="1.0.0"

# ---------------------------------------------------------------------
#  Ayuda
# ---------------------------------------------------------------------
usage() {
    cat <<EOF
${C_BOLD}SwayFX dotfiles${C_RESET} v$VERSION
Configuración modular de SwayFX + DMS para CachyOS/Arch (y modo portable).

${C_BOLD}USO${C_RESET}
  $0 [comando] [opciones]

${C_BOLD}COMANDOS${C_RESET}
  install              Instala todo (por defecto).
  uninstall            Restaura tus respaldos y quita lo instalado.
  doctor               Diagnóstico del setup y dependencias.
  backups              Lista los respaldos disponibles.
  help                 Muestra esta ayuda.

${C_BOLD}OPCIONES${C_RESET}
  -y, --yes            No preguntar; aceptar valores por defecto.
  -n, --dry-run        Mostrar lo que se haría sin cambiar nada.
  -v, --verbose        Salida detallada.
      --no-deps        No instalar paquetes del sistema.
      --no-validate    No validar la config con 'sway -C'.
      --no-backup      No crear respaldos (¡no recomendado!).
      --force          Continuar aunque la validación falle.
      --no-dms         Forzar el modo portable sin DMS.
      --full           Instalar extras: navegador, wallpaper engine y config DMS.
      --minimal        Solo lo esencial (sin extras opcionales).
      --with-dms-config
                       Copiar también la configuración visual de DMS.
      --with-wallpaper Instalar linux-wallpaperengine (AUR).
      --with-browser   Instalar Helium/Firefox.

${C_BOLD}PERSONALIZACIÓN${C_RESET}
      --term NOMBRE        Terminal (por defecto: kitty).
      --browser NOMBRE     Navegador (helium-browser, firefox, ...).
      --filemanager NOMBRE Gestor de archivos (thunar, nautilus, ...).
      --mod TECLA          Modificador: Mod4 (Super, por defecto), Mod1 (Alt)...
      --layout LAYOUT      Distribución(es) XKB, p. ej. "us,es" o "latam".
      --xkb-options OPC    Opciones XKB, p. ej. "grp:alt_shift_toggle".

${C_BOLD}EJEMPLOS${C_RESET}
  $0                         # instalación normal (pregunta lo necesario)
  $0 --full -y               # todo automático
  $0 --minimal --no-deps     # solo archivos, sin tocar paquetes
  $0 --term foot --mod Mod1  # personaliza terminal y tecla Super/Alt
  $0 doctor                  # comprobar qué falta
  $0 uninstall               # volver a tu configuración anterior

${C_BOLD}NOTAS${C_RESET}
  - No lo ejecutes con sudo: pedirá permisos solo para instalar paquetes.
  - Arch/CachyOS tiene soporte completo (SwayFX + DMS + AUR).
  - Debian/Fedora usan sway normal y el modo portable sin DMS.
  - Los respaldos quedan en ~/.local/state/swayfx-dotfiles/backups/.
EOF
}

# ---------------------------------------------------------------------
#  Argumentos
# ---------------------------------------------------------------------
DMS_CONFIG_SET=0

parse_args() {
    while (($#)); do
        case "$1" in
            install|uninstall|doctor|backups|help) ACTION="$1"; shift ;;
            -y|--yes)      ASSUME_YES=1; shift ;;
            -n|--dry-run)  DRY_RUN=1; shift ;;
            -v|--verbose)  VERBOSE=1; shift ;;
            --no-deps)     NO_DEPS=1; shift ;;
            --no-validate) NO_VALIDATE=1; shift ;;
            --no-backup)   NO_BACKUP=1; shift ;;
            --force)       FORCE=1; shift ;;
            --no-dms)      NO_DMS=1; INSTALL_DMS_CONFIG=0; DMS_CONFIG_SET=1; shift ;;
            --with-dms-config) INSTALL_DMS_CONFIG=1; DMS_CONFIG_SET=1; shift ;;
            --with-wallpaper)  INSTALL_WALLPAPER=1; shift ;;
            --with-browser)    INSTALL_BROWSER=1; shift ;;
            --full)        INSTALL_BROWSER=1; INSTALL_WALLPAPER=1
                           INSTALL_DMS_CONFIG=1; DMS_CONFIG_SET=1; shift ;;
            --minimal)     INSTALL_BROWSER=0; INSTALL_WALLPAPER=0
                           INSTALL_DMS_CONFIG=0; DMS_CONFIG_SET=1; shift ;;
            --term)        TERM_BIN="${2:?Falta el valor de --term}"; shift 2 ;;
            --term=*)      TERM_BIN="${1#*=}"; shift ;;
            --browser)     BROWSER_BIN="${2:?Falta el valor de --browser}"; shift 2 ;;
            --browser=*)   BROWSER_BIN="${1#*=}"; shift ;;
            --filemanager) FILEMANAGER_BIN="${2:?Falta el valor de --filemanager}"; shift 2 ;;
            --filemanager=*) FILEMANAGER_BIN="${1#*=}"; shift ;;
            --mod)         MOD_KEY="${2:?Falta el valor de --mod}"; shift 2 ;;
            --mod=*)       MOD_KEY="${1#*=}"; shift ;;
            --layout)      XKB_LAYOUT="${2:?Falta el valor de --layout}"; shift 2 ;;
            --layout=*)    XKB_LAYOUT="${1#*=}"; shift ;;
            --xkb-options) XKB_OPTIONS="${2:?Falta el valor de --xkb-options}"; shift 2 ;;
            --xkb-options=*) XKB_OPTIONS="${1#*=}"; shift ;;
            -h|--help)     ACTION=help; shift ;;
            --version)     printf '%s\n' "$VERSION"; exit 0 ;;
            --)            shift; break ;;
            *)             die "Opción desconocida: $1 (usa --help)" ;;
        esac
    done
}

# ---------------------------------------------------------------------
#  Flujo de instalación
# ---------------------------------------------------------------------
ask_dms_config() {
    (( DMS_CONFIG_SET )) && return 0
    (( NO_DMS )) && return 0
    [[ $DMS_INSTALLED -eq 1 ]] || return 0
    if confirm "¿Copiar también la configuración visual de DMS (barra, widgets, tema)?"; then
        INSTALL_DMS_CONFIG=1
    fi
}

do_install() {
    detect_all
    show_environment

    if (( NO_BACKUP )); then
        warn "Modo --no-backup: no se guardará tu configuración anterior."
    fi

    init_state
    install_core_packages

    # Reevaluar tras instalar paquetes.
    detect_aur_helper
    detect_sway
    detect_dms
    detect_extras

    ask_dms_config
    install_optional_packages
    detect_dms
    detect_extras

    stage_dotfiles
    adapt_all
    validate_stage
    install_stage

    section "Resultado"
    ok "Instalación completada."
    log "Respaldos: $STATE_DIR/backups"

    if [[ -f "$HOME/.config/sway/config" ]]; then
        local mods
        mods="$(find "$HOME/.config/sway/config.d" -maxdepth 1 -name '*.conf' 2>/dev/null | wc -l)"
        printf '  %-22s %s\n' "Configuración:" "$HOME/.config/sway" >&2
        printf '  %-22s %s\n' "Módulos:" "$mods" >&2
        printf '  %-22s %s\n' "Terminal:" "$TERM_BIN" >&2
        printf '  %-22s %s\n' "Modificador:" "$MOD_KEY" >&2
        printf '  %-22s %s\n' "DMS:" "$([[ $DMS_INSTALLED -eq 1 && $NO_DMS -eq 0 ]] && echo sí || echo 'no (modo portable)')" >&2
    fi

    if (( DRY_RUN )); then
        warn "Esto fue un simulacro (--dry-run). No se cambió nada."
        return 0
    fi

    cat >&2 <<EOF

${C_BOLD}Próximos pasos${C_RESET}
  1. Cierra sesión y vuelve a entrar eligiendo la sesión ${C_CYAN}swayfx${C_RESET}.
  2. Si ya estabas dentro de sway:  ${C_DIM}swaymsg reload${C_RESET}
  3. Revisa los atajos:              ${C_DIM}\$mod+Shift+/${C_RESET}
  4. Diagnóstico cuando quieras:     ${C_DIM}$0 doctor${C_RESET}

EOF

    local real_home
    real_home="$(getent passwd "$(id -u)" | cut -d: -f6)"
    if [[ $SWAY_RUNNING -eq 1 && "$HOME" == "$real_home" && $ASSUME_YES -eq 0 ]] \
        && confirm "¿Recargar Sway ahora para aplicar los cambios?"; then
        if swaymsg reload; then
            ok "Sway recargado."
        else
            warn "No se pudo recargar; hazlo manualmente con: swaymsg reload"
        fi
    fi
}

# ---------------------------------------------------------------------
#  Main
# ---------------------------------------------------------------------
main() {
    parse_args "$@"

    if [[ "$ACTION" != "help" && $EUID -eq 0 && "${SWAYFX_ALLOW_ROOT:-0}" != "1" ]]; then
        die "No ejecutes este script como root. Usa tu usuario; se pedirá sudo para los paquetes."
    fi

    case "$ACTION" in
        help)
            usage
            exit 0
            ;;
        doctor)
            doctor
            exit $?
            ;;
        backups)
            detect_all
            init_state
            show_backups
            exit 0
            ;;
        uninstall)
            detect_all
            init_state
            uninstall_all
            exit 0
            ;;
        install)
            :
            ;;
        *)
            die "Comando desconocido: $ACTION"
            ;;
    esac

    # Los dotfiles se instalan en el HOME del usuario, no en /root.
    [[ -n "${HOME:-}" ]] || die "HOME no está definido."
    [[ -d "$HOME" ]] || die "HOME no existe: $HOME"

    do_install
}

main "$@"
