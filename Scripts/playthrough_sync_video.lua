-- @description Playthrough Kit: sync de video com audio
-- @version 1.5
-- @author Vinicius Alvino
-- @about
--   Alinha o video da camera com o audio gravado no REAPER, procurando o mesmo
--   transiente nos dois arquivos. O marcador tem que existir nos dois sinais:
--   use um golpe seco nas cordas abafadas, nao palma.

--[[
  playthrough_sync_video.lua
  Playthrough Kit v1.5

  Toda mensagem de erro tem um codigo [PT-xx]. Procure esse codigo no
  LEIA-ME.md que a causa e o conserto estao la.

  Alinha o item de video (gravado no celular) com o item de audio da guitarra,
  usando o transiente mais forte do inicio de cada um como ponto de encontro.

  O PONTO CRITICO
    O marcador precisa existir NOS DOIS sinais. Palma nao serve: ela entra no
    mic do celular mas nao passa pelo captador da guitarra. O que serve e um
    golpe seco nas cordas abafadas, o "chunk": ele sai pelo captador (entra no
    REAPER) e sai acusticamente (o mic do celular pega). E esse evento comum
    que o script procura nos dois arquivos.

  COMO USAR
    1. Comece a gravar nos dois lados.
    2. De o chunk, forte. Espere 1 ou 2 segundos. Toque.
    3. Arraste o arquivo do celular pra uma track.
    4. Selecione DOIS itens: o de video e o da guitarra.
    5. Rode este script. Ele move o item de video pra posicao certa.
]]

-- ajustes ------------------------------------------------------------------
-- Janela de busca. Curta de proposito: o piso de ruido e estimado a partir da
-- propria janela, entao quanto mais musica couber dentro dela, mais alto o piso
-- fica e mais dificil e enxergar o marcador. 12 segundos e folga de sobra pra
-- quem da o golpe no comeco, e mantem a maior parte da janela em silencio.
local SEARCH_WINDOW = 12.0
local READ_SR       = 48000   -- taxa de leitura da analise
local BLOCK         = 48000   -- samples por leitura (1 segundo)

-- Como o marcador e reconhecido.
--
-- A versao antiga procurava o pico da janela e pegava o primeiro ponto acima de
-- 50% dele. Isso quebra no audio do microfone da camera: ali a musica e muito
-- mais alta que o golpe inicial, entao o golpe nao chegava nem perto de 50% do
-- pico e o script marcava um ponto qualquer no meio da musica.
--
-- Agora a referencia e o SILENCIO, nao o pico. O marcador e o primeiro evento
-- que se levanta muito acima do ruido de fundo da sala, e isso vale mesmo que a
-- musica depois fique dez vezes mais alta que ele.
local NOISE_FACTOR     = 10.0  -- quantas vezes acima do silencio de fundo conta
local MIN_PEAK_RATIO   = 0.05  -- piso de seguranca, fracao do pico da janela
local NOISE_PERCENTILE = 0.2   -- fracao da janela que se assume ser silencio
local ENV_BLOCK        = 960   -- 20 ms a 48k, resolucao do envelope

-- Compensacao do priming do AAC, em milissegundos.
--
-- Encoders AAC inserem um bloco de silencio no inicio do stream (1024 samples,
-- que a 48 kHz dao 21,33 ms). Players que leem o metadado descartam esse bloco;
-- o REAPER nao descarta ao entregar o audio pelo audio accessor. Resultado: o
-- audio do video chega aqui ~21 ms atrasado em relacao a imagem, e o alinhamento
-- herdaria esse erro.
--
-- Praticamente todo video de camera e celular usa AAC, entao a compensacao vem
-- ligada. Se o audio do seu video for PCM (alguns .mov), ponha 0 aqui.
-- Se o audio do video for AAC a 44,1 kHz, o valor certo e 23.2.
-- 1024 samples a 48 kHz. Nao arredonde nem "atualize" este numero sem motivo:
-- ele vem da conta 1024/48000, nao de tentativa e erro.
local VIDEO_AUDIO_OFFSET_MS = 21.3
-----------------------------------------------------------------------------

local VIDEO_EXT = { mp4=true, mov=true, m4v=true, mkv=true, avi=true, webm=true }

local function itemFile(item)
  local take = reaper.GetActiveTake(item)
  if not take or reaper.TakeIsMIDI(take) then return nil end
  local src = reaper.GetMediaItemTake_Source(take)
  if not src then return nil end
  return reaper.GetMediaSourceFileName(src, "")
end

local function isVideo(item)
  local fn = itemFile(item)
  if not fn then return false end
  local ext = fn:match("%.([^%.\\/]+)$")
  return ext ~= nil and VIDEO_EXT[ext:lower()] == true
end

