@echo off
rem Mede o FPS do Arcane Forge com um roteiro fixo (uns 70 segundos).
rem Nao mexa no mouse nem troque de janela enquanto roda.
cd /d "%~dp0"
echo Medindo o FPS... nao mexa no mouse nem troque de janela (uns 70 segundos).
start "" /wait "ArcaneForge.exe" --resolution 1920x1080 -- --medir-fps
set "RELATORIO=%APPDATA%\Godot\app_userdata\Arcane Forge\medicao_fps.txt"
if exist "%RELATORIO%" (
  copy /y "%RELATORIO%" "%~dp0resultado_fps.txt" >nul
  echo.
  type "%~dp0resultado_fps.txt"
  echo.
  echo Pronto. O resultado tambem ficou salvo em resultado_fps.txt, nesta pasta.
) else (
  echo.
  echo Nao achei o relatorio em "%RELATORIO%". Mande um print desta janela para o Vitor.
)
pause
