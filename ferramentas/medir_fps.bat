@echo off
rem Mede o FPS da arena com roteiro fixo (70 segundos). Rodar no PC com a RTX 2060.
rem Precisa do Godot 4.7.2 instalado e chamado "godot" no PATH (o WinGet ja faz isso).
rem Nao mexa no mouse nem troque de janela durante a medicao.
cd /d "%~dp0..\jogo"
godot --path . --resolution 1920x1080 --script res://scripts/ferramentas/medir_fps.gd
echo.
echo Medicao terminada. Copie o texto acima (ou o arquivo medicao_fps.txt) e mande para o Claude.
pause
