#!/bin/bash
# Tira um print do jogo rodando de verdade, sem GPU (tela virtual Xvfb +
# OpenGL por software). Só renderiza o modo Compatibility: névoa volumétrica
# e SDFGI (Forward+) não aparecem aqui, só no PC do Vitor.
#
# Uso:
#   ferramentas/tirar_print.sh SAIDA.png [opções]
# Opções:
#   --posicao x,y,z   onde colocar o mago
#   --olhar x,y,z     para onde o mago olha
#   --terceira        troca para a câmera em terceira pessoa
#   --espera s        segundos até o print (padrão 2.5)
#   --runas a,b,c     dá essas runas ao mago
#   --barra-cheia     equipa 2 medalhões forjados nos espaços vazios
#   --usar n          usa o medalhão n (1 a 4) aos 0,5 s (fica em recarga)
#   --camera x,y,z    câmera livre nesse ponto (ex.: ver o mago de frente)
#   --alvo-camera x,y,z  para onde a câmera livre olha (padrão 0,1,0)
#
# Exemplo (canto de atmosfera):
#   ferramentas/tirar_print.sh /tmp/canto.png --posicao -13,1.6,-9 --olhar -13,1.6,-13
set -uo pipefail

if [ $# -lt 1 ]; then
  sed -n '2,20p' "$0"
  exit 1
fi

SAIDA="$(realpath -m "$1")"
shift
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"

if ! pgrep -x Xvfb > /dev/null; then
  Xvfb :99 -screen 0 1280x720x24 > /dev/null 2>&1 &
  sleep 2
fi

cd "$RAIZ/jogo"
DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 timeout 60 godot --rendering-driver opengl3 --path . \
  --script res://scripts/ferramentas/tirar_print.gd -- --saida "$SAIDA" "$@" > /tmp/tirar_print.log 2>&1
codigo=$?

grep -E "SCRIPT ERROR|Parse Error|PRINT SALVO" /tmp/tirar_print.log
if [ ! -f "$SAIDA" ]; then
  echo "Print não foi gerado. Log completo em /tmp/tirar_print.log"
  exit 1
fi
exit $codigo
