#!/bin/bash
# Grava um trecho do jogo quadro a quadro com o tempo de jogo exato (modo
# Movie Maker do Godot), mesmo nesta máquina lenta e sem GPU: roda a uns 10%
# da velocidade real, então grave só o que importa. Depois monta a folha de
# quadros numerada (para quem só enxerga imagens paradas), um GIF (para o
# Vitor ver o movimento) e a lista de quadros em que o som toca.
# Ferramenta do agente animador (ADR-042). Renderiza em Compatibility.
#
# Uso:
#   ferramentas/gravar_quadros.sh PASTA [--fps 30] [--colunas 6] [--de N] [--ate N] [--passo N] [opções do tirar_print]
# Opções do tirar_print: --posicao, --olhar, --terceira, --camera, --alvo-camera,
#   --runas, --barra-cheia, --usar n, --interagir, --andar s, --galinha x,y,z, --espera s
#   (a gravação dura até --espera; padrão 2.5 s)
# Saída em PASTA: quadros/ (PNG), folha.png, movimento.gif, som.txt
#
# Exemplo (mago lançando em terceira pessoa):
#   ferramentas/gravar_quadros.sh /tmp/lancar --terceira --posicao 0,0,8 --olhar 0,1.5,-30 --usar 1 --espera 1.4 --de 12 --ate 30
set -uo pipefail

if [ $# -lt 1 ]; then
  sed -n '2,19p' "$0"
  exit 1
fi

PASTA="$(realpath -m "$1")"
shift
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
FPS=30; COLUNAS=6; DE=0; ATE=-1; PASSO=1
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --fps) FPS="$2"; shift 2 ;;
    --colunas) COLUNAS="$2"; shift 2 ;;
    --de) DE="$2"; shift 2 ;;
    --ate) ATE="$2"; shift 2 ;;
    --passo) PASSO="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

rm -rf "$PASTA/quadros"
mkdir -p "$PASTA/quadros"
if ! pgrep -x Xvfb > /dev/null; then
  Xvfb :99 -screen 0 1280x720x24 > /dev/null 2>&1 &
  sleep 1
fi

cd "$RAIZ/jogo"
DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 timeout 600 godot --rendering-driver opengl3 --path . \
  --write-movie "$PASTA/quadros/q.png" --fixed-fps "$FPS" \
  --script res://scripts/ferramentas/tirar_print.gd -- --saida "$PASTA/final.png" "${ARGS[@]}" \
  > "$PASTA/log.txt" 2>&1
codigo=$?
if ! ls "$PASTA"/quadros/q*.png > /dev/null 2>&1; then
  echo "Nenhum quadro gravado (código $codigo). Veja $PASTA/log.txt"
  exit 1
fi
grep -E "SCRIPT ERROR|Parse Error" "$PASTA/log.txt" && echo "Atenção: erro de script durante a gravação (ver log.txt)."

python3 -I "$RAIZ/ferramentas/folha_quadros.py" "$PASTA" "$FPS" "$COLUNAS" "$DE" "$ATE" "$PASSO"
# GIF leve (paleta própria, 480 px, 15 quadros por segundo de jogo) para
# caber no repositório; a folha de quadros guarda o detalhe quadro a quadro.
ffmpeg -loglevel error -y -framerate "$FPS" -i "$PASTA/quadros/q%08d.png" \
  -vf "fps=15,scale=480:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer" \
  "$PASTA/movimento.gif" && echo "GIF: $PASTA/movimento.gif"
