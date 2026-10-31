# Terminal · Configuración Farid

Configuración de Farid para la **Terminal nativa de macOS**: prompt Powerlevel10k, fuente Hack Nerd Font, fondo transparente con desenfoque, colores vivos y neofetch. Además configura la Terminal para recuperar sus ventanas y agrega notificaciones de Claude Code (ver [Extras](#extras-terminal-y-claude-code)).

**Regla principal para la Terminal:** no reemplaza comandos (`ls` y `cat` siguen siendo los de Mac). El tema solo afecta a la Terminal de Mac: VS Code, la app de Claude y cualquier otra terminal quedan igual. El `.zshrc` es el mismo que usa Farid a diario, así que también trae autocompletado con TAB, NVM y atajos de edición estilo Mac (ver [Cómo funciona el `.zshrc`](#cómo-funciona-el-zshrc)).

Además instala las **notificaciones de Claude Code**: un aviso de macOS cada vez que Claude termina una tarea, con el resumen completo a un clic, y otros extras (ver [Extras](#extras-terminal-y-claude-code)).

## Prompt de instalación

Pégalo en un asistente de IA que pueda usar tu terminal, de preferencia Claude Code:

```text
Instala la configuración de terminal del repo público de GitHub IFEE09/terminal-configuracion-farid.

1. Clónalo con `git clone https://github.com/IFEE09/terminal-configuracion-farid.git ~/terminal-configuracion-farid` (si ya existe, haz `git -C ~/terminal-configuracion-farid pull`).
2. Lee el README.md completo para entender qué hace y qué NO debe hacer. En la Terminal: sin reemplazar ls/cat, sin Kitty. Las notificaciones de Claude Code (hook Stop en ~/.claude/settings.json) sí van incluidas a propósito.
3. Verifica que Homebrew esté instalado. Si no, detente y dime qué comando correr: pide contraseña y lo tengo que hacer yo.
4. Ejecuta `~/terminal-configuracion-farid/install.sh`.
5. Verifica lo que dice la sección "Verificación" del README y dime el resultado de cada punto (incluida la notificación de prueba).
6. Recuérdame los pasos manuales de notificaciones (permitir terminal-notifier y ponerlo en Persistente), abrir una ventana nueva de la Terminal y, si uso Claude Code, reiniciarlo para que tome el hook de notificaciones.
```

A mano: `git clone https://github.com/IFEE09/terminal-configuracion-farid.git ~/terminal-configuracion-farid && ~/terminal-configuracion-farid/install.sh` (requiere Homebrew).

## Opcional: Claude Usage

No viene incluida en este instalador. Si también la quieres, es una app aparte para la barra de menús que muestra tus límites de uso de Claude: **[IFEE09/claude-usage](https://github.com/IFEE09/claude-usage)**

```bash
git clone https://github.com/IFEE09/claude-usage.git ~/claude-usage
~/claude-usage/build.sh --install
```

## Qué se instala

| Pieza | Para qué | Cómo |
|---|---|---|
| Homebrew | Gestor de paquetes | Manual (pide contraseña) |
| Hack Nerd Font | Fuente con los íconos del prompt | `brew install --cask font-hack-nerd-font` |
| Powerlevel10k | Prompt de colores con carpeta, git y hora | `brew install powerlevel10k` |
| zsh-autosuggestions | Sugerencia en gris según el historial | `brew install zsh-autosuggestions` |
| zsh-syntax-highlighting | Comando en verde si existe, rojo si no | `brew install zsh-syntax-highlighting` |
| Perfil "Farid" | Fuente, transparencia, colores y cursor de la Terminal | `terminal/make-profile.js` |
| Recuperar ventanas | La Terminal reabre sus ventanas y pestañas tras ⌘Q | `defaults write com.apple.Terminal NSQuitAlwaysKeepsWindows` |
| neofetch | Logo de Apple y datos de la Mac al escribir `neofetch` | Descarga de la versión 7.1.0 a `~/.local/bin` (Homebrew ya no lo tiene) |
| terminal-notifier + jq | Notificaciones de Claude Code al terminar | `brew install terminal-notifier jq` |
| Hook de Claude Code | Aviso al terminar una tarea | `claude/notify.sh` + `claude/settings.json` |

## Archivos

```
install.sh                 Instalador (se puede correr varias veces)
dotfiles/zshrc             → ~/.zshrc
dotfiles/p10k.zsh          → ~/.p10k.zsh (estilo del prompt: lean, nerdfont, 24h)
terminal/make-profile.js   Genera el perfil de la Terminal (JXA, sin dependencias)
terminal/bolita-titulo.py  → ~/.local/bin/bolita-titulo.py (bolita en el título que pone Claude Code)
claude/notify.sh           → ~/.claude/hooks/notify.sh (notificación al terminar)
claude/clawd.png           → ~/.claude/hooks/clawd.png (monito de Claude Code en la notificación)
claude/settings.json       Hooks, idioma y variables que se mezclan en ~/.claude/settings.json
claude/CLAUDE.md           Preferencias globales de Claude (español, breve) → ~/.claude/CLAUDE.md
```

## Qué hace `install.sh`, paso a paso

1. Comprueba que sea macOS y que Homebrew esté instalado (en `/opt/homebrew` o `/usr/local`). Si falta Homebrew, se detiene y muestra el comando para instalarlo.
2. Agrega `brew shellenv` a `~/.zprofile` si no está.
3. Instala la fuente, Powerlevel10k y los dos plugins.
4. Respalda `~/.zshrc` y `~/.p10k.zsh` si existen y son distintos (`.backup-FECHA`), y copia los del repo.
5. Genera `Farid.terminal` con `make-profile.js`, lo importa (se abre una ventana de la Terminal) y lo deja como perfil predeterminado y de inicio.
6. Activa que la Terminal recupere sus ventanas al reabrirse.
7. Descarga neofetch 7.1.0 desde su repo en GitHub, comprueba su huella SHA-256 y lo deja en `~/.local/bin`. Homebrew lo retiró porque el proyecto ya no se mantiene; esa versión es la última y funciona en macOS.
8. Instala `terminal-notifier` y `jq`, copia `notify.sh` y mezcla `claude/settings.json` en `~/.claude/settings.json` (con respaldo `.backup-FECHA`; conserva tus otros ajustes y hooks, reemplaza hooks anteriores de `notify.sh` y no duplica nada si se corre otra vez). Al final pide permiso de notificaciones.

## Detalles del perfil de la Terminal

| Ajuste | Valor |
|---|---|
| Fuente | Hack Nerd Font Mono, 14 pt (`HackNFM-Regular`) |
| Fondo | `#0f111a` al 70 % de opacidad, desenfoque 0.6 |
| Texto | `#e6edff`; negrita `#ffffff` con colores brillantes |
| Cursor | Barra rosa `#ff79c6` |
| Selección | `#3d59a1` |
| Tamaño | 110 × 30 |

Paleta ANSI (normal / brillante):

| Color | Normal | Brillante |
|---|---|---|
| Negro | `#1b1e2b` | `#5c6690` |
| Rojo | `#ff5370` | `#ff6e85` |
| Verde | `#50fa7b` | `#7dffa0` |
| Amarillo | `#ffcb6b` | `#ffe08a` |
| Azul | `#5ea8ff` | `#82bfff` |
| Magenta | `#c792ea` | `#e0aaff` |
| Cian | `#00e5ff` | `#6cf6ff` |
| Blanco | `#c3cee3` | `#ffffff` |

Para cambiar colores o transparencia, edita `terminal/make-profile.js` y vuelve a correr `install.sh`, o ajústalo a mano en **Terminal → Ajustes → Perfiles → Farid**.

## Cómo funciona el `.zshrc`

Todo el tema está dentro de `if [[ "$TERM_PROGRAM" == "Apple_Terminal" && -o interactive ]]`, así que:

- Solo se carga en la Terminal de Mac y en shells interactivos; los scripts no lo ven.
- En otras terminales el prompt sigue siendo el de Mac (`usuario@mac carpeta %`).
- `CLICOLOR=1` y `LSCOLORS` activan el color del `ls` original de Mac. No es un alias, así que todas sus opciones funcionan igual.
- Usa `$HOMEBREW_PREFIX`, por lo que funciona en Macs con Apple Silicon y con Intel.
- Además agrega `~/.local/bin` al PATH, que es donde se instala Claude Code.

Fuera de ese bloque (en cualquier terminal) también trae:

- **Autocompletado con TAB**: menú navegable con flechas, sin distinguir mayúsculas.
- **NVM** (Node): se carga si está instalado en `~/.nvm`.
- **Atajos de edición estilo Mac** (widgets de zsh): `^Xa` seleccionar toda la línea, `^Xc` copiarla, `^Xd` borrarla, y selección por palabra o hasta inicio/fin (`^Xh`, `^Xl`, `^XH`, `^XL`, `^Xk`, `^Xx`, `^Xu`). Por sí solos no hacen nada visible: los dispara [Hammerspoon](https://www.hammerspoon.org) desde `~/.hammerspoon/init.lua` para que funcionen ⌘A, ⌥⇧←/→ y ⌘⇧←/→. Esa configuración de Hammerspoon no se incluye en este repo.
- **Bolitas de color por pestaña** (solo en la Terminal de Mac, ver [Extras](#bolitas-de-color-por-pestaña)).

## Extras: Terminal y Claude Code

### Recuperar ventanas

La Terminal reabre sus ventanas y pestañas, cada una en su carpeta, al cerrarla con **⌘Q** y volver a abrirla. Si se cierran las ventanas una por una con la X roja, no se recuperan. Claude no se reinicia solo: en cada pestaña usa `claude --continue` (última conversación de esa carpeta) o `claude --resume` (elegir de una lista).

### Bolitas de color por pestaña

Cada pestaña nueva de la Terminal de Mac toma el siguiente color (🔴 🟠 🟡 🟢 🔵 🟣 🟤 ⚪ ⚫), lo antepone a su título y tiñe levemente su fondo con ese color (12 %, con 15 % de transparencia) cambiando la pestaña al perfil "Farid <bolita>". Así se distingue cada pestaña de un vistazo. La función `claude` del `.zshrc` corre Claude Code a través de `bolita-titulo.py` para que la bolita no se borre cuando Claude cambia el título. Para quitarlo, borra el bloque "Bolita de color por pestaña" de `~/.zshrc`.

### Historial de sesiones

`CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1` está en `~/.zshrc` (y en el `env` de `~/.claude/settings.json`) para que Claude Code guarde siempre el historial y se pueda retomar. Solo usa disco, no tokens.

### Notificaciones

El hook `Stop` corre `~/.claude/hooks/notify.sh` al terminar cada tarea completa (no avisa por subagentes), y muestra una notificación con:

- **Título:** "Tarea terminada".
- **Subtítulo:** la carpeta del proyecto.
- **Texto:** el inicio del último mensaje de Claude (máx. ~180 caracteres, sin markdown).
- **Imagen:** el monito de Claude Code a la derecha. El icono de la izquierda es el de `terminal-notifier` y no se puede cambiar sin modificar la app firmada.

Al hacer clic se abre el resumen completo en TextEdit y la notificación se borra. Corre en segundo plano (`async`), así que no hace esperar a Claude; si algo falla, no muestra error.

Claude Code lee la configuración al arrancar: después de instalar, cierra y vuelve a abrir Claude Code para que empiecen a salir las notificaciones. Los resúmenes se guardan en `~/.claude/notificaciones/` y se borran a los 7 días.

**Pasos manuales** (macOS no deja hacerlos por script):

1. Aceptar el aviso de permiso de **terminal-notifier**.
2. **Ajustes → Notificaciones → terminal-notifier → Estilo de alerta: Persistente**, para que se queden hasta cerrarlas.
3. Recomendado: apagar **Resumir notificaciones** en ese mismo panel.

Se usa `terminal-notifier` y no `osascript` porque las notificaciones de `osascript` salen a nombre de *Editor de Scripts* y al hacer clic solo abren esa app vacía. Si alguna vez se quedan atoradas en pantalla: `terminal-notifier -remove ALL` y, si siguen, `killall NotificationCenter` (se reinicia solo).

### Preferencias de Claude

`install.sh` fija `"language": "spanish"` en `~/.claude/settings.json` y agrega `claude/CLAUDE.md` a `~/.claude/CLAUDE.md` (sin borrar lo que ya tenga), para que Claude responda siempre en español, breve y preciso, en modo *caveman* (estilo telegráfico que ahorra tokens de salida, sin recortar código, comandos, errores ni advertencias).

## Historia: qué se probó y se descartó

Este setup es el resultado de varias iteraciones. Queda documentado para no repetir errores:

1. **Kitty como terminal**: funcionaba bien, pero se descartó para usar la Terminal nativa de Mac. Su paleta y transparencia se pasaron al perfil "Farid".
2. **Atajos de teclado** (alias `ll`/`la`/`l`, función `mkt`, plugin sudo con `Esc Esc`, fzf con `Ctrl+R`/`Ctrl+T`, paneles con `Cmd+D`, `bindkey` de Option y flechas): se quitaron porque la idea es que todo funcione como viene en Mac.
3. **`ls` → lsd y `cat` → bat con alias**: se quitaron porque rompen opciones de Mac. Probado: `ls -laT`, `ls -l@`, `ls -lO`, `cat -b`, `cat -e`, `cat -v` y `cat -t` fallaban. Se reemplazó por el color nativo de `ls` (`CLICOLOR`).
4. **Tema cargado en todas las terminales**: se limitó a la Terminal de Mac porque en otras (VS Code, la app de Claude) no hay Nerd Font y los íconos se veían rotos.
5. **Rutas fijas `/opt/homebrew`**: se cambiaron por `$HOMEBREW_PREFIX` para que también funcione en Macs con Intel.

## Verificación

Después de instalar, deberían cumplirse estas comprobaciones:

```bash
# 1. Perfil predeterminado
osascript -e 'tell application "Terminal" to name of default settings'        # → Farid

# 2. El tema carga en la Terminal de Mac
TERM_PROGRAM=Apple_Terminal zsh -lic 'echo ${+functions[p10k]}'              # → 1

# 3. Y no carga en otras terminales
TERM_PROGRAM=vscode zsh -lic 'echo ${+functions[p10k]}'                      # → 0

# 4. ls y cat siguen siendo los de Mac
zsh -ic 'whence -w ls cat'                                                   # → ls: command, cat: command

# 5. Sin errores de sintaxis
zsh -n ~/.zshrc && echo ok                                                   # → ok

# 6. La Terminal recupera sus ventanas
defaults read com.apple.Terminal NSQuitAlwaysKeepsWindows                    # → 1

# 7. Historial de Claude Code activado
zsh -ic 'echo $CLAUDE_CODE_FORCE_SESSION_PERSISTENCE'                        # → 1

# 8. Hooks de notificaciones en Claude Code
jq -r '.hooks.Stop[].hooks[].command' ~/.claude/settings.json                # → ~/.claude/hooks/notify.sh ...

# 9. Permiso y estilo de notificaciones
terminal-notifier -diagnose | grep -E 'authorization|alert style'            # → authorized / alerts

# 10. El script de notificaciones funciona
echo '{"cwd":"/tmp/prueba","last_assistant_message":"Prueba"}' | ~/.claude/hooks/notify.sh   # → aparece una notificación

# 11. neofetch instalado
zsh -ic 'neofetch --version'                                                 # → Neofetch 7.1.0
```

## Desinstalar

```bash
osascript -e 'tell application "Terminal" to set default settings to settings set "Basic"'
osascript -e 'tell application "Terminal" to set startup settings to settings set "Basic"'
brew uninstall powerlevel10k zsh-autosuggestions zsh-syntax-highlighting
brew uninstall --cask font-hack-nerd-font
# Restaurar el respaldo más reciente de ~/.zshrc (o borrarlo) y borrar ~/.p10k.zsh

# Extras
defaults delete com.apple.Terminal NSQuitAlwaysKeepsWindows
rm -f ~/.local/bin/neofetch && rm -rf ~/.config/neofetch
jq 'del(.hooks.Stop[] | select(any(.hooks[]; .command | contains("notify.sh"))))' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
rm -f ~/.claude/hooks/notify.sh ~/.claude/hooks/clawd.png
rm -rf ~/.claude/notificaciones
brew uninstall terminal-notifier
# Quitar las preferencias de ~/.claude/CLAUDE.md y "language" de ~/.claude/settings.json si ya no las quieres
```
