# SwayFX dotfiles · CachyOS + DMS

Configuración modular de **SwayFX** con **Dux Modular Shell (DMS)**, pensada para
CachyOS/Arch y con un instalador que detecta tu sistema, instala dependencias,
adapta la configuración y guarda respaldos antes de tocar nada.

```text
  ███████╗██╗    ██╗ █████╗ ██╗   ██╗███████╗██╗  ██╗
  ██╔════╝██║    ██║██╔══██╗╚██╗ ██╔╝██╔════╝╚██╗██╔╝
  ███████╗██║ █╗ ██║███████║ ╚████╔╝ █████╗   ╚███╔╝
  ╚════██║██║███╗██║██╔══██║  ╚██╔╝  ██╔══╝   ██╔██╗
  ███████║╚███╔███╔╝██║  ██║   ██║   ██║     ██╔╝ ██╗
  ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝
```

## ¿Qué incluye?

- **SwayFX**: blur, esquinas redondeadas, sombras y animaciones nativas.
- **DMS (Dux Modular Shell)**: barra, lanzador, OSD, notificaciones, portapapeles,
  bloqueo, capturas y panel de wallpapers.
- **Config modular** en `config.d/`: entorno, entrada, monitores, apariencia,
  efectos, reglas de ventana, atajos, workspaces, multimedia y wallpaper engine.
- **Kitty** con tema y pestañas integradas con DMS/matugen.
- **Wallpaper Engine animado** vía `linux-wallpaperengine` + plugin de DMS.
- **Instalador dinámico** con respaldos, validación y desinstalación.
- **Modo portable** para Debian/Fedora o para quien no quiera DMS/SwayFX.

## Instalación rápida

```bash
git clone https://github.com/BrayanDeLaOssa/Sway-fx-backup-dotsfiles.git
cd Sway-fx-backup-dotsfiles
./install.sh
```

El script te preguntará si quieres instalar dependencias del sistema y si quieres
copiar también la configuración visual de DMS. Para una instalación sin preguntas:

```bash
./install.sh --full -y
```

Después **cierra sesión y vuelve a entrar** eligiendo la sesión `swayfx`.

> No ejecutes `install.sh` con `sudo`. El script pide permisos solo cuando hace
> falta instalar paquetes.

## Instalador

```text
./install.sh [install|uninstall|doctor|backups] [opciones]
```

| Opción | Qué hace |
|---|---|
| `-y, --yes` | No preguntar; aceptar valores por defecto. |
| `-n, --dry-run` | Mostrar lo que haría sin cambiar nada. |
| `-v, --verbose` | Salida detallada. |
| `--no-deps` | No instalar paquetes; solo copiar archivos. |
| `--no-validate` | No validar con `sway -C`. |
| `--no-backup` | No crear respaldos (no recomendado). |
| `--force` | Continuar aunque falle la validación. |
| `--no-dms` | Forzar el modo portable sin DMS. |
| `--full` | Instalar navegador, wallpaper engine y config DMS. |
| `--minimal` | Solo lo esencial, sin extras opcionales. |
| `--with-dms-config` | Copiar la configuración visual de DMS. |
| `--with-wallpaper` | Instalar `linux-wallpaperengine` (AUR). |
| `--with-browser` | Instalar Helium o Firefox. |
| `--term NOMBRE` | Terminal (por defecto `kitty`). |
| `--browser NOMBRE` | Navegador (`helium-browser`, `firefox`, ...). |
| `--filemanager NOMBRE` | Gestor de archivos (`thunar`, `nautilus`, ...). |
| `--mod TECLA` | Modificador: `Mod4` (Super) por defecto, `Mod1` (Alt), etc. |
| `--layout LAYOUT` | Distribuciones XKB, por ejemplo `us,es` o `latam`. |

### Qué hace por dentro

1. Detecta distro, gestor de paquetes, helper AUR, sesión y componentes.
2. Instala dependencias (con tu confirmación) y habla `dms.service`.
3. Copia los dotfiles a una **carpeta temporal** y los adapta:
   - SwayFX vs. sway normal.
   - Fuente y cursor disponibles.
   - Terminal, navegador y gestor de archivos reales.
   - Distribución de teclado y tecla modificadora.
   - DMS vs. modo portable.