-- O script assume itens inteiros e em velocidade normal. Se nao for o caso, a
-- conta do offset sai errada de um jeito silencioso, entao vale avisar antes.
local function itemWarnings(item, label)
  local take = reaper.GetActiveTake(item)
  local out = {}
  if not take then return out end

  local rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  if math.abs(rate - 1.0) > 0.0001 then
    out[#out+1] = string.format("%s: playrate %.4f (o script assume 1.0)", label, rate)
  end

  local offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  if offs > 0.0001 then
    out[#out+1] = string.format("%s: item cortado no inicio (%.3f s). " ..
                               "Sincronize primeiro, corte depois.", label, offs)
  end
  return out
end

-- devolve o offset (segundos, relativo ao inicio do item) do ataque mais forte
local function findTransient(item)
  local take = reaper.GetActiveTake(item)
  if not take then return nil, "item sem take" end

  local acc = reaper.CreateTakeAudioAccessor(take)
  if not acc then return nil, "nao consegui abrir o audio" end

  local t0  = reaper.GetAudioAccessorStartTime(acc)
  local t1  = reaper.GetAudioAccessorEndTime(acc)
  local dur = math.min(SEARCH_WINDOW, t1 - t0)
  if dur <= 0 then
    reaper.DestroyAudioAccessor(acc)
    return nil, "item vazio"
  end

  -- Le um canal so. Com numchannels=1 nao existe ambiguidade de layout de
  -- buffer (interleaved e planar coincidem), entao a posicao do transiente sai
  -- certa independente da convencao interna. Pra achar ataque, um canal basta.
  local nch = 1
  local buf = reaper.new_array(BLOCK)

  -- passada 1: monta um envelope grosseiro (pico a cada 20 ms) pra descobrir
  -- tanto o pico da janela quanto o nivel do silencio de fundo
  local env  = {}
  local peak = 0.0
  local pos  = 0.0
  while pos < dur do
    local n = math.min(BLOCK, math.floor((dur - pos) * READ_SR))
    if n <= 0 then break end
    buf.clear()
    reaper.GetAudioAccessorSamples(acc, READ_SR, nch, t0 + pos, n, buf)
    local i = 1
    while i <= n do
      local stop = math.min(i + ENV_BLOCK - 1, n)
      local m = 0.0
      for k = i, stop do
        local v = math.abs(buf[k] or 0)
        if v > m then m = v end
      end
      env[#env + 1] = m
      if m > peak then peak = m end
      i = stop + 1
    end
    pos = pos + n / READ_SR
  end

  if peak < 0.001 then
    reaper.DestroyAudioAccessor(acc)
    return nil, "audio silencioso ou nao decodificado"
  end

  -- O piso de ruido vem do percentil 20 do envelope, nao do minimo: um unico
  -- bloco de silencio digital puxaria o minimo pra zero e derrubaria o limiar.
  table.sort(env)
  local noiseFloor = env[math.max(1, math.floor(#env * NOISE_PERCENTILE))] or 0

  -- limiar = bem acima do silencio, com piso de seguranca pra nao disparar em
  -- ruidinho de sala, e teto pra garantir que sempre exista algo que cruze
  local threshold = math.max(noiseFloor * NOISE_FACTOR, peak * MIN_PEAK_RATIO)
  threshold = math.min(threshold, peak * 0.9)

  -- passada 2: primeiro ponto que cruza o limiar (o ataque, nao o topo)
  local hit = nil
  pos = 0.0
  while pos < dur and not hit do
    local n = math.min(BLOCK, math.floor((dur - pos) * READ_SR))
    if n <= 0 then break end
    buf.clear()
    reaper.GetAudioAccessorSamples(acc, READ_SR, nch, t0 + pos, n, buf)
    for i = 1, n do
      if math.abs(buf[i] or 0) >= threshold then
        hit = pos + (i - 1) / READ_SR
        break
      end
    end
    pos = pos + n / READ_SR
  end

  reaper.DestroyAudioAccessor(acc)
  if not hit then return nil, "nao achei o transiente" end
  return hit
end

-- main ---------------------------------------------------------------------
local n = reaper.CountSelectedMediaItems(0)
if n ~= 2 then
  reaper.MB("[PT-01]\n\nSelecione exatamente 2 itens: o de video e o da " ..
            "guitarra.\n\nSelecionados agora: " .. n, "Playthrough: sync", 0)
  return
end

local a = reaper.GetSelectedMediaItem(0, 0)
local b = reaper.GetSelectedMediaItem(0, 1)

local vid, ref
if isVideo(a) and not isVideo(b) then
  vid, ref = a, b
elseif isVideo(b) and not isVideo(a) then
  vid, ref = b, a
else
  reaper.MB("[PT-02]\n\nPreciso de um item de video e um de audio.\n\n" ..
            "Se os dois forem video, ou nenhum for, nao tem como saber qual " ..
            "mover. Extensoes reconhecidas como video: mp4, mov, m4v, mkv, " ..
            "avi, webm.", "Playthrough: sync", 0)
  return
end

local warn = {}
for _, w in ipairs(itemWarnings(vid, "video"))    do warn[#warn+1] = w end
for _, w in ipairs(itemWarnings(ref, "guitarra")) do warn[#warn+1] = w end
if #warn > 0 then
  local msg = "[PT-05]\n\nEncontrei isto:\n\n  " .. table.concat(warn, "\n  ") ..
              "\n\nQuer continuar mesmo assim?"
  if reaper.MB(msg, "Playthrough: sync", 1) ~= 1 then return end
end

-- vale a taxa em que o audio realmente roda: a do device, a menos que o projeto
-- crave outra. Olhar so PROJECT_SRATE dava alarme falso pra quem tinha o device
-- certo e o projeto sem a flag ligada.
local _, devSr = reaper.GetAudioDeviceInfo("SRATE", "")
local projSr   = reaper.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
local projUse  = reaper.GetSetProjectInfo(0, "PROJECT_SRATE_USE", 0, false)
local efetivo  = (projUse ~= 0) and projSr or (tonumber(devSr) or 0)

if efetivo > 0 and math.abs(efetivo - 48000) > 1 then
  reaper.ShowConsoleMsg(string.format(
    "[PT-06] o audio esta rodando a %d Hz. Video e sempre 48 kHz; em outra " ..
    "taxa o REAPER resampla e takes longos podem derivar.\nConserto: " ..
    "Preferences > Audio > Device, marque Request sample rate com 48000.\n\n",
    efetivo))
end

local tVid, errV = findTransient(vid)
local tRef, errR = findTransient(ref)

local CHUNK_HINT =
  "\n\nLembre: o marcador tem que aparecer nos DOIS sinais. Palma nao entra " ..
  "pelo captador. Use um golpe seco nas cordas abafadas, e forte."

-- audio que nao decodifica e audio sem chunk sao problemas diferentes e tem
-- consertos diferentes, entao ganham codigos diferentes
local function errCode(err)
  if err == "audio silencioso ou nao decodificado" then return "PT-04" end
  return "PT-03"
end

if not tVid then
  reaper.MB("[" .. errCode(errV) .. "]\n\nNao consegui analisar o video: " ..
            tostring(errV) ..
            "\n\nSe for problema de decodificacao, converta pra H.264 ou " ..
            "instale o LAV Filters." .. CHUNK_HINT, "Playthrough: sync", 0)
  return
end
if not tRef then
  reaper.MB("[" .. errCode(errR) .. "]\n\nNao consegui analisar a guitarra: " ..
            tostring(errR) .. CHUNK_HINT, "Playthrough: sync", 0)
  return
end

local posVid = reaper.GetMediaItemInfo_Value(vid, "D_POSITION")
local posRef = reaper.GetMediaItemInfo_Value(ref, "D_POSITION")

-- o transiente medido no audio do video vem atrasado pelo priming do AAC, entao
-- a posicao real do chunk e um pouco antes do que a analise encontrou
local tVidCorr = tVid - VIDEO_AUDIO_OFFSET_MS / 1000

local absVid = posVid + tVidCorr  -- onde o chunk cai, no video
local absRef = posRef + tRef      -- onde o chunk cai, na guitarra
local delta  = absRef - absVid

local novaPos  = posVid + delta
local empurrou = 0

reaper.Undo_BeginBlock()
if novaPos < 0 then
  -- O video precisaria comecar antes do zero da timeline. Isso acontece sempre
  -- que voce aperta REC na camera antes de apertar REC no REAPER, que e a ordem
  -- natural. O REAPER nao aceita item em posicao negativa: ele trava em 0 e o
  -- alinhamento sai errado sem avisar ninguem.
  --
  -- Entao, em vez de puxar o video pra tras, empurramos todo o resto pra frente
  -- na mesma medida. O alinhamento entre as tracks de audio e preservado,
  -- porque todas andam juntas.
  empurrou = -novaPos
  local total = reaper.CountMediaItems(0)
  for i = 0, total - 1 do
    local it = reaper.GetMediaItem(0, i)
    if it ~= vid then
      local p = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
      reaper.SetMediaItemInfo_Value(it, "D_POSITION", p + empurrou)
    end
  end
  novaPos = 0
end
reaper.SetMediaItemInfo_Value(vid, "D_POSITION", novaPos)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Playthrough: sync video com audio", -1)

reaper.ShowConsoleMsg(string.format(
  "sync ok\n" ..
  "  marcador no video    : %.4f s  (medido %.4f, priming AAC -%.1f ms)\n" ..
  "  marcador na referencia: %.4f s\n" ..
  "  video deslocado      : %+.1f ms\n",
  tVidCorr, tVid, VIDEO_AUDIO_OFFSET_MS, tRef, delta * 1000))

if empurrou > 0 then
  reaper.ShowConsoleMsg(string.format(
    "  o video comecaria antes do zero, entao ele foi pra 0 e todo o resto\n" ..
    "  andou %+.1f ms pra frente, mantendo o alinhamento entre as tracks\n",
    empurrou * 1000))
end
reaper.ShowConsoleMsg("\n")

-- Se o marcador caiu perto do fim da janela de busca, e provavel que o script
-- tenha pego a primeira nota da musica no lugar do chunk.
if tVid > SEARCH_WINDOW * 0.8 or tRef > SEARCH_WINDOW * 0.8 then
  reaper.ShowConsoleMsg(
    "[PT-10] o marcador foi achado bem no fim da janela de busca. Confira " ..
    "de ouvido, pode ter pego a primeira nota no lugar do chunk.\n\n")
end
