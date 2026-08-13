@echo off
setlocal
title Playthrough Kit - instalador

echo.
echo  ==================================================
echo    PLAYTHROUGH KIT v1.0
echo  ==================================================
echo.

set "DEST=%APPDATA%\REAPER"

if not exist "%DEST%" (
  echo  [X] Nao achei a pasta de configuracao do REAPER em:
  echo      %DEST%
  echo.
  echo  Abra o REAPER pelo menos uma vez e rode este instalador de novo.
  echo.
  pause
  exit /b 1
)

echo  REAPER encontrado em:
echo    %DEST%
echo.
echo  Vou copiar:
echo    2 scripts  para  %DEST%\Scripts\
echo    1 template para  %DEST%\ProjectTemplates\
echo.
echo  Nada fora dessas duas pastas e tocado.
echo.

choice /C SN /M "Pode continuar (S/N)"
if errorlevel 2 goto :fim

if not exist "%DEST%\Scripts" mkdir "%DEST%\Scripts"
if not exist "%DEST%\ProjectTemplates" mkdir "%DEST%\ProjectTemplates"

copy /Y "%~dp0Scripts\*.lua" "%DEST%\Scripts\" >nul
if errorlevel 1 goto :erro
copy /Y "%~dp0ProjectTemplates\*.RPP" "%DEST%\ProjectTemplates\" >nul
if errorlevel 1 goto :erro

echo.
echo  [OK] Arquivos copiados.
echo.

where ffmpeg >nul 2>&1
if %errorlevel%==0 (
  echo  [OK] ffmpeg ja esta instalado.
  goto :depois
)

echo  [!] ffmpeg nao encontrado, e ele e obrigatorio pro export.
echo      Sao uns 200 MB. Nao e servico, nao roda em segundo plano:
echo      fica parado no disco ate o script chamar.
echo.

choice /C SN /M "Instalar agora via winget (S/N)"
if errorlevel 2 (
  echo.
  echo  Sem problema. Quando quiser, abra o PowerShell e rode:
  echo      winget install Gyan.FFmpeg
  goto :depois
)

echo.
winget install Gyan.FFmpeg --accept-package-agreements --accept-source-agreements
echo.

:depois
echo.
echo  ==================================================
echo    FALTA UM PASSO, E E NO REAPER
echo  ==================================================
echo.
echo  Os scripts precisam ser registrados como acoes. Isso nao da pra
echo  automatizar sem mexer na sua configuracao de atalhos, e nao vou
echo  fazer isso no arquivo de config de ninguem.
echo.
echo  No REAPER:
echo    1. Actions ^> Show action list
echo    2. Botao "New action" ^> "Load ReaScript..."
echo    3. Escolha os TRES arquivos em:
echo       %DEST%\Scripts\
echo         playthrough_sync_video.lua
echo         playthrough_export_mux.lua
echo         playthrough_diagnostico.lua
echo.
echo  O template ja aparece sozinho em:
echo    File ^> Project templates ^> Playthrough
echo.
echo  DEPOIS DISSO, TESTE: a pasta Teste\ tem dois arquivos com
echo  deslocamento conhecido. Arraste os dois pro REAPER na posicao 0,
echo  selecione os dois e rode o sync. Tem que dar +3000.0 ms.
echo  Se der, a instalacao esta redonda.
echo.
echo  Leia o LEIA-ME.md antes do primeiro take. Tem uma parte sobre o
echo  golpe nas cordas que e a unica coisa que costuma dar errado.
echo  Se travar em alguma coisa, abra o TO COM PROBLEMA.txt.
echo.
goto :fim

:erro
echo.
echo  [X] Falhou ao copiar. O REAPER esta com algum desses arquivos aberto?
echo.

:fim
echo.
pause
endlocal