4. Valida la configuración con `sway -C` **antes de instalar**.
5. Respalda tu configuración anterior y copia los archivos.
6. Genera `keybinds.flat.conf` para el cheatsheet de DMS.

Si algo falla, **no se instala nada**: la validación ocurre sobre la copia temporal.

## Estructura

```text
.
├── install.sh              # Instalador / desinstalador / doctor
├── uninstall.sh            # Atajo para desinstalar
├── dotfiles/
│   ├── sway/
│   │   ├── config          # Variables globales + include
│   │   ├── config.d/       # Módulos numerados
│   │   ├── scripts/        # Generador de cheatsheet, wallpaper, helpers
│   │   └── README.md
│   ├── kitty/              # kitty.conf + tema DMS/matugen
│   ├── environment.d/      # Entorno para DMS y cursor
│   └── dms/                # settings.json + plugin_settings.json
├── scripts/
│   ├── lib/                # Lógica del instalador
│   └── doctor.sh
├── docs/                   # Instalación, atajos y troubleshooting
└── extras/                 # Plugins de DMS y wallpaper engine
```

## Atajos principales

| Atajo | Acción |
|---|---|
| `Super + Return` | Terminal (kitty) |
| `Super + D` | Spotlight / lanzador |
| `Super + E` | Gestor de archivos |
| `Super + B` | Navegador |
| `Super + Q` | Cerrar ventana |
| `Super + 1..0` | Cambiar de workspace |
| `Super + Shift + 1..0` | Mover ventana y seguirla |
| `Super + Shift + F` | Pantalla completa |
| `Super + Space` | Alternar flotante |
| `Super + R` | Modo redimensionar |
| `Super + Shift + /` | Cheatsheet de atajos |
| `Print` | Captura de región |
| `Super + Shift + W` | Encender/apagar wallpaper animado |

La lista completa está en [`docs/KEYBINDS.md`](docs/KEYBINDS.md) y dentro de la
sesión con `Super + Shift + /`.

## Wallpaper Engine

1. Compra/instala **Wallpaper Engine** en Steam.
2. Descarga escenas del Workshop (app `431960`).
3. Instala el plugin **linuxWallpaperEngine** desde DMS.
4. Configura las rutas en DMS → Ajustes → Plugins → Linux Wallpaper Engine:
   - Assets: `~/.local/share/Steam/steamapps/common/wallpaper_engine/assets`
   - Backgrounds: `~/.local/share/Steam/steamapps/workshop/content/431960`

El script `dotfiles/sway/scripts/wallpaper-engine.sh` también funciona como
alternativa sin plugin. Más detalles en [`extras/wallpaper-engine.md`](extras/wallpaper-engine.md).

## Requisitos

- **Arch / CachyOS** (recomendado): soporte completo, incluido AUR.
- **Debian / Ubuntu / Fedora**: se instala `sway` normal y el modo portable sin
  DMS/SwayFX. Lo mejor es Arch/CachyOS para la experiencia completa.
- `git`, conexión a internet y permisos de `sudo` para instalar paquetes.

## Desinstalar

```bash
./uninstall.sh
# o
./install.sh uninstall
```

Restaura los archivos originales y elimina los que instaló el script. Los
respaldos quedan en:

```text
~/.local/state/swayfx-dotfiles/backups/
```

Puedes verlos con:

```bash
./install.sh backups
```

## Diagnóstico

```bash
./install.sh doctor
# o
./scripts/doctor.sh
```

Comprueba compositor, DMS, dependencias, fuentes, cursor, wallpaper engine y
valida la configuración con `sway -C`.

## Documentación

- [Instalación detallada](docs/INSTALL.md)
- [Atajos de teclado](docs/KEYBINDS.md)
- [Solución de problemas](docs/TROUBLESHOOTING.md)
- [Plugins de DMS](extras/dms-plugins.md)
- [Wallpaper Engine](extras/wallpaper-engine.md)

## Créditos

- [SwayFX](https://github.com/WillPower3309/swayfx)
- [Dux Modular Shell (DMS)](https://github.com/duxlabs-dev/dux-shell)
- [linux-wallpaperengine](https://github.com/Almamu/linux-wallpaperengine)
- Configuración y scripts: [BrayanDeLaOssa](https://github.com/BrayanDeLaOssa)

## Licencia

MIT. Consulta [`LICENSE`](LICENSE).
