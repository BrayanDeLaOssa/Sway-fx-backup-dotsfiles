#!/usr/bin/env bash
# =====================================================================
#  Paquetes por distribución
# =====================================================================
#  Estrategia:
#   - Arch/CachyOS: soporte completo (repos oficiales + AUR).
#   - Debian/Ubuntu y Fedora: mejor esfuerzo con sway normal.
#   - Si falta un paquete opcional, se avisa y se continúa.
# =====================================================================

[[ -n "${SWAYFX_PACKAGES_LOADED:-}" ]] && return 0
SWAYFX_PACKAGES_LOADED=1

# ---------------------------------------------------------------------
#  Arch / CachyOS
# ---------------------------------------------------------------------
ARCH_CORE=(
    base-devel git
    swayfx dux-shell
    kitty thunar xdg-utils
    jq playerctl brightnessctl
    grim slurp wl-clipboard
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    swaybg swayidle swaylock
    networkmanager bluez bluez-utils
    pipewire pipewire-pulse wireplumber
    polkit libnotify
    ttf-cascadia-code-nerd ttf-nerd-fonts-symbols noto-fonts noto-fonts-emoji
    adwaita-cursors adwaita-icon-theme
    matugen qt6ct
    btop cliphist wofi
    power-profiles-daemon i2c-tools
    gvfs thunar-volman tumbler xdg-user-dirs
)

ARCH_BROWSER=(helium-browser-bin)
ARCH_BROWSER_FALLBACK=(firefox)
ARCH_WALLPAPER=(linux-wallpaperengine-git)

# ---------------------------------------------------------------------
#  Debian / Ubuntu
# ---------------------------------------------------------------------
DEB_CORE=(
    sway kitty thunar
    jq playerctl brightnessctl
    grim slurp wl-clipboard
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    swaybg swayidle swaylock
    network-manager bluez
    pipewire wireplumber pipewire-pulse
    polkitd policykit-1
    libnotify-bin
    fonts-noto-core fonts-noto-color-emoji
    fonts-cascadia-code
    adwaita-icon-theme
    btop cliphist wofi
    pulseaudio-utils
    xdg-utils xdg-user-dirs
    gvfs thunar-volman tumbler
)

DEB_BROWSER=(firefox-esr firefox)

# ---------------------------------------------------------------------
#  Fedora
# ---------------------------------------------------------------------
FED_CORE=(
    sway kitty thunar
    jq playerctl brightnessctl
    grim slurp wl-clipboard
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    swaybg swayidle swaylock
    NetworkManager bluez
    pipewire wireplumber pipewire-pulseaudio
    polkit libnotify
    google-noto-sans-fonts google-noto-color-emoji-fonts
    cascadia-code-fonts
    adwaita-icon-theme
    btop cliphist wofi
    pulseaudio-utils
    xdg-utils xdg-user-dirs
    gvfs thunar-volman tumbler
)

FED_BROWSER=(firefox)

# ---------------------------------------------------------------------
#  Helpers
# ---------------------------------------------------------------------
arch_repo_has() {
    pacman -Si "$1" >/dev/null 2>&1 || pacman -Sg "$1" >/dev/null 2>&1
}

ensure_aur_helper() {
    [[ -n "$AUR_HELPER" ]] && return 0
    [[ "$DISTRO" == arch ]] || return 1

    if [[ $EUID -eq 0 ]]; then
        warn "No se puede compilar yay como root. Instala un helper AUR (yay/paru) como tu usuario."
        return 1
    fi
    if ! confirm "Hay paquetes que solo están en AUR. ¿Instalar yay-bin automáticamente?"; then
        warn "Sin helper AUR se omitirán esos paquetes."
        return 1
    fi

    log "Instalando base-devel y git..."
    run as_root pacman -S --needed --noconfirm base-devel git || return 1

    if (( DRY_RUN )); then
        log "[dry-run] se compilaría yay-bin desde AUR"
        AUR_HELPER=yay
        return 0
    fi

    local tmp
    new_tmp_dir
    tmp="$NEW_TMP"
    log "Clonando yay-bin..."
    if ! git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"; then
        warn "No se pudo clonar yay-bin."
        return 1
    fi
    if (cd "$tmp/yay-bin" && makepkg -si --noconfirm); then
        AUR_HELPER="$(command -v yay || true)"
        [[ -n "$AUR_HELPER" ]] && { ok "yay instalado."; return 0; }
    fi
    warn "No se pudo instalar yay-bin."
    return 1
}

