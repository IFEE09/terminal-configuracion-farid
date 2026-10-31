-- Cmd+A en Terminal: selecciona todo lo que estás escribiendo (zsh o Claude Code).
-- Después: Borrar = borra todo · Cmd+C = copia todo · Cmd+X = corta · Cmd+V = reemplaza con lo pegado.
-- Cualquier otra tecla cancela. Fuera de zsh/Claude Code, Cmd+A funciona normal.
-- Lado zsh: widgets en ~/.zshrc (^Xa seleccionar, ^Xc copiar, ^Xd borrar).

hs.autoLaunch(true)
require("hs.ipc")

local K = hs.keycodes.map
local props = hs.eventtap.event.properties
local MARCA = 4242          -- marca para ignorar las teclas que enviamos nosotros
local modo, reloj = nil, nil -- "zsh" | "claude" | nil

local function enviar(mods, tecla)
  for _, abajo in ipairs({ true, false }) do
    local e = hs.eventtap.event.newKeyEvent(mods, tecla, abajo)
    e:setProperty(props.eventSourceUserData, MARCA)
    e:post()
  end
end

local function detectarModo()
  local ok, procs = hs.osascript.applescript(
    'tell application "Terminal" to get processes of selected tab of front window')
  if not ok or type(procs) ~= "table" then return nil end
  for _, p in ipairs(procs) do
    if p == "claude" then return "claude" end
  end
  local ultimo = procs[#procs]
  if ultimo == "-zsh" or ultimo == "zsh" then return "zsh" end
  return nil
end

local acciones = {
  zsh = {
    seleccionar = function() enviar({ "ctrl" }, "x"); enviar({}, "a") end,
    borrar      = function() enviar({ "ctrl" }, "x"); enviar({}, "d") end,
    copiar      = function() enviar({ "ctrl" }, "x"); enviar({}, "c") end,
  },
  claude = {
    seleccionar = function() hs.alert.show("Todo seleccionado  (Delete borra · ⌘V reemplaza)", 1.5) end,
    borrar      = function() enviar({ "ctrl" }, "l") end,  -- chat:clearInput
    copiar      = function() hs.alert.show("Claude Code no permite copiar la entrada", 1.2) end,
  },
}

local function terminar()
  modo = nil
  if reloj then reloj:stop(); reloj = nil end
end

atajoSeleccionarTodo = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(ev)
  if ev:getProperty(props.eventSourceUserData) == MARCA then return false end
  local app = hs.application.frontmostApplication()
  if not app or app:bundleID() ~= "com.apple.Terminal" then terminar(); return false end

  local tecla, f = ev:getKeyCode(), ev:getFlags()
  local soloCmd, sinMods = f:containExactly({ "cmd" }), f:containExactly({})

  if soloCmd and tecla == K.a then
    local m = detectarModo()
    if not m then terminar(); return false end  -- fuera de zsh/Claude Code: Cmd+A normal de Terminal
    terminar()
    modo = m
    acciones[modo].seleccionar()
    return true
  end

  if not modo then return false end
  local a = acciones[modo]

  if sinMods and (tecla == K.delete or tecla == K.forwarddelete) then
    a.borrar(); terminar(); return true
  elseif soloCmd and tecla == K.c then
    a.copiar(); return true  -- como en el navegador: la selección se mantiene
  elseif soloCmd and tecla == K.x then
    if modo == "zsh" then a.copiar() end
    a.borrar(); terminar(); return true
  elseif soloCmd and tecla == K.v then
    a.borrar(); terminar()
    hs.timer.doAfter(0.05, function() enviar({ "cmd" }, "v") end)
    return true
  end

  -- Como en el navegador: escribir reemplaza lo seleccionado; otra tecla (flechas, Esc…) deselecciona
  local car = ev:getCharacters()
  local escribe = not (f.cmd or f.ctrl or f.alt) and car ~= nil and (car:byte(1) or 0) >= 32
    and tecla ~= K.escape and tecla ~= K["return"] and tecla ~= K.tab
    and tecla ~= K.left and tecla ~= K.right and tecla ~= K.up and tecla ~= K.down
  local m = modo
  terminar()
  if escribe then a.borrar()
  elseif m == "zsh" then enviar({ "ctrl" }, "x"); enviar({}, "x")
  else hs.alert.closeAll(0) end
  local copia = ev:copy()
  copia:setProperty(props.eventSourceUserData, MARCA)
  copia:post()
  return true
end):start()

-- Cmd+D+J (en cualquier app): inicia el dictado (~/.local/bin/dictado).
-- Cmd+D se retiene 0.4 s esperando la J; si no llega, se envía Cmd+D normal.
local MARCA_DICT = 4343
local esperaD = nil

local function enviarCmdD()
  for _, abajo in ipairs({ true, false }) do
    local e = hs.eventtap.event.newKeyEvent({ "cmd" }, "d", abajo)
    e:setProperty(props.eventSourceUserData, MARCA_DICT)
    e:post()
  end
end

