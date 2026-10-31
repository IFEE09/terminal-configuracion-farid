#!/bin/bash
# Instala la configuración "Farid" en la Terminal de Mac (solo aspecto, sin atajos)
# y las notificaciones de Claude Code.
# Se puede ejecutar varias veces: respalda lo existente y no duplica nada.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

info() { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m ✔\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31m ✘\033[0m %s\n' "$1" >&2; exit 1; }

[[ "$(uname)" == "Darwin" ]] || fail "Este script es solo para macOS."

# 1. Homebrew (su instalador pide contraseña de administrador: se corre a mano)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  fail 'Falta Homebrew. Instálalo primero con:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
fi
ok "Homebrew en $HOMEBREW_PREFIX"

if ! grep -qs 'brew shellenv' ~/.zprofile; then
  echo "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\"" >> ~/.zprofile
  ok "Homebrew agregado a ~/.zprofile"
fi

# 2. Fuente, prompt y plugins
info "Instalando fuente, prompt y plugins..."
brew install --cask font-hack-nerd-font
brew install powerlevel10k zsh-autosuggestions zsh-syntax-highlighting
ok "Paquetes instalados"

# 3. Dotfiles (con respaldo)
for f in zshrc p10k.zsh; do
  dest="$HOME/.$f"
  if [[ -f "$dest" ]] && ! cmp -s "$dest" "$REPO/dotfiles/$f"; then
    cp "$dest" "$dest.backup-$STAMP"
    ok "Respaldo: $dest.backup-$STAMP"
  fi
  cp "$REPO/dotfiles/$f" "$dest"
done
zsh -n ~/.zshrc || fail "~/.zshrc tiene errores de sintaxis"
ok "~/.zshrc y ~/.p10k.zsh instalados"

# 4. Perfil de la Terminal
info "Creando perfil 'Farid' de la Terminal..."
PROFILE="$(mktemp -d)/Farid.terminal"
OUT="$PROFILE" osascript -l JavaScript "$REPO/terminal/make-profile.js" >/dev/null
plutil -lint "$PROFILE" >/dev/null || fail "El perfil generado no es válido"
open "$PROFILE"      # importa el perfil (abre una ventana de la Terminal)
sleep 2
osascript -e 'tell application "Terminal"
  set default settings to settings set "Farid"
  set startup settings to settings set "Farid"
end tell'
ok "Perfil 'Farid' importado y marcado como predeterminado"

# 5. Terminal: recuperar ventanas y pestañas al cerrar con Cmd+Q y volver a abrir
defaults write com.apple.Terminal NSQuitAlwaysKeepsWindows -bool true
ok "La Terminal recuperará sus ventanas al reabrirse"

# 6. neofetch: logo de Apple y datos de la Mac (se corre a mano con `neofetch`)
# Homebrew ya no lo tiene: se descarga la versión 7.1.0 (la última) y se comprueba su huella
info "Instalando neofetch..."
NEOFETCH_URL="https://raw.githubusercontent.com/dylanaraps/neofetch/7.1.0/neofetch"
NEOFETCH_SHA256="3dc33493e54029fb1528251552093a9f9a2894fcf94f9c3a6f809136a42348c7"
NEOFETCH_TMP="$(mktemp)"
curl -fsSL "$NEOFETCH_URL" -o "$NEOFETCH_TMP" || fail "No se pudo descargar neofetch"
echo "$NEOFETCH_SHA256  $NEOFETCH_TMP" | shasum -a 256 -c --status \
  || { rm -f "$NEOFETCH_TMP"; fail "El neofetch descargado no coincide con la versión 7.1.0"; }
mkdir -p ~/.local/bin
install -m 755 "$NEOFETCH_TMP" ~/.local/bin/neofetch
rm -f "$NEOFETCH_TMP"
ok "neofetch 7.1.0 instalado en ~/.local/bin"

# 7. Claude Code: notificaciones al terminar y historial de sesiones
info "Configurando Claude Code..."
brew install terminal-notifier jq
mkdir -p ~/.claude/hooks
cp "$REPO/claude/notify.sh" ~/.claude/hooks/notify.sh
chmod +x ~/.claude/hooks/notify.sh
cp "$REPO/claude/clawd.png" ~/.claude/hooks/clawd.png

# Preferencias globales de Claude (español, breve): se agregan a ~/.claude/CLAUDE.md sin borrar lo que haya
if ! grep -qs 'Responde siempre en español' ~/.claude/CLAUDE.md; then
  [[ -s ~/.claude/CLAUDE.md ]] && echo >> ~/.claude/CLAUDE.md
  cat "$REPO/claude/CLAUDE.md" >> ~/.claude/CLAUDE.md
  ok "Preferencias agregadas a ~/.claude/CLAUDE.md"
fi

# Mezcla con ~/.claude/settings.json sin borrar lo que ya tenga (se puede repetir)
SETTINGS="$HOME/.claude/settings.json"
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"
jq empty "$SETTINGS" 2>/dev/null || fail "$SETTINGS no es JSON válido; corrígelo y vuelve a correr el script"
cp "$SETTINGS" "$SETTINGS.backup-$STAMP"
jq --slurpfile f "$REPO/claude/settings.json" '
  . + ($f[0] | del(.env, .hooks))
  | .env = ((.env // {}) + $f[0].env)
  # quita cualquier hook previo de notify.sh (en cualquier evento) y los eventos que queden vacíos
  | .hooks = ((.hooks // {})
      | map_values([ .[] | select([.hooks[]?.command // ""] | any(test("notify\\.sh")) | not) ])
      | with_entries(select(.value | length > 0)))
  | reduce ($f[0].hooks | to_entries[]) as $e (.; .hooks[$e.key] = ((.hooks[$e.key] // []) + $e.value))
' "$SETTINGS.backup-$STAMP" > "$SETTINGS" || { cp "$SETTINGS.backup-$STAMP" "$SETTINGS"; fail "No se pudo actualizar $SETTINGS"; }
ok "Hooks de notificaciones agregados a $SETTINGS (respaldo: $SETTINGS.backup-$STAMP)"

# Pide permiso de notificaciones (macOS muestra un aviso: dale Permitir)
open -a "$(brew --prefix terminal-notifier)/terminal-notifier.app" --args \
  -title "Claude Code" -message "Permite las notificaciones para terminar la configuración"
ok "Falta un paso manual: Ajustes → Notificaciones → terminal-notifier → Estilo de alerta: Persistente"

echo
ok "Listo. Abre una ventana nueva de la Terminal para ver el tema."
ok "La primera notificación de Claude Code puede pedir permiso: acéptalo en Ajustes del Sistema → Notificaciones."
