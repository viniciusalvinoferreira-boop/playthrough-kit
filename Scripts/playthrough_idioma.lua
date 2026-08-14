-- @description Playthrough Kit: idioma / language
-- @version 1.7
-- @author Vinicius Alvino
-- @about
--   Escolhe o idioma das mensagens do Playthrough Kit (portugues ou ingles).
--   A escolha fica guardada e sobrevive as atualizacoes do ReaPack.
--
--   Chooses the language for Playthrough Kit messages (Portuguese or English).
--   The choice is stored and survives ReaPack updates.

--[[
  playthrough_idioma.lua
  Playthrough Kit v1.7

  Existe porque a preferencia de idioma nao pode morar dentro dos scripts: o
  ReaPack sobrescreve os arquivos ao atualizar, e a escolha da pessoa seria
  apagada em toda nova versao.

  Aqui a escolha vai pro ExtState do REAPER, que fica num arquivo de
  configuracao separado e sobrevive a qualquer atualizacao. Os tres scripts do
  kit leem a mesma chave, entao voce escolhe uma vez so.
]]

local SECTION = "PlaythroughKit"
local KEY     = "lang"

local atual = reaper.GetExtState(SECTION, KEY)
local rotulo
if     atual == "pt" then rotulo = "Portugues"
elseif atual == "en" then rotulo = "English"
else                      rotulo = "ainda nao escolhido / not chosen yet" end

local r = reaper.MB(
  "Idioma atual / current language:\n    " .. rotulo .. "\n\n" ..
  "Escolha o idioma das mensagens do Playthrough Kit:\n" ..
  "Choose the language for Playthrough Kit messages:\n\n" ..
  "SIM / YES     =  Portugues\n" ..
  "NAO / NO      =  English\n" ..
  "CANCELAR      =  manter como esta / keep as is",
  "Playthrough Kit", 3)

if r == 2 then return end   -- cancelou

local escolha = (r == 6) and "pt" or "en"
reaper.SetExtState(SECTION, KEY, escolha, true)   -- true = persiste em disco

reaper.MB(
  escolha == "pt"
    and "Pronto. As mensagens do Playthrough Kit agora saem em portugues."
    or  "Done. Playthrough Kit messages will now be in English.",
  "Playthrough Kit", 0)
