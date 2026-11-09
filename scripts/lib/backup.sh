#!/usr/bin/env bash
# =====================================================================
#  Respaldos, manifiesto e instalación de archivos
# =====================================================================
#  Cada archivo instalado se registra en un manifiesto. Antes de
#  sobrescribir se guarda una copia en:
#    ~/.local/state/swayfx-dotfiles/backups/<fecha>/
#  El manifiesto conserva el respaldo ORIGINAL (el primero que se hizo),
#  para que `uninstall` restaure tu configuración de antes.
# =====================================================================

[[ -n "${SWAYFX_BACKUP_LOADED:-}" ]] && return 0
SWAYFX_BACKUP_LOADED=1

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$STATE_HOME/swayfx-dotfiles"
MANIFEST="$STATE_DIR/manifest.tsv"
BACKUP_DIR="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)-$$"

init_state() {
    (( DRY_RUN )) && return 0
    mkdir -p "$STATE_DIR/backups"
    touch "$MANIFEST"
    if ! command -v flock >/dev/null 2>&1; then
        return 0
    fi
    exec 9>"$STATE_DIR/.lock"
    if ! flock -n 9; then
        die "Ya hay otra instalación/desinstalación en curso."
    fi
}

# Devuelve el respaldo original registrado para un destino (o vacío).
manifest_lookup() {
    local target="$1"
    [[ -f "$MANIFEST" ]] || return 0
    awk -F'\t' -v t="$target" '$1 == t { print $2; exit }' "$MANIFEST"
}

manifest_has() {
    [[ -n "$(manifest_lookup "$1")" ]]
}

record_manifest() {
    local target="$1" backup="$2"
    (( DRY_RUN )) && return 0
    printf '%s\t%s\n' "$target" "$backup" >>"$MANIFEST"
}

# Registra un archivo generado por el instalador (p. ej. keybinds.flat.conf)
# para poder restaurarlo/eliminarlo al desinstalar.
track_file() {
    local target="$1" backup
    manifest_has "$target" && return 0
    (( DRY_RUN )) && return 0

    if [[ -e "$target" ]]; then
        if (( NO_BACKUP )); then
            record_manifest "$target" "-"
        else
            backup="$(make_backup "$target")" || return 1
            record_manifest "$target" "$backup"
        fi
    else
        record_manifest "$target" "-"
    fi
}

# Ruta dentro del backup conservando la estructura desde $HOME.
backup_destination() {
    local target="$1" rel
    if [[ "$target" == "$HOME/"* ]]; then
        rel="${target#"$HOME"/}"
    else
        rel="root${target}"
    fi
    printf '%s/%s' "$BACKUP_DIR" "$rel"
}

# Copia un archivo/directorio al backup y devuelve la ruta del respaldo.
make_backup() {
    local target="$1" dest
    dest="$(backup_destination "$target")"
    mkdir -p "$(dirname "$dest")"
    cp -a -- "$target" "$dest"
    printf '%s' "$dest"
}

# install_file <origen> <destino>
install_file() {
    local src="$1" target="$2"
    [[ -e "$src" ]] || { warn "No existe el origen: $src"; return 1; }

    if (( DRY_RUN )); then
        log "[dry-run] copiar $(basename "$src") -> $target"
        return 0
    fi

    local original_backup safety_backup
    original_backup="$(manifest_lookup "$target")"

    if [[ -e "$target" ]]; then
        if (( NO_BACKUP )); then
            debug "Sin respaldo por --no-backup: $target"
        else
            safety_backup="$(make_backup "$target")" || {
                err "No se pudo respaldar: $target"
                return 1
            }
            if [[ -z "$original_backup" ]]; then
                original_backup="$safety_backup"
            fi
            debug "Respaldo: $safety_backup"
        fi
    fi

    if ! manifest_has "$target"; then
        record_manifest "$target" "${original_backup:--}"
    fi

    mkdir -p "$(dirname "$target")"
    cp -a -- "$src" "$target"
    ok "Instalado: $target"
}

# install_tree <dir_origen> <dir_destino>
install_tree() {
    local src_dir="$1" target_dir="$2"
    [[ -d "$src_dir" ]] || { warn "No existe el directorio: $src_dir"; return 1; }
    local src rel
    while IFS= read -r -d '' src; do
        rel="${src#"$src_dir"/}"
        install_file "$src" "$target_dir/$rel"
    done < <(find "$src_dir" -type f -print0 | sort -z)
}

# restore_file <destino> <respaldo|->>
restore_file() {
    local target="$1" backup="$2"

    if [[ "$backup" != "-" && -e "$backup" ]]; then
        if (( DRY_RUN )); then
            log "[dry-run] restaurar $backup -> $target"
            return 0
        fi
        rm -rf -- "$target"
        mkdir -p "$(dirname "$target")"
        cp -a -- "$backup" "$target"
        ok "Restaurado: $target"
    else
        if (( DRY_RUN )); then
            log "[dry-run] eliminar $target"
            return 0
        fi
        rm -f -- "$target"
        ok "Eliminado: $target"
    fi
}

# Elimina directorios vacíos que haya podido dejar la instalación.
prune_empty_dirs() {
    local dir
    for dir in \
        "$HOME/.config/sway/config.d" \
        "$HOME/.config/sway/scripts" \
        "$HOME/.config/sway" \
        "$HOME/.config/kitty" \
        "$HOME/.config/environment.d" \
        "$HOME/.config/dms"; do
        [[ -d "$dir" ]] && rmdir --ignore-fail-on-non-empty -- "$dir" 2>/dev/null || true
    done
}

uninstall_all() {
    [[ -f "$MANIFEST" ]] || { warn "No hay nada instalado (no existe el manifiesto)."; return 0; }
    [[ -s "$MANIFEST" ]] || { warn "El manifiesto está vacío."; return 0; }

    section "Desinstalando dotfiles"
    if ! confirm "¿Restaurar tus respaldos y quitar los archivos instalados?"; then
        die "Cancelado."
    fi

    local target backup
    while IFS=$'\t' read -r target backup; do
        [[ -n "$target" ]] || continue
        restore_file "$target" "${backup:--}"
    done <"$MANIFEST"

    if (( ! DRY_RUN )); then
        prune_empty_dirs
        mv "$MANIFEST" "$MANIFEST.uninstalled.$(date +%Y%m%d-%H%M%S)"
    fi

    ok "Desinstalación completada."
    log "Los respaldos se conservan en: $STATE_DIR/backups"
    if [[ $SWAY_RUNNING -eq 1 ]]; then
        suggest "swaymsg reload   # o cierra sesión y vuelve a entrar"
    fi
}

show_backups() {
    section "Respaldos disponibles"
    if [[ -d "$STATE_DIR/backups" ]]; then
        find "$STATE_DIR/backups" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' | sort -r >&2
    else
        warn "Todavía no hay respaldos."
    fi
}
