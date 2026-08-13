-- @description Playthrough Kit: diagnostico
-- @version 1.1
-- @author Vinicius Alvino
-- @about
--   Relatorio de ambiente pra quando algo nao funciona. Nao altera nada no
--   projeto. Checa REAPER, ffmpeg, sample rate e os itens selecionados.

--[[
  playthrough_diagnostico.lua
  Playthrough Kit v1.1

  Nao muda nada no seu projeto. Só olha o ambiente e escreve um relatorio no
  console do REAPER.

  QUANDO USAR
    Quando alguma coisa nao funcionar. Rode este script, copie TUDO que
    aparecer no console e mande junto com a sua duvida (pro suporte ou pra
    uma IA, junto com o arquivo CONTEXTO-IA.md).

    Com esse relatorio na mao, quem for te ajudar ve o problema em vez de
    adivinhar.

  COMO USAR
    Opcional: selecione os itens de video e guitarra antes de rodar, que o
    relatorio inclui a analise deles tambem.
]]

local L = {}
local function say(s) L[#L+1] = s or "" end

local function fmtBool(b) if b then return "sim" else return "nao" end end

-- mesma busca do export, replicada aqui de proposito: cada script do kit e
-- independente, entao um instala sem o outro e nada quebra
local function splitPath(p)
  local dir, file = p:match("^(.*)[\\/]([^\\/]+)$")
  if not dir then return ".", p end
  return dir, file
end

local function findFFmpeg()
  local _, scriptPath = reaper.get_action_context()
  if scriptPath then
    local sdir = splitPath(scriptPath)
    local cand = sdir .. "\\ffmpeg.exe"
    if reaper.file_exists(cand) then return cand, "ao lado do script" end
  end

  local LOCAL = os.getenv("LOCALAPPDATA") or ""
  local root = LOCAL .. "\\Microsoft\\WinGet\\Packages"
  local i = 0
  while true do
    local pkg = reaper.EnumerateSubdirectories(root, i)
    if not pkg then break end
    if pkg:match("^Gyan%.FFmpeg") then
      local j = 0
      while true do
        local build = reaper.EnumerateSubdirectories(root .. "\\" .. pkg, j)
        if not build then break end
        local cand = root .. "\\" .. pkg .. "\\" .. build .. "\\bin\\ffmpeg.exe"
        if reaper.file_exists(cand) then return cand, "winget" end
        j = j + 1
      end
    end
    i = i + 1
  end

  for _, p in ipairs({
      LOCAL .. "\\Microsoft\\WinGet\\Links\\ffmpeg.exe",
      "C:\\ffmpeg\\bin\\ffmpeg.exe",
      "C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe" }) do
    if reaper.file_exists(p) then return p, "caminho comum" end
  end

  local res = reaper.ExecProcess('cmd.exe /C where ffmpeg', 5000)
  if res then
    for line in res:gmatch("[^\r\n]+") do
      if line:lower():match("ffmpeg%.exe$") and reaper.file_exists(line) then
        return line, "PATH do sistema"
      end
    end
  end

  return nil, nil
end

-- analisa um item e devolve pico e duracao, pra saber se o audio decodifica
local function probeItem(item)
  local take = reaper.GetActiveTake(item)
  if not take then return nil, "sem take" end
  local acc = reaper.CreateTakeAudioAccessor(take)
  if not acc then return nil, "sem audio accessor" end

  local t0 = reaper.GetAudioAccessorStartTime(acc)
  local t1 = reaper.GetAudioAccessorEndTime(acc)
  local n = 48000
  local buf = reaper.new_array(n)
  local peak = 0.0
  local secs = math.min(10, t1 - t0)
  local pos = 0.0
  while pos < secs do
    local cnt = math.min(n, math.floor((secs - pos) * 48000))
    if cnt <= 0 then break end
    buf.clear()
    reaper.GetAudioAccessorSamples(acc, 48000, 1, t0 + pos, cnt, buf)
    for i = 1, cnt do
      local v = math.abs(buf[i] or 0)
      if v > peak then peak = v end
    end
    pos = pos + cnt / 48000
  end
  reaper.DestroyAudioAccessor(acc)
  return peak, nil
end

-- coleta -------------------------------------------------------------------
say("========================================")
say(" PLAYTHROUGH KIT - RELATORIO DE AMBIENTE")
say("========================================")
say()

local ver, arch = reaper.GetAppVersion()
say("REAPER            : " .. tostring(ver) .. "  " .. tostring(arch))
say("Pasta de recursos : " .. reaper.GetResourcePath())
say("SWS instalado     : " .. fmtBool(reaper.APIExists("CF_GetSWSVersion")))
say()

-- scripts do kit
local resPath = reaper.GetResourcePath()
for _, f in ipairs({ "playthrough_sync_video.lua",
                     "playthrough_export_mux.lua",
                     "playthrough_diagnostico.lua" }) do
  local p = resPath .. "\\Scripts\\" .. f
  say(string.format("%-34s %s", f, reaper.file_exists(p) and "OK" or "NAO ENCONTRADO"))
end
say()

-- ffmpeg
local ffmpeg, how = findFFmpeg()
if ffmpeg then
  say("ffmpeg            : " .. ffmpeg)
  say("  achado via      : " .. how)
  local out = reaper.ExecProcess('"' .. ffmpeg .. '" -version', 8000)
  if out then
    local first = out:match("ffmpeg version [^\r\n]*")
    say("  versao          : " .. (first or "nao consegui ler"))
  else
    say("  versao          : nao consegui executar o binario")
  end
else
  say("ffmpeg            : NAO ENCONTRADO   [PT-07]")
  say("  conserto        : winget install Gyan.FFmpeg, depois reabra o REAPER")
end
say()

-- sample rate
local sr    = reaper.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
local srUse = reaper.GetSetProjectInfo(0, "PROJECT_SRATE_USE", 0, false)
say(string.format("Sample rate       : %d Hz (cravado: %s)", sr, fmtBool(srUse ~= 0)))
if srUse == 0 or math.abs(sr - 48000) > 1 then
  say("  ATENCAO         : deveria ser 48000 cravado   [PT-06]")
  say("  conserto        : Project Settings > Sample rate = 48000, marcado")
end
say()

-- itens selecionados
local n = reaper.CountSelectedMediaItems(0)
say("Itens selecionados: " .. n)
if n == 0 then
  say("  (selecione o video e a guitarra e rode de novo pra analisar os dois)")
end

for i = 0, n - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local take = reaper.GetActiveTake(item)
  say()
  say("  --- item " .. (i + 1) .. " ---")
  if take then
    local src = reaper.GetMediaItemTake_Source(take)
    local fn  = src and reaper.GetMediaSourceFileName(src, "") or "?"
    local _, nome = splitPath(fn)
    say("  arquivo         : " .. nome)
    say(string.format("  posicao         : %.3f s", reaper.GetMediaItemInfo_Value(item, "D_POSITION")))
    say(string.format("  duracao         : %.3f s", reaper.GetMediaItemInfo_Value(item, "D_LENGTH")))
    local rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    say(string.format("  playrate        : %.4f%s", rate,
        math.abs(rate - 1.0) > 0.0001 and "   ATENCAO: deveria ser 1.0   [PT-05]" or ""))
    say(string.format("  corte no inicio : %.3f s%s", offs,
        offs > 0.0001 and "   ATENCAO: sincronize antes de cortar   [PT-05]" or ""))

    local peak, err = probeItem(item)
    if peak then
      say(string.format("  pico do audio   : %.4f%s", peak,
          peak < 0.001 and "   ATENCAO: silencioso ou nao decodifica   [PT-04]" or ""))
    else
      say("  pico do audio   : falhou (" .. tostring(err) .. ")   [PT-04]")
    end
  else
    say("  item sem take ativo")
  end
end

say()
say("========================================")
say(" Copie tudo acima e mande junto com a")
say(" sua duvida, com o arquivo CONTEXTO-IA.md")
say("========================================")
say()

reaper.ShowConsoleMsg(table.concat(L, "\n") .. "\n")
