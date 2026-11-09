#!/usr/bin/env bash
# =====================================================================
#  Detección de distro, sesión y componentes
# =====================================================================

[[ -n "${SWAYFX_DISTRO_LOADED:-}" ]] && return 0
SWAYFX_DISTRO_LOADED=1

detect_distro() {
    OS_ID=""
    OS_ID_LIKE=""
    OS_NAME="Linux"
    OS_PRETTY_NAME="Linux"

    if [[ -r /etc/os-release ]]; then
        local key value
        while IFS='=' read -r key value; do
            case "$key" in
                ID)          eval "OS_ID=$value" ;;
                ID_LIKE)     eval "OS_ID_LIKE=$value" ;;
                NAME)        eval "OS_NAME=$value" ;;
                PRETTY_NAME) eval "OS_PRETTY_NAME=$value" ;;
            esac
        done </etc/os-release
    fi

    local like=" ${OS_ID} ${OS_ID_LIKE} "
    if [[ "$like" == *" arch "* || "$like" == *" cachyos "* || "$like" == *" manjaro "* || "$like" == *" endeavouros "* ]]; then
        DISTRO=arch
        PKG_MGR=pacman
    elif [[ "$like" == *" debian "* || "$like" == *" ubuntu "* || "$like" == *" linuxmint "* || "$like" == *" pop "* ]]; then
        DISTRO=debian
        PKG_MGR=apt
    elif [[ "$like" == *" fedora "* || "$like" == *" rhel "* || "$like" == *" centos "* || "$like" == *" nobara "* ]]; then
        DISTRO=fedora
        PKG_MGR=dnf
    else
        # Último recurso: mirar qué gestor existe.
        if have pacman; then DISTRO=arch; PKG_MGR=pacman
        elif have apt-get; then DISTRO=debian; PKG_MGR=apt
        elif have dnf; then DISTRO=fedora; PKG_MGR=dnf
        else DISTRO=unknown; PKG_MGR=""
        fi
    fi

    # Corregir si os-release miente y el gestor no existe.
    if [[ -n "$PKG_MGR" ]] && ! have "$PKG_MGR" && ! { [[ "$PKG_MGR" == "apt" ]] && have apt-get; }; then
        warn "No encuentro '$PKG_MGR'; se omitirá la instalación de paquetes."
        DISTRO=unknown
        PKG_MGR=""
    fi

    DISTRO_LABEL="${OS_PRETTY_NAME:-${OS_NAME:-Linux}}"
    export DISTRO PKG_MGR DISTRO_LABEL OS_ID OS_ID_LIKE OS_NAME
}

detect_aur_helper() {
    AUR_HELPER=""
    if [[ "$DISTRO" != "arch" ]]; then
        return 0
    fi
    if have yay; then AUR_HELPER=yay
    elif have paru; then AUR_HELPER=paru
    elif have pikaur; then AUR_HELPER=pikaur
    fi
}

detect_session() {
    SESSION_TYPE="${XDG_SESSION_TYPE:-desconocido}"
    CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-desconocido}"
    SWAY_RUNNING=0
    if have swaymsg && swaymsg -t get_version >/dev/null 2>&1; then
        SWAY_RUNNING=1
    fi
    export SWAY_RUNNING SESSION_TYPE CURRENT_DESKTOP
}

detect_sway() {
    SWAY_BIN="$(command -v sway 2>/dev/null || true)"
    SWAY_VERSION=""
    SWAY_IS_FX=0
    if [[ -n "$SWAY_BIN" ]]; then
        SWAY_VERSION="$("$SWAY_BIN" --version 2>/dev/null | head -n1 || true)"
        if [[ "$SWAY_VERSION" == *[Ss]way[Ff][Xx]* ]]; then
            SWAY_IS_FX=1
        fi
    fi
    export SWAY_BIN SWAY_VERSION SWAY_IS_FX
}

detect_dms() {
    DMS_BIN="$(command -v dms 2>/dev/null || true)"
    DMS_INSTALLED=0
    [[ -n "$DMS_BIN" ]] && DMS_INSTALLED=1
    DMS_VERSION=""
    if [[ $DMS_INSTALLED -eq 1 && "$PKG_MGR" == "pacman" ]]; then
        DMS_VERSION="$(pacman -Q dux-shell 2>/dev/null | awk '{print $2}' || true)"
    fi
    export DMS_BIN DMS_INSTALLED DMS_VERSION
}

detect_extras() {
    WALLPAPER_BIN="$(command -v linux-wallpaperengine 2>/dev/null || true)"
    STEAM_DIR="${STEAM_DIR:-$HOME/.local/share/Steam}"
    WE_ASSETS="$STEAM_DIR/steamapps/common/wallpaper_engine/assets"
    WE_WORKSHOP="$STEAM_DIR/steamapps/workshop/content/431960"
    export WALLPAPER_BIN STEAM_DIR WE_ASSETS WE_WORKSHOP
}

detect_all() {
    detect_distro
    detect_aur_helper
    detect_session
    detect_sway
    detect_dms
    detect_extras
}

# Resumen legible.
show_environment() {
    section "Entorno detectado"
    printf '  %-22s %s\n' "Distribución:" "$DISTRO_LABEL" >&2
    printf '  %-22s %s\n' "Gestor de paquetes:" "${PKG_MGR:-no detectado}" >&2
    printf '  %-22s %s\n' "Helper AUR:" "${AUR_HELPER:-no detectado}" >&2
    printf '  %-22s %s (%s)\n' "Sesión:" "$SESSION_TYPE" "$CURRENT_DESKTOP" >&2
    if [[ -n "$SWAY_VERSION" ]]; then
        printf '  %-22s %s\n' "Compositor:" "$SWAY_VERSION" >&2
    else
        printf '  %-22s %s\n' "Compositor:" "sway no instalado" >&2
    fi
    if [[ $DMS_INSTALLED -eq 1 ]]; then
        printf '  %-22s %s\n' "DMS (dux-shell):" "instalado${DMS_VERSION:+ ($DMS_VERSION)}" >&2
    else
        printf '  %-22s %s\n' "DMS (dux-shell):" "no instalado" >&2
    fi
    printf '  %-22s %s\n' "Usuario / HOME:" "$(id -un) / $HOME" >&2
}
