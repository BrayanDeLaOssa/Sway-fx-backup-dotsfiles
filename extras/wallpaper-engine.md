# Wallpaper Engine animado

El setup usa **linux-wallpaperengine** para reproducir escenas de Wallpaper
Engine como fondo de SwayFX.

## Requisitos

- Steam nativo (no Flatpak) con **Wallpaper Engine** comprado.
- Escenas descargadas del Workshop (app `431960`).
- `linux-wallpaperengine` en el `PATH`.

```bash
# Arch/CachyOS (AUR)
yay -S linux-wallpaperengine-git

# Comprobar
command -v linux-wallpaperengine
```

## Rutas de Steam

```text
Assets:      ~/.local/share/Steam/steamapps/common/wallpaper_engine/assets
Backgrounds: ~/.local/share/Steam/steamapps/workshop/content/431960
```

Si usas otra biblioteca de Steam, ajusta las rutas en DMS o en las variables de
entorno del script.

## Opción A: plugin de DMS (recomendado)

1. Instala el plugin **linuxWallpaperEngine** desde DMS → Ajustes → Plugins.
2. Configura `Assets Folder` y `Backgrounds Folder`.
3. El plugin arranca con `dms.service` y se encarga de todo.
4. Atajos:
   - `Super + Shift + W`: encender/apagar.
   - `Super + Ctrl + W`: siguiente escena.
   - `Super + Alt + W`: selector.

Ventaja: no hay que lanzar nada desde `sway config`, y `swaymsg reload` no
duplica procesos.

## Opción B: script sin plugin

El repo incluye un lanzador idempotente:

```bash
~/.config/sway/scripts/wallpaper-engine.sh
```

Detecta la salida enfocada, lee la escena configurada en el plugin de DMS y no
lanza una segunda instancia si ya hay una.

```bash
# Elegir salida y escena
WE_OUTPUT=eDP-1 WE_SCENE=3273913010 ~/.config/sway/scripts/wallpaper-engine.sh

# Forzar aunque el plugin esté activo
~/.config/sway/scripts/wallpaper-engine.sh --force

# Bajar FPS para ahorrar batería
WE_FPS=30 ~/.config/sway/scripts/wallpaper-engine.sh --force
```

Variables disponibles:

| Variable | Por defecto | Descripción |
|---|---|---|
| `WE_OUTPUT` | salida enfocada / `eDP-1` | Monitor donde dibujar. |
| `WE_SCENE` | escena del plugin o primera del Workshop | ID o ruta absoluta. |
| `WE_FPS` | `60` | Fotogramas por segundo. |
| `WE_LAYER` | `background` | Capa de wlr-layer-shell. |
| `WE_SILENT` | `1` | `0` para reproducir audio. |
| `WE_VOLUME` | `50` | Volumen si `WE_SILENT=0`. |
| `WE_SCALING` | vacío | `fill`, `fit`, `stretch`... |
| `WE_NO_FULLSCREEN_PAUSE` | `0` | `1` para no pausar en fullscreen. |
| `WE_STEAM` / `WE_ASSETS` / `WE_WORKSHOP` | rutas de Steam | Personalizar rutas. |

Para usarlo como fallback permanente, descomenta en
`~/.config/sway/config.d/80-wallpaper-engine.conf`:

```text
exec_always ~/.config/sway/scripts/wallpaper-engine.sh
```

> Cuidado: si el plugin de DMS está activo, usa `--force` solo para probar. El
> script normal sale sin lanzar otra instancia para evitar duplicados.

## Rendimiento

- Baja `WE_FPS` a 30 en laptops.
- Usa `--silent` (por defecto) para no gastar audio.
- Si la batería sufre, apaga el wallpaper con `Super + Shift + W`.
- En NVIDIA, `WLR_NO_HARDWARE_CURSORS=1` puede ayudar con el cursor.

## Problemas comunes

| Problema | Solución |
|---|---|
| No aparece nada | `command -v linux-wallpaperengine`; revisa rutas de Steam. |
| Pantalla negra | Prueba `WE_LAYER=bottom` o `--force`. |
| Se duplica | No uses `exec_always` si el plugin de DMS está activo. |
| No hay escenas | Descarga escenas del Workshop en Steam. |
| FPS muy bajos | `WE_FPS=30`, cierra apps pesadas. |
