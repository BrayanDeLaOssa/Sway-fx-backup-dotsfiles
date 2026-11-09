# Atajos de teclado

`$mod` = **Super** (`Mod4`) por defecto. Puedes cambiarlo con `--mod Mod1` o
editando `set $mod Mod4` en `~/.config/sway/config`.

> Dentro de la sesión: `Super + Shift + /` abre el cheatsheet generado
> (`~/.config/sway/keybinds.flat.conf`).

## Lanzadores y paneles

| Atajo | Acción |
|---|---|
| `Super + Return` | Terminal (`kitty` por defecto) |
| `Super + E` | Gestor de archivos (`thunar` por defecto) |
| `Super + B` | Navegador (`helium-browser` por defecto) |
| `Super + D` | Spotlight / lanzador de DMS |
| `Super + ,` | Ajustes de DMS |
| `Super + Shift + E` | Ajustes de DMS |
| `Super + M` | Lista de procesos |
| `Super + Shift + N` | Centro de notificaciones |
| `Super + W` | Panel de wallpapers de DMS |
| `Super + Alt + V` | Historial de portapapeles |
| `Super + Shift + /` | Cheatsheet de atajos |

## Sesión

| Atajo | Acción |
|---|---|
| `Super + Q` | Cerrar la ventana enfocada |
| `Super + Shift + Q` | Cerrar la ventana enfocada |
| `Ctrl + Alt + Delete` | Diálogo para cerrar sesión |
| `Ctrl + Alt + L` | Bloquear sesión |
| `Super + Alt + L` | Bloquear sesión |
| `Super + Shift + C` | Recargar Sway |

## Ventanas

### Foco

| Atajo | Acción |
|---|---|
| `Super + ←/↓/↑/→` | Foco a la izquierda/abajo/arriba/derecha |
| `Super + H/J/K/L` | Lo mismo con Vim keys |

### Mover / intercambiar

| Atajo | Acción |
|---|---|
| `Super + Ctrl + ←/↓/↑/→` | Mover ventana en esa dirección |
| `Super + Ctrl + H/J/K/L` | Lo mismo con Vim keys |

### Redimensionar

| Atajo | Acción |
|---|---|
| `Super + Shift + ←` | Reducir ancho |
| `Super + Shift + →` | Aumentar ancho |
| `Super + Shift + ↑` | Reducir alto |
| `Super + Shift + ↓` | Aumentar alto |
| `Super + Shift + H/J/K/L` | Lo mismo con Vim keys |
| `Super + R` | Entrar al modo `resize` |

### Layout

| Atajo | Acción |
|---|---|
| `Super + Shift + F` | Pantalla completa |
| `Super + Space` | Alternar flotante |
| `Super + Shift + I` | Alternar split horizontal/vertical |
| `Super + Alt + B` | Split horizontal |
| `Super + Shift + B` | Split vertical |
| `Super + A` | Enfocar contenedor padre |
| ``Super + ` `` | Alternar entre modo foco y mosaico |

## Workspaces

| Atajo | Acción |
|---|---|
| `Super + 1..0` | Ir al workspace 1..10 |
| `Super + Shift + 1..0` | Mover ventana al workspace y seguirlo |
| `Super + Ctrl + 1..0` | Mover ventana al workspace sin seguirlo |
| `Super + Tab` | Workspace siguiente |
| `Super + Shift + Tab` | Workspace anterior |
| `Super + rueda arriba/abajo` | Workspace anterior/siguiente |
| `Super + Shift + rueda` | Mover ventana al workspace anterior/siguiente |

## Scratchpad

| Atajo | Acción |
|---|---|
| `Super + U` | Mostrar/ocultar scratchpad |
| `Super + Shift + U` | Mover ventana al scratchpad |
| `Super + -` | Mostrar/ocultar scratchpad |
| `Super + Shift + -` | Mover ventana al scratchpad |

## Multimedia

| Atajo | Acción |
|---|---|
| `XF86AudioRaiseVolume` | Subir volumen |
| `XF86AudioLowerVolume` | Bajar volumen |
| `XF86AudioMute` | Silenciar salida |
| `XF86AudioMicMute` | Silenciar micrófono |
| `XF86AudioPlay` / `XF86AudioPause` | Reproducir/pausar |
| `XF86AudioPrev` / `XF86AudioNext` | Pista anterior/siguiente |
| `XF86AudioStop` | Detener |
| `XF86MonBrightnessUp` / `Down` | Subir/bajar brillo |

## Capturas y wallpaper

| Atajo | Acción |
|---|---|
| `Print` | Captura de región |
| `Super + Print` | Captura de pantalla completa |
| `Super + Shift + Print` | Captura de región |
| `Super + Shift + W` | Encender/apagar wallpaper animado |
| `Super + Ctrl + W` | Siguiente escena |
| `Super + Alt + W` | Selector de wallpapers |

## Modo resize (`Super + R`)

| Tecla | Acción |
|---|---|
| `H` / `←` | Reducir ancho |
| `L` / `→` | Aumentar ancho |
| `K` / `↑` | Reducir alto |
| `J` / `↓` | Aumentar alto |
| `Return` / `Escape` | Salir del modo resize |

## Modo portable (sin DMS)

Si no tienes DMS, el instalador traduce los atajos automáticamente:

| Atajo de DMS | Alternativa portable |
|---|---|
| Spotlight | `wofi`, `fuzzel`, `rofi` o `bemenu` |
| Ajustes | Abre `~/.config/sway` en el gestor de archivos |
| Procesos | `btop` / `htop` / `top` en la terminal |
| Notificaciones | `swaync`, `mako` o `dunst` |
| Portapapeles | `cliphist` + menú |
| Bloqueo | `swaylock` o `loginctl lock-session` |
| Audio | `wpctl` o `pactl` |
| Brillo | `brightnessctl` |
| Capturas | `grim` + `slurp` |
