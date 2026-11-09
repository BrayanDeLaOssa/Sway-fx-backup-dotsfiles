#!/usr/bin/env bash
# =====================================================================
#  Adaptación dinámica de la configuración al sistema del usuario
# =====================================================================
#  Todo se hace sobre una copia temporal (staging). La configuración
#  original del repo nunca se modifica.
# =====================================================================

[[ -n "${SWAYFX_ADAPT_LOADED:-}" ]] && return 0
SWAYFX_ADAPT_LOADED=1

STAGE=""

stage_dotfiles() {
    new_tmp_dir
    STAGE="$NEW_TMP"
    cp -a "$DOTFILES_DIR/." "$STAGE/"
    debug "Staging: $STAGE"
}

# ---------------------------------------------------------------------
#  Elección de programas
# ---------------------------------------------------------------------
detect_choices() {
    # Terminal
    if [[ -z "${TERM_BIN:-}" ]]; then
        if have kitty; then
            TERM_BIN=kitty
        else
            TERM_BIN="$(first_cmd kitty foot alacritty wezterm ghostty st xterm || true)"
            TERM_BIN="${TERM_BIN:-kitty}"
        fi
    fi

    # Navegador
    if [[ -z "${BROWSER_BIN:-}" ]]; then
        BROWSER_BIN="$(first_cmd helium-browser firefox firefox-esr chromium chromium-browser brave-browser google-chrome-stable microsoft-edge || true)"
        if [[ -n "$BROWSER_BIN" ]]; then
            :
        elif (( INSTALL_BROWSER )); then
            BROWSER_BIN=helium-browser
        else
            BROWSER_BIN="$HOME/.config/sway/scripts/browser.sh"
        fi
    fi

    # Gestor de archivos
    if [[ -z "${FILEMANAGER_BIN:-}" ]]; then
        FILEMANAGER_BIN="$(first_cmd thunar nautilus nemo dolphin pcmanfm caja || true)"
        FILEMANAGER_BIN="${FILEMANAGER_BIN:-xdg-open ~}"
    fi

    # Comando para ejecutar dentro de la terminal
    case "$TERM_BIN" in
        foot)              TERM_EXEC="foot" ;;
        wezterm)           TERM_EXEC="wezterm start --" ;;
        kitty|alacritty|st|xterm|ghostty)
                           TERM_EXEC="$TERM_BIN -e" ;;
        *)                 TERM_EXEC="$TERM_BIN -e" ;;
    esac

    MOD_KEY="${MOD_KEY:-Mod4}"
    XKB_LAYOUT="${XKB_LAYOUT:-us,es}"

    case "$MOD_KEY" in
        Mod1|Mod3|Mod4|Mod5) ;;
        *) die "Valor inválido para --mod: $MOD_KEY (usa Mod1, Mod3, Mod4 o Mod5)" ;;
    esac

    if [[ -n "${TERM_BIN:-}" ]] && ! have "$TERM_BIN"; then
        warn "La terminal '$TERM_BIN' no está instalada; revisa la configuración."
    fi
    export TERM_BIN TERM_EXEC BROWSER_BIN FILEMANAGER_BIN MOD_KEY XKB_LAYOUT
}

# ---------------------------------------------------------------------
#  Variables globales de Sway
# ---------------------------------------------------------------------
adapt_core_vars() {
    local cfg="$STAGE/sway/config"
    replace_fixed "$cfg" 'set $mod Mod4' "set \$mod $MOD_KEY"
    replace_fixed "$cfg" 'set $term kitty' "set \$term $TERM_BIN"
    replace_fixed "$cfg" 'set $term_exec kitty -e' "set \$term_exec $TERM_EXEC"
    replace_fixed "$cfg" 'set $browser helium-browser' "set \$browser $BROWSER_BIN"
    replace_fixed "$cfg" 'set $filemanager thunar' "set \$filemanager $FILEMANAGER_BIN"
}

adapt_input() {
    local cfg="$STAGE/sway/config.d/10-input.conf"
    replace_fixed "$cfg" 'xkb_layout "us,es"' "xkb_layout \"$XKB_LAYOUT\""
    if [[ -n "${XKB_OPTIONS:-}" ]]; then
        replace_fixed "$cfg" 'xkb_options "grp:alt_shift_toggle"' "xkb_options \"$XKB_OPTIONS\""
    fi
}