atajoDictado = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(ev)
  if ev:getProperty(props.eventSourceUserData) == MARCA_DICT then return false end
  local tecla, f = ev:getKeyCode(), ev:getFlags()
  local soloCmd = f:containExactly({ "cmd" })

  if soloCmd and tecla == K.d then
    if esperaD then return true end  -- autorepetición mientras mantienes la D
    esperaD = hs.timer.doAfter(0.4, function() esperaD = nil; enviarCmdD() end)
    return true
  end

  if esperaD and soloCmd and tecla == K.j then
    esperaD:stop(); esperaD = nil
    hs.task.new(os.getenv("HOME") .. "/.local/bin/dictado", nil):start()
    return true
  end

  if esperaD then  -- otra tecla: suelta el Cmd+D pendiente primero
    esperaD:stop(); esperaD = nil
    enviarCmdD()
  end
  return false
end):start()

-- Selección estilo Mac en Terminal (zsh y Claude Code). Acordado 31 oct 2026.
--   ⌥⇧← / ⌥⇧→  selecciona palabra por palabra (se acumula)
--   ⌘⇧← / ⌘⇧→  selecciona hasta el inicio / fin de la línea
--   Delete      borra lo seleccionado; cualquier otra tecla cancela
--   ⌘← / ⌘→ inicio / fin de línea · ⌘⌫ borra hasta el inicio
-- zsh: selección resaltada real (widgets _sel_* en ~/.zshrc).
-- Claude Code: no hay resaltado; se muestra un aviso y se borra con ctrl+w / ctrl+u / ctrl+k.
local sel = nil

local function avisarSel()
  hs.alert.closeAll(0)
  local partes = {}
  if sel.inicio then table.insert(partes, "← hasta el inicio")
  elseif sel.izq > 0 then table.insert(partes, "← " .. sel.izq .. " palabra(s)") end
  if sel.fin then table.insert(partes, "→ hasta el final")
  elseif sel.der > 0 then table.insert(partes, "→ " .. sel.der .. " palabra(s)") end
  hs.alert.show("Seleccionado " .. table.concat(partes, " · ") .. "  (Delete borra)", 2)
end

local function borrarClaude()
  if sel.fin then enviar({ "ctrl" }, "k")
  else for _ = 1, sel.der do enviar({ "alt" }, "right") end end
  if sel.inicio then enviar({ "ctrl" }, "u")
  else
    local n = sel.izq + (sel.fin and 0 or sel.der)
    for _ = 1, n do enviar({ "ctrl" }, "w") end
  end
end

local function cancelarSel()
  if sel and sel.modo == "zsh" then enviar({ "ctrl" }, "x"); enviar({}, "x") end
  if sel and sel.modo == "claude" then hs.alert.closeAll(0) end
  sel = nil
end

atajoSeleccion = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(ev)
  local marca = ev:getProperty(props.eventSourceUserData)
  if marca == MARCA or marca == MARCA_DICT then return false end
  local app = hs.application.frontmostApplication()
  if not app or app:bundleID() ~= "com.apple.Terminal" then sel = nil; return false end

  local tecla, f = ev:getKeyCode(), ev:getFlags()
  local cmdShift, altShift = f:containExactly({ "cmd", "shift" }), f:containExactly({ "alt", "shift" })
  local soloCmd, sinMods = f:containExactly({ "cmd" }), f:containExactly({})
  local flecha = (tecla == K.left) or (tecla == K.right)

  -- 1) Teclas que seleccionan
  if (cmdShift or altShift) and flecha then
    local m = sel and sel.modo or detectarModo()
    if not m then return false end
    sel = sel or { modo = m, izq = 0, der = 0, inicio = false, fin = false }
    local izq = tecla == K.left
    if m == "zsh" then
      enviar({ "ctrl" }, "x")
      if cmdShift then enviar({ "shift" }, izq and "h" or "l") else enviar({}, izq and "h" or "l") end
    else
      if cmdShift then
        if izq then sel.inicio = true else sel.fin = true end
      elseif izq then sel.izq = sel.izq + 1 else sel.der = sel.der + 1 end
      avisarSel()
    end
    return true
  end

  -- 2) Con selección activa: Delete borra; cualquier otra tecla cancela
  if sel then
    if sinMods and (tecla == K.delete or tecla == K.forwarddelete) then
      if sel.modo == "zsh" then enviar({ "ctrl" }, "x"); enviar({}, "k")
      else hs.alert.closeAll(0); borrarClaude() end
      sel = nil
      return true
    end
    local copia = ev:copy()
    -- Como en el navegador: escribir una letra reemplaza lo seleccionado
    local escribe = not (f.cmd or f.ctrl or f.alt) and ev:getCharacters() ~= nil
      and (ev:getCharacters():byte(1) or 0) >= 32 and tecla ~= K.escape and tecla ~= K["return"]
      and tecla ~= K.tab and tecla ~= K.left and tecla ~= K.right and tecla ~= K.up and tecla ~= K.down
    if escribe then
      if sel.modo == "zsh" then enviar({ "ctrl" }, "x"); enviar({}, "k")
      else hs.alert.closeAll(0); borrarClaude() end
      sel = nil
    else
      cancelarSel()
    end
    copia:setProperty(props.eventSourceUserData, MARCA)
    copia:post()
    return true
  end

  -- 3) Navegación estilo Mac sin Shift
  if soloCmd and (flecha or tecla == K.delete) then
    local m = detectarModo()
    if not m then return false end
    if tecla == K.left then enviar({ "ctrl" }, "a")
    elseif tecla == K.right then enviar({ "ctrl" }, "e")
    elseif m == "zsh" then enviar({ "ctrl" }, "x"); enviar({}, "u")
    else enviar({ "ctrl" }, "u") end
    return true
  end

  return false
end):start()