install_arch_packages() {
    (($#)) || return 0
    local p
    local repo_pkgs=()
    local aur_pkgs=()

    for p in "$@"; do
        if [[ "$p" == "base-devel" ]]; then
            repo_pkgs+=("$p")
            continue
        fi
        pkg_installed "$p" && continue
        if arch_repo_has "$p"; then
            repo_pkgs+=("$p")
        else
            aur_pkgs+=("$p")
        fi
    done

    if ((${#repo_pkgs[@]})); then
        log "Repos oficiales: ${repo_pkgs[*]}"
        if ! run as_root pacman -S --needed --noconfirm "${repo_pkgs[@]}"; then
            warn "La instalación conjunta falló; probando una por una..."
            for p in "${repo_pkgs[@]}"; do
                run as_root pacman -S --needed --noconfirm "$p" || warn "No se pudo instalar: $p"
            done
        fi
    fi

    if ((${#aur_pkgs[@]})); then
        if [[ -z "$AUR_HELPER" ]]; then
            ensure_aur_helper || true
        fi
        if [[ -z "$AUR_HELPER" ]]; then
            warn "Sin helper AUR se omiten: ${aur_pkgs[*]}"
            return 0
        fi
        log "AUR ($AUR_HELPER): ${aur_pkgs[*]}"

        # yay acepta flags extra para no preguntar; paru/pikaur no.
        local -a helper_cmd=("$AUR_HELPER" -S --needed --noconfirm)
        if [[ "$(basename "$AUR_HELPER")" == "yay" ]]; then
            helper_cmd+=(--answerclean None --answerdiff None --answeredit None --answerupgrade None)
        fi

        if ! run "${helper_cmd[@]}" "${aur_pkgs[@]}"; then
            warn "La instalación AUR conjunta falló; probando una por una..."
            for p in "${aur_pkgs[@]}"; do
                run "${helper_cmd[@]}" "$p" || warn "No se pudo instalar desde AUR: $p"
            done
        fi
    fi
}

install_debian_packages() {
    (($#)) || return 0
    local p
    local pkgs=()
    for p in "$@"; do
        pkg_installed "$p" && continue
        pkgs+=("$p")
    done
    ((${#pkgs[@]})) || return 0

    log "apt: ${pkgs[*]}"
    run as_root apt-get update || warn "apt-get update falló; se intentará instalar igual."
    if ! run as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"; then
        warn "La instalación conjunta falló; probando una por una..."
        for p in "${pkgs[@]}"; do
            run as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$p" \
                || warn "No se pudo instalar: $p"
        done
    fi
}

install_fedora_packages() {
    (($#)) || return 0
    local p
    local pkgs=()
    for p in "$@"; do
        pkg_installed "$p" && continue
        pkgs+=("$p")
    done
    ((${#pkgs[@]})) || return 0

    log "dnf: ${pkgs[*]}"
    if ! run as_root dnf install -y "${pkgs[@]}"; then
        warn "La instalación conjunta falló; probando una por una..."
        for p in "${pkgs[@]}"; do
            run as_root dnf install -y "$p" || warn "No se pudo instalar: $p"
        done
    fi
}

install_packages() {
    case "$DISTRO" in
        arch)   install_arch_packages "$@" ;;
        debian) install_debian_packages "$@" ;;
        fedora) install_fedora_packages "$@" ;;
        *)      warn "Distro no soportada para instalar paquetes: $*" ;;
    esac
}

# ---------------------------------------------------------------------
#  Instalación principal de dependencias
# ---------------------------------------------------------------------
install_core_packages() {
    if (( NO_DEPS )); then
        warn "Instalación de paquetes omitida (--no-deps)."
        return 0
    fi
    if [[ "$DISTRO" == "unknown" ]]; then
        warn "No reconozco tu distro; no instalaré dependencias. Usa --no-deps y instálalas a mano."
        return 0
    fi

    if ! confirm "Se instalarán dependencias con ${PKG_MGR}. ¿Continuar?" "s"; then
        warn "Instalación de paquetes omitida por el usuario."
        return 0
    fi

    section "Dependencias del sistema"

    case "$DISTRO" in
        arch)
            # SwayFX suele estar en AUR fuera de CachyOS. Si no hay helper,
            # se intenta instalar yay; si no, se cae a sway normal.
            if ! arch_repo_has swayfx && [[ -z "$AUR_HELPER" ]]; then
                ensure_aur_helper || true
            fi

            local pkgs=("${ARCH_CORE[@]}")
            if ! arch_repo_has swayfx && [[ -z "$AUR_HELPER" ]]; then
                warn "SwayFX no está en los repos y no hay helper AUR."
                warn "Se instalará 'sway' normal; los efectos de SwayFX se desactivarán."
                local filtered=()
                local p
                for p in "${pkgs[@]}"; do
                    [[ "$p" == "swayfx" ]] || filtered+=("$p")
                done
                filtered+=(sway)
                pkgs=("${filtered[@]}")
            fi
            install_arch_packages "${pkgs[@]}"
            if ! have sway; then
                warn "No se instaló ningún compositor; probando 'sway' como respaldo..."
                install_arch_packages sway
            fi
            ;;
        debian)
            warn "SwayFX y DMS (dux-shell) no están empaquetados en Debian/Ubuntu."
            warn "Se instalará sway normal y se aplicará el modo portable sin DMS."
            install_debian_packages "${DEB_CORE[@]}"
            ;;
        fedora)
            warn "SwayFX y DMS (dux-shell) no están empaquetados en Fedora."
            warn "Se instalará sway normal y se aplicará el modo portable sin DMS."
            install_fedora_packages "${FED_CORE[@]}"
            ;;
    esac
}

install_optional_packages() {
    if (( NO_DEPS )); then
        return 0
    fi

    if (( INSTALL_BROWSER )); then
        section "Navegador (opcional)"
        case "$DISTRO" in
            arch)
                install_arch_packages "${ARCH_BROWSER[@]}"
                if ! have helium-browser; then
                    warn "No se pudo instalar Helium; probando Firefox."
                    install_arch_packages "${ARCH_BROWSER_FALLBACK[@]}"
                fi
                ;;
            debian) install_debian_packages "${DEB_BROWSER[@]}" ;;
            fedora) install_fedora_packages "${FED_BROWSER[@]}" ;;
        esac
    fi

    if (( INSTALL_WALLPAPER )); then
        section "Wallpaper Engine (opcional)"
        case "$DISTRO" in
            arch)
                install_arch_packages "${ARCH_WALLPAPER[@]}"
                if ! have linux-wallpaperengine; then
                    warn "No se pudo instalar linux-wallpaperengine."
                    warn "Necesitas Steam + Wallpaper Engine comprado para descargar escenas."
                fi
                ;;
            *)
                warn "linux-wallpaperengine solo está disponible en Arch/AUR."
                ;;
        esac
    fi
}

enable_user_services() {
    (( DRY_RUN )) && return 0
    have systemctl || return 0

    if [[ $DMS_INSTALLED -eq 1 ]] && (( ! NO_DMS )); then
        if systemctl --user list-unit-files dms.service >/dev/null 2>&1; then
            if systemctl --user is-enabled dms.service >/dev/null 2>&1; then
                debug "dms.service ya estaba habilitado."
            else
                run systemctl --user enable dms.service && ok "dms.service habilitado." \
                    || warn "No se pudo habilitar dms.service."
            fi
        else
            warn "No encuentro dms.service; revisa la instalación de dux-shell."
        fi
    fi
}