# ---------------------------------------------------------------------
#  Apariencia: fuente y cursor
# ---------------------------------------------------------------------
adapt_appearance() {
    local appearance="$STAGE/sway/config.d/30-appearance.conf"
    local cursor_env="$STAGE/environment.d/95-cursor.conf"

    if ! font_available "Google Sans Flex"; then
        local fallback="sans-serif"
        font_available "Noto Sans" && fallback="Noto Sans"
        replace_fixed "$appearance" 'font pango:Google Sans Flex 10' "font pango:$fallback 10"
        warn "Fuente 'Google Sans Flex' no instalada; se usará '$fallback'."
    fi

    local cursor_theme='GLT_Chito (No White Border)'
    if ! cursor_available "$cursor_theme"; then
        local fallback
        fallback="$(first_cursor Adwaita breeze_cursors Breeze DMZ-White default || true)"
        fallback="${fallback:-default}"
        replace_fixed "$appearance" \
            "seat seat0 xcursor_theme \"$cursor_theme\" 24" \
            "seat seat0 xcursor_theme \"$fallback\" 24"
        replace_fixed "$cursor_env" \
            "XCURSOR_THEME=$cursor_theme" \
            "XCURSOR_THEME=$fallback"
        warn "Tema de cursor '$cursor_theme' no instalado; se usará '$fallback'."
    fi
}

adapt_kitty() {
    local kitty="$STAGE/kitty/kitty.conf"
    if ! font_available "Caskaydia"; then
        sed -i 's|^font_family.*|font_family monospace|' "$kitty"
        warn "Fuente CaskaydiaCove Nerd Font no instalada; kitty usará monospace."
    fi
}

adapt_environment() {
    local env_file="$STAGE/environment.d/90-dms.conf"
    replace_fixed "$env_file" 'TERMINAL=kitty' "TERMINAL=$TERM_BIN"
}

# ---------------------------------------------------------------------
#  SwayFX vs sway normal
# ---------------------------------------------------------------------
adapt_effects() {
    local effects="$STAGE/sway/config.d/31-effects.conf"

    if [[ -z "$SWAY_BIN" ]]; then
        warn "No detecté el binario de sway; dejo los efectos de SwayFX sin tocar."
        return 0
    fi
    if [[ $SWAY_IS_FX -eq 1 ]]; then
        return 0
    fi

    warn "Estás usando sway normal (no SwayFX): se desactivan blur, sombras y animaciones."
    local tmp="$STAGE/.effects.tmp"

    {
        echo "# ====================================================================="
        echo "#  SwayFX no está instalado: directivas de efectos desactivadas."
        echo "#  Instala swayfx si quieres blur, sombras, esquinas y animaciones."
        echo "# ====================================================================="
        echo
        awk '
            /^[[:space:]]*(blur|blur_radius|blur_passes|blur_noise|blur_brightness|blur_contrast|blur_saturation|blur_xray|animation_duration_ms|corner_radius|smart_corner_radius|shadows|shadow_blur_radius|shadow_color|shadow_inactive_color|shadow_offset)[[:space:]]/ {
                print "# [sway] " $0
                next
            }
            { print }
        ' "$effects"
    } >"$tmp"

    cp -a "$tmp" "$effects"
    rm -f -- "$tmp"
}

adapt_system_include() {
    if [[ ! -d /etc/sway/config.d ]]; then
        replace_fixed "$STAGE/sway/config" \
            'include /etc/sway/config.d/*' \
            '# include /etc/sway/config.d/*  (no existe en esta distro)'
    fi
}

# ---------------------------------------------------------------------
#  Salidas detectadas (solo como comentarios de ayuda)
# ---------------------------------------------------------------------
adapt_outputs() {
    [[ $SWAY_RUNNING -eq 1 ]] || return 0
    have jq || return 0

    local outputs
    outputs="$(swaymsg -t get_outputs 2>/dev/null | jq -r '
        .[] | select(.active != false)
        | "# output \(.name) resolution \(.current_mode.width // 0)x\(.current_mode.height // 0) position \(.rect.x // 0),\(.rect.y // 0) scale \(.scale // 1)"
    ' 2>/dev/null || true)"
    [[ -n "$outputs" ]] || return 0

    {
        echo
        echo "# --- Salidas detectadas al instalar (descomenta y ajusta si quieres fijarlas) ---"
        printf '%s\n' "$outputs"
    } >>"$STAGE/sway/config.d/20-outputs.conf"
}

