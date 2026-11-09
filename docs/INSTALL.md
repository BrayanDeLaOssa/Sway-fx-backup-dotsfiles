# Instalación detallada

## Requisitos

| Requisito | Notas |
|---|---|
| Linux x86_64 | Probado en CachyOS (Arch). |
| `git` | Para clonar el repo. |
| `sudo` | Solo para instalar paquetes del sistema. |
| Conexión a internet | Para paquetes y fuentes. |
| SwayFX | En Arch/CachyOS se instala solo; en otras distros se usa sway normal. |
| DMS (`dux-shell`) | Opcional pero recomendado; sin él se activa el modo portable. |

## Arch / CachyOS (recomendado)

```bash
git clone https://github.com/BrayanDeLaOssa/Sway-fx-backup-dotsfiles.git
cd Sway-fx-backup-dotsfiles
./install.sh
```

El instalador:

1. Detecta que usas Arch/CachyOS y que tienes `yay`/`paru`.
2. Pregunta si puede instalar dependencias con `pacman`.
3. Instala `swayfx`, `dux-shell`, `kitty`, `thunar`, utilidades Wayland, fuentes,
   `pipewire`, `networkmanager`, etc.
4. Si `swayfx` solo está en AUR y no tienes helper, ofrece instalar `yay-bin`.
5. Adapta la config y la valida con `sway -C`.
6. Respalda tus archivos actuales y copia los nuevos.
7. Habilita `dms.service`.

Para que no pregunte nada:

```bash
./install.sh --full -y
```

`--full` añade navegador (Helium/Firefox), `linux-wallpaperengine` y la
configuración visual de DMS. Es lo más parecido al setup original.

### Después de instalar

```bash
# Cierra sesión y elige la sesión "swayfx" en el login.
# Si ya estás dentro de Sway:
swaymsg reload
```

Comprueba el estado:

```bash
./install.sh doctor
```

## Debian / Ubuntu

```bash
sudo apt update
git clone https://github.com/BrayanDeLaOssa/Sway-fx-backup-dotsfiles.git
cd Sway-fx-backup-dotsfiles
./install.sh --no-dms
```

Notas:

- `swayfx` y `dux-shell` no están empaquetados en Debian/Ubuntu. Se instala
  `sway` normal y el instalador **desactiva** las directivas de SwayFX.
- Se activa el **modo portable**: los atajos de DMS se traducen a `wofi`,
  `swaylock`, `grim`, `slurp`, `wpctl`/`pactl` y `brightnessctl`.
- El resultado es funcional, pero sin blur, sombras, animaciones ni la barra DMS.

## Fedora

```bash
sudo dnf install -y git
git clone https://github.com/BrayanDeLaOssa/Sway-fx-backup-dotsfiles.git
cd Sway-fx-backup-dotsfiles
./install.sh --no-dms
```

Mismas limitaciones que Debian: sway normal + modo portable.

## Instalación manual (sin script)

Si prefieres copiar a mano:

```bash
cp -a dotfiles/sway ~/.config/sway
cp -a dotfiles/kitty ~/.config/kitty
cp -a dotfiles/environment.d ~/.config/environment.d
# Opcional:
cp dotfiles/dms/settings.json ~/.config/dms/settings.json
cp dotfiles/dms/plugin_settings.json ~/.config/dms/plugin_settings.json
sed -i "s|@HOME@|$HOME|g" ~/.config/dms/*.json
chmod +x ~/.config/sway/scripts/*.sh
~/.config/sway/scripts/gen-keybinds-flat.sh
```

Ten en cuenta que la copia manual **no** adapta fuentes, cursor, terminal ni
SwayFX vs. sway normal. El instalador hace todo eso automáticamente.

## Personalización

Puedes cambiar valores sin editar archivos a mano:

```bash
./install.sh --term foot --browser firefox --mod Mod1 --layout latam
```

O editar después:

| Archivo | Qué cambiar |
|---|---|
| `~/.config/sway/config` | `$mod`, `$term`, `$term_exec`, `$browser`, `$filemanager`. |
| `config.d/10-input.conf` | Distribución de teclado y touchpad. |
| `config.d/20-outputs.conf` | Monitores, resolución, escala. |
| `config.d/30-appearance.conf` | Fuente, gaps, bordes, colores, cursor. |
| `config.d/31-effects.conf` | Blur, sombras, esquinas y animaciones. |
| `config.d/50-keybinds.conf` | Atajos generales. |
| `config.d/60-workspaces.conf` | Workspaces y scratchpad. |

## Respaldos y estado

```text
~/.local/state/swayfx-dotfiles/
├── manifest.tsv          # archivos instalados y su respaldo original
├── .lock                 # evita instalaciones simultáneas
└── backups/
    └── 20261109-081500/  # copia de lo que había antes
```

- `./install.sh uninstall` restaura el respaldo original y elimina lo instalado.
- `./install.sh backups` lista los respaldos.
- Si vuelves a instalar, el respaldo **original** se conserva; las copias nuevas
  se guardan por seguridad.

## Solución de problemas

Consulta [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).
