-- @description Playthrough Kit: export sem re-encode
-- @version 1.3
-- @author Vinicius Alvino
-- @about
--   Renderiza o mix na extensao do item de video e junta os dois com ffmpeg em
--   modo copy. O video final e bit a bit identico ao da camera, so com a faixa
--   de audio trocada. Requer ffmpeg (winget install Gyan.FFmpeg).

--[[
  playthrough_export_mux.lua
  Playthrough Kit v1.3

  Toda mensagem de erro tem um codigo [PT-xx]. Procure esse codigo no
  LEIA-ME.md que a causa e o conserto estao la.

  Renderiza o mix do REAPER exatamente na extensao do item de video e junta os
  dois com ffmpeg SEM re-encodar o video. O arquivo final carrega o video
  original da camera bit a bit, so com a faixa de audio trocada.

  E por isso que a qualidade nao cai: nenhum editor consegue melhor que copiar,
  porque nao existe "melhor" que zero perda.

  PRE-REQUISITO
    ffmpeg instalado. Abra o PowerShell e rode:
        winget install Gyan.FFmpeg
    Depois disso, o script localiza o binario sozinho. So preencha FFMPEG_PATH
    abaixo se voce instalou em algum lugar fora do comum.

  COMO USAR
    1. Rode o playthrough_sync_video.lua antes, pra alinhar.
    2. Selecione APENAS o item de video.
    3. Rode este script.
]]

-- ajustes ------------------------------------------------------------------
local FFMPEG_PATH = ""         -- vazio = localiza sozinho
local AUDIO_KBPS  = "320k"     -- bitrate do AAC final
local SUFFIX      = "_final"   -- sufixo do arquivo de saida
-----------------------------------------------------------------------------

local VIDEO_EXT = { mp4=true, mov=true, m4v=true, mkv=true, avi=true, webm=true }

local function splitPath(p)
  local dir, file = p:match("^(.*)[\\/]([^\\/]+)$")
  if not dir then return ".", p end
  local base, ext = file:match("^(.*)%.([^%.]+)$")
  return dir, base or file, ext or ""
end

-- Acha o ffmpeg sem depender do PATH do processo do REAPER. Isso importa
-- porque o REAPER so enxerga o PATH que existia quando ele foi aberto: quem
-- instala o ffmpeg com o REAPER ja rodando nao consegue chamar "ffmpeg" puro.
-- Procurar o caminho absoluto tambem sobrevive a atualizacao de versao do
-- winget, que troca o nome da pasta a cada release.
local function findFFmpeg()
  if FFMPEG_PATH ~= "" then return FFMPEG_PATH end

  -- 1. ao lado do proprio script
  local _, scriptPath = reaper.get_action_context()
  if scriptPath then
    local sdir = splitPath(scriptPath)
    local cand = sdir .. "\\ffmpeg.exe"
    if reaper.file_exists(cand) then return cand end
  end

  local LOCAL = os.getenv("LOCALAPPDATA") or ""

  -- 2. pasta de pacotes do winget
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
        if reaper.file_exists(cand) then return cand end
        j = j + 1
      end
    end
    i = i + 1
  end

  -- 3. links do winget e instalacoes manuais comuns
  for _, p in ipairs({
      LOCAL .. "\\Microsoft\\WinGet\\Links\\ffmpeg.exe",
      "C:\\ffmpeg\\bin\\ffmpeg.exe",
      "C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe" }) do
    if reaper.file_exists(p) then return p end
  end

  -- 4. ultimo recurso: pergunta ao proprio Windows
  local res = reaper.ExecProcess('cmd.exe /C where ffmpeg', 5000)
  if res then
    for line in res:gmatch("[^\r\n]+") do
      if line:lower():match("ffmpeg%.exe$") and reaper.file_exists(line) then
        return line
      end
    end
  end

  return nil
end

local item = reaper.GetSelectedMediaItem(0, 0)
if not item or reaper.CountSelectedMediaItems(0) ~= 1 then
  reaper.MB("[PT-01]\n\nSelecione apenas o item de video.",
            "Playthrough: export", 0)
  return
end

local take = reaper.GetActiveTake(item)
if not take then return end
local srcFile = reaper.GetMediaSourceFileName(
                  reaper.GetMediaItemTake_Source(take), "")
local ext = srcFile:match("%.([^%.\\/]+)$")
if not ext or not VIDEO_EXT[ext:lower()] then
  reaper.MB("[PT-02]\n\nO item selecionado nao parece ser video.",
            "Playthrough: export", 0)
  return
end

local ffmpeg = findFFmpeg()
if not ffmpeg then
  reaper.MB("[PT-07]\n\nNao encontrei o ffmpeg.\n\n" ..
            "Abra o PowerShell e rode:\n\n    winget install Gyan.FFmpeg\n\n" ..
            "Se ja instalou, feche e reabra o REAPER, ou preencha a variavel " ..
            "FFMPEG_PATH no topo deste script com o caminho do ffmpeg.exe.",
            "Playthrough: export", 0)
  return