# ---------------------------------------------------------------------
#  Modo portable sin DMS
# ---------------------------------------------------------------------
adapt_dms_fallbacks() {
    local use_dms=1
    if (( NO_DMS )) || [[ $DMS_INSTALLED -eq 0 ]]; then
        use_dms=0
    fi
    (( use_dms )) && return 0

    warn "DMS no está disponible: se activan los atajos portables sin DMS."

    local keys="$STAGE/sway/config.d/50-keybinds.conf"
    local media="$STAGE/sway/config.d/70-media-keys.conf"
    local wallpaper="$STAGE/sway/config.d/80-wallpaper-engine.conf"

    sed -i '1i # [install] Modo portable sin DMS: atajos traducidos a herramientas nativas.\n' "$keys"
    sed -i '1i # [install] Modo portable sin DMS: audio/brillo/capturas nativos.\n' "$media"
    sed -i '1i # [install] Modo portable sin DMS: los atajos de wallpaper se desactivan.\n' "$wallpaper"

    # Lanzadores / paneles de DMS
    replace_fixed "$keys" 'exec dms ipc call spotlight toggle' \
        'exec ~/.config/sway/scripts/launcher.sh'
    replace_fixed "$keys" 'exec dms ipc call settings focusOrToggle' \
        'exec $filemanager ~/.config/sway'
    replace_fixed "$keys" 'exec dms ipc call processlist focusOrToggle' \
        'exec $term_exec ~/.config/sway/scripts/processlist.sh'
    replace_fixed "$keys" 'exec dms ipc call notifications toggle' \
        'exec ~/.config/sway/scripts/notifications.sh'
    replace_fixed "$keys" 'exec dms ipc call dash toggle wallpaper' \
        "exec notify-send -a wallpaper 'Wallpaper' 'DMS no está instalado; usa swaybg'"
    replace_fixed "$keys" 'exec dms ipc call clipboard toggle' \
        'exec ~/.config/sway/scripts/clipboard.sh'
    replace_fixed "$keys" 'exec dms ipc call keybinds openWithPath sway ~/.config/sway/keybinds.flat.conf' \
        'exec $term_exec less ~/.config/sway/keybinds.flat.conf'
    replace_fixed "$keys" 'exec dms ipc call lock lock' \
        'exec ~/.config/sway/scripts/lock.sh'

    # Audio / brillo / capturas
    replace_fixed "$media" 'exec dms ipc call audio increment 3' \
        'exec ~/.config/sway/scripts/audio.sh up'
    replace_fixed "$media" 'exec dms ipc call audio decrement 3' \
        'exec ~/.config/sway/scripts/audio.sh down'
    replace_fixed "$media" 'exec dms ipc call audio mute' \
        'exec ~/.config/sway/scripts/audio.sh mute'
    replace_fixed "$media" 'exec pactl set-source-mute @DEFAULT_SOURCE@ toggle' \
        'exec ~/.config/sway/scripts/audio.sh micmute'
    replace_fixed "$media" 'exec dms ipc call brightness decrement 5 ""' \
        'exec ~/.config/sway/scripts/brightness.sh down'
    replace_fixed "$media" 'exec dms ipc call brightness increment 5 ""' \
        'exec ~/.config/sway/scripts/brightness.sh up'
    replace_fixed "$media" 'exec dms screenshot full' \
        'exec ~/.config/sway/scripts/screenshot.sh full'
    replace_fixed "$media" 'exec dms screenshot region' \
        'exec ~/.config/sway/scripts/screenshot.sh region'

    # Wallpaper Engine (plugin de DMS)
    replace_fixed "$wallpaper" 'exec dms ipc call plugins toggle linuxWallpaperEngine' \
        "exec notify-send -a wallpaper 'Wallpaper Engine' 'DMS no está instalado'"
    replace_fixed "$wallpaper" 'exec dms ipc call linuxWallpaperEngine next' \
        "exec notify-send -a wallpaper 'Wallpaper Engine' 'DMS no está instalado'"
    replace_fixed "$wallpaper" 'exec dms ipc call linuxWallpaperEngine picker' \
        "exec notify-send -a wallpaper 'Wallpaper Engine' 'DMS no está instalado'"
}

