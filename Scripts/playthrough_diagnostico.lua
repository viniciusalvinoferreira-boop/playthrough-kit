-- @description Playthrough Kit: diagnostico
-- @version 1.6
-- @author Vinicius Alvino
-- @about
--   Relatorio de ambiente pra quando algo nao funciona. Nao altera nada no
--   projeto. Checa REAPER, ffmpeg, sample rate e os itens selecionados.

--[[
  playthrough_diagnostico.lua
  Playthrough Kit v1.6

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

-- idioma das mensagens: "pt" ou "en" --------------------------------------
local LANG = "pt"

local STR = {
  pt = {
    header    = " PLAYTHROUGH KIT - RELATORIO DE AMBIENTE",
    yes       = "sim",
    no        = "nao",
    reaper    = "REAPER            : ",
    resource  = "Pasta de recursos : ",
    sws       = "SWS instalado     : ",
    installed = "Instalado em      : ",
    unknown   = "nao consegui determinar",
    notFound  = "NAO ENCONTRADO",
    ffmpeg    = "ffmpeg            : ",
    foundVia  = "  achado via      : ",
    version   = "  versao          : ",
    cantRead  = "nao consegui ler",
    cantRun   = "nao consegui executar o binario",
    ffNone    = "ffmpeg            : NAO ENCONTRADO   [PT-07]",
    ffFix     = "  conserto        : winget install Gyan.FFmpeg, depois reabra o REAPER",
    srReal    = "Sample rate real  : %d Hz  (interface de audio)",
    srUnread  = "Sample rate real  : nao consegui ler (interface fechada?)",
    srPin     = "  projeto crava   : %d Hz",
    srNoPin   = "  projeto crava   : nao (guarda %d Hz sem efeito)",
    srWarn    = "  ATENCAO         : o audio esta rodando fora de 48000 Hz   [PT-06]",
    srFix1    = "  conserto        : Preferences > Audio > Device, marque",
    srFix2    = "                    Request sample rate com 48000, e reinicie o REAPER",
    selected  = "Itens selecionados: ",
    selHint   = "  (selecione o video e o audio e rode de novo pra analisar os dois)",
    itemHdr   = "  --- item %d ---",
    iFile     = "  arquivo         : ",
    iPos      = "  posicao         : %.3f s",
    iLen      = "  duracao         : %.3f s",
    iRate     = "  playrate        : %.4f%s",
    iTrim     = "  corte no inicio : %.3f s%s",
    iPeak     = "  pico do audio   : %.4f%s",
    wRate     = "   ATENCAO: deveria ser 1.0   [PT-05]",
    wTrim     = "   ATENCAO: sincronize antes de cortar   [PT-05]",
    wSilent   = "   ATENCAO: silencioso ou nao decodifica   [PT-04]",
    peakFail  = "  pico do audio   : falhou (%s)   [PT-04]",
    noTake    = "  item sem take ativo",
    foot1     = " Copie tudo acima e mande junto com a sua duvida.",
    foot2     = " Documentacao e arquivos de teste (quem instalou pelo",
    foot3     = " ReaPack nao recebe esses arquivos junto):",
    foot4     = "   CONTEXTO-IA.md .... cole numa IA junto com este relatorio",
    foot5     = "   LEIA-ME.md ........ tabela dos codigos [PT-xx]",
    foot6     = "   Teste/ ............ dois arquivos pra validar a instalacao",
  },
  en = {
    header    = " PLAYTHROUGH KIT - ENVIRONMENT REPORT",
    yes       = "yes",
    no        = "no",
    reaper    = "REAPER            : ",
    resource  = "Resource path     : ",
    sws       = "SWS installed     : ",
    installed = "Installed in      : ",
    unknown   = "could not determine",
    notFound  = "NOT FOUND",
    ffmpeg    = "ffmpeg            : ",
    foundVia  = "  found via       : ",
    version   = "  version         : ",
    cantRead  = "could not read",
    cantRun   = "could not run the binary",
    ffNone    = "ffmpeg            : NOT FOUND   [PT-07]",
    ffFix     = "  fix             : winget install Gyan.FFmpeg, then reopen REAPER",
    srReal    = "Actual sample rate: %d Hz  (audio interface)",
    srUnread  = "Actual sample rate: could not read (interface closed?)",
    srPin     = "  project pins    : %d Hz",
    srNoPin   = "  project pins    : no (stores %d Hz with no effect)",
    srWarn    = "  WARNING         : audio is running outside 48000 Hz   [PT-06]",
    srFix1    = "  fix             : Preferences > Audio > Device, tick",
    srFix2    = "                    Request sample rate with 48000, then restart REAPER",
    selected  = "Selected items    : ",
    selHint   = "  (select the video and the audio, then run again to analyze both)",
    itemHdr   = "  --- item %d ---",
    iFile     = "  file            : ",
    iPos      = "  position        : %.3f s",
    iLen      = "  length          : %.3f s",
    iRate     = "  playrate        : %.4f%s",
    iTrim     = "  trimmed start   : %.3f s%s",
    iPeak     = "  audio peak      : %.4f%s",
    wRate     = "   WARNING: should be 1.0   [PT-05]",
    wTrim     = "   WARNING: sync before trimming   [PT-05]",
    wSilent   = "   WARNING: silent, or not decoding   [PT-04]",
    peakFail  = "  audio peak      : failed (%s)   [PT-04]",
    noTake    = "  item has no active take",
    foot1     = " Copy everything above and send it with your question.",
    foot2     = " Docs and test files (installing via ReaPack does not",
    foot3     = " bring these files along):",
    foot4     = "   AI-CONTEXT.md ..... paste into an AI along with this report",
    foot5     = "   MANUAL-en.md ...... table of the [PT-xx] codes",
    foot6     = "   Teste/ ............ two files to validate the install",
  },
}
local T = STR[LANG] or STR.en
-----------------------------------------------------------------------------

local L = {}
local function say(s) L[#L+1] = s or "" end

local function fmtBool(b) if b then return T.yes else return T.no end end

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
say(T.header)
say("========================================")
say()

-- GetAppVersion devolve UM valor so ("7.73/x64"), nao dois
local ver = reaper.GetAppVersion()
say(T.reaper   .. tostring(ver))
say(T.resource .. reaper.GetResourcePath())
say(T.sws      .. fmtBool(reaper.APIExists("CF_GetSWSVersion")))
say()

-- Os outros scripts do kit ficam na mesma pasta que este aqui, seja ela qual
-- for: quem instala pelo INSTALAR.bat cai em Scripts\, quem instala pelo
-- ReaPack cai numa subpasta propria dele. Perguntar onde EU estou funciona nos
-- dois casos. Procurar num caminho fixo dava falso "NAO ENCONTRADO" pra quem
-- tinha instalado certinho pelo ReaPack.
local _, thisPath = reaper.get_action_context()
local myDir = thisPath and splitPath(thisPath) or nil
say(T.installed .. (myDir or T.unknown))
if myDir then
  for _, f in ipairs({ "playthrough_sync_video.lua",
                       "playthrough_export_mux.lua",
                       "playthrough_diagnostico.lua" }) do
    say(string.format("  %-32s %s", f,
        reaper.file_exists(myDir .. "\\" .. f) and "OK" or T.notFound))
  end
end
say()

-- ffmpeg
local ffmpeg, how = findFFmpeg()
if ffmpeg then
  say(T.ffmpeg   .. ffmpeg)
  say(T.foundVia .. how)
  local out = reaper.ExecProcess('"' .. ffmpeg .. '" -version', 8000)
  if out then
    local first = out:match("ffmpeg version [^\r\n]*")
    say(T.version .. (first or T.cantRead))
  else
    say(T.version .. T.cantRun)
  end
else
  say(T.ffNone)
  say(T.ffFix)
end
say()

-- Sample rate. O que importa e a taxa em que o audio esta REALMENTE rodando,
-- que e a do device. PROJECT_SRATE so vale quando PROJECT_SRATE_USE esta
-- ligado; com a flag desligada aquele numero fica no projeto sem efeito nenhum,
-- e reportar ele como se fosse a taxa real era enganoso.
local _, devSr = reaper.GetAudioDeviceInfo("SRATE", "")
local devRate  = tonumber(devSr) or 0
local projSr   = reaper.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
local projUse  = reaper.GetSetProjectInfo(0, "PROJECT_SRATE_USE", 0, false)

if devRate > 0 then
  say(string.format(T.srReal, devRate))
else
  say(T.srUnread)
end
if projUse ~= 0 then
  say(string.format(T.srPin, projSr))
else
  say(string.format(T.srNoPin, projSr))
end

local efetivo = (projUse ~= 0) and projSr or devRate
if efetivo > 0 and math.abs(efetivo - 48000) > 1 then
  say(T.srWarn)
  say(T.srFix1)
  say(T.srFix2)
end
say()

-- itens selecionados
local n = reaper.CountSelectedMediaItems(0)
say(T.selected .. n)
if n == 0 then
  say(T.selHint)
end

for i = 0, n - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local take = reaper.GetActiveTake(item)
  say()
  say(string.format(T.itemHdr, i + 1))
  if take then
    local src = reaper.GetMediaItemTake_Source(take)
    local fn  = src and reaper.GetMediaSourceFileName(src, "") or "?"
    local _, nome = splitPath(fn)
    say(T.iFile .. nome)
    say(string.format(T.iPos, reaper.GetMediaItemInfo_Value(item, "D_POSITION")))
    say(string.format(T.iLen, reaper.GetMediaItemInfo_Value(item, "D_LENGTH")))
    local rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    say(string.format(T.iRate, rate,
        math.abs(rate - 1.0) > 0.0001 and T.wRate or ""))
    say(string.format(T.iTrim, offs, offs > 0.0001 and T.wTrim or ""))

    local peak, err = probeItem(item)
    if peak then
      say(string.format(T.iPeak, peak, peak < 0.001 and T.wSilent or ""))
    else
      say(string.format(T.peakFail, tostring(err)))
    end
  else
    say(T.noTake)
  end
end

say()
say("========================================")
say(T.foot1)
say()
say(T.foot2)
say(T.foot3)
say("   https://github.com/viniciusalvinoferreira-boop/playthrough-kit")
say()
say(T.foot4)
say(T.foot5)
say(T.foot6)
say("========================================")
say()

reaper.ShowConsoleMsg(table.concat(L, "\n") .. "\n")