end

-- Video e sempre 48 kHz. Renderizar o audio em outra taxa gera resample e, em
-- takes longos, deriva audivel. Melhor barrar aqui do que entregar um arquivo
-- que dessincroniza no fim.
local _, devSr = reaper.GetAudioDeviceInfo("SRATE", "")
local projSr   = reaper.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
local projUse  = reaper.GetSetProjectInfo(0, "PROJECT_SRATE_USE", 0, false)
local efetivo  = (projUse ~= 0) and projSr or (tonumber(devSr) or 0)

if efetivo > 0 and math.abs(efetivo - 48000) > 1 then
  if reaper.MB(string.format(
       "[PT-06]\n\nO audio esta rodando a %d Hz.\n\n" ..
       "Video e sempre 48 kHz. Em outra taxa o audio e resampleado e takes " ..
       "longos podem derivar.\n\nConserto: Preferences > Audio > Device, " ..
       "marque Request sample rate com 48000 e reinicie o REAPER.\n\n" ..
       "Continuar assim mesmo?", efetivo), "Playthrough: export", 1) ~= 1 then
    return
  end
end

local dir, base = splitPath(srcFile)
local wavPath   = dir .. "\\" .. base .. "_mix.wav"
local outPath   = dir .. "\\" .. base .. SUFFIX .. ".mp4"

-- time selection exatamente sobre o video ----------------------------------
local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
reaper.GetSet_LoopTimeRange(true, false, pos, pos + len, false)

-- render do master mix dentro da time selection ----------------------------
reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 0, true)     -- master mix
reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 2, true)   -- time selection
reaper.GetSetProjectInfo(0, "RENDER_SRATE", 48000, true)
reaper.GetSetProjectInfo(0, "RENDER_CHANNELS", 2, true)

-- "ZXZhdxgAAQ==" e o cfg de WAV 24 bits do REAPER: base64 de "evaw" (wave ao
-- contrario) seguido de 0x18, que e 24 em decimal. Cravando isso aqui, o
-- script nao depende do que estiver aberto na janela de render.
reaper.GetSetProjectInfo_String(0, "RENDER_FORMAT", "ZXZhdxgAAQ==", true)
reaper.GetSetProjectInfo_String(0, "RENDER_FILE", dir, true)
reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", base .. "_mix", true)

reaper.Main_OnCommand(41824, 0)  -- render usando as configuracoes recentes

-- 41824 costuma ser sincrono, mas com "render em background" ligado o arquivo
-- pode demorar a aparecer. Espera defensiva antes de desistir.
local waitStart = os.clock()
while not reaper.file_exists(wavPath) and (os.clock() - waitStart) < 15 do end

if not reaper.file_exists(wavPath) then
  reaper.MB("[PT-08]\n\nO render nao gerou:\n" .. wavPath ..
            "\n\nSe o REAPER estiver com render em segundo plano ligado, " ..
            "espere terminar e rode de novo.", "Playthrough: export", 0)
  return
end

-- mux sem re-encode do video -----------------------------------------------
-- escrito num .bat pra nao brigar com aspas do cmd
local batPath = dir .. "\\_mux_tmp.bat"
local bat = io.open(batPath, "w")
if not bat then
  reaper.MB("Nao consegui escrever o .bat em " .. dir, "Playthrough: export", 0)
  return
end

-- -c:v copy = o stream de video passa bit a bit, sem decodificar nem
-- recodificar. E por isso que o arquivo final tem exatamente a qualidade que
-- saiu da camera. -movflags +faststart poe o indice no comeco, pra web.
bat:write("@echo off\r\n")
bat:write(string.format(
  '"%s" -y -i "%s" -i "%s" -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a %s ' ..
  '-movflags +faststart -shortest "%s"\r\n',
  ffmpeg, srcFile, wavPath, AUDIO_KBPS, outPath))
bat:close()

local out = reaper.ExecProcess('cmd.exe /C "' .. batPath .. '"', 0)
os.remove(batPath)

if reaper.file_exists(outPath) then
  reaper.ShowConsoleMsg("pronto, sem re-encode: " .. outPath .. "\n\n")
  reaper.MB("Video final gerado:\n\n" .. outPath ..
            "\n\nO stream de video e identico ao da camera. So o audio mudou.",
            "Playthrough: export", 0)
else
  reaper.ShowConsoleMsg("ffmpeg usado: " .. ffmpeg .. "\n" ..
                        tostring(out) .. "\n\n")
  reaper.MB("[PT-09]\n\nO ffmpeg nao gerou o arquivo.\n\nBinario tentado:\n" .. ffmpeg ..
            "\n\nA saida completa do erro foi pro console: " ..
            "View > Show console output.", "Playthrough: export", 0)
end
