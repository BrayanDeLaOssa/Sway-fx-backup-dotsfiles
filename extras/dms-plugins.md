# Plugins de DMS

El setup original usa **Dux Modular Shell (DMS)** con varios plugins. No todos
se pueden instalar automáticamente: DMS tiene su propia tienda de plugins.

## Plugins usados en este setup

| Plugin | Para qué sirve |
|---|---|
| `linuxWallpaperEngine` | Wallpaper animado con `linux-wallpaperengine`. |
| `wallpaperCarousel` | Cambia wallpapers/escenas periódicamente. |
| `mpvpaper` | Videos de fondo con `mpvpaper`. |
| `mpvpaperWallpaper` | Variante de integración con `mpvpaper`. |
| `cavaVisualizer` | Visualizador de audio con Cava. |
| `dankAudioVisualizer` | Visualizador de audio alternativo. |
| `enderPulse` | Visualizador tipo pulso. |
| `bongoCat` | Gato que reacciona al teclado. |
| `activateLinux` | Integración de activación de Linux. |
| `homeAssistantDash` | Panel de Home Assistant. |
| `homeAssistantMonitor` | Monitor de Home Assistant. |

## Cómo instalarlos

1. Abre **DMS → Ajustes → Plugins**.
2. Busca el plugin por nombre y pulsa instalar.
3. Algunos plugins requieren paquetes extra:

   ```bash
   # Wallpaper Engine
   yay -S linux-wallpaperengine-git

   # Visualizadores / multimedia
   sudo pacman -S cava mpv
   ```

4. Reinicia DMS:

   ```bash
   systemctl --user restart dms.service
   ```

## Configuración de plugins

La configuración se guarda en:

```text
~/.config/dms/plugin_settings.json
```

El instalador puede copiar una versión adaptada de este archivo con:

```bash
./install.sh --with-dms-config
```

Las rutas absolutas se reemplazan por tu `$HOME`. Si tu versión de DMS es muy
distinta, es mejor **no** copiar el archivo y configurar los plugins a mano desde
la interfaz.

## Linux Wallpaper Engine

Es el plugin principal del setup. Configúralo en:

```text
DMS → Ajustes → Plugins → Linux Wallpaper Engine
```

Rutas típicas:

```text
Assets:      ~/.local/share/Steam/steamapps/common/wallpaper_engine/assets
Backgrounds: ~/.local/share/Steam/steamapps/workshop/content/431960
```

Más detalles en [`wallpaper-engine.md`](wallpaper-engine.md).
