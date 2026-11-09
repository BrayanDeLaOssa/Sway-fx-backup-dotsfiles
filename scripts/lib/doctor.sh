#!/usr/bin/env bash
# =====================================================================
#  Diagnóstico del setup
# =====================================================================

[[ -n "${SWAYFX_DOCTOR_LOADED:-}" ]] && return 0
SWAYFX_DOCTOR_LOADED=1

doctor() {
    detect_all
    local problems=0

    section "Sistema"
    printf '  %-24s %s\n' "Distribución:" "$DISTRO_LABEL" >&2
    printf '  %-24s %s\n' "Kernel:" "$(uname -r)" >&2
    printf '  %-24s %s\n' "Sesión:" "$SESSION_TYPE ($CURRENT_DESKTOP)" >&2
    printf '  %-24s %s\n' "Sway en ejecución:" "$([[ $SWAY_RUNNING -eq 1 ]] && echo sí || echo no)" >&2
    printf '  %-24s %s\n' "Usuario / HOME:" "$(id -un) / $HOME" >&2

    section "Compositor y shell"
    if [[ -n "$SWAY_VERSION" ]]; then
        printf '  %-24s %s\n' "sway:" "$SWAY_VERSION" >&2
    else
        printf '  %-24s %s\n' "sway:" "NO INSTALADO" >&2
        problems=$((problems + 1))
    fi
    if [[ $SWAY_IS_FX -eq 1 ]]; then
        ok "SwayFX activo (efectos disponibles)."
    elif [[ -n "$SWAY_BIN" ]]; then
        warn "sway normal: blur/sombras/animaciones desactivados."
    fi
    if [[ $DMS_INSTALLED -eq 1 ]]; then
        ok "DMS instalado${DMS_VERSION:+ ($DMS_VERSION)}."
    else
        warn "DMS no instalado: se usa el modo portable."
    fi

    section "Dependencias"
    local -a critical_bins=(sway kitty jq playerctl brightnessctl)
    local -a optional_bins=(thunar grim slurp wl-copy wofi swaylock btop notify-send cliphist)
    local b
    for b in "${critical_bins[@]}"; do
        if have "$b"; then
            printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$b" >&2
        else
            printf '  %s✗%s %s\n' "$C_RED" "$C_RESET" "$b" >&2
            problems=$((problems + 1))
        fi
    done
    for b in "${optional_bins[@]}"; do
        if have "$b"; then
            printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$b" >&2
        else
            printf '  %s·%s %s (opcional)\n' "$C_YELLOW" "$C_RESET" "$b" >&2
        fi
    done

    section "Configuración"
    local cfg="$HOME/.config/sway/config"
    if [[ -f "$cfg" ]]; then
        ok "Existe $cfg"
        local modules
        modules="$(find "$HOME/.config/sway/config.d" -maxdepth 1 -name '*.conf' 2>/dev/null | wc -l)"
        printf '  %-24s %s\n' "Módulos config.d:" "$modules" >&2
        [[ -f "$HOME/.config/sway/keybinds.flat.conf" ]] \
            && ok "Cheatsheet keybinds.flat.conf presente." \
            || warn "Falta keybinds.flat.conf (se regenera al recargar sway)."

        local xdg
        xdg="$(mktemp -d "${TMPDIR:-/tmp}/swayfx-doctor.XXXXXX")"
        chmod 700 "$xdg"
        local out status=0
        if [[ -n "$SWAY_BIN" ]]; then
            out="$(env -u WAYLAND_DISPLAY -u WAYLAND_SOCKET -u DISPLAY \
                XDG_RUNTIME_DIR="$xdg" \
                WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
                "$SWAY_BIN" -C -c "$cfg" 2>&1)" || status=$?
        else
            status=1
            out="sway no está instalado"
        fi
        rm -rf "$xdg"
        if (( status == 0 )); then
            ok "La configuración pasa 'sway -C'."
        else
            err "La configuración tiene errores:"
            printf '%s\n' "$out" >&2
            problems=$((problems + 1))
        fi
    else
        err "No existe $cfg"
        problems=$((problems + 1))
    fi

    section "Apariencia y extras"
    if font_available "Caskaydia"; then
        ok "Fuente CaskaydiaCove Nerd Font instalada."
    else
        warn "Falta CaskaydiaCove Nerd Font (kitty usará monospace)."
    fi
    if font_available "Google Sans Flex"; then
        ok "Fuente Google Sans Flex instalada."
    elif font_available "Noto Sans"; then
        ok "Noto Sans disponible (fallback de Google Sans Flex)."
    else
        warn "Sin fuente de interfaz; revisa fontconfig."
    fi
    if cursor_available 'GLT_Chito (No White Border)'; then
        ok "Tema de cursor GLT_Chito instalado."
    else
        warn "Tema GLT_Chito no instalado; se usa el cursor por defecto."
    fi

    if [[ -n "$WALLPAPER_BIN" ]]; then
        ok "linux-wallpaperengine instalado."
        [[ -d "$WE_ASSETS" ]] && ok "Assets de Wallpaper Engine encontrados." \
            || warn "Faltan assets de Wallpaper Engine en $WE_ASSETS"
        [[ -d "$WE_WORKSHOP" ]] && ok "Escenas de Workshop encontradas." \
            || warn "No hay escenas en $WE_WORKSHOP"
    else
        warn "linux-wallpaperengine no instalado (wallpaper animado desactivado)."
    fi

    section "Servicios"
    if have systemctl; then
        if systemctl --user is-enabled dms.service >/dev/null 2>&1; then
            ok "dms.service habilitado."
        elif [[ $DMS_INSTALLED -eq 1 ]]; then
            warn "dms.service no está habilitado: systemctl --user enable dms.service"
        fi
    fi

    section "Resultado"
    if (( problems == 0 )); then
        ok "Todo listo. No se encontraron problemas críticos."
        return 0
    fi
    warn "Se encontraron $problems problema(s). Revisa los mensajes de arriba."
    return 1
}
