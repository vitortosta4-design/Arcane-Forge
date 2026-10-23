@echo off
rem Junta as informacoes do PC (placa de video, processador, memoria, Windows)
rem num arquivo info_pc.txt nesta pasta. So le, nao muda nada no PC.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0coletar_info_pc.ps1"
echo.
echo Pronto: info_pc.txt foi salvo nesta pasta.
pause
