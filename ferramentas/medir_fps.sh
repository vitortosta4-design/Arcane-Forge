#!/bin/bash
# Mede o FPS da arena com roteiro fixo (detalhes em
# jogo/scripts/ferramentas/medir_fps.gd). Na nuvem, sem GPU, o número não
# vale nada: serve só para conferir que a ferramenta roda. O número que conta
# é o do PC com a RTX 2060, via medir_fps.bat.
# Uso: ferramentas/medir_fps.sh [--rapido]
set -uo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ/jogo"
if [ -z "${DISPLAY:-}" ]; then
  if ! pgrep -x Xvfb > /dev/null; then
    Xvfb :99 -screen 0 1280x720x24 > /dev/null 2>&1 &
    sleep 2
  fi
  export DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1
  DRIVER="--rendering-driver opengl3"
else
  DRIVER=""
fi
timeout 300 godot $DRIVER --path . --script res://scripts/ferramentas/medir_fps.gd -- "$@" 2>&1 \
  | grep -v -E "ALSA|^\s*$|audio driver|status < 0|V-Sync|backtrace|\[0\] _initialize|leaked at exit|still in use at exit"
