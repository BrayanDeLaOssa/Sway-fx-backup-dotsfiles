# Config de SwayFX modular

`config` es el punto de entrada: define las variables globales (`$mod`, `$term`,
`$term_exec`, `$browser`, `$filemanager`, etc.) y carga automáticamente todo lo
que haya en `config.d/`.

## Estructura

| Archivo | Qué contiene |
|---|---|
| `config` | Variables globales + `include config.d/*.conf` |
| `config.d/00-environment.conf` | `dbus-update-activation-environment`, `sway-session.target`, autostart |
| `config.d/10-input.conf` | Teclado (US/ES), touchpad, ratón |
| `config.d/20-outputs.conf` | Monitores, resolución, escala, posición |
| `config.d/30-appearance.conf` | Fuente, gaps, bordes, colores, cursor |
| `config.d/31-effects.conf` | SwayFX: blur, animaciones, esquinas, sombras |
| `config.d/40-window-rules.conf` | `for_window`: flotantes, opacidad, etc. |
| `config.d/50-keybinds.conf` | Atajos generales, gestión de ventanas, modo resize |
| `config.d/60-workspaces.conf` | Workspaces, rueda del ratón, scratchpad |
| `config.d/70-media-keys.conf` | Audio, multimedia, brillo, capturas |
| `config.d/80-wallpaper-engine.conf` | Wallpaper animado (plugin DMS + script fallback) |

Los archivos se cargan en orden alfabético; por eso llevan prefijo numérico. Para
añadir un módulo nuevo basta con crear `config.d/NN-nombre.conf` (por ejemplo
`config.d/45-gaming.conf`).

## Scripts

| Script | Qué hace |
|---|---|
| `scripts/gen-keybinds-flat.sh` | Genera `keybinds.flat.conf` para el cheatsheet de DMS. |
| `scripts/wallpaper-engine.sh` | Lanzador idempotente de linux-wallpaperengine. |
| `scripts/launcher.sh` | Lanzador portable (wofi/fuzzel/rofi/bemenu). |
| `scripts/notifications.sh` | Centro de notificaciones portable (swaync/mako/dunst). |
| `scripts/clipboard.sh` | Historial de portapapeles con cliphist. |
| `scripts/audio.sh` | Volumen/mute con wpctl o pactl. |
| `scripts/brightness.sh` | Brillo con brightnessctl. |
| `scripts/screenshot.sh` | Capturas full/region con grim + slurp. |
| `scripts/lock.sh` | Bloqueo con swaylock o loginctl. |
| `scripts/processlist.sh` | btop/htop/top dentro de la terminal. |
| `scripts/browser.sh` | Abre el navegador por defecto si no hay uno conocido. |

Los scripts portables solo se usan cuando el instalador detecta que DMS no está
disponible (o cuando se instala con `--no-dms`).

## Comandos útiles

```bash
# Recargar sin cerrar sesión
swaymsg reload

# Validar la config completa (incluye todos los módulos)
sway -C -c ~/.config/sway/config

# Ver errores de la última recarga
journalctl --user -b | grep -i sway | tail -30
```

## Notas

- Las variables (`$mod`, `$left`, `$term`, `$term_exec`, `$browser`,
  `$filemanager`, ...) viven en `config` y están disponibles en todos los
  módulos porque los `include` se procesan después.
- `include` usa `wordexp(3)`: admite `~`, comodines `*` y variables de entorno.
- DMS **no** sigue los `include`, así que el cheatsheet usa un archivo plano
  generado: `keybinds.flat.conf`.
- `scripts/gen-keybinds-flat.sh` detecta automáticamente cualquier módulo de
  `config.d/` que contenga `bindsym`/`bindcode` y lo añade al archivo plano. Se
  ejecuta en cada `swaymsg reload` vía `exec_always`.
- El atajo `$mod+Shift+slash` abre el cheatsheet con ese archivo plano
  (`openWithPath`).
- El instalador adapta `$term`, `$term_exec`, `$browser`, `$filemanager`, la
  distribución de teclado, la fuente y el cursor a tu sistema.
- Los respaldos del instalador están en
  `~/.local/state/swayfx-dotfiles/backups/`.