# ---------------------------------------------------------------------
#  Configuración de DMS (opcional)
# ---------------------------------------------------------------------
adapt_dms_config() {
    [[ -d "$STAGE/dms" ]] || return 0
    local f
    for f in "$STAGE"/dms/*.json; do
        [[ -f "$f" ]] || continue
        replace_fixed "$f" '@HOME@' "$HOME"
        if have jq && ! jq empty "$f" >/dev/null 2>&1; then
            die "JSON inválido tras adaptar: $(basename "$f")"
        fi
    done
}

# ---------------------------------------------------------------------
#  Validación previa a la instalación
# ---------------------------------------------------------------------
validate_stage() {
    if (( NO_VALIDATE )); then
        warn "Validación omitida (--no-validate)."
        return 0
    fi

    section "Validando configuración"

    # Sintaxis de los scripts.
    local script
    while IFS= read -r -d '' script; do
        if ! bash -n "$script"; then
            die "Error de sintaxis en $(basename "$script")"
        fi
    done < <(find "$STAGE" -type f -name '*.sh' -print0)
    ok "Scripts con sintaxis válida."

    # JSON de DMS.
    if [[ -d "$STAGE/dms" ]] && have jq; then
        local f
        for f in "$STAGE"/dms/*.json; do
            [[ -f "$f" ]] || continue
            jq empty "$f" >/dev/null 2>&1 || die "JSON inválido: $(basename "$f")"
        done
        ok "JSON de DMS válido."
    fi

    if [[ -z "$SWAY_BIN" ]]; then
        warn "sway no está instalado; no puedo validar el archivo de configuración."
        return 0
    fi

    local xdg="$STAGE/.xdg"
    mkdir -p "$xdg"
    chmod 700 "$xdg"

    local output status=0
    output="$(env -u WAYLAND_DISPLAY -u WAYLAND_SOCKET -u DISPLAY \
        XDG_RUNTIME_DIR="$xdg" \
        WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
        "$SWAY_BIN" -C -c "$STAGE/sway/config" 2>&1)" || status=$?

    if (( status != 0 )); then
        err "La configuración no pasó la validación de sway:"
        printf '%s\n' "$output" >&2
        if (( FORCE )); then
            warn "Continuando por --force (la sesión podría fallar)."
        else
            die "No se instaló nada. Corrige los errores o usa --force."
        fi
    else
        [[ -n "$output" ]] && warn "$output"
        ok "Configuración de sway válida."
    fi
}

# ---------------------------------------------------------------------
#  Instalación final
# ---------------------------------------------------------------------
install_stage() {
    section "Instalando archivos"

    install_tree "$STAGE/sway" "$HOME/.config/sway"
    install_tree "$STAGE/kitty" "$HOME/.config/kitty"
    install_tree "$STAGE/environment.d" "$HOME/.config/environment.d"

    if (( INSTALL_DMS_CONFIG )) && [[ $DMS_INSTALLED -eq 1 ]] && (( ! NO_DMS )); then
        install_file "$STAGE/dms/settings.json" "$HOME/.config/dms/settings.json"
        install_file "$STAGE/dms/plugin_settings.json" "$HOME/.config/dms/plugin_settings.json"
    else
        log "Configuración visual de DMS omitida (usa --with-dms-config para copiarla)."
    fi

    if (( ! DRY_RUN )); then
        chmod +x "$HOME/.config/sway/scripts/"*.sh 2>/dev/null || true

        if [[ -x "$HOME/.config/sway/scripts/gen-keybinds-flat.sh" ]]; then
            # El cheatsheet es un archivo generado: si ya existía, se respalda.
            track_file "$HOME/.config/sway/keybinds.flat.conf" || true
            if "$HOME/.config/sway/scripts/gen-keybinds-flat.sh"; then
                ok "Cheatsheet de atajos generado."
            else
                warn "No se pudo generar keybinds.flat.conf."
            fi
        fi
    fi

    enable_user_services
}

# ---------------------------------------------------------------------
#  Orquestador
# ---------------------------------------------------------------------
adapt_all() {
    detect_choices
    adapt_core_vars
    adapt_input
    adapt_appearance
    adapt_kitty
    adapt_environment
    adapt_effects
    adapt_system_include
    adapt_outputs
    adapt_dms_fallbacks
    adapt_dms_config
}
