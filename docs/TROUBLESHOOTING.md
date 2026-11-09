# Solución de problemas

## El instalador no encuentra mi distro

El soporte completo es para **Arch/CachyOS**. En Debian/Ubuntu/Fedora se usa
`sway` normal y el modo portable. Puedes forzar que no toque paquetes:

```bash
./install.sh --no-deps
```

Y instalar a mano lo que falte según [`INSTALL.md`](INSTALL.md).

## `sway: command not found` o no aparece la sesión `swayfx`

```bash
# Arch/CachyOS
sudo pacman -S swayfx

# Comprobar que existe la sesión
ls /usr/share/wayland-sessions/
```

Si no aparece `swayfx.desktop`, cierra sesión y revisa que el paquete esté
instalado. En Debian/Fedora usa la sesión `sway`.

## `Unknown command 'blur'` / `corner_radius` / `shadows`

Estás usando **sway normal**, no SwayFX. El instalador ya desactiva esas
directivas cuando detecta sway normal. Si las ves, puedes:

- Instalar SwayFX (Arch/AUR), o
- Volver a ejecutar `./install.sh --no-dms` para regenerar el modo portable.

## DMS no arranca o no sale la barra

```bash
systemctl --user status dms.service
systemctl --user enable --now dms.service
journalctl --user -b -u dms.service --no-pager | tail -50
```

Si acabas de instalar, cierra sesión y vuelve a entrar para que se apliquen
`~/.config/environment.d/*.conf` y `sway-session.target`.

Comprueba que el binario existe:

```bash
command -v dms
```

En Debian/Fedora no está empaquetado; usa el modo portable:

```bash
./install.sh --no-dms
```

## Los atajos de DMS no hacen nada

Sin DMS, los comandos `dms ipc ...` fallan. Ejecuta:

```bash
./install.sh --no-dms
```

El instalador reemplaza esos atajos por `launcher.sh`, `audio.sh`,
`brightness.sh`, `screenshot.sh`, `lock.sh`, etc.

## La configuración no pasa `sway -C`

```bash
sway -C -c ~/.config/sway/config
```

Corrige el error que muestre. Si estás probando algo puntual y quieres instalar
igual (no recomendado):

```bash
./install.sh --force
```

El instalador valida en una copia temporal **antes** de tocar tu configuración,
así que si falla no se instala nada.

## Fuentes raras o cuadrados en la barra/terminal

```bash
# Arch/CachyOS
sudo pacman -S ttf-cascadia-code-nerd ttf-nerd-fonts-symbols noto-fonts

fc-cache -f
fc-list | grep -i caskaydia
```

Si no tienes Caskaydia, el instalador pone `monospace` en kitty y `sans-serif`
en Sway. Puedes editar `~/.config/kitty/kitty.conf` y
`~/.config/sway/config.d/30-appearance.conf`.

## El cursor se ve pequeño o no es el de la captura

El tema `GLT_Chito (No White Border)` no está en los repos. Si no lo tienes, el
instalador usa `Adwaita`. Para instalarlo, coloca la carpeta del tema en:

```text
~/.icons/GLT_Chito (No White Border)/
```

Y comprueba:

```bash
ls ~/.icons/
```

## No tengo helper AUR (`yay`/`paru`)

En Arch, el instalador puede compilar `yay-bin` automáticamente si aceptas.
También puedes instalarlo a mano:

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin && makepkg -si
```

## `swayfx` solo está en AUR y falla la instalación

Si no quieres AUR, el instalador cae a `sway` normal y desactiva los efectos.
Para la experiencia completa necesitas SwayFX:

```bash
yay -S swayfx
```

## Wallpaper Engine no se ve

1. Comprueba que `linux-wallpaperengine` está en el PATH:

   ```bash
   command -v linux-wallpaperengine
   ```

2. Verifica las rutas de Steam:

   ```bash
   ls ~/.local/share/Steam/steamapps/common/wallpaper_engine/assets
   ls ~/.local/share/Steam/steamapps/workshop/content/431960
   ```

3. En DMS → Ajustes → Plugins → **Linux Wallpaper Engine**, configura:
   - Assets Folder
   - Backgrounds Folder

4. Prueba el script alternativo:

   ```bash
   ~/.config/sway/scripts/wallpaper-engine.sh --force
   WE_SCENE=123456789 WE_FPS=30 ~/.config/sway/scripts/wallpaper-engine.sh --force
   ```

Si el plugin de DMS ya gestiona el wallpaper, el script no lanza otra instancia
(es idempotente).

## La pantalla se ve negra o Sway no arranca

Prueba desde una TTY:

```bash
sway -c ~/.config/sway/config 2> /tmp/sway-error.log
cat /tmp/sway-error.log
```

Y revisa la configuración:

```bash
sway -C -c ~/.config/sway/config
```

Si acabas de cambiar la config y no puedes entrar, restaura el respaldo:

```bash
./install.sh uninstall
```

## Quiero volver a mi configuración anterior

```bash
./uninstall.sh
# o
./install.sh uninstall
```

Los respaldos están en `~/.local/state/swayfx-dotfiles/backups/`. Puedes verlos
con:

```bash
./install.sh backups
```

## Sigo teniendo dudas

Ejecuta el diagnóstico y adjunta la salida al abrir un issue:

```bash
./install.sh doctor > doctor.txt 2>&1
```

Incluye también:

```bash
sway --version
cat /etc/os-release
journalctl --user -b -u dms.service --no-pager | tail -50
```
